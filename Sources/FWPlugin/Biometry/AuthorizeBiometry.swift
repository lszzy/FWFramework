//
//  AuthorizeBiometry.swift
//  FWFramework
//
//  Created by wuyong on 2024/5/17.
//

import LocalAuthentication
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Biometry
extension AuthorizeType {
    /// 生物识别，Info.plist需配置NSFaceIDUsageDescription
    public static let biometry: AuthorizeType = .init("biometry")
}

// MARK: - AuthorizeBiometry
/// 生物识别授权
public class AuthorizeBiometry: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeBiometry()

    // MARK: - Accessor
    /// 当前识别策略，默认为1不含Passcode，可设置为2开启Passcode
    public var policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    /// 本地化识别原因，默认身份验证，详见evaluatePolicy
    public var localizedReason: (@Sendable (LAContext) -> String)?
    /// 本地化回滚标题，默认根据policy自动处理，详见LAContext。为空串时隐藏Fallback操作，为nil时开启Fallback且需处理LAError.userFallback错误
    public var localizedFallbackTitle: (@Sendable (LAContext) -> String?)?
    /// 自定义上下文配置句柄，默认nil
    public var customContextBlock: (@Sendable (LAContext) -> Void)?

    /// 当前生物识别类型，如none|touchID|faceID|opticID，详见LAContext
    public var biometryType: LABiometryType {
        if _biometryType == nil {
            _biometryType = LAContext().biometryType
        }
        return _biometryType ?? .none
    }

    private var _biometryType: LABiometryType?

    private var latestAuthorizeStatus: AuthorizeStatus?
    private var latestAuthorizeError: Error?

    // MARK: - AuthorizeProtocol
    /// 同步查询状态，默认返回最近一次认证状态，未认证时为notDetermined，不支持时为restricted
    public func authorizeStatus() -> AuthorizeStatus {
        if latestAuthorizeStatus == nil {
            createContext()
        }

        let status = latestAuthorizeStatus ?? .notDetermined
        return status
    }

    /// 异步查询状态，主线程回调，默认返回最近一次认证状态，未认证时为notDetermined，不支持时为restricted
    public func authorizeStatus(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        if latestAuthorizeStatus == nil {
            createContext()
        }

        let status = latestAuthorizeStatus ?? .notDetermined
        let error = latestAuthorizeError
        DispatchQueue.fw.mainAsync {
            completion?(status, error)
        }
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        guard let context = createContext() else {
            let status = latestAuthorizeStatus ?? .restricted
            let error = latestAuthorizeError
            DispatchQueue.fw.mainAsync {
                completion?(status, error)
            }
            return
        }

        if localizedFallbackTitle != nil {
            context.localizedFallbackTitle = localizedFallbackTitle?(context)
        } else {
            context.localizedFallbackTitle = policy == .deviceOwnerAuthenticationWithBiometrics ? "" : nil
        }
        customContextBlock?(context)

        let reason = localizedReason?(context) ?? FrameworkBundle.biometryReasonTitle
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            let status: AuthorizeStatus = success ? .authorized : .denied
            self?.latestAuthorizeStatus = status
            self?.latestAuthorizeError = error

            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(status, error)
                }
            }
        }
    }

    // MARK: - Private
    @discardableResult
    private func createContext() -> LAContext? {
        let context = LAContext()
        if _biometryType == nil {
            _biometryType = context.biometryType
        }

        var nserror: NSError?
        guard context.canEvaluatePolicy(policy, error: &nserror) else {
            latestAuthorizeStatus = .restricted
            latestAuthorizeError = nserror
            return nil
        }
        return context
    }
}

// MARK: - Autoloader+Biometry
@objc extension Autoloader {
    static func loadPlugin_Biometry() {
        AuthorizeManager.presetAuthorize(.biometry) { AuthorizeBiometry.shared }
    }
}
