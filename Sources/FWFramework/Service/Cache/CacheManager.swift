//
//  CacheManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

// MARK: - CacheType
/// 缓存类型枚举
public struct CacheType: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 默认缓存，同文件
    public static let `default`: CacheType = .init(0)
    /// 内存缓存
    public static let memory: CacheType = .init(1)
    /// UserDefaults缓存
    public static let userDefaults: CacheType = .init(2)
    /// Keychain缓存
    public static let keychain: CacheType = .init(3)
    /// 文件缓存
    public static let file: CacheType = .init(4)
    /// Sqlite数据库缓存
    public static let sqlite: CacheType = .init(5)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: - CacheManager
/// 缓存管理器
public class CacheManager: NSObject, @unchecked Sendable {
    private static let shared = CacheManager()
    private var blocks: [CacheType: @Sendable () -> CacheProtocol] = [:]

    /// 注册指定类型的缓存管理器创建句柄，用于动态扩展缓存类型
    public static func registerCache(_ type: CacheType, block: @escaping @Sendable () -> CacheProtocol) {
        shared.blocks[type] = block
    }

    /// 预置指定类型的缓存管理器创建句柄，已注册时不生效，用于动态扩展缓存类型
    @discardableResult
    public static func presetCache(_ type: CacheType, block: @escaping @Sendable () -> CacheProtocol) -> Bool {
        guard shared.blocks[type] == nil else { return false }
        shared.blocks[type] = block
        return true
    }

    /// 获取指定类型的缓存单例对象
    public static func manager(type: CacheType) -> CacheProtocol? {
        if let block = shared.blocks[type] {
            return block()
        }

        switch type {
        case .default:
            return CacheFile.shared
        case .memory:
            return CacheMemory.shared
        case .userDefaults:
            return CacheUserDefaults.shared
        case .keychain:
            return CacheKeychain.shared
        case .file:
            return CacheFile.shared
        case .sqlite:
            return CacheSqlite.shared
        default:
            return nil
        }
    }
}

// MARK: - CachedValue
/// 缓存属性包装器注解，默认为手工指定或初始值
///
/// 使用示例：
/// @CachedValue("cacheKey")
/// static var cacheValue: String = ""
@propertyWrapper
public struct CachedValue<Value> {
    private let key: String
    private let defaultValue: Value
    private let type: CacheType
    private let block: ((CacheType, String) -> Value?)?

    public init(
        wrappedValue: Value,
        _ key: String,
        defaultValue: Value? = nil,
        type: CacheType = .default
    ) {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.type = type
        self.block = nil
    }

    public init<WrappedValue>(
        wrappedValue: WrappedValue? = nil,
        _ key: String,
        defaultValue: Value? = nil,
        type: CacheType = .default
    ) where WrappedValue? == Value {
        self.key = key
        self.defaultValue = defaultValue ?? wrappedValue
        self.type = type
        self.block = { CacheManager.manager(type: $0)?.object(forKey: $1) as WrappedValue? }
    }

    public var wrappedValue: Value {
        get {
            let value = block != nil ? block?(type, key) : CacheManager.manager(type: type)?.object(forKey: key) as Value?
            return !Optional<Any>.isNil(value) ? (value ?? defaultValue) : defaultValue
        }
        set {
            if !Optional<Any>.isNil(newValue) {
                CacheManager.manager(type: type)?.setObject(newValue, forKey: key)
            } else {
                CacheManager.manager(type: type)?.removeObject(forKey: key)
            }
        }
    }
}
