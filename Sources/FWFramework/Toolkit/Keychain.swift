//
//  Keychain.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import Security

// MARK: - KeychainManager
/// Keychain管理器
public class KeychainManager {
    
    // MARK: - Accessor
    /// 单例模式
    public static let shared = KeychainManager()
    
    private var group: String?
    
    // MARK: - Lifecycle
    /// 公用对象
    public init() {}
    
    /// 分组对象
    public init(group: String?) {
        self.group = group
    }
    
    // MARK: - Public
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
        return passwordData.fw.unarchivedObject()
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
        guard let passwordData = Data.fw.archivedData(passwordObject) else { return false }
        return setPasswordData(passwordData, forService: service, account: account)
    }
    
    /// 删除数据
    @discardableResult
    public func deletePassword(forService service: String?, account: String?) -> Bool {
        let query = query(forService: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Private
    private func query(forService service: String?, account: String?) -> [String: Any] {
        var query: [String: Any] = [:]
        query[String(kSecClass)] = kSecClassGenericPassword
        if let service = service { query[String(kSecAttrService)] = service }
        if let account = account { query[String(kSecAttrAccount)] = account }
        if let group = group { query[String(kSecAttrAccessGroup)] = group }
        return query
    }
    
}
