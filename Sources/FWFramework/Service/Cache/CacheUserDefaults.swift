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
    override open func readCache(forKey key: String) -> Any? {
        var value = userDefaults.object(forKey: cacheKey(key))
        return ArchiveCoder.safeUnarchivedObject(value)
    }

    override open func writeCache(_ object: Any, forKey key: String) {
        let value = ArchiveCoder.safeArchivedData(object)
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
