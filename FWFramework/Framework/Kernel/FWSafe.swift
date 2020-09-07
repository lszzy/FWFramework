//
//  FWSafe.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
import CoreGraphics

/// 安全解包协议
public protocol FWSafelyUnwrappable {
    // 提供安全默认值
    static var fwSafeValue: Self { get }
    // 判断对象是否为空(nil或默认值)
    func fwIsEmpty() -> Bool
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
    
    /// 判断对象是否为空(nil或默认值)。注意可选链调用时可能不会触发，推荐使用FWIsEmpty
    public func fwIsEmpty() -> Bool {
        if let value = self {
            return value.fwIsEmpty()
        } else {
            return true
        }
    }
}

extension Optional {
    /// 判断对象是否为nil。注意可选链调用时可能不会触发，推荐使用FWIsNil
    public func fwIsNil() -> Bool {
        return self == nil
    }
}

/// 获取安全值。当值为nil时，会返回默认值
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWSafeValue<T: FWSafelyUnwrappable>(_ value: T?) -> T {
    return value.fwSafeValue()
}

/// 判断对象是否为空(nil或默认值)
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWIsEmpty<T: FWSafelyUnwrappable>(_ value: T?) -> Bool {
    return value.fwIsEmpty()
}

/// 判断对象是否为nil
/// - Parameter value: 可选对象
public func FWIsNil(_ value: Any?) -> Bool {
    return value.fwIsNil()
}

/// 常用类实现安全解包协议
extension Int: FWSafelyUnwrappable {
    public static var fwSafeValue: Int = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Int8: FWSafelyUnwrappable {
    public static var fwSafeValue: Int8 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Int16: FWSafelyUnwrappable {
    public static var fwSafeValue: Int16 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Int32: FWSafelyUnwrappable {
    public static var fwSafeValue: Int32 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Int64: FWSafelyUnwrappable {
    public static var fwSafeValue: Int64 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension UInt: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension UInt8: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt8 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension UInt16: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt16 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension UInt32: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt32 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension UInt64: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt64 = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Float: FWSafelyUnwrappable {
    public static var fwSafeValue: Float = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Double: FWSafelyUnwrappable {
    public static var fwSafeValue: Double = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension CGFloat: FWSafelyUnwrappable {
    public static var fwSafeValue: CGFloat = .zero
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension Bool: FWSafelyUnwrappable {
    public static var fwSafeValue: Bool = false
    public func fwIsEmpty() -> Bool { return self == Self.fwSafeValue }
}
extension String: FWSafelyUnwrappable {
    public static var fwSafeValue: String = ""
    public func fwIsEmpty() -> Bool { return self.isEmpty }
}
extension Array: FWSafelyUnwrappable {
    public static var fwSafeValue: Array<Element> { return [] }
    public func fwIsEmpty() -> Bool { return self.isEmpty }
}
extension Set: FWSafelyUnwrappable {
    public static var fwSafeValue: Set<Element> { return [] }
    public func fwIsEmpty() -> Bool { return self.isEmpty }
}
extension Dictionary: FWSafelyUnwrappable {
    public static var fwSafeValue: Dictionary<Key, Value> { return [:] }
    public func fwIsEmpty() -> Bool { return self.isEmpty }
}

/// 常用类快捷OC桥接属性
extension Array {
    public var fwNSArray: NSArray { return self as NSArray }
}
extension Data {
    public var fwNSData: NSData { return self as NSData }
}
extension Date {
    public var fwNSDate: NSDate { return self as NSDate }
}
extension Dictionary {
    public var fwNSDictionary: NSDictionary { return self as NSDictionary }
}
extension String {
    public var fwNSString: NSString { return self as NSString }
}
extension URL {
    public var fwNSURL: NSURL { return self as NSURL }
}
