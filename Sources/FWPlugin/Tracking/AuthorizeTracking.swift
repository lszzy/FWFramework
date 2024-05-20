//
//  AuthorizeTracking.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import AdSupport
import AppTrackingTransparency
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Wrapper+UIDevice
extension Wrapper where Base: UIDevice {
    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限
    public static var deviceIDFA: String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}

// MARK: - AuthorizeType+Tracking
extension AuthorizeType {
    /// 广告跟踪，Info.plist需配置NSUserTrackingUsageDescription
    public static let tracking: AuthorizeType = .init("tracking")
}

// MARK: - AuthorizeTracking
/// IDFA授权，iOS14+使用AppTrackingTransparency，其它使用AdSupport
public class AuthorizeTracking: NSObject, AuthorizeProtocol {
    public static let shared = AuthorizeTracking()
    
    public func authorizeStatus() -> AuthorizeStatus {
        if #available(iOS 14.0, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
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
        } else {
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? .authorized : .denied
        }
    }
    
    public func requestAuthorize(_ completion: ((AuthorizeStatus, Error?) -> Void)?) {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if completion != nil {
                    DispatchQueue.fw.mainAsync {
                        completion?(self.authorizeStatus(), nil)
                    }
                }
            }
        } else {
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(self.authorizeStatus(), nil)
                }
            }
        }
    }
}

// MARK: - Autoloader+Tracking
@objc extension Autoloader {
    static func loadPlugin_Tracking() {
        AuthorizeManager.presetAuthorize(.tracking) { AuthorizeTracking.shared }
    }
}
