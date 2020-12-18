//
//  FWCodable.swift
//  FWFramework
//
//  Created by wuyong on 2020/12/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - FWAnyCodable

/// https://github.com/Flight-School/AnyCodable
#if swift(>=5.1)
@frozen public struct FWAnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#else
public struct FWAnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#endif

extension FWAnyCodable: _FWAnyEncodable, _FWAnyDecodable {}

extension FWAnyCodable: Equatable {
    public static func == (lhs: FWAnyCodable, rhs: FWAnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: FWAnyCodable], rhs as [String: FWAnyCodable]):
            return lhs == rhs
        case let (lhs as [FWAnyCodable], rhs as [FWAnyCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension FWAnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension FWAnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "FWAnyCodable(\(value.debugDescription))"
        default:
            return "FWAnyCodable(\(description))"
        }
    }
}

extension FWAnyCodable: ExpressibleByNilLiteral {}
extension FWAnyCodable: ExpressibleByBooleanLiteral {}
extension FWAnyCodable: ExpressibleByIntegerLiteral {}
extension FWAnyCodable: ExpressibleByFloatLiteral {}
extension FWAnyCodable: ExpressibleByStringLiteral {}
extension FWAnyCodable: ExpressibleByArrayLiteral {}
extension FWAnyCodable: ExpressibleByDictionaryLiteral {}

// MARK: - FWAnyEncodable

#if swift(>=5.1)
@frozen public struct FWAnyEncodable: Encodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#else
public struct FWAnyEncodable: Encodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#endif

#if swift(>=4.2)
@usableFromInline
protocol _FWAnyEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _FWAnyEncodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension FWAnyEncodable: _FWAnyEncodable {}

// MARK: - Encodable

extension _FWAnyEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        case let number as NSNumber:
            try encode(nsnumber: number, into: &container)
#endif
#if canImport(Foundation)
        case is NSNull:
            try container.encodeNil()
#endif
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(int8)
        case let int16 as Int16:
            try container.encode(int16)
        case let int32 as Int32:
            try container.encode(int32)
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint8 as UInt8:
            try container.encode(uint8)
        case let uint16 as UInt16:
            try container.encode(uint16)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
#if canImport(Foundation)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
#endif
        case let array as [Any?]:
            try container.encode(array.map { FWAnyEncodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { FWAnyEncodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "FWAnyEncodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    private func encode(nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
        switch CFNumberGetType(nsnumber) {
        case .charType:
            try container.encode(nsnumber.boolValue)
        case .sInt8Type:
            try container.encode(nsnumber.int8Value)
        case .sInt16Type:
            try container.encode(nsnumber.int16Value)
        case .sInt32Type:
            try container.encode(nsnumber.int32Value)
        case .sInt64Type:
            try container.encode(nsnumber.int64Value)
        case .shortType:
            try container.encode(nsnumber.uint16Value)
        case .longType:
            try container.encode(nsnumber.uint32Value)
        case .longLongType:
            try container.encode(nsnumber.uint64Value)
        case .intType, .nsIntegerType, .cfIndexType:
            try container.encode(nsnumber.intValue)
        case .floatType, .float32Type:
            try container.encode(nsnumber.floatValue)
        case .doubleType, .float64Type, .cgFloatType:
            try container.encode(nsnumber.doubleValue)
        #if swift(>=5.0)
        @unknown default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "NSNumber cannot be encoded because its type is not handled")
            throw EncodingError.invalidValue(nsnumber, context)
        #endif
        }
    }
    #endif
}

extension FWAnyEncodable: Equatable {
    public static func == (lhs: FWAnyEncodable, rhs: FWAnyEncodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: FWAnyEncodable], rhs as [String: FWAnyEncodable]):
            return lhs == rhs
        case let (lhs as [FWAnyEncodable], rhs as [FWAnyEncodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension FWAnyEncodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension FWAnyEncodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "FWAnyEncodable(\(value.debugDescription))"
        default:
            return "FWAnyEncodable(\(description))"
        }
    }
}

extension FWAnyEncodable: ExpressibleByNilLiteral {}
extension FWAnyEncodable: ExpressibleByBooleanLiteral {}
extension FWAnyEncodable: ExpressibleByIntegerLiteral {}
extension FWAnyEncodable: ExpressibleByFloatLiteral {}
extension FWAnyEncodable: ExpressibleByStringLiteral {}
#if swift(>=5.0)
extension FWAnyEncodable: ExpressibleByStringInterpolation {}
#endif
extension FWAnyEncodable: ExpressibleByArrayLiteral {}
extension FWAnyEncodable: ExpressibleByDictionaryLiteral {}

extension _FWAnyEncodable {
    public init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }

    public init(booleanLiteral value: Bool) {
        self.init(value)
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(floatLiteral value: Double) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { first, _ in first }))
    }
}

// MARK: - FWAnyDecodable

#if swift(>=5.1)
@frozen public struct FWAnyDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#else
public struct FWAnyDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}
#endif

#if swift(>=4.2)
@usableFromInline
protocol _FWAnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#else
protocol _FWAnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}
#endif

extension FWAnyDecodable: _FWAnyDecodable {}

extension _FWAnyDecodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            #if canImport(Foundation)
                self.init(NSNull())
            #else
                self.init(Optional<Self>.none)
            #endif
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([FWAnyDecodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: FWAnyDecodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "FWAnyDecodable value cannot be decoded")
        }
    }
}

extension FWAnyDecodable: Equatable {
    public static func == (lhs: FWAnyDecodable, rhs: FWAnyDecodable) -> Bool {
        switch (lhs.value, rhs.value) {
#if canImport(Foundation)
        case is (NSNull, NSNull), is (Void, Void):
            return true
#endif
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: FWAnyDecodable], rhs as [String: FWAnyDecodable]):
            return lhs == rhs
        case let (lhs as [FWAnyDecodable], rhs as [FWAnyDecodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension FWAnyDecodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension FWAnyDecodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "FWAnyDecodable(\(value.debugDescription))"
        default:
            return "FWAnyDecodable(\(description))"
        }
    }
}
