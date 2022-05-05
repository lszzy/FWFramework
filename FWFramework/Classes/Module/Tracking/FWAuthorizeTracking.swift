//
//  FWAuthorizeTracking.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
import AdSupport
import AppTrackingTransparency
#if FWFrameworkSPM
import FWFramework
import FWFrameworkCompatible
#endif

@objc extension UIDevice {
    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public class var fwDeviceIDFA: String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}

/// IDFA授权，iOS14+使用AppTrackingTransparency，其它使用AdSupport
private class FWAuthorizeTracking: NSObject, FWAuthorizeProtocol {
    func authorizeStatus() -> FWAuthorizeStatus {
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
    
    func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if completion != nil {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        completion?(self.authorizeStatus())
                    }
                }
            }
        } else {
            if completion != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

@objc extension FWAutoloader {
    private func loadAuthorizeTracking() {
        FWAuthorizeManager.registerAuthorize(.tracking) {
            return FWAuthorizeTracking()
        }
    }
}
