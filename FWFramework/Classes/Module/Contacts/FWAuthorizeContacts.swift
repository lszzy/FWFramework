//
//  FWAuthorizeContacts.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Contacts
#if FWFrameworkSPM
import FWFramework
import FWFrameworkCompatible
#endif

/// 通讯录授权
@objcMembers public class FWAuthorizeContacts: NSObject, FWAuthorizeProtocol, FWAutoloadProtocol {
    public static func autoload() {
        FWAuthorizeManager.registerAuthorize(.contacts) {
            return FWAuthorizeContacts()
        }
    }
    
    public func authorizeStatus() -> FWAuthorizeStatus {
        let status = CNContactStore.authorizationStatus(for: .contacts)
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
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            let status: FWAuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
}
