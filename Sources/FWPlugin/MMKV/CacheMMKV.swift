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
    public static let mmkv: CacheType = .init("mmkv")
}

// MARK: - CacheMMKV
/// MMKV缓存。复杂对象需遵循NSCoding|AnyArchivable协议
///
/// [MMKV](https://github.com/Tencent/MMKV)
open class CacheMMKV: CacheEngine, @unchecked Sendable {
    /// 单例模式
    public static let shared = CacheMMKV()

    private nonisolated(unsafe) static var mmkvInitialized = false
    private nonisolated(unsafe) static var mmkvCryptKey: Data?

    /// 主线程初始化MMKV，仅第一次生效，参数cryptKey仅对默认MMKV生效
    public static func initializeMMKV(
        cryptKey: Data? = nil,
        rootDir: String? = nil,
        groupDir: String? = nil,
        logLevel: MMKVLogLevel = .info,
        handler: MMKVHandler? = nil
    ) {
        guard !mmkvInitialized else { return }
        mmkvInitialized = true
        mmkvCryptKey = cryptKey
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
        if !CacheMMKV.mmkvInitialized { Self.initializeMMKV() }
        if let cryptKey = CacheMMKV.mmkvCryptKey {
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
        if !CacheMMKV.mmkvInitialized { Self.initializeMMKV() }
        self.mmkv = MMKV(mmapID: mmapID, cryptKey: cryptKey, rootPath: rootPath, mode: mode, expectedCapacity: 0)
        super.init()
    }

    /// 和非缓存Key区分开，防止清除非缓存信息
    private func cacheKey(_ key: String) -> String {
        "FWCache.\(key)"
    }

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        if let compatibleType = T.self as? CacheMMKVCompatible.Type,
           let mmkv, mmkv.contains(key: cacheKey(key)),
           let value = compatibleType.readMMKV(mmkv, forKey: cacheKey(key)) as? T {
            return value
        }

        guard let data = mmkv?.data(forKey: cacheKey(key)) else { return nil }
        return data.fw.unarchivedObject(as: T.self)
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
        if let compatibleType = T.self as? CacheMMKVCompatible.Type, let mmkv {
            compatibleType.writeMMKV(mmkv, forKey: cacheKey(key), value: object)
            return
        }

        guard let data = Data.fw.archivedData(object) else { return }
        mmkv?.set(data, forKey: cacheKey(key))
    }

    override open func clearCache(forKey key: String) {
        mmkv?.removeValue(forKey: cacheKey(key))
    }

    override open func clearAllCaches() {
        var keys: [String] = []
        mmkv?.enumerateKeys { key, _ in
            if key.hasPrefix("FWCache.") {
                keys.append(key)
            }
        }
        mmkv?.removeValues(forKeys: keys)
    }

    override open func readCacheKeys() -> [String] {
        var result: [String] = []
        let keys = mmkv?.allKeys() as? [String] ?? []
        for key in keys {
            if key.hasPrefix("FWCache."), !isExpireKey(key) {
                result.append(String(key.suffix(from: key.index(key.startIndex, offsetBy: 8))))
            }
        }
        return result
    }
}

// MARK: - CacheMMKVCompatible
/// 可扩展MMKV缓存兼容类型，用于针对指定类型优化存取方式，默认采用Archiver归档存取
public protocol CacheMMKVCompatible {
    /// 从MMKV读取当前类型值，未实现时默认采用Archiver解档方式
    static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self?

    /// 往MMKV写入当前类型值，未实现时默认采用Archiver归档方式。参数value类型为Self，此处为兼容Swift编译设置为Any
    static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any)
}

extension Int: CacheMMKVCompatible {
    public static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self? {
        Int(mmkv.int64(forKey: key))
    }

    public static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any) {
        mmkv.set(Int64(value as! Self), forKey: key)
    }
}

extension Bool: CacheMMKVCompatible {
    public static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self? {
        mmkv.bool(forKey: key)
    }

    public static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any) {
        mmkv.set(value as! Self, forKey: key)
    }
}

extension Float: CacheMMKVCompatible {
    public static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self? {
        mmkv.float(forKey: key)
    }

    public static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any) {
        mmkv.set(value as! Self, forKey: key)
    }
}

extension Double: CacheMMKVCompatible {
    public static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self? {
        mmkv.double(forKey: key)
    }

    public static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any) {
        mmkv.set(value as! Self, forKey: key)
    }
}

extension String: CacheMMKVCompatible {
    public static func readMMKV(_ mmkv: MMKV, forKey key: String) -> Self? {
        mmkv.string(forKey: key)
    }

    public static func writeMMKV(_ mmkv: MMKV, forKey key: String, value: Any) {
        mmkv.set(value as! Self, forKey: key)
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
    private let block: ((CacheMMKV, String) -> Value?)?

    private var cacheMMKV: CacheMMKV {
        mmapID != nil ? CacheMMKV(mmapID: mmapID!) : CacheMMKV.shared
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
        self.block = nil
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
        self.block = { $0.object(forKey: $1) as WrappedValue? }
    }

    public var wrappedValue: Value {
        get {
            let value = block != nil ? block?(cacheMMKV, key) : cacheMMKV.object(forKey: key) as Value?
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
