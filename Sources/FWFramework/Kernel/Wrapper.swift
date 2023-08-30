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

/// 自定义FW为任意名称(如APP)示例：
/// public typealias APP = WrapperGlobal
/// 使用示例：
/// APP.safeString(object)
#if FWMacroSPI
@_spi(FW) public typealias FW = WrapperGlobal
#else
public typealias FW = WrapperGlobal
#endif

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
    #if FWMacroSPI
    @_spi(FW) static var fw: Wrapper<WrapperBase>.Type { get set }
    #else
    static var fw: Wrapper<WrapperBase>.Type { get set }
    #endif
    
    /// 对象包装器属性
    #if FWMacroSPI
    @_spi(FW) var fw: Wrapper<WrapperBase> { get set }
    #else
    var fw: Wrapper<WrapperBase> { get set }
    #endif
    
}

extension WrapperCompatible {
    
    /// 类包装器属性
    #if FWMacroSPI
    @_spi(FW) public static var fw: Wrapper<Self>.Type {
        get { Wrapper<Self>.self }
        set {}
    }
    #else
    public static var fw: Wrapper<Self>.Type {
        get { Wrapper<Self>.self }
        set {}
    }
    #endif
    
    /// 对象包装器属性
    #if FWMacroSPI
    @_spi(FW) public var fw: Wrapper<Self> {
        get { Wrapper(self) }
        set {}
    }
    #else
    public var fw: Wrapper<Self> {
        get { Wrapper(self) }
        set {}
    }
    #endif
    
}

// MARK: - WrapperObject
/// 属性包装器对象，用于扩展AnyObject
public typealias WrapperObject = AnyObject & WrapperCompatible
