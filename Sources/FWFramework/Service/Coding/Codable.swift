//
//  Codable.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - AnyEncoder
/// https://github.com/JohnSundell/Codextended
public protocol AnyEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

extension JSONEncoder: AnyEncoder {}

#if canImport(ObjectiveC) || swift(>=5.1)
extension PropertyListEncoder: AnyEncoder {}
#endif

// MARK: - Encodable+AnyEncoder
public extension Encodable {
    func encoded(using encoder: AnyEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] ?? [:]
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> [Any] {
        let data = try encoded(using: encoder) as Data
        return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [Any] ?? []
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        let data = try encoded(using: encoder) as Data
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Foundation+AnyEncoder
public extension Data {
    static func encoded<T>(_ value: T, using encoder: AnyEncoder = JSONEncoder()) throws -> Data where T : Encodable {
        return try encoder.encode(value)
    }
}

// MARK: - Encoder+AnyEncoder
extension Encoder {
    public func encodeSingle<T: Encodable>(_ value: T) throws {
        var container = singleValueContainer()
        try container.encode(value)
    }

    public func encode<T: Encodable>(_ value: T, for key: String) throws {
        try encode(value, for: AnyCodingKey(key))
    }

    public func encode<T: Encodable, K: CodingKey>(_ value: T, for key: K) throws {
        var container = container(keyedBy: K.self)
        try container.encode(value, forKey: key)
    }

    public func encode<F: AnyDateFormatter>(_ date: Date, for key: String, using formatter: F) throws {
        try encode(date, for: AnyCodingKey(key), using: formatter)
    }

    public func encode<K: CodingKey, F: AnyDateFormatter>(_ date: Date, for key: K, using formatter: F) throws {
        let string = formatter.string(from: date)
        try encode(string, for: key)
    }
}

// MARK: - AnyDecoder
public protocol AnyDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONDecoder: AnyDecoder {}

#if canImport(ObjectiveC) || swift(>=5.1)
extension PropertyListDecoder: AnyDecoder {}
#endif

// MARK: - Decodable+AnyDecoder
public extension Decodable {
    static func decoded(from data: Data, using decoder: AnyDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(from json: [String: Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(from jsonArray: [Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: .fragmentsAllowed)
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(from string: String, using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = Data(string.utf8)
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Foundation+AnyDecoder
public extension Data {
    func decoded<T: Decodable>(using decoder: AnyDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        return try decoder.decode(type, from: self)
    }
}

public extension Dictionary {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)
        return try data.decoded(using: decoder, as: type)
    }
}

public extension Array {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed)
        return try data.decoded(using: decoder, as: type)
    }
}

public extension String {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        return try Data(self.utf8).decoded(using: decoder, as: type)
    }
}

// MARK: - Decoder+AnyDecoder
extension Decoder {
    public func decodeSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        let container = try singleValueContainer()
        return try container.decode(type)
    }

    public func decode<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try decode(AnyCodingKey(key), as: type)
    }

    public func decode<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        let container = try container(keyedBy: K.self)
        return try container.decode(type, forKey: key)
    }

    public func decodeIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try decodeIf(AnyCodingKey(key), as: type)
    }

    public func decodeIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        let container = try container(keyedBy: K.self)
        return try container.decodeIfPresent(type, forKey: key)
    }

    public func decode<F: AnyDateFormatter>(_ key: String, using formatter: F) throws -> Date {
        return try decode(AnyCodingKey(key), using: formatter)
    }

    public func decode<K: CodingKey, F: AnyDateFormatter>(_ key: K, using formatter: F) throws -> Date {
        let container = try container(keyedBy: K.self)
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
    
    // MARK: - JSON
    public func jsonSingle() throws -> JSON {
        return try decodeSingle(as: JSON.self)
    }
    
    public func json(_ key: String) throws -> JSON {
        return try decodeIf(key, as: JSON.self) ?? JSON.null
    }
    
    public func json<K: CodingKey>(_ key: K) throws -> JSON {
        return try decodeIf(key, as: JSON.self) ?? JSON.null
    }

    public func jsonIf(_ key: String) throws -> JSON? {
        return try decodeIf(key, as: JSON.self)
    }

    public func jsonIf<K: CodingKey>(_ key: K) throws -> JSON? {
        return try decodeIf(key, as: JSON.self)
    }
    
    // MARK: - Value
    public func valueSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        if let value = value(with: try decodeSingle(as: JSON.self), as: type) {
            return value
        }
        return try decodeSingle(as: type)
    }
    
    public func value<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try value(AnyCodingKey(key), as: type)
    }

    public func value<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        if let value = value(with: try decodeIf(key, as: JSON.self) ?? JSON.null, as: type) {
            return value
        }
        return try decode(key, as: type)
    }

    public func valueIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try valueIf(AnyCodingKey(key), as: type)
    }

    public func valueIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        if let json = try decodeIf(key, as: JSON.self), let value = value(with: json, as: type) {
            return value
        }
        return try decodeIf(key, as: type)
    }
    
    private func value<T>(with json: JSON, as type: T.Type) -> T? {
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
        case is Bool?.Type:
            return json.bool as? T
        case is String?.Type:
            return json.string as? T
        case is Double?.Type:
            return json.double as? T
        case is Float?.Type:
            return json.float as? T
        case is Int?.Type:
            return json.int as? T
        case is Int8?.Type:
            return json.int8 as? T
        case is Int16?.Type:
            return json.int16 as? T
        case is Int32?.Type:
            return json.int32 as? T
        case is Int64?.Type:
            return json.int64 as? T
        case is UInt?.Type:
            return json.uInt as? T
        case is UInt8?.Type:
            return json.uInt8 as? T
        case is UInt16?.Type:
            return json.uInt16 as? T
        case is UInt32?.Type:
            return json.uInt32 as? T
        case is UInt64?.Type:
            return json.uInt64 as? T
        default:
            return nil
        }
    }
}

// MARK: - AnyDateFormatter
public protocol AnyDateFormatter {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension DateFormatter: AnyDateFormatter {}

extension ISO8601DateFormatter: AnyDateFormatter {}

// MARK: - AnyCodingKey
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
    
    init<S: LosslessStringConvertible>(_ stringValue: S) {
        self.stringValue = stringValue as? String ?? String(stringValue)
        self.intValue = nil
    }
}

// MARK: - AnyCodable
extension KeyedDecodingContainer {
    public func decode(_ type: [Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [Any] {
        var values = try nestedUnkeyedContainer(forKey: key)
        return try values.decode(type)
    }

    public func decode(_ type: [AnyHashable: Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [AnyHashable: Any] {
        let values = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        return try values.decode(type)
    }

    public func decodeIfPresent(_ type: [Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [Any]? {
        guard contains(key),
            try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

    public func decodeIfPresent(_ type: [AnyHashable: Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [AnyHashable: Any]? {
        guard contains(key),
            try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }
}

private extension KeyedDecodingContainer {
    func decode(_ type: [AnyHashable: Any].Type) throws -> [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]
        for key in allKeys {
            if try decodeNil(forKey: key) {
                dictionary[key.stringValue] = NSNull()
            } else if let bool = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = bool
            } else if let string = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = string
            } else if let int = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = int
            } else if let double = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = double
            } else if let dict = try? decode([AnyHashable: Any].self, forKey: key) {
                dictionary[key.stringValue] = dict
            } else if let array = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = array
            }
        }
        return dictionary
    }
}

private extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var elements: [Any] = []
        while !isAtEnd {
            if try decodeNil() {
                elements.append(NSNull())
            } else if let int = try? decode(Int.self) {
                elements.append(int)
            } else if let bool = try? decode(Bool.self) {
                elements.append(bool)
            } else if let double = try? decode(Double.self) {
                elements.append(double)
            } else if let string = try? decode(String.self) {
                elements.append(string)
            } else if let values = try? nestedContainer(keyedBy: AnyCodingKey.self),
                let element = try? values.decode([AnyHashable: Any].self) {
                elements.append(element)
            } else if var values = try? nestedUnkeyedContainer(),
                let element = try? values.decode([Any].self) {
                elements.append(element)
            }
        }
        return elements
    }
}

extension KeyedEncodingContainer {
    public mutating func encode(_ value: [AnyHashable: Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
        var container = nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        try container.encode(value)
    }

    public mutating func encode(_ value: [Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }

    public mutating func encodeIfPresent(_ value: [AnyHashable: Any]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            var container = nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
            try container.encode(value)
        } else {
            try encodeNil(forKey: key)
        }
    }

    public mutating func encodeIfPresent(_ value: [Any]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            var container = nestedUnkeyedContainer(forKey: key)
            try container.encode(value)
        } else {
            try encodeNil(forKey: key)
        }
    }
}

private extension KeyedEncodingContainer where K == AnyCodingKey {
    mutating func encode(_ value: [AnyHashable: Any]) throws {
        for (k, v) in value {
            let key = AnyCodingKey(k as? String ?? String(describing: k))
            switch v {
            case is NSNull:
                try encodeNil(forKey: key)
            case let string as String:
                try encode(string, forKey: key)
            case let int as Int:
                try encode(int, forKey: key)
            case let bool as Bool:
                try encode(bool, forKey: key)
            case let double as Double:
                try encode(double, forKey: key)
            case let dict as [AnyHashable: Any]:
                try encode(dict, forKey: key)
            case let array as [Any]:
                try encode(array, forKey: key)
            default:
                debugPrint("⚠️ Unsuported type!", v)
                continue
            }
        }
    }
}

private extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [Any]) throws {
        for v in value {
            switch v {
            case is NSNull:
                try encodeNil()
            case let string as String:
                try encode(string)
            case let int as Int:
                try encode(int)
            case let bool as Bool:
                try encode(bool)
            case let double as Double:
                try encode(double)
            case let dict as [AnyHashable: Any]:
                try encode(dict)
            case let array as [Any]:
                var values = nestedUnkeyedContainer()
                try values.encode(array)
            default:
                debugPrint("⚠️ Unsuported type!", v)
            }
        }
    }

    mutating func encode(_ value: [AnyHashable: Any]) throws {
        var container = self.nestedContainer(keyedBy: AnyCodingKey.self)
        try container.encode(value)
    }
}

// MARK: - DefaultCaseCodable
public protocol DefaultCaseCodable: RawRepresentable, Codable {
    static var defaultCase: Self { get }
}

public extension DefaultCaseCodable where Self.RawValue: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        self = Self.init(rawValue: rawValue) ?? Self.defaultCase
    }
}

// MARK: - CodableValue
/// Codable属性注解，解析成功且不为nil时才会覆盖默认值
///
/// https://github.com/iwill/ExCodable
@propertyWrapper
public final class CodableValue<Value> {
    fileprivate let stringKeys: [String]?
    fileprivate let nonnull, `throws`: Bool?
    fileprivate let encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?
    public var wrappedValue: Value
    
    private init(wrappedValue: Value, stringKeys: [String]? = nil, nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
        (self.wrappedValue, self.stringKeys, self.nonnull, self.throws, self.encode, self.decode) = (wrappedValue, stringKeys, nonnull, `throws`, encode, decode)
    }
    
    public convenience init(wrappedValue: Value, _ stringKey: String? = nil, nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKey.map { [$0] }, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
    
    public convenience init(wrappedValue: Value, _ stringKeys: String..., nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKeys, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
    
    public convenience init(wrappedValue: Value, _ codingKeys: CodingKey..., nonnull: Bool? = nil, throws: Bool? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: codingKeys.map { $0.stringValue }, nonnull: nonnull, throws: `throws`, encode: encode, decode: decode)
    }
}

extension CodableValue: Equatable where Value: Equatable {
    public static func == (lhs: CodableValue<Value>, rhs: CodableValue<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension CodableValue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { String(describing: wrappedValue) }
    public var debugDescription: String { description }
}

fileprivate protocol EncodablePropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws
}

extension CodableValue: EncodablePropertyWrapper where Value: Encodable {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else {
            let value = deepUnwrap(wrappedValue)
            if value != nil || self.nonnull ?? nonnull {
                try encoder.encode(wrappedValue, for: stringKeys?.first ?? String(label), nonnull: self.nonnull ?? nonnull, throws: self.throws ?? `throws`)
            }
        }
    }
}

fileprivate protocol DecodablePropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws
}

extension CodableValue: DecodablePropertyWrapper where Value: Decodable {
    fileprivate func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws {
        let value = decode != nil ? try decode!(decoder) : try decoder.decode(stringKeys ?? [String(label)], nonnull: self.nonnull ?? nonnull, throws: self.throws ?? `throws`)
        if let value = value {
            wrappedValue = value
        }
    }
}

fileprivate protocol EncodableAnyPropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws
}

extension CodableValue: EncodableAnyPropertyWrapper {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else {
            let t = type(of: wrappedValue)
            let key = AnyCodingKey(label)
            if (t is [AnyHashable: Any].Type || t is [AnyHashable: Any?].Type || t is [AnyHashable: Any]?.Type || t is [AnyHashable: Any?]?.Type) {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encodeIfPresent(wrappedValue as? [AnyHashable: Any], forKey: key)
            } else if (t is [Any].Type || t is [Any?].Type || t is [Any]?.Type || t is [Any?]?.Type) {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encodeIfPresent(wrappedValue as? [Any], forKey: key)
            }
        }
    }
}

fileprivate protocol DecodableAnyPropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws
}

extension CodableValue: DecodableAnyPropertyWrapper {
    fileprivate func decode<Label: StringProtocol>(from decoder: Decoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if let decode = decode {
            if let value = try decode(decoder) {
                wrappedValue = value
            }
        } else {
            let t = type(of: wrappedValue)
            let key = AnyCodingKey(label)
            if (t is [AnyHashable: Any].Type || t is [AnyHashable: Any?].Type || t is [AnyHashable: Any]?.Type || t is [AnyHashable: Any?]?.Type) {
                let container = try decoder.container(keyedBy: AnyCodingKey.self)
                if let value = try container.decodeIfPresent([AnyHashable: Any].self, forKey: key) as? Value {
                    wrappedValue = value
                }
            } else if (t is [Any].Type || t is [Any?].Type || t is [Any]?.Type || t is [Any?]?.Type) {
                let container = try decoder.container(keyedBy: AnyCodingKey.self)
                if let value = try container.decodeIfPresent([Any].self, forKey: key) as? Value {
                    wrappedValue = value
                }
            }
        }
    }
}

// MARK: - AutoCodable
public protocol AutoEncodable: Encodable {}
public protocol AutoDecodable: Decodable { init() }
public typealias AutoCodable = AutoEncodable & AutoDecodable

public extension AutoEncodable {
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
    }
}

public extension AutoDecodable {
    init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder, nonnull: false, throws: false)
    }
}

public extension Encodable {
    func encode(to encoder: Encoder, nonnull: Bool, throws: Bool) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? EncodablePropertyWrapper) {
                    try wrapper.encode(to: encoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
                } else {
                    try (child.value as? EncodableAnyPropertyWrapper)?.encode(to: encoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
                }
            }
            mirror = mirror.superclassMirror
        }
    }
}

public extension Decodable {
    func decode(from decoder: Decoder, nonnull: Bool, throws: Bool) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? DecodablePropertyWrapper) {
                    try wrapper.decode(from: decoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
                } else {
                    try (child.value as? DecodableAnyPropertyWrapper)?.decode(from: decoder, label: child.label!.dropFirst(), nonnull: false, throws: false)
                }
            }
            mirror = mirror.superclassMirror
        }
    }
}

// MARK: - CodableValue+Codable
public extension Encoder {
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: stringKey) }
    }
    
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { encode(newValue, for: codingKey) }
    }
}

public extension Decoder {
    subscript<T: Decodable>(stringKeys: [String]) -> T? {
        return decode(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable>(stringKeys: String ...) -> T? {
        return decode(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: [K]) -> T? {
        return decode(codingKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: K ...) -> T? {
        return decode(codingKeys, as: T.self)
    }
}

public extension Encoder {
    func encodeNonnullThrows<T: Encodable>(_ value: T, for stringKey: String) throws {
        try encode(value, for: stringKey, nonnull: true, throws: true)
    }
    
    func encodeThrows<T: Encodable>(_ value: T?, for stringKey: String) throws {
        try encode(value, for: stringKey, nonnull: false, throws: true)
    }
    
    func encode<T: Encodable>(_ value: T?, for stringKey: String) {
        try? encode(value, for: stringKey, nonnull: false, throws: false)
    }
    
    internal func encode<T: Encodable>(_ value: T?, for stringKey: String, nonnull: Bool = false, throws: Bool = false) throws {
        
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encode(value, for: AnyCodingKey(stringKey), nonnull: nonnull, throws: `throws`)
            return
        }
        
        let keys = stringKey.split(separator: dot).map { AnyCodingKey($0) }
        var container = self.container(keyedBy: AnyCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        }
        
        let codingKey = keys.last!
        do {
            if nonnull { try container.encode(value, forKey: codingKey) }
            else { try container.encodeIfPresent(value, forKey: codingKey) }
        }
        catch { if `throws` || nonnull { throw error } }
    }
    
    func encodeNonnullThrows<T: Encodable, K: CodingKey>(_ value: T, for codingKey: K) throws {
        try encode(value, for: codingKey, nonnull: true, throws: true)
    }
    
    func encodeThrows<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        try encode(value, for: codingKey, nonnull: false, throws: true)
    }
    
    func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) {
        try? encode(value, for: codingKey, nonnull: false, throws: false)
    }
    
    internal func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K, nonnull: Bool = false, throws: Bool = false) throws {
        var container = self.container(keyedBy: K.self)
        do {
            if nonnull { try container.encode(value, forKey: codingKey) }
            else { try container.encodeIfPresent(value, forKey: codingKey) }
        }
        catch { if `throws` || nonnull { throw error } }
    }
}

public extension Decoder {
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T {
        return try decodeNonnullThrows(stringKeys, as: type)
    }
    
    func decodeNonnullThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T {
        return try decode(stringKeys, as: type, nonnull: true, throws: true)!
    }
    
    func decodeThrows<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T? {
        return try decodeThrows(stringKeys, as: type)
    }
    
    func decodeThrows<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T? {
        return try decode(stringKeys, as: type, nonnull: false, throws: true)
    }
    
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) -> T? {
        return decode(stringKeys, as: type)
    }
    
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) -> T? {
        return try? decode(stringKeys, as: type, nonnull: false, throws: false)
    }
    
    internal func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        return try decode(stringKeys.map { AnyCodingKey($0) }, as: type, nonnull: nonnull, throws: `throws`)
    }
    
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T {
        return try decodeNonnullThrows(codingKeys, as: type)
    }
    
    func decodeNonnullThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T {
        return try decode(codingKeys, as: type, nonnull: true, throws: true)!
    }
    
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T? {
        return try decodeThrows(codingKeys, as: type)
    }
    
    func decodeThrows<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T? {
        return try decode(codingKeys, as: type, nonnull: false, throws: true)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) -> T? {
        return decode(codingKeys, as: type)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) -> T? {
        return try? decode(codingKeys, as: type, nonnull: false, throws: false)
    }
    
    internal func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return try container.decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`)
        }
        catch { if `throws` || nonnull { throw error } }
        return nil
    }
}

fileprivate extension KeyedDecodingContainer {
    func decodeForAlternativeKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeForNestedKeys(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        catch { firstError = error }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = try? decodeForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`) {
            return value
        }
        
        if (`throws` || nonnull) && firstError != nil { throw firstError! }
        return nil
    }
    
    func decodeForNestedKeys<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = try decodeForValue(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        catch { firstError = error }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? AnyCodingKey,
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { AnyCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = try? container.decodeForNestedKeys(codingKey as! Self.Key, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        
        if firstError != nil && (`throws` || nonnull) { throw firstError! }
        return nil
    }
    
    private func nestedContainer(with keys: [AnyCodingKey]) -> Self? {
        var container: Self? = self
        for key in keys {
            container = try? container?.nestedContainer(keyedBy: Self.Key.self, forKey: key as! Self.Key)
            if container == nil { return nil }
        }
        return container
    }
    
    func decodeForValue<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = (nonnull
                            ? (`throws` ? try decode(type, forKey: codingKey) : try? decode(type, forKey: codingKey))
                            : (`throws` ? try decodeIfPresent(type, forKey: codingKey) : try? decodeIfPresent(type, forKey: codingKey))) {
                return value
            }
        }
        catch { firstError = error }
        
        if contains(codingKey),
           let value = decodeForTypeConversion(codingKey, as: type) {
            return value
        }
        
        if firstError != nil && (`throws` || nonnull) { throw firstError! }
        return nil
    }
    
    func decodeForTypeConversion<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        
        if type is Bool.Type || type is Bool?.Type {
            if let int = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return (int != 0) as? T
            }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
                switch string.lowercased() {
                    case "true", "t", "yes", "y":
                        return true as? T
                    case "false", "f", "no", "n", "":
                        return false as? T
                    default:
                        if let int = Int(string) { return (int != 0) as? T }
                        else if let double = Double(string) { return (Int(double) != 0) as? T }
                }
            }
        }
        else if type is Int.Type || type is Int?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int(string) { return value as? T }
        }
        else if type is Int8.Type || type is Int8?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int8(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int8(string) { return value as? T }
        }
        else if type is Int16.Type || type is Int16?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int16(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int16(string) { return value as? T }
        }
        else if type is Int32.Type || type is Int32?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int32(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int32(string) { return value as? T }
        }
        else if type is Int64.Type || type is Int64?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int64(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int64(string) { return value as? T }
        }
        else if type is UInt.Type || type is UInt?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt(string) { return value as? T }
        }
        else if type is UInt8.Type || type is UInt8?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt8(string) { return value as? T }
        }
        else if type is UInt16.Type || type is UInt16?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt16(string) { return value as? T }
        }
        else if type is UInt32.Type || type is UInt32?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt32(string) { return value as? T }
        }
        else if type is UInt64.Type || type is UInt64?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt64(string) { return value as? T }
        }
        else if type is Double.Type || type is Double?.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Double(int64) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Double(string) { return value as? T }
        }
        else if type is Float.Type || type is Float?.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Float(int64) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Float(string) { return value as? T }
        }
        else if type is String.Type || type is String?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return String(describing: int64) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return String(describing: double) as? T }
        }
        
        for converter in _codableDecodingConverters {
            if let value = try? converter.decode(self, codingKey: codingKey, as: type) {
                return value
            }
        }
        if let customConverter = self as? CodableDecodingConverter,
           let value = try? customConverter.decode(self, codingKey: codingKey, as: type) {
            return value
        }
        
        return nil
    }
}

// MARK: - CodableDecodingConverter
private var _codableDecodingConverters: [CodableDecodingConverter] = []

public protocol CodableDecodingConverter {
    func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) throws -> T?
}

public func register(_ decodingConverter: CodableDecodingConverter) {
    _codableDecodingConverters.append(decodingConverter)
}

// MARK: - CodableValue+Optional
private protocol _OptionalProtocol {
    var deepWrapped: Any? { get }
}

extension Optional: _OptionalProtocol {
    var deepWrapped: Any? {
        guard case let .some(wrapped) = self else { return nil }
        guard let wrapped = wrapped as? _OptionalProtocol else { return wrapped }
        return wrapped.deepWrapped
    }
}

private func deepUnwrap(_ any: Any) -> Any? {
    if let any = any as? _OptionalProtocol {
        return any.deepWrapped
    }
    return any
}
