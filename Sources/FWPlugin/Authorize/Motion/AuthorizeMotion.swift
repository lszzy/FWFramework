//
//  AuthorizeMotion.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/8.
//

import CoreMotion
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Motion
extension AuthorizeType {
    /// 运动，Info.plist需配置NSMotionUsageDescription
    public static let motion: AuthorizeType = .init("motion")
}

// MARK: - AuthorizeMotion
/// 运动授权
public class AuthorizeMotion: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeMotion()
    
    public lazy var activityManager: CMMotionActivityManager = {
        let result = CMMotionActivityManager()
        return result
    }()

    public func authorizeStatus() -> AuthorizeStatus {
        let status = CMMotionActivityManager.authorizationStatus()
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
        let date = Date()
        activityManager.queryActivityStarting(from: date, to: date, to: .main) { _, error in
            self.activityManager.stopActivityUpdates()
            let status: AuthorizeStatus = error == nil ? .authorized : .denied
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(status, error)
                }
            }
        }
    }
}

// MARK: - Autoloader+Motion
@objc extension Autoloader {
    static func loadPlugin_Motion() {
        AuthorizeManager.presetAuthorize(.motion) { AuthorizeMotion.shared }
    }
}
