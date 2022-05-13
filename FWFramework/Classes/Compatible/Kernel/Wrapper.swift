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

// MARK: - FW
/// 全局包装器(因struct只读，只能用class)
///
/// 自定义FW为任意名称(如APP)示例：
/// public typealias APP = FW
/// 使用示例：
/// APP.safeString(object)
public class FW {}

// MARK: - Wrapper
/// 属性包装器(因struct只读，只能用class)
public class Wrapper<Base> {
    
    /// 原始对象
    public private(set) var base: Base
    
    /// 初始化方法
    public init(_ base: Base) {
        self.base = base
    }
    
}

// MARK: - WrapperCompatible
/// 属性包装器兼容协议
///
/// 自定义fw为任意名称(如app)示例：
/// extension WrapperCompatible {
///     public static var app: Wrapper<Self>.Type { get { fw } set {} }
///     public var app: Wrapper<Self> { get { fw } set {} }
/// }
/// 使用示例：
/// String.app.jsonEncode(object)
public protocol WrapperCompatible {
    
    /// 关联类型
    associatedtype WrapperBase
    
    /// 类包装器属性
    static var fw: Wrapper<WrapperBase>.Type { get set }
    
    /// 对象包装器属性
    var fw: Wrapper<WrapperBase> { get set }
    
}

extension WrapperCompatible {
    
    /// 类包装器属性
    public static var fw: Wrapper<Self>.Type {
        get { Wrapper<Self>.self }
        set {}
    }
    
    /// 对象包装器属性
    public var fw: Wrapper<Self> {
        get { Wrapper(self) }
        set {}
    }
    
}

// MARK: - WrapperCompatible
extension Int: WrapperCompatible {}
extension Int8: WrapperCompatible {}
extension Int16: WrapperCompatible {}
extension Int32: WrapperCompatible {}
extension Int64: WrapperCompatible {}
extension UInt: WrapperCompatible {}
extension UInt8: WrapperCompatible {}
extension UInt16: WrapperCompatible {}
extension UInt32: WrapperCompatible {}
extension UInt64: WrapperCompatible {}
extension Float: WrapperCompatible {}
extension Double: WrapperCompatible {}
extension Bool: WrapperCompatible {}
extension String: WrapperCompatible {}
extension Data: WrapperCompatible {}
extension Date: WrapperCompatible {}
extension URL: WrapperCompatible {}
extension Array: WrapperCompatible {}
extension Set: WrapperCompatible {}
extension Dictionary: WrapperCompatible {}
extension NSObject: WrapperCompatible {}
