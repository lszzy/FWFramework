//
//  FWEncode.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - FWAnyEncoder

/// https://github.com/JohnSundell/Codextended
public protocol FWAnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: FWAnyEncoder {}

#if canImport(ObjectiveC) || swift(>=5.1)
extension PropertyListEncoder: FWAnyEncoder {}
#endif

public extension Encodable {
    func fwEncoded(using encoder: FWAnyEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
}

public extension Encoder {
    func fwEncodeSingle<T: Encodable>(_ value: T) throws {
        var container = singleValueContainer()
        try container.encode(value)
    }

    func fwEncode<T: Encodable>(_ value: T, for key: String) throws {
        try fwEncode(value, for: FWAnyCodingKey(key))
    }

    func fwEncode<T: Encodable, K: CodingKey>(_ value: T, for key: K) throws {
        var container = self.container(keyedBy: K.self)
        try container.encode(value, forKey: key)
    }

    func fwEncode<F: FWAnyDateFormatter>(_ date: Date, for key: String, using formatter: F) throws {
        try fwEncode(date, for: FWAnyCodingKey(key), using: formatter)
    }

    func fwEncode<K: CodingKey, F: FWAnyDateFormatter>(_ date: Date, for key: K, using formatter: F) throws {
        let string = formatter.string(from: date)
        try fwEncode(string, for: key)
    }
}

// MARK: - FWAnyDecoder

public protocol FWAnyDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: FWAnyDecoder {}

#if canImport(ObjectiveC) || swift(>=5.1)
extension PropertyListDecoder: FWAnyDecoder {}
#endif

public extension Data {
    func fwDecoded<T: Decodable>(as type: T.Type = T.self,
                               using decoder: FWAnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: self)
    }
}

public extension Decoder {
    func fwDecodeSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        let container = try singleValueContainer()
        return try container.decode(type)
    }

    func fwDecode<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try fwDecode(FWAnyCodingKey(key), as: type)
    }

    func fwDecode<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        let container = try self.container(keyedBy: K.self)
        return try container.decode(type, forKey: key)
    }

    func fwDecodeIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try fwDecodeIf(FWAnyCodingKey(key), as: type)
    }

    func fwDecodeIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        let container = try self.container(keyedBy: K.self)
        return try container.decodeIfPresent(type, forKey: key)
    }

    func fwDecode<F: FWAnyDateFormatter>(_ key: String, using formatter: F) throws -> Date {
        return try fwDecode(FWAnyCodingKey(key), using: formatter)
    }

    func fwDecode<K: CodingKey, F: FWAnyDateFormatter>(_ key: K, using formatter: F) throws -> Date {
        let container = try self.container(keyedBy: K.self)
        let rawString = try container.decode(String.self, forKey: key)

        guard let date = formatter.date(from: rawString) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Unable to format date string"
            )
        }

        return date
    }
    
    // MARK: - FWJSON
    
    func fwJsonSingle() throws -> FWJSON {
        return try fwDecodeSingle(as: FWJSON.self)
    }
    
    func fwJson(_ key: String) throws -> FWJSON {
        return try fwDecodeIf(key, as: FWJSON.self) ?? FWJSON.null
    }
    
    func fwJson<K: CodingKey>(_ key: K) throws -> FWJSON {
        return try fwDecodeIf(key, as: FWJSON.self) ?? FWJSON.null
    }

    func fwJsonIf(_ key: String) throws -> FWJSON? {
        return try fwDecodeIf(key, as: FWJSON.self)
    }

    func fwJsonIf<K: CodingKey>(_ key: K) throws -> FWJSON? {
        return try fwDecodeIf(key, as: FWJSON.self)
    }
    
    // MARK: - Value
    
    func fwValueSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        if let value = fwValue(with: try fwDecodeSingle(as: FWJSON.self), as: type) {
            return value
        }
        return try fwDecodeSingle(as: type)
    }
    
    func fwValue<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try fwValue(FWAnyCodingKey(key), as: type)
    }

    func fwValue<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        if let value = fwValue(with: try fwDecodeIf(key, as: FWJSON.self) ?? FWJSON.null, as: type) {
            return value
        }
        return try fwDecode(key, as: type)
    }

    func fwValueIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try fwValueIf(FWAnyCodingKey(key), as: type)
    }

    func fwValueIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        if let json = try fwDecodeIf(key, as: FWJSON.self), let value = fwValue(with: json, as: type) {
            return value
        }
        return try fwDecodeIf(key, as: type)
    }
    
    private func fwValue<T>(with json: FWJSON, as type: T.Type) -> T? {
        switch type {
        case is Bool.Type:
            return json.boolValue as? T
        case is String.Type:
            return json.stringValue as? T
        case is Double.Type:
            return json.doubleValue as? T
        case is Float.Type:
            return json.floatValue as? T
        case is Int.Type:
            return json.intValue as? T
        case is Int8.Type:
            return json.int8Value as? T
        case is Int16.Type:
            return json.int16Value as? T
        case is Int32.Type:
            return json.int32Value as? T
        case is Int64.Type:
            return json.int64Value as? T
        case is UInt.Type:
            return json.uIntValue as? T
        case is UInt8.Type:
            return json.uInt8Value as? T
        case is UInt16.Type:
            return json.uInt16Value as? T
        case is UInt32.Type:
            return json.uInt32Value as? T
        case is UInt64.Type:
            return json.uInt64Value as? T
        default:
            return nil
        }
    }
}

public protocol FWAnyDateFormatter {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension DateFormatter: FWAnyDateFormatter {}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension ISO8601DateFormatter: FWAnyDateFormatter {}

private struct FWAnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

// MARK: - FWSafelyUnwrappable

/// 安全解包协议
public protocol FWSafelyUnwrappable {
    /// 提供安全默认值
    static var fwSafeValue: Self { get }
    /// 判断对象是否为空(nil或默认值)
    var fwIsEmpty: Bool { get }
}

extension Optional where Wrapped: FWSafelyUnwrappable {
    /// 获取安全值。当值为nil时，会返回默认值。注意可选链调用时可能不会触发，推荐使用FWSafeValue
    public var fwSafeValue: Wrapped {
        if let value = self {
            return value
        } else {
            return Wrapped.fwSafeValue
        }
    }
    
    /// 判断对象是否为空(nil或默认值)。注意可选链调用时可能不会触发，推荐使用FWIsEmpty
    public var fwIsEmpty: Bool {
        if let value = self {
            return value.fwIsEmpty
        } else {
            return true
        }
    }
}

extension Optional {
    /// 判断对象是否为nil。注意可选链调用时可能不会触发，推荐使用FWIsNil
    public var fwIsNil: Bool {
        return self == nil
    }
}

/// 获取安全值。当值为nil时，会返回默认值
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWSafeValue<T: FWSafelyUnwrappable>(_ value: T?) -> T {
    return value.fwSafeValue
}

/// 判断对象是否为空(nil或默认值)
/// - Parameter value: 实现了安全解包协议的可选对象
public func FWIsEmpty<T: FWSafelyUnwrappable>(_ value: T?) -> Bool {
    return value.fwIsEmpty
}

/// 判断对象是否为nil
/// - Parameter value: 可选对象
public func FWIsNil(_ value: Any?) -> Bool {
    return value.fwIsNil
}

/// 常用类实现安全解包协议
extension Int: FWSafelyUnwrappable {
    public static var fwSafeValue: Int = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Int8: FWSafelyUnwrappable {
    public static var fwSafeValue: Int8 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Int16: FWSafelyUnwrappable {
    public static var fwSafeValue: Int16 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Int32: FWSafelyUnwrappable {
    public static var fwSafeValue: Int32 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Int64: FWSafelyUnwrappable {
    public static var fwSafeValue: Int64 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension UInt: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension UInt8: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt8 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension UInt16: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt16 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension UInt32: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt32 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension UInt64: FWSafelyUnwrappable {
    public static var fwSafeValue: UInt64 = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Float: FWSafelyUnwrappable {
    public static var fwSafeValue: Float = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Double: FWSafelyUnwrappable {
    public static var fwSafeValue: Double = .zero
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension Bool: FWSafelyUnwrappable {
    public static var fwSafeValue: Bool = false
    public var fwIsEmpty: Bool { return self == Self.fwSafeValue }
}
extension String: FWSafelyUnwrappable {
    public static var fwSafeValue: String = ""
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Array: FWSafelyUnwrappable {
    public static var fwSafeValue: Array<Element> { return [] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Set: FWSafelyUnwrappable {
    public static var fwSafeValue: Set<Element> { return [] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Dictionary: FWSafelyUnwrappable {
    public static var fwSafeValue: Dictionary<Key, Value> { return [:] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}

// MARK: - FWSafelyBridge

/// 常用类快捷OC桥接属性
extension Array {
    public var fwNSArray: NSArray { return self as NSArray }
}
extension Data {
    public var fwNSData: NSData { return self as NSData }
    public var fwUTF8String: String? { return String(data: self, encoding: .utf8) }
}
extension Date {
    public var fwNSDate: NSDate { return self as NSDate }
}
extension Dictionary {
    public var fwNSDictionary: NSDictionary { return self as NSDictionary }
}
extension String {
    public var fwNSString: NSString { return self as NSString }
    public var fwUTF8Data: Data? { return self.data(using: .utf8) }
}
extension URL {
    public var fwNSURL: NSURL { return self as NSURL }
}
