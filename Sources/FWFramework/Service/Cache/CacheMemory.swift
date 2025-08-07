//
//  CacheMemory.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// 内存缓存
open class CacheMemory: CacheEngine, @unchecked Sendable {
    /// 单例模式
    public static let shared = CacheMemory()

    private var cachePool = [String: Any]()

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        cachePool[key] as? T
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
        cachePool[key] = object
    }

    override open func clearCache(forKey key: String) {
        cachePool.removeValue(forKey: key)
    }

    override open func clearAllCaches() {
        cachePool.removeAll()
    }

    override open func readCacheKeys() -> [String] {
        cachePool.keys.filter { !isExpireKey($0) }
    }
}
