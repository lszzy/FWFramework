//
//  CacheUserDefaults.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// UserDefaults缓存。复杂对象需遵循AnyArchivable协议
open class CacheUserDefaults: CacheEngine, @unchecked Sendable {
    /// 单例模式
    public static let shared = CacheUserDefaults()

    private let userDefaults: UserDefaults

    /// 初始化
    override public init() {
        self.userDefaults = UserDefaults.standard
        super.init()
    }

    /// 分组对象
    public init(group: String?) {
        self.userDefaults = UserDefaults(suiteName: group) ?? .standard
        super.init()
    }

    /// 和非缓存Key区分开，防止清除非缓存信息
    private func cacheKey(_ key: String) -> String {
        "FWCache.\(key)"
    }
    
    // MARK: - UserDefaults
    /// 高性能读取Int值，必须和setInt(_:forKey:)配对使用
    open func int(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    /// 高性能设置Int值，必须和int(forKey:)配对使用
    open func setInt(_ value: Int?, forKey key: String) {
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// 高性能读取Bool值，必须和setBool(_:forKey:)配对使用
    open func bool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    /// 高性能设置Bool值，必须和bool(forKey:)配对使用
    open func setBool(_ value: Bool?, forKey key: String) {
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// 高性能读取Double值，必须和setDouble(_:forKey:)配对使用
    open func double(forKey key: String) -> Double {
        return userDefaults.double(forKey: key)
    }
    
    /// 高性能设置Double值，必须和double(forKey:)配对使用
    open func setDouble(_ value: Double?, forKey key: String) {
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    /// 高性能读取String值，必须和setString(_:forKey:)配对使用
    open func string(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    /// 高性能设置String值，必须和string(forKey:)配对使用
    open func setString(_ value: String?, forKey key: String) {
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    // MARK: - CacheEngineProtocol
    override open func readCache(forKey key: String) -> Any? {
        var value = userDefaults.object(forKey: cacheKey(key))
        if let data = value as? Data, let coder = ArchiveCoder.unarchiveData(data) {
            value = coder.archivableObject
        }
        return value
    }

    override open func writeCache(_ object: Any, forKey key: String) {
        var value: Any? = object
        if ArchiveCoder.isArchivableObject(object) {
            value = Data.fw.archivedData(object)
        }
        userDefaults.set(value, forKey: cacheKey(key))
        userDefaults.synchronize()
    }

    override open func clearCache(forKey key: String) {
        userDefaults.removeObject(forKey: cacheKey(key))
        userDefaults.synchronize()
    }

    override open func clearAllCaches() {
        let dict = userDefaults.dictionaryRepresentation()
        for key in dict.keys {
            if key.hasPrefix("FWCache.") {
                userDefaults.removeObject(forKey: key)
            }
        }
        userDefaults.synchronize()
    }
}
