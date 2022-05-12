//
//  Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Wrapper
/// 全局包装器
public struct Wrapper {}

/// 全局包装器别名
///
/// 自定义FW为任意名称(如APP)示例：
/// public typealias APP = Wrapper
/// 使用示例：
/// APP.safeString(object)
public typealias FW = Wrapper

// MARK: - WrapperExtension
/// 扩展包装器
public struct WrapperExtension<Base> {
    
    /// 原始对象
    public let base: Base
    
    /// 初始化方法
    public init(_ base: Base) {
        self.base = base
    }
    
}

// MARK: - WrapperExtended
/// 包装器扩展协议
///
/// 自定义fw为任意名称(如app)示例：
/// extension WrapperExtended {
///     public static var app: WrapperExtension<Self>.Type { fw }
///     public var app: WrapperExtension<Self> { fw }
/// }
/// 使用示例：
/// String.app.jsonEncode(object)
public protocol WrapperExtended {
    
    /// 关联类型
    associatedtype Base
    
    /// 类包装器属性
    static var fw: WrapperExtension<Base>.Type { get }
    
    /// 对象包装器属性
    var fw: WrapperExtension<Base> { get }
    
}

extension WrapperExtended {
    
    /// 类包装器属性
    public static var fw: WrapperExtension<Self>.Type {
        return WrapperExtension<Self>.self
    }
    
    /// 对象包装器属性
    public var fw: WrapperExtension<Self> {
        return WrapperExtension(self)
    }
    
}

// MARK: - WrapperExtended
extension Int: WrapperExtended {}
extension Int8: WrapperExtended {}
extension Int16: WrapperExtended {}
extension Int32: WrapperExtended {}
extension Int64: WrapperExtended {}
extension UInt: WrapperExtended {}
extension UInt8: WrapperExtended {}
extension UInt16: WrapperExtended {}
extension UInt32: WrapperExtended {}
extension UInt64: WrapperExtended {}
extension Float: WrapperExtended {}
extension Double: WrapperExtended {}
extension Bool: WrapperExtended {}
extension String: WrapperExtended {}
extension Data: WrapperExtended {}
extension Date: WrapperExtended {}
extension URL: WrapperExtended {}
extension Array: WrapperExtended {}
extension Set: WrapperExtended {}
extension Dictionary: WrapperExtended {}
extension NSObject: WrapperExtended {}
