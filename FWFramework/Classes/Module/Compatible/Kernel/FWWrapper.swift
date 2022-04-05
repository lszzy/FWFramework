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
/// Swift包装器
public struct FWWrapper<Base> {
    /// 原始对象
    public let base: Base
    
    /// 初始化方法
    public init(_ base: Base) {
        self.base = base
    }
}

/// Swift包装器兼容协议
public protocol FWWrapperCompatible {
    /// 关联类型
    associatedtype WrapperBase
    
    /// 类包装器属性
    static var fw: FWWrapper<WrapperBase>.Type { get }
    
    /// 对象包装器属性
    var fw: FWWrapper<WrapperBase> { get }
}

extension FWWrapperCompatible {
    /// 类包装器属性
    public static var fw: FWWrapper<Self>.Type {
        return FWWrapper<Self>.self
    }
    
    /// 对象包装器属性
    public var fw: FWWrapper<Self> {
        return FWWrapper(self)
    }
}

// MARK: - FWWrapperCompatible

extension String: FWWrapperCompatible {}
extension Data: FWWrapperCompatible {}
extension URL: FWWrapperCompatible {}
extension Int: FWWrapperCompatible {}
extension Int8: FWWrapperCompatible {}
extension Int16: FWWrapperCompatible {}
extension Int32: FWWrapperCompatible {}
extension Int64: FWWrapperCompatible {}
extension UInt: FWWrapperCompatible {}
extension UInt8: FWWrapperCompatible {}
extension UInt16: FWWrapperCompatible {}
extension UInt32: FWWrapperCompatible {}
extension UInt64: FWWrapperCompatible {}
extension Float: FWWrapperCompatible {}
extension Double: FWWrapperCompatible {}
extension Bool: FWWrapperCompatible {}
extension Array: FWWrapperCompatible {}
extension Set: FWWrapperCompatible {}
extension Dictionary: FWWrapperCompatible {}
