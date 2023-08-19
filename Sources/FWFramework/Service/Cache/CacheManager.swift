//
//  CacheManager.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation

/// 缓存类型枚举
public struct CacheType: RawRepresentable, Equatable, Hashable {
    
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

/// 缓存管理器
public class CacheManager: NSObject {
    
    /// 自定义缓存创建句柄，默认nil
    public static var factoryBlock: ((CacheType) -> CacheProtocol?)?
    
    /// 获取指定类型的缓存单例对象
    public static func manager(type: CacheType) -> CacheProtocol? {
        if let cache = factoryBlock?(type) {
            return cache
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
