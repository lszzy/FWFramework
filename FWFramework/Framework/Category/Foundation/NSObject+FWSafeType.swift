//
//  NSObject+FWSafeType.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 安全解包协议
public protocol FWSafelyUnwrapped {
    // 提供安全解包默认值
    static var fwUnwrappedValue: Self { get }
}

/// 可选值安全解包扩展
extension Optional where Wrapped: FWSafelyUnwrapped {
    /// 解包对象实现了安全解包协议，当值为nil时，会返回默认值
    public func fwSafeValue() -> Wrapped {
        if let value = self {
            return value
        } else {
            return Wrapped.fwUnwrappedValue
        }
    }
}

/// 常用类实现安全解包协议
extension Int: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Int = .zero
}
extension Int8: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Int8 = .zero
}
extension Int16: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Int16 = .zero
}
extension Int32: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Int32 = .zero
}
extension Int64: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Int64 = .zero
}
extension UInt: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: UInt = .zero
}
extension UInt8: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: UInt8 = .zero
}
extension UInt16: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: UInt16 = .zero
}
extension UInt32: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: UInt32 = .zero
}
extension UInt64: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: UInt64 = .zero
}
extension Float: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Float = .zero
}
extension Double: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Double = .zero
}
extension Bool: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: Bool = false
}
extension String: FWSafelyUnwrapped {
    public static var fwUnwrappedValue: String = ""
}
