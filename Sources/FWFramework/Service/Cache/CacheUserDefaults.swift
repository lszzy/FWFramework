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

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        var value = userDefaults.object(forKey: cacheKey(key))
        if let data = value as? Data, let coder = ArchiveCoder.unarchivedCoder(data) {
            value = coder.archivableObject(as: T.self)
        }
        return value as? T
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
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
