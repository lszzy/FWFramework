//
//  CacheKeychain.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// Keychain缓存。复杂对象需遵循NSCoding|AnyArchivable协议
open class CacheKeychain: CacheEngine, @unchecked Sendable {
    /// 单例模式
    public static let shared = CacheKeychain()

    private var group: String?
    private var service = "FWCache"
    private let keysKey = "__KEYS__"

    override public init() {
        super.init()
    }

    /// 分组对象
    public init(group: String?, service: String? = nil) {
        super.init()
        self.group = group
        if let service, !service.isEmpty {
            self.service = service
        }
    }

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        passwordObject(forService: service, account: key)
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
        setPasswordObject(object, forService: service, account: key)

        if !isExpireKey(key) {
            var keys = readCacheKeys()
            if !keys.contains(key) {
                keys.append(key)
                setPasswordObject(keys, forService: service, account: keysKey)
            }
        }
    }

    override open func clearCache(forKey key: String) {
        deletePassword(forService: service, account: key)

        if !isExpireKey(key) {
            var keys = readCacheKeys()
            if keys.contains(key) {
                keys.removeAll { $0 == key }
                setPasswordObject(keys, forService: service, account: keysKey)
            }
        }
    }

    override open func clearAllCaches() {
        deletePassword(forService: service, account: nil)
    }

    override open func readCacheKeys() -> [String] {
        readCache(forKey: keysKey) ?? []
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

    private func passwordObject<T>(forService service: String, account: String?) -> T? {
        guard let passwordData = passwordData(forService: service, account: account) else {
            return nil
        }

        return passwordData.fw.unarchivedObject(as: T.self)
    }

    @discardableResult
    private func setPasswordData(_ passwordData: Data, forService service: String, account: String?) -> Bool {
        let searchQuery = query(forService: service, account: account)
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
    private func setPasswordObject<T>(_ passwordObject: T, forService service: String, account: String?) -> Bool {
        guard let passwordData = Data.fw.archivedData(passwordObject) else { return false }
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
        if let account {
            query[kSecAttrAccount as String] = account
        }
        if let group {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}
