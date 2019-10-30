//
//  NSObject+FWSafeType.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 安全解包协议
public protocol FWSafelyUnwrappable: Equatable {
    // 提供安全解包默认值
    static var fwUnwrappedValue: Self { get }
}

/// 可选值安全解包扩展
extension Optional where Wrapped: FWSafelyUnwrappable {
    /// 获取安全值。当值为nil时，会返回默认值。注意可选链调用时可能不会触发
    public func fwSafeValue() -> Wrapped {
        if let value = self {
            return value
        } else {
            return Wrapped.fwUnwrappedValue
        }
    }
    
    /// 判断对象是否非空。当值为nil时，会返回false。注意可选链调用时可能不会触发
    public func fwIsNotEmpty() -> Bool {
        if let value = self {
            return value != Wrapped.fwUnwrappedValue;
        } else {
            return false
        }
    }
}

/// 当值为nil时，会返回默认值
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWSafeValue<T: FWSafelyUnwrappable>(_ value: T?) -> T {
    return value.fwSafeValue()
}

/// 当值为nil时，会返回false
/// - Parameter value: 实现了安全判断协议的可选对象
public func FWIsNotEmpty<T: FWSafelyUnwrappable>(_ value: T?) -> Bool {
    return value.fwIsNotEmpty()
}

/// 常用类实现安全解包协议
extension Int: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Int = .zero
}
extension Int8: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Int8 = .zero
}
extension Int16: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Int16 = .zero
}
extension Int32: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Int32 = .zero
}
extension Int64: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Int64 = .zero
}
extension UInt: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: UInt = .zero
}
extension UInt8: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: UInt8 = .zero
}
extension UInt16: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: UInt16 = .zero
}
extension UInt32: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: UInt32 = .zero
}
extension UInt64: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: UInt64 = .zero
}
extension Float: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Float = .zero
}
extension Double: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Double = .zero
}
extension Bool: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: Bool = false
}
extension String: FWSafelyUnwrappable {
    public static var fwUnwrappedValue: String = ""
}
