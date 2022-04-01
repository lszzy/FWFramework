//
//  FWKeychain.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
import Security

/// Keychain管理器
@objcMembers public class FWKeychainManager: NSObject {
    /// 单例模式
    public static let sharedInstance = FWKeychainManager()
    
    private var group: String?
    
    /// 公用对象
    public override init() {
        super.init()
    }
    
    /// 分组对象
    public init(group: String?) {
        super.init()
        self.group = group
    }
    
    private func query(forService service: String?, account: String?) -> [String: Any] {
        var query: [String: Any] = [:]
        query[String(kSecClass)] = kSecClassGenericPassword
        if let service = service { query[String(kSecAttrService)] = service }
        if let account = account { query[String(kSecAttrAccount)] = account }
        if let group = group { query[String(kSecAttrAccessGroup)] = group }
        return query
    }
    
    /// 读取String数据
    public func password(forService service: String?, account: String?) -> String? {
        guard let passwordData = passwordData(forService: service, account: account) else { return nil }
        return String(data: passwordData, encoding: .utf8)
    }
    
    /// 读取Data数据
    public func passwordData(forService service: String?, account: String?) -> Data? {
        var query = query(forService: service, account: account)
        query[String(kSecReturnData)] = kCFBooleanTrue
        query[String(kSecMatchLimit)] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }
    
    /// 读取Object数据
    public func passwordObject(forService service: String?, account: String?) -> Any? {
        guard let passwordData = passwordData(forService: service, account: account) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: passwordData)
    }
    
    /// 保存String数据
    @discardableResult
    public func setPassword(_ password: String, forService service: String?, account: String?) -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }
        return setPasswordData(passwordData, forService: service, account: account)
    }
    
    /// 保存Data数据
    @discardableResult
    public func setPasswordData(_ passwordData: Data, forService service: String?, account: String?) -> Bool {
        let searchQuery = query(forService: service, account: account)
        var status = SecItemCopyMatching(searchQuery as CFDictionary, nil)
        // 更新数据
        if status == errSecSuccess {
            var query: [String: Any] = [:]
            query[String(kSecValueData)] = passwordData
            status = SecItemUpdate(searchQuery as CFDictionary, query as CFDictionary)
        // 更新数据
        } else if status == errSecItemNotFound {
            var query = query(forService: service, account: account)
            query[String(kSecValueData)] = passwordData
            status = SecItemAdd(query as CFDictionary, nil)
        }
        return status == errSecSuccess
    }
    
    /// 保存Object数据
    @discardableResult
    public func setPasswordObject(_ passwordObject: Any, forService service: String?, account: String?) -> Bool {
        let passwordData = NSKeyedArchiver.archivedData(withRootObject: passwordObject)
        return setPasswordData(passwordData, forService: service, account: account)
    }
    
    /// 删除数据
    @discardableResult
    public func deletePassword(forService service: String?, account: String?) -> Bool {
        let query = query(forService: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
