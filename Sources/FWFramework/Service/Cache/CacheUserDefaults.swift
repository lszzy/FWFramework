//
//  CacheUserDefaults.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// UserDefaults缓存
open class CacheUserDefaults: CacheEngine {
    
    /// 单例模式
    public static let shared = CacheUserDefaults()
    
    private let userDefaults: UserDefaults
    
    /// 初始化
    public override init() {
        self.userDefaults = UserDefaults.standard
        super.init()
    }
    
    /// 分组对象
    public init(group: String?) {
        self.userDefaults = UserDefaults(suiteName: group) ?? .standard
        super.init()
    }
    
    // 和非缓存Key区分开，防止清除非缓存信息
    private func cacheKey(_ key: String) -> String {
        return "FWCache.\(key)"
    }
    
    // MARK: - CacheEngineProtocol
    open override func readCache(forKey key: String) -> Any? {
        var value = self.userDefaults.object(forKey: self.cacheKey(key))
        if let data = value as? Data, ArchiveCoder.isArchivableData(data) {
            value = data.fw.unarchivedObject()
        }
        return value
    }
    
    open override func writeCache(_ object: Any, forKey key: String) {
        var value: Any? = object
        if ArchiveCoder.isArchivableObject(object) {
            value = Data.fw.archivedData(object)
        }
        self.userDefaults.set(value, forKey: self.cacheKey(key))
        self.userDefaults.synchronize()
    }
    
    open override func clearCache(forKey key: String) {
        self.userDefaults.removeObject(forKey: self.cacheKey(key))
        self.userDefaults.synchronize()
    }
    
    open override func clearAllCaches() {
        let dict = self.userDefaults.dictionaryRepresentation()
        for key in dict.keys {
            if key.hasPrefix("FWCache.") {
                self.userDefaults.removeObject(forKey: key)
            }
        }
        self.userDefaults.synchronize()
    }
    
}
