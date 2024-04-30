//
//  AuthorizeContacts.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Contacts
#if FWMacroSPM
import FWFramework
#endif

// MARK: - AuthorizeType+Contacts
extension AuthorizeType {
    /// 联系人，Info.plist需配置NSContactsUsageDescription
    public static let contacts: AuthorizeType = .init("contacts")
}

// MARK: - AuthorizeContacts
/// 通讯录授权
private class AuthorizeContacts: NSObject, AuthorizeProtocol {
    func authorizeStatus() -> AuthorizeStatus {
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
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
}

// MARK: - Autoloader+Contacts
@objc extension Autoloader {
    static func loadPlugin_Contacts() {
        AuthorizeManager.presetAuthorize(.contacts) { AuthorizeContacts() }
    }
}
