//
//  NSObject+FWSafeType.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - FWSafelyUnwrappable

/// 安全解包协议
public protocol FWSafelyUnwrappable {
    // 提供安全默认值
    static var fwSafeValue: Self { get }
}

extension Optional where Wrapped: FWSafelyUnwrappable {
    /// 获取安全值。当值为nil时，会返回默认值。注意可选链调用时可能不会触发，推荐使用FWSafeValue
    public func fwSafeValue() -> Wrapped {
        if let value = self {
            return value
        } else {
            return Wrapped.fwSafeValue
        }
    }
}

/// 当值为nil时，会返回默认值
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWSafeValue<T: FWSafelyUnwrappable>(_ value: T?) -> T {
    return value.fwSafeValue()
}

// MARK: - FWSafelyEquatable

/// 安全判断协议
public protocol FWSafelyEquatable {
    // 判断对象是否非空
    func fwIsNotEmpty() -> Bool
}

extension Optional where Wrapped: FWSafelyEquatable {
    /// 判断对象是否非空。当值为nil时，会返回false。注意可选链调用时可能不会触发，推荐使用FWIsNotEmpty
    public func fwIsNotEmpty() -> Bool {
        if let value = self {
            return value.fwIsNotEmpty()
        } else {
            return false
        }
    }
}

/// 当值为nil时，会返回false
/// - Parameter value: 实现了安全判断协议的可选对象
public func FWIsNotEmpty<T: FWSafelyEquatable>(_ value: T?) -> Bool {
    return value.fwIsNotEmpty()
}

// MARK: - NSObject+FWSafeType

/// 常用类实现安全解包和安全判断协议
extension Int: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Int = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Int8: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Int8 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Int16: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Int16 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Int32: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Int32 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Int64: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Int64 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension UInt: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: UInt = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension UInt8: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: UInt8 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension UInt16: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: UInt16 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension UInt32: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: UInt32 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension UInt64: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: UInt64 = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Float: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Float = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Double: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Double = .zero
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension Bool: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: Bool = false
    public func fwIsNotEmpty() -> Bool { return self != Self.fwSafeValue }
}
extension String: FWSafelyUnwrappable, FWSafelyEquatable {
    public static var fwSafeValue: String = ""
    public func fwIsNotEmpty() -> Bool { return !self.isEmpty }
}
extension Array: FWSafelyEquatable {
    public func fwIsNotEmpty() -> Bool { return !self.isEmpty }
}
extension Set: FWSafelyEquatable {
    public func fwIsNotEmpty() -> Bool { return !self.isEmpty }
}
extension Dictionary: FWSafelyEquatable {
    public func fwIsNotEmpty() -> Bool { return !self.isEmpty }
}
