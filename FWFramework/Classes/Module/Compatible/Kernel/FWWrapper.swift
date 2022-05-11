//
//  FWWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - FWWrapper

/// 全局包装器
public struct FWWrapper {}

/// 全局包装器别名
///
/// 自定义FW为任意名称(如APP)示例：
/// public typealias APP = FWWrapper
/// 使用示例：
/// APP.safeString(object)
public typealias FW = FWWrapper

// MARK: - FWWrapperExtension

/// 扩展包装器
public struct FWWrapperExtension<Base> {
    /// 原始对象
    public let base: Base
    
    /// 初始化方法
    public init(_ base: Base) {
        self.base = base
    }
}

/// 包装器扩展协议
///
/// 自定义fw为任意名称(如app)示例：
/// extension FWWrapperExtended {
///     public static var app: FWWrapperExtension<Self>.Type { fw }
///     public var app: FWWrapperExtension<Self> { fw }
/// }
/// 使用示例：
/// String.app.jsonEncode(object)
public protocol FWWrapperExtended {
    /// 关联类型
    associatedtype Base
    
    /// 类包装器属性
    static var fw: FWWrapperExtension<Base>.Type { get }
    
    /// 对象包装器属性
    var fw: FWWrapperExtension<Base> { get }
}

extension FWWrapperExtended {
    /// 类包装器属性
    public static var fw: FWWrapperExtension<Self>.Type {
        return FWWrapperExtension<Self>.self
    }
    
    /// 对象包装器属性
    public var fw: FWWrapperExtension<Self> {
        return FWWrapperExtension(self)
    }
}

// MARK: - FWWrapperExtended

extension Int: FWWrapperExtended {}
extension Int8: FWWrapperExtended {}
extension Int16: FWWrapperExtended {}
extension Int32: FWWrapperExtended {}
extension Int64: FWWrapperExtended {}
extension UInt: FWWrapperExtended {}
extension UInt8: FWWrapperExtended {}
extension UInt16: FWWrapperExtended {}
extension UInt32: FWWrapperExtended {}
extension UInt64: FWWrapperExtended {}
extension Float: FWWrapperExtended {}
extension Double: FWWrapperExtended {}
extension Bool: FWWrapperExtended {}
extension String: FWWrapperExtended {}
extension Data: FWWrapperExtended {}
extension Date: FWWrapperExtended {}
extension URL: FWWrapperExtended {}
extension Array: FWWrapperExtended {}
extension Set: FWWrapperExtended {}
extension Dictionary: FWWrapperExtended {}
