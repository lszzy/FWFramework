//
//  FWAuthorizeCalendar.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import EventKit
#if FWFrameworkSPM
import FWFramework
import FWFrameworkCompatible
#endif

/// 日历授权
@objcMembers public class FWAuthorizeCalendar: NSObject, FWAuthorizeProtocol, FWAutoloadProtocol {
    private var type: EKEntityType = .event
    
    public static func autoload() {
        FWAuthorizeManager.registerAuthorize(.calendars) {
            return FWAuthorizeCalendar(type: .event)
        }
        FWAuthorizeManager.registerAuthorize(.reminders) {
            return FWAuthorizeCalendar(type: .reminder)
        }
    }
    
    public init(type: EKEntityType) {
        super.init()
        self.type = type
    }
    
    public func authorizeStatus() -> FWAuthorizeStatus {
        let status = EKEventStore.authorizationStatus(for: type)
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
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        EKEventStore().requestAccess(to: type) { granted, error in
            let status: FWAuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
}
