//
//  AuthorizeSpeech.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/8.
//

import Speech
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Speech
extension AuthorizeType {
    /// 语音识别，Info.plist需配置NSSpeechRecognitionUsageDescription
    public static let speech: AuthorizeType = .init("speech")
}

// MARK: - AuthorizeSpeech
/// 语音识别授权
public class AuthorizeSpeech: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeSpeech()

    public func authorizeStatus() -> AuthorizeStatus {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        default:
            return .notDetermined
        }
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        SFSpeechRecognizer.requestAuthorization { _ in
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(self.authorizeStatus(), nil)
                }
            }
        }
    }
}

// MARK: - Autoloader+Speech
@objc extension Autoloader {
    static func loadPlugin_Speech() {
        AuthorizeManager.presetAuthorize(.speech) { AuthorizeSpeech.shared }
    }
}
