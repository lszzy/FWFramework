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
    }
    
    /// 单例模式
    public static let shared = CacheMMKV()
    
    /// 主线程初始化MMKV，仅第一次生效
    @discardableResult
    public static func initializeMMKV(
        rootDir: String? = nil,
        groupDir: String? = nil,
        logLevel: MMKVLogLevel = .info,
        handler: MMKVHandler? = nil
    ) -> String {
        Configuration.initialized = true
        if let groupDir {
            return MMKV.initialize(rootDir: rootDir, groupDir: groupDir, logLevel: logLevel, handler: handler)
        } else {
            return MMKV.initialize(rootDir: rootDir, logLevel: logLevel, handler: handler)
        }
    }

    private let mmkv: MMKV?

    /// 初始化默认MMKV缓存
    override public convenience init() {
        self.init(cryptKey: nil)
    }
    
    /// 指定加密key初始化默认MMKV缓存
    public init(cryptKey: Data?) {
        if !Configuration.initialized { Self.initializeMMKV() }
        self.mmkv = cryptKey != nil ? MMKV.defaultMMKV(withCryptKey: cryptKey) : MMKV.default()
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
    
    // 和非缓存Key区分开，防止清除非缓存信息
    private func cacheKey(_ key: String) -> String {
        "FWCache.\(key)"
    }

    // MARK: - CacheEngineProtocol
    override open func readCache(forKey key: String) -> Any? {
        guard let data = mmkv?.data(forKey: cacheKey(key)) else { return nil }
        return data.fw.unarchivedObject()
    }

    override open func writeCache(_ object: Any, forKey key: String) {
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

// MARK: - Autoloader+MMKV
@objc extension Autoloader {
    static func loadPlugin_MMKV() {
        CacheManager.presetCache(.mmkv) { CacheMMKV.shared }
    }
}
