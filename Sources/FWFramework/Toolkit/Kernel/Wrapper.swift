//
//  Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation
import QuartzCore

// MARK: - WrapperGlobal
/// 全局包装器
///
/// 自定义WrapperGlobal为任意名称(如APP)示例：
/// ```swift
/// public typealias APP = WrapperGlobal
/// ```
/// 使用示例：
/// ```swift
/// APP.safeString(object)
/// ```
public class WrapperGlobal {
    /// 当前框架版本号
    public static let version = "9.1.0"
}

/// 全局包装器别名
@_spi(FW) public typealias FW = WrapperGlobal

// MARK: - Wrapper
/// 属性包装器
public class Wrapper<Base> {
    /// 原始对象
    public let base: Base

    /// 初始化方法
    public init(_ base: Base) {
        self.base = base
    }
}

// MARK: - WrapperCompatible
/// 属性包装器兼容协议
///
/// 自定义wrapperExtension为任意名称(如app)示例：
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
}

/// 注意事项：
/// 1. 静态扩展方法中尽量不使用Base.self，因为可能会出现类型与预期不一致的场景。
///   示例1：Logger.fw.method()，此时method中Base.self为Logger，预期结果正确
///   示例2：ModuleBundle类 class var 实现时使用 self.fw.method()，此时子类method中Base.self可能为父类，与预期结果不一致
/// 2. 扩展方法闭包中请勿使用[weak self]，而应该使用[weak base]，因为self使用完就会释放；闭包如需强引用base，可外部声明let strongBase = base，再在内部使用strongBase即可；详情可参见Block实现
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
extension Decimal: WrapperCompatible {}
extension CGFloat: WrapperCompatible {}
extension CGPoint: WrapperCompatible {}
extension CGSize: WrapperCompatible {}
extension CGRect: WrapperCompatible {}
extension NSObject: WrapperCompatible {}
