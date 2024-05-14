//
//  CacheEngine.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

// MARK: - CacheProtocol
/// 缓存调用协议。复杂对象需遵循NSCoding协议
public protocol CacheProtocol {
    
    /// 读取某个缓存
    func object(forKey key: String) -> Any?
    /// 设置某个缓存
    func setObject(_ object: Any?, forKey key: String)
    /// 设置某个缓存，支持缓存有效期，小于等于0为永久有效
    func setObject(_ object: Any?, forKey key: String, withExpire expire: TimeInterval)
    /// 移除某个缓存
    func removeObject(forKey key: String)
    /// 清空所有缓存
    func removeAllObjects()
    
}

// MARK: - CacheEngineProtocol
/// 缓存引擎内部协议。复杂对象需遵循NSCoding协议
public protocol CacheEngineProtocol {
    
    /// 从引擎读取某个缓存，内部方法，必须实现
    func readCache(forKey key: String) -> Any?
    /// 从引擎写入某个缓存，内部方法，必须实现
    func writeCache(_ object: Any, forKey key: String)
    /// 从引擎清空某个缓存，内部方法，必须实现
    func clearCache(forKey key: String)
    /// 从引擎清空所有缓存，内部方法，必须实现
    func clearAllCaches()
    
}

// MARK: - CacheEngine
/// 缓存引擎基类，自动管理缓存有效期，线程安全。复杂对象需遵循NSCoding协议
open class CacheEngine: NSObject, CacheProtocol, CacheEngineProtocol {
    
    private var semaphore = DispatchSemaphore(value: 1)
    
    override public init() {
        super.init()
    }
    
    private func expireKey(_ key: String) -> String {
        return key + ".__EXPIRE__"
    }
    
    // MARK: - Public
    open func object(forKey key: String) -> Any? {
        if key.isEmpty { return nil }
        
        semaphore.wait()
        let object = readCache(forKey: key)
        if object == nil {
            semaphore.signal()
            return nil
        }
        
        // 检查缓存有效期
        if let expire = readCache(forKey: expireKey(key)) as? NSNumber {
            // 检查是否过期，大于0为过期
            if Date().timeIntervalSince1970 > expire.doubleValue {
                clearCache(forKey: key)
                clearCache(forKey: expireKey(key))
                semaphore.signal()
                return nil
            }
        }
        
        semaphore.signal()
        return object
    }
    
    open func setObject(_ object: Any?, forKey key: String) {
        setObject(object, forKey: key, withExpire: 0)
    }
    
    open func setObject(_ object: Any?, forKey key: String, withExpire expire: TimeInterval) {
        if key.isEmpty { return }
        
        semaphore.wait()
        if let object = object {
            writeCache(object, forKey: key)
            
            // 小于等于0为永久有效
            if expire <= 0 {
                clearCache(forKey: expireKey(key))
            } else {
                writeCache(NSNumber(value: Date().timeIntervalSince1970 + expire), forKey: expireKey(key))
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
    
    // MARK: - Archive
    open func archivedData(_ object: Any) -> Data? {
        return Data.fw.archivedData(object)
    }
    
    open func unarchivedObject(_ data: Data) -> Any? {
        return data.fw.unarchivedObject()
    }
    
    // MARK: - CacheEngineProtocol
    open func readCache(forKey key: String) -> Any? {
        // 子类重写
        return nil
    }
    
    open func writeCache(_ object: Any, forKey key: String) {
        // 子类重写
    }
    
    open func clearCache(forKey key: String) {
        // 子类重写
    }
    
    open func clearAllCaches() {
        // 子类重写
    }
    
}
