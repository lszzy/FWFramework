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

    open override func readCache(forKey key: String) -> Any? {
        return cachePool[key]
    }

    open override func writeCache(_ object: Any, forKey key: String) {
        cachePool[key] = object
    }

    open override func clearCache(forKey key: String) {
        cachePool.removeValue(forKey: key)
    }

    open override func clearAllCaches() {
        cachePool.removeAll()
    }
    
}
