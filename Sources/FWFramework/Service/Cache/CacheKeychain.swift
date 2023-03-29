//
//  CacheKeychain.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// Keychain缓存
open class CacheKeychain: CacheEngine {

    /// 单例模式
    public static let shared = CacheKeychain()
    
    private var group: String?
    
    public override init() {
        super.init()
    }

    /// 分组对象
    public init(group: String?) {
        super.init()
        self.group = group
    }

    // MARK: - CacheEngineProtocol
    open override func readCache(forKey key: String) -> Any? {
        return passwordObject(forService: "FWCache", account: key)
    }

    open override func writeCache(_ object: Any, forKey key: String) {
        setPasswordObject(object, forService: "FWCache", account: key)
    }

    open override func clearCache(forKey key: String) {
        deletePassword(forService: "FWCache", account: key)
    }

    open override func clearAllCaches() {
        deletePassword(forService: "FWCache", account: nil)
    }

    // MARK: - Private
    private func passwordData(forService service: String, account: String?) -> Data? {
        var result: AnyObject?
        var query = query(forService: service, account: account)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != errSecSuccess {
            return nil
        }
        return result as? Data
    }

    private func passwordObject(forService service: String, account: String?) -> Any? {
        guard let passwordData = passwordData(forService: service, account: account) else {
            return nil
        }

        let object = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
        return object
    }

    @discardableResult
    private func setPasswordData(_ passwordData: Data, forService service: String, account: String?) -> Bool {
        var searchQuery = query(forService: service, account: account)
        var status = SecItemCopyMatching(searchQuery as CFDictionary, nil)

        // 更新数据
        if status == errSecSuccess {
            var query = [String: Any]()
            query[kSecValueData as String] = passwordData
            status = SecItemUpdate(searchQuery as CFDictionary, query as CFDictionary)
        // 添加数据
        } else if status == errSecItemNotFound {
            var query = query(forService: service, account: account)
            query[kSecValueData as String] = passwordData
            status = SecItemAdd(query as CFDictionary, nil)
        }
        return status == errSecSuccess
    }

    @discardableResult
    private func setPasswordObject(_ passwordObject: Any, forService service: String, account: String?) -> Bool {
        let passwordData = NSKeyedArchiver.archivedData(withRootObject: passwordObject)
        return setPasswordData(passwordData, forService: service, account: account)
    }

    @discardableResult
    private func deletePassword(forService service: String, account: String?) -> Bool {
        let query = query(forService: service, account: account)
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    private func query(forService service: String, account: String?) -> [String: Any] {
        var query = [String: Any]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        if let group = group {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

}
