//
//  Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - WrapperGlobal
/// 全局包装器(因struct只读，只能用class)
public class WrapperGlobal {}

/// 全局包装器别名
///
/// 自定义FW为任意名称(如APP)示例：
/// ```swift
/// public typealias APP = WrapperGlobal
/// ```
/// 使用示例：
/// ```swift
/// APP.safeString(object)
/// ```
@_spi(FW) public typealias FW = WrapperGlobal

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
/// ```swift
/// extension WrapperCompatible {
///     public static var app: Wrapper<Self>.Type { get { wrapperExtension } set {} }
///     public var app: Wrapper<Self> { get { wrapperExtension } set {} }
/// }
/// ```
/// 使用示例：
/// ```swift
/// String.app.jsonEncode(object)
/// ```
public protocol WrapperCompatible {
    
    /// 关联类型
    associatedtype WrapperBase
    
    /// wrapperExtension类包装器属性
    static var wrapperExtension: Wrapper<WrapperBase>.Type { get set }
    /// wrapperExtension对象包装器属性
    var wrapperExtension: Wrapper<WrapperBase> { get set }
    
    /// fw类包装器属性
    @_spi(FW) static var fw: Wrapper<WrapperBase>.Type { get set }
    /// fw对象包装器属性
    @_spi(FW) var fw: Wrapper<WrapperBase> { get set }
    
}

extension WrapperCompatible {
    
    /// wrapperExtension类包装器属性
    public static var wrapperExtension: Wrapper<Self>.Type {
        get { Wrapper<Self>.self }
        set {}
    }
    
    /// wrapperExtension对象包装器属性
    public var wrapperExtension: Wrapper<Self> {
        get { Wrapper(self) }
        set {}
    }
    
    /// fw类包装器属性
    @_spi(FW) public static var fw: Wrapper<Self>.Type {
        get { Wrapper<Self>.self }
        set {}
    }
    
    /// fw对象包装器属性
    @_spi(FW) public var fw: Wrapper<Self> {
        get { Wrapper(self) }
        set {}
    }
    
}

// MARK: - WrapperObject
/// 属性包装器对象，用于扩展AnyObject
///
/// 注意事项：
/// 1. 需要AnyObject通用的才扩展WrapperObject，否则扩展NSObject
/// 2. 静态static方法需要使用self的才扩展WrapperObject，否则扩展NSObject
/// 3. 扩展WrapperObject时如需使用static var变量，可借助NSObject的fileprivate扩展
public typealias WrapperObject = AnyObject & WrapperCompatible
