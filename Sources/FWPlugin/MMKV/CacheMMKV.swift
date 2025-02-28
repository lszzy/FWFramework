//
//  CacheMMKV.swift
//  FWFramework
//
//  Created by wuyong on 2025/2/26.
//

import MMKV
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - CacheType+MMKV
extension CacheType {
    /// MMKV缓存
    public static let mmkv: CacheType = .init(6)
}

// MARK: - CacheMMKV
/// MMKV缓存。复杂对象需遵循NSCoding|AnyArchivable协议
///
/// [MMKV](https://github.com/Tencent/MMKV)
open class CacheMMKV: CacheEngine, @unchecked Sendable {
    private actor Configuration {
        static var initialized = false
        static var cryptKey: Data?
    }
    
    /// 单例模式
    public static let shared = CacheMMKV()
    
    /// 主线程初始化MMKV，仅第一次生效，参数cryptKey仅对默认MMKV生效
    public static func initializeMMKV(
        cryptKey: Data? = nil,
        rootDir: String? = nil,
        groupDir: String? = nil,
        logLevel: MMKVLogLevel = .info,
        handler: MMKVHandler? = nil
    ) {
        guard !Configuration.initialized else { return }
        Configuration.initialized = true
        Configuration.cryptKey = cryptKey
        if let groupDir {
            MMKV.initialize(rootDir: rootDir, groupDir: groupDir, logLevel: logLevel, handler: handler)
        } else {
            MMKV.initialize(rootDir: rootDir, logLevel: logLevel, handler: handler)
        }
    }

    /// 获取原始MMKV对象
    public let mmkv: MMKV?

    /// 初始化默认MMKV缓存
    override public init() {
        if !Configuration.initialized { Self.initializeMMKV() }
        if let cryptKey = Configuration.cryptKey {
            self.mmkv = MMKV.defaultMMKV(withCryptKey: cryptKey)
        } else {
            self.mmkv = MMKV.default()
        }
        super.init()
    }
    
    /// 指定参数初始化MMKV缓存
    public init(
        mmapID: String,
        cryptKey: Data? = nil,
        rootPath: String? = nil,
        mode: MMKVMode = .singleProcess
    ) {
        if !Configuration.initialized { Self.initializeMMKV() }
        self.mmkv = MMKV(mmapID: mmapID, cryptKey: cryptKey, rootPath: rootPath, mode: mode, expectedCapacity: 0)
        super.init()
    }
    
    /// 和非缓存Key区分开，防止清除非缓存信息
    private func cacheKey(_ key: String) -> String {
        "FWCache.\(key)"
    }
    
    // MARK: - MMKV
    /// 高性能读取Int值，必须和setInt(_:forKey:)配对使用
    open func int(forKey key: String, defaultValue: Int = 0) -> Int {
        if let value = mmkv?.int64(forKey: key) {
            return Int(value)
        }
        return defaultValue
    }
    
    /// 高性能设置Int值，必须和int(forKey:)配对使用
    open func setInt(_ value: Int?, forKey key: String, expireDuration: Int? = nil) {
        if let value {
            if let expireDuration, expireDuration >= 0 {
                mmkv?.set(Int64(value), forKey: key, expireDuration: UInt32(expireDuration))
            } else {
                mmkv?.set(Int64(value), forKey: key)
            }
        } else {
            mmkv?.removeValue(forKey: key)
        }
    }
    
    /// 高性能读取Bool值，必须和setBool(_:forKey:)配对使用
    open func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return mmkv?.bool(forKey: key) ?? defaultValue
    }
    
    /// 高性能设置Bool值，必须和bool(forKey:)配对使用
    open func setBool(_ value: Bool?, forKey key: String, expireDuration: Int? = nil) {
        if let value {
            if let expireDuration, expireDuration >= 0 {
                mmkv?.set(value, forKey: key, expireDuration: UInt32(expireDuration))
            } else {
                mmkv?.set(value, forKey: key)
            }
        } else {
            mmkv?.removeValue(forKey: key)
        }
    }
    
    /// 高性能读取Double值，必须和setDouble(_:forKey:)配对使用
    open func double(forKey key: String, defaultValue: Double = 0) -> Double {
        return mmkv?.double(forKey: key) ?? defaultValue
    }
    
    /// 高性能设置Double值，必须和double(forKey:)配对使用
    open func setDouble(_ value: Double?, forKey key: String, expireDuration: Int? = nil) {
        if let value {
            if let expireDuration, expireDuration >= 0 {
                mmkv?.set(value, forKey: key, expireDuration: UInt32(expireDuration))
            } else {
                mmkv?.set(value, forKey: key)
            }
        } else {
            mmkv?.removeValue(forKey: key)
        }
    }
    
    /// 高性能读取String值，必须和setString(_:forKey:)配对使用
    open func string(forKey key: String, defaultValue: String? = nil) -> String? {
        return mmkv?.string(forKey: key, defaultValue: defaultValue)
    }
    
    /// 高性能设置String值，必须和string(forKey:)配对使用
    open func setString(_ value: String?, forKey key: String, expireDuration: Int? = nil) {
        if let value {
            if let expireDuration, expireDuration >= 0 {
                mmkv?.set(value, forKey: key, expireDuration: UInt32(expireDuration))
            } else {
                mmkv?.set(value, forKey: key)
            }
        } else {
            mmkv?.removeValue(forKey: key)
        }
    }

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        guard let data = mmkv?.data(forKey: cacheKey(key)) else { return nil }
        return data.fw.unarchivedObject() as? T
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
        guard let data = Data.fw.archivedData(object) else { return }
        mmkv?.set(data, forKey: cacheKey(key))
    }

    override open func clearCache(forKey key: String) {
        mmkv?.removeValue(forKey: cacheKey(key))
    }

    override open func clearAllCaches() {
        var keys: [String] = []
        mmkv?.enumerateKeys({ key, _ in
            if key.hasPrefix("FWCache.") {
                keys.append(key)
            }
        })
        mmkv?.removeValues(forKeys: keys)
    }
}

// MARK: - MMAPValue
/// MMKV缓存属性包装器注解，默认为手工指定或初始值
///
/// 使用示例：
/// @MMAPValue("mmapKey")
/// static var mmapValue: String = ""
@propertyWrapper
public struct MMAPValue<Value> {
    private let key: String
    private let defaultValue: Value
    private let mmapID: String?
    
    private var cacheMMKV: CacheMMKV {
        return mmapID != nil ? CacheMMKV(mmapID: mmapID!) : CacheMMKV.shared
    }

    public init(
        wrappedValue: Value,
        _ key: String,
        defaultValue: Value? = nil,
        mmapID: String? = nil
    ) {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.mmapID = mmapID
    }

    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: Value? = nil,
        mmapID: String? = nil
    ) where WrappedValue? == Value {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.mmapID = mmapID
    }

    public var wrappedValue: Value {
        get {
            let value = cacheMMKV.object(forKey: key) as Value?
            return !Optional<Any>.isNil(value) ? (value ?? defaultValue) : defaultValue
        }
        set {
            if !Optional<Any>.isNil(newValue) {
                cacheMMKV.setObject(newValue, forKey: key)
            } else {
                cacheMMKV.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Autoloader+MMKV
@objc extension Autoloader {
    static func loadPlugin_MMKV() {
        CacheManager.presetCache(.mmkv) { CacheMMKV.shared }
    }
}
