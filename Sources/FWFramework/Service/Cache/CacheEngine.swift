//
//  CacheEngine.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

// MARK: - CacheProtocol
/// 缓存调用协议。复杂对象需遵循NSCoding|AnyArchivable协议
public protocol CacheProtocol {
    /// 读取某个缓存
    func object<T>(forKey key: String) -> T?
    /// 设置某个缓存
    func setObject<T>(_ object: T?, forKey key: String)
    /// 设置某个缓存，支持缓存有效期，小于等于0为永久有效
    func setObject<T>(_ object: T?, forKey key: String, withExpire expire: TimeInterval)
    /// 移除某个缓存
    func removeObject(forKey key: String)
    /// 清空所有缓存
    func removeAllObjects()
    /// 获取所有缓存key
    func allObjectKeys() -> [String]
}

// MARK: - CacheEngineProtocol
/// 缓存引擎内部协议。复杂对象需遵循NSCoding|AnyArchivable协议
public protocol CacheEngineProtocol {
    /// 从引擎读取某个缓存，内部方法，必须实现
    func readCache<T>(forKey key: String) -> T?
    /// 从引擎写入某个缓存，内部方法，必须实现
    func writeCache<T>(_ object: T, forKey key: String)
    /// 从引擎清空某个缓存，内部方法，必须实现
    func clearCache(forKey key: String)
    /// 从引擎清空所有缓存，内部方法，必须实现
    func clearAllCaches()
    /// 从引擎读取所有缓存key，内部方法，必须实现
    func readCacheKeys() -> [String]
}

// MARK: - CacheEngine
/// 缓存引擎基类，自动管理缓存有效期，线程安全。复杂对象需遵循NSCoding|AnyArchivable协议
open class CacheEngine: NSObject, CacheProtocol, CacheEngineProtocol {
    private var semaphore = DispatchSemaphore(value: 1)

    override public init() {
        super.init()
    }

    /// 读取指定key缓存的有效期，大于0有效，小于等于0无效，nil未设置有效期
    open func expire(forKey key: String) -> TimeInterval? {
        if key.isEmpty { return nil }

        var expire: TimeInterval?
        semaphore.wait()
        if let number = readCache(forKey: expireKey(key)) as NSNumber? {
            expire = number.doubleValue - Date.fw.currentTime
        }
        semaphore.signal()
        return expire
    }
    
    /// 判断指定key是否为有效期key，子类使用
    open func isExpireKey(_ key: String) -> Bool {
        key.hasSuffix(".__EXPIRE__")
    }

    private func expireKey(_ key: String) -> String {
        key + ".__EXPIRE__"
    }

    // MARK: - CacheProtocol
    open func object<T>(forKey key: String) -> T? {
        if key.isEmpty { return nil }

        semaphore.wait()
        let object = readCache(forKey: key) as T?
        if object == nil {
            semaphore.signal()
            return nil
        }

        // 检查缓存有效期
        if let expire = readCache(forKey: expireKey(key)) as NSNumber? {
            // 检查是否过期，大于0为过期
            if Date.fw.currentTime > expire.doubleValue {
                clearCache(forKey: key)
                clearCache(forKey: expireKey(key))
                semaphore.signal()
                return nil
            }
        }

        semaphore.signal()
        return object
    }

    open func setObject<T>(_ object: T?, forKey key: String) {
        setObject(object, forKey: key, withExpire: 0)
    }

    open func setObject<T>(_ object: T?, forKey key: String, withExpire expire: TimeInterval) {
        if key.isEmpty { return }

        semaphore.wait()
        if let object {
            writeCache(object, forKey: key)

            // 小于等于0为永久有效
            if expire <= 0 {
                clearCache(forKey: expireKey(key))
            } else {
                writeCache(NSNumber(value: Date.fw.currentTime + expire), forKey: expireKey(key))
            }
        } else {
            clearCache(forKey: key)
            clearCache(forKey: expireKey(key))
        }
        semaphore.signal()
    }

    open func removeObject(forKey key: String) {
        if key.isEmpty { return }

        semaphore.wait()
        clearCache(forKey: key)
        clearCache(forKey: expireKey(key))
        semaphore.signal()
    }

    open func removeAllObjects() {
        semaphore.wait()
        clearAllCaches()
        semaphore.signal()
    }
    
    open func allObjectKeys() -> [String] {
        semaphore.wait()
        let keys = readCacheKeys()
        semaphore.signal()
        return keys
    }

    // MARK: - CacheEngineProtocol
    open func readCache<T>(forKey key: String) -> T? {
        fatalError("readCache(forKey:) has not been implemented")
    }

    open func writeCache<T>(_ object: T, forKey key: String) {
        fatalError("writeCache(_:forKey:) has not been implemented")
    }

    open func clearCache(forKey key: String) {
        fatalError("clearCache(forKey:) has not been implemented")
    }

    open func clearAllCaches() {
        fatalError("clearAllCaches() has not been implemented")
    }
    
    open func readCacheKeys() -> [String] {
        fatalError("readCacheKeys() has not been implemented")
    }
}
