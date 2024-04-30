//
//  AuthorizeMicrophone.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import AVFoundation
#if FWMacroSPM
import FWFramework
#endif

// MARK: - AuthorizeType+Microphone
extension AuthorizeType {
    /// 麦克风，Info.plist需配置NSMicrophoneUsageDescription
    public static let microphone: AuthorizeType = .init("microphone")
}

// MARK: - AuthorizeMicrophone
/// 麦克风授权
private class AuthorizeMicrophone: NSObject, AuthorizeProtocol {
    func authorizeStatus() -> AuthorizeStatus {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .denied:
            return .denied
        case .granted:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
}

// MARK: - Autoloader+Microphone
@objc extension Autoloader {
    static func loadPlugin_Microphone() {
        AuthorizeManager.presetAuthorize(.microphone) { AuthorizeMicrophone() }
    }
}
