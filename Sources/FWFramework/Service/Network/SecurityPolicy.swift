//
//  SecurityPolicy.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import Security

public enum SSLPinningMode: Int, Sendable {
    case none = 0
    case publicKey
    case certificate
}

open class SecurityPolicy: NSObject {
    open private(set) var pinningMode: SSLPinningMode = .none
    open var pinnedCertificates: Set<Data>? {
        didSet { updatePinnedCertificates() }
    }

    open var allowInvalidCertificates = false
    open var validatesDomainName = true

    private var pinnedPublicKeys: Set<SecKey>?

    public static func certificates(in bundle: Bundle) -> Set<Data> {
        let paths = bundle.paths(forResourcesOfType: "cer", inDirectory: ".")
        var certificates: Set<Data> = []
        for path in paths {
            if let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                certificates.insert(certificateData)
            }
        }
        return certificates
    }

    public static var `default`: SecurityPolicy {
        let securityPolicy = SecurityPolicy()
        securityPolicy.pinningMode = .none
        return securityPolicy
    }

    override public init() {
        super.init()
    }

    public convenience init(pinningMode: SSLPinningMode) {
        let defaultPinnedCertificates = Self.certificates(in: .main)
        self.init(pinningMode: pinningMode, pinnedCertificates: defaultPinnedCertificates)
    }

    public convenience init(pinningMode: SSLPinningMode, pinnedCertificates: Set<Data>) {
        self.init()
        self.pinningMode = pinningMode
        self.pinnedCertificates = pinnedCertificates
        updatePinnedCertificates()
    }

    private func updatePinnedCertificates() {
        if let pinnedCertificates {
            var mutablePublicKeys: Set<SecKey> = []
            for certificate in pinnedCertificates {
                if let publicKey = Self.publicKey(for: certificate) {
                    mutablePublicKeys.insert(publicKey)
                }
            }
            pinnedPublicKeys = mutablePublicKeys
        } else {
            pinnedPublicKeys = nil
        }
    }

    open func evaluateServerTrust(_ serverTrust: SecTrust, forDomain domain: String? = nil) -> Bool {
        if domain != nil && allowInvalidCertificates && validatesDomainName && (pinningMode == .none || (pinnedCertificates?.count ?? 0) == 0) {
            Logger.debug(group: Logger.fw.moduleName, "In order to validate a domain name for self signed certificates, you MUST use pinning.")
            return false
        }

        var policies = [SecPolicy]()
        if validatesDomainName {
            policies.append(SecPolicyCreateSSL(true, domain != nil ? (domain! as CFString) : nil))
        } else {
            policies.append(SecPolicyCreateBasicX509())
        }

        SecTrustSetPolicies(serverTrust, policies as CFArray)

        if pinningMode == .none {
            return allowInvalidCertificates || Self.serverTrustIsValid(serverTrust)
        } else if !allowInvalidCertificates && !Self.serverTrustIsValid(serverTrust) {
            return false
        }

        switch pinningMode {
        case .certificate:
            var certificates = [SecCertificate]()
            pinnedCertificates?.forEach { certificateData in
                if let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) {
                    certificates.append(certificate)
                }
            }
            SecTrustSetAnchorCertificates(serverTrust, certificates as CFArray)

            if !Self.serverTrustIsValid(serverTrust) {
                return false
            }

            let serverCertificates = Self.certificateTrustChain(for: serverTrust)
            for trustChainCertificate in serverCertificates.reversed() {
                if pinnedCertificates?.contains(trustChainCertificate) ?? false {
                    return true
                }
            }

            return false

        case .publicKey:
            var trustedPublicKeyCount = 0
            let publicKeys = Self.publicKeyTrustChain(for: serverTrust)

            for trustChainPublicKey in publicKeys {
                pinnedPublicKeys?.forEach { pinnedPublicKey in
                    if trustChainPublicKey == pinnedPublicKey {
                        trustedPublicKeyCount += 1
                    }
                }
            }
            return trustedPublicKeyCount > 0

        default:
            return false
        }
    }

    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if key == "pinnedPublicKeys" {
            return Set(arrayLiteral: "pinnedCertificates")
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }

    private static func publicKey(for certificate: Data) -> SecKey? {
        guard let allowedCertificate = SecCertificateCreateWithData(nil, certificate as CFData) else { return nil }

        let policy = SecPolicyCreateBasicX509()
        var allowedTrust: SecTrust?
        let status = SecTrustCreateWithCertificates(allowedCertificate, policy, &allowedTrust)
        guard status == errSecSuccess, let allowedTrust else { return nil }
        guard SecTrustEvaluateWithError(allowedTrust, nil) else { return nil }

        let allowedPublicKey = SecTrustCopyPublicKey(allowedTrust)
        return allowedPublicKey
    }

    private static func serverTrustIsValid(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        return isValid
    }

    private static func certificateTrustChain(for serverTrust: SecTrust) -> [Data] {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var trustChain = [Data]()
        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
                let certificateData = SecCertificateCopyData(certificate) as Data
                trustChain.append(certificateData)
            }
        }
        return trustChain
    }

    private static func publicKeyTrustChain(for serverTrust: SecTrust) -> [SecKey] {
        let policy = SecPolicyCreateBasicX509()
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var trustChain = [SecKey]()
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else { continue }
            let certificates = [certificate] as CFArray

            var trust: SecTrust?
            let status = SecTrustCreateWithCertificates(certificates, policy, &trust)
            guard status == errSecSuccess, let trust else { continue }
            guard SecTrustEvaluateWithError(trust, nil) else { continue }
            if let publicKey = SecTrustCopyPublicKey(trust) {
                trustChain.append(publicKey)
            }
        }
        return trustChain
    }
}
