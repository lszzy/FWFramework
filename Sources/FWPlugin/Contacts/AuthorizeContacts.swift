//
//  AuthorizeContacts.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Contacts
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Contacts
extension AuthorizeType {
    /// 联系人，Info.plist需配置NSContactsUsageDescription
    public static let contacts: AuthorizeType = .init("contacts")
}

// MARK: - AuthorizeContacts
/// 通讯录授权
public class AuthorizeContacts: NSObject, AuthorizeProtocol {
    public static let shared = AuthorizeContacts()
    
    public func authorizeStatus() -> AuthorizeStatus {
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
    
    public func requestAuthorize(_ completion: ((AuthorizeStatus, Error?) -> Void)?) {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status, error)
                }
            }
        }
    }
}

// MARK: - Autoloader+Contacts
@objc extension Autoloader {
    static func loadPlugin_Contacts() {
        AuthorizeManager.presetAuthorize(.contacts) { AuthorizeContacts.shared }
    }
}
