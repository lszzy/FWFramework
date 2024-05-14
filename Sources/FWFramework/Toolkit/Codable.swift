//
//  Codable.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 注册自定义Codable解码转换器
    /// - Parameter decodingConverter: 解码转换器
    public static func register(_ decodingConverter: CodableDecodingConverter) {
        _codableDecodingConverters.append(decodingConverter)
    }
    
    fileprivate static var _codableDecodingConverters: [CodableDecodingConverter] = []
}

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
        return try Data.fw.jsonDecode(data, options: .fragmentsAllowed) as? [String: Any] ?? [:]
    }
    
    func encoded(using encoder: JSONEncoder = JSONEncoder()) throws -> [Any] {
        let data = try encoded(using: encoder) as Data
        return try Data.fw.jsonDecode(data, options: .fragmentsAllowed) as? [Any] ?? []
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
    // MARK: - Encodable
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
    
    public func encodeIf<T: Encodable>(_ value: T?, for key: String) throws {
        try encodeIf(value, for: AnyCodingKey(key))
    }

    public func encodeIf<T: Encodable, K: CodingKey>(_ value: T?, for key: K) throws {
        var container = container(keyedBy: K.self)
        try container.encodeIfPresent(value, forKey: key)
    }
    
    // MARK: - Any
    public func encodeAny<T>(_ value: T, for key: String) throws {
        try encodeAny(value, for: AnyCodingKey(key))
    }

    public func encodeAny<T, K: CodingKey>(_ value: T, for key: K) throws {
        var container = container(keyedBy: K.self)
        try container.encodeAny(value, as: T.self, forKey: key)
    }
    
    public func encodeAnyIf<T>(_ value: T?, for key: String) throws {
        try encodeAnyIf(value, for: AnyCodingKey(key))
    }

    public func encodeAnyIf<T, K: CodingKey>(_ value: T?, for key: K) throws {
        var container = container(keyedBy: K.self)
        try container.encodeAnyIfPresent(value, as: T.self, forKey: key)
    }

    // MARK: - Date
    public func encode<F: AnyDateFormatter>(_ date: Date, for key: String, using formatter: F) throws {
        try encode(date, for: AnyCodingKey(key), using: formatter)
    }

    public func encode<K: CodingKey, F: AnyDateFormatter>(_ date: Date, for key: K, using formatter: F) throws {
        let string = formatter.string(from: date)
        try encode(string, for: key)
    }
    
    public func encodeIf<F: AnyDateFormatter>(_ date: Date?, for key: String, using formatter: F) throws {
        try encodeIf(date, for: AnyCodingKey(key), using: formatter)
    }

    public func encodeIf<K: CodingKey, F: AnyDateFormatter>(_ date: Date?, for key: K, using formatter: F) throws {
        let string = date != nil ? formatter.string(from: date!) : nil
        try encodeIf(string, for: key)
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
        let data = try Data.fw.jsonEncode(json, options: .fragmentsAllowed)
        return try decoder.decode(type, from: data)
    }
    
    static func decoded(from jsonArray: [Any], using decoder: JSONDecoder = JSONDecoder(), as type: Self.Type = Self.self) throws -> Self {
        let data = try Data.fw.jsonEncode(jsonArray, options: .fragmentsAllowed)
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
        let data = try Data.fw.jsonEncode(self, options: .fragmentsAllowed)
        return try data.decoded(using: decoder, as: type)
    }
}

public extension Array {
    func decoded<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), as type: T.Type = T.self) throws -> T {
        let data = try Data.fw.jsonEncode(self, options: .fragmentsAllowed)
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
    // MARK: - Decodable
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
    
    // MARK: - Any
    public func decodeAny<T>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try decodeAny(AnyCodingKey(key), as: type)
    }
    
    public func decodeAny<T, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        let container = try container(keyedBy: K.self)
        return try container.decodeAny(type, forKey: key)
    }
    
    public func decodeAnyIf<T>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try decodeAnyIf(AnyCodingKey(key), as: type)
    }
    
    public func decodeAnyIf<T, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        let container = try container(keyedBy: K.self)
        return try container.decodeAnyIfPresent(type, forKey: key)
    }

    // MARK: - Date
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
    
    public func decodeIf<F: AnyDateFormatter>(_ key: String, using formatter: F) throws -> Date? {
        return try decodeIf(AnyCodingKey(key), using: formatter)
    }

    public func decodeIf<K: CodingKey, F: AnyDateFormatter>(_ key: K, using formatter: F) throws -> Date? {
        let container = try container(keyedBy: K.self)
        let rawString = try container.decodeIfPresent(String.self, forKey: key)
        guard let rawString = rawString, !rawString.isEmpty else { return nil }

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
}

// MARK: - AnyDateFormatter
public protocol AnyDateFormatter {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension DateFormatter: AnyDateFormatter {}

extension ISO8601DateFormatter: AnyDateFormatter {}

// MARK: - AnyCodingKey
public struct AnyCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
    
    public init<S: LosslessStringConvertible>(_ stringValue: S) {
        self.stringValue = stringValue as? String ?? String(stringValue)
        self.intValue = nil
    }
}

// MARK: - AnyCodable
extension KeyedDecodingContainer {
    public func decodeAny<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        if (type is [AnyHashable: Any].Type || type is [AnyHashable: Any?].Type ||
            type is [AnyHashable: Any]?.Type || type is [AnyHashable: Any?]?.Type) {
            let values = try nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
            return try values.decodeAnyDictionary() as! T
        } else if (type is [Any].Type || type is [Any?].Type ||
                   type is [Any]?.Type || type is [Any?]?.Type) {
            var values = try nestedUnkeyedContainer(forKey: key)
            return try values.decodeAnyArray() as! T
        } else {
            if try decodeNil(forKey: key) {
                return NSNull() as! T
            } else if let bool = try? decode(Bool.self, forKey: key) {
                return bool as! T
            } else if let string = try? decode(String.self, forKey: key) {
                return string as! T
            } else if let int = try? decode(Int.self, forKey: key) {
                return int as! T
            } else if let double = try? decode(Double.self, forKey: key) {
                return double as! T
            } else if let dict = try? decodeAny([AnyHashable: Any].self, forKey: key) {
                return dict as! T
            } else if let array = try? decodeAny([Any].self, forKey: key) {
                return array as! T
            } else {
                throw DecodingError.typeMismatch(Any.self, .init(codingPath: codingPath, debugDescription: "Unsuported type"))
            }
        }
    }
    
    public func decodeAnyIfPresent<T>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T? {
        guard contains(key),
            try decodeNil(forKey: key) == false else { return nil }
        return try decodeAny(type, forKey: key)
    }
}

private extension KeyedDecodingContainer {
    func decodeAnyDictionary() throws -> [AnyHashable: Any] {
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
            } else if let dict = try? decodeAny([AnyHashable: Any].self, forKey: key) {
                dictionary[key.stringValue] = dict
            } else if let array = try? decodeAny([Any].self, forKey: key) {
                dictionary[key.stringValue] = array
            }
        }
        return dictionary
    }
}

private extension UnkeyedDecodingContainer {
    mutating func decodeAnyArray() throws -> [Any] {
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
                let element = try? values.decodeAnyDictionary() {
                elements.append(element)
            } else if var values = try? nestedUnkeyedContainer(),
                let element = try? values.decodeAnyArray() {
                elements.append(element)
            }
        }
        return elements
    }
}

extension KeyedEncodingContainer {
    public mutating func encodeAny<T>(_ value: T, as type: T.Type, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if (type is [AnyHashable: Any].Type || type is [AnyHashable: Any?].Type ||
            type is [AnyHashable: Any]?.Type || type is [AnyHashable: Any?]?.Type) {
            var container = nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
            try container.encodeAnyDictionary(value as? [AnyHashable: Any] ?? [:])
        } else if (type is [Any].Type || type is [Any?].Type ||
                   type is [Any]?.Type || type is [Any?]?.Type) {
            var container = nestedUnkeyedContainer(forKey: key)
            try container.encodeAnyArray(value as? [Any] ?? [])
        } else {
            switch value {
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
                try encodeAny(dict, as: [AnyHashable: Any].self, forKey: key)
            case let array as [Any]:
                try encodeAny(array, as: [Any].self, forKey: key)
            default:
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Unsuported type"))
            }
        }
    }
    
    public mutating func encodeAnyIfPresent<T>(_ value: T?, as type: T.Type, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value {
            try encodeAny(value, as: type, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}

private extension KeyedEncodingContainer where K == AnyCodingKey {
    mutating func encodeAnyDictionary(_ value: [AnyHashable: Any]) throws {
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
                try encodeAny(dict, as: [AnyHashable: Any].self, forKey: key)
            case let array as [Any]:
                try encodeAny(array, as: [Any].self, forKey: key)
            default:
                throw EncodingError.invalidValue(v, .init(codingPath: codingPath, debugDescription: "Unsuported type"))
            }
        }
    }
}

private extension UnkeyedEncodingContainer {
    mutating func encodeAnyArray(_ value: [Any]) throws {
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
                try encodeAnyDictionary(dict)
            case let array as [Any]:
                var values = nestedUnkeyedContainer()
                try values.encodeAnyArray(array)
            default:
                throw EncodingError.invalidValue(v, .init(codingPath: codingPath, debugDescription: "Unsuported type"))
            }
        }
    }

    mutating func encodeAnyDictionary(_ value: [AnyHashable: Any]) throws {
        var container = self.nestedContainer(keyedBy: AnyCodingKey.self)
        try container.encodeAnyDictionary(value)
    }
}

// MARK: - SafeCodable
public extension Encoder {
    // MARK: - Subscript
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { try? encodeSafe(newValue, for: stringKey) }
    }
    
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { try? encodeSafe(newValue, for: codingKey) }
    }
    
    subscript<T>(stringKey: String) -> T? { get { return nil }
        nonmutating set { try? encodeSafeAny(newValue, for: stringKey) }
    }
    
    subscript<T, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { try? encodeSafeAny(newValue, for: codingKey) }
    }
    
    // MARK: - Safe
    func encodeSafe<T: Encodable>(_ value: T?, for stringKey: String) throws {
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encodeSafe(value, for: AnyCodingKey(stringKey))
            return
        }
        
        let keys = stringKey.split(separator: dot).map { AnyCodingKey($0) }
        var container = self.container(keyedBy: AnyCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        }
        
        let codingKey = keys.last!
        do {
            try container.encodeIfPresent(value, forKey: codingKey)
        } catch {}
    }
    
    func encodeSafe<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        var container = self.container(keyedBy: K.self)
        do {
            try container.encodeIfPresent(value, forKey: codingKey)
        } catch {}
    }
    
    // MARK: - SafeAny
    func encodeSafeAny<T>(_ value: T?, for stringKey: String) throws {
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encodeSafeAny(value, for: AnyCodingKey(stringKey))
            return
        }
        
        let keys = stringKey.split(separator: dot).map { AnyCodingKey($0) }
        var container = self.container(keyedBy: AnyCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        }
        
        let codingKey = keys.last!
        do {
            try container.encodeAnyIfPresent(value, as: T.self, forKey: codingKey)
        } catch {}
    }
    
    func encodeSafeAny<T, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        var container = self.container(keyedBy: K.self)
        do {
            try container.encodeAnyIfPresent(value, as: T.self, forKey: codingKey)
        } catch {}
    }
}

public extension Decoder {
    // MARK: - Subscript
    subscript<T: Decodable>(stringKeys: [String]) -> T? {
        return try? decodeSafe(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable>(stringKeys: String ...) -> T? {
        return try? decodeSafe(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: [K]) -> T? {
        return try? decodeSafe(codingKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: K ...) -> T? {
        return try? decodeSafe(codingKeys, as: T.self)
    }
    
    subscript<T>(stringKeys: [String]) -> T? {
        return try? decodeSafeAny(stringKeys, as: T.self)
    }
    
    subscript<T>(stringKeys: String ...) -> T? {
        return try? decodeSafeAny(stringKeys, as: T.self)
    }
    
    subscript<T, K: CodingKey>(codingKeys: [K]) -> T? {
        return try? decodeSafeAny(codingKeys, as: T.self)
    }
    
    subscript<T, K: CodingKey>(codingKeys: K ...) -> T? {
        return try? decodeSafeAny(codingKeys, as: T.self)
    }
    
    // MARK: - Safe
    func decodeSafe<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafe(stringKeys, as: type, throws: `throws`)
    }
    
    func decodeSafe<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafe(stringKeys.map { AnyCodingKey($0) }, as: type, throws: `throws`)
    }
    
    func decodeSafe<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafe(codingKeys, as: type, throws: `throws`)
    }
    
    func decodeSafe<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return try container.decodeForAlternativeKeys(codingKeys, as: type)
        } catch { if `throws` { throw error } }
        return nil
    }
    
    // MARK: - SafeAny
    func decodeSafeAny<T>(_ stringKeys: String ..., as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafeAny(stringKeys, as: type, throws: `throws`)
    }
    
    func decodeSafeAny<T>(_ stringKeys: [String], as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafeAny(stringKeys.map { AnyCodingKey($0) }, as: type, throws: `throws`)
    }
    
    func decodeSafeAny<T, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        return try decodeSafeAny(codingKeys, as: type, throws: `throws`)
    }
    
    func decodeSafeAny<T, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, throws: Bool = false) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return try container.decodeAnyForAlternativeKeys(codingKeys, as: type)
        } catch { if `throws` { throw error } }
        return nil
    }
}

fileprivate extension KeyedDecodingContainer {
    func decodeForAlternativeKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeForNestedKeys(codingKey, as: type) {
                return value
            }
        } catch { firstError = error }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = try? decodeForAlternativeKeys(codingKeys, as: type) {
            return value
        }
        
        if let firstError = firstError { throw firstError }
        return nil
    }
    
    func decodeAnyForAlternativeKeys<T>(_ codingKeys: [Self.Key], as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeAnyForNestedKeys(codingKey, as: type) {
                return value
            }
        } catch { firstError = error }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = try? decodeAnyForAlternativeKeys(codingKeys, as: type) {
            return value
        }
        
        if let firstError = firstError { throw firstError }
        return nil
    }
    
    func decodeForNestedKeys<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            if let value = try decodeForValue(codingKey, as: type) {
                return value
            }
        } catch { firstError = error }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? AnyCodingKey,
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { AnyCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = try? container.decodeForNestedKeys(codingKey as! Self.Key, as: type) {
                return value
            }
        }
        
        if let firstError = firstError { throw firstError }
        return nil
    }
    
    func decodeAnyForNestedKeys<T>(_ codingKey: Self.Key, as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            if let value = try decodeAnyForValue(codingKey, as: type) {
                return value
            }
        } catch { firstError = error }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? AnyCodingKey,
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { AnyCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = try? container.decodeAnyForNestedKeys(codingKey as! Self.Key, as: type) {
                return value
            }
        }
        
        if let firstError = firstError { throw firstError }
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
    
    func decodeForValue<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            if let value = try decodeIfPresent(type, forKey: codingKey) {
                return value
            }
        } catch { firstError = error }
        
        if contains(codingKey),
           let value = decodeForTypeConversion(codingKey, as: type) {
            return value
        }
        
        if let firstError = firstError { throw firstError }
        return nil
    }
    
    func decodeAnyForValue<T>(_ codingKey: Self.Key, as type: T.Type = T.self) throws -> T? {
        var firstError: Error?
        do {
            if let value = try decodeAnyIfPresent(type, forKey: codingKey) {
                return value
            }
        } catch { firstError = error }
        
        if contains(codingKey),
           let value = try? decodeAnyIfPresent(type, forKey: codingKey) {
            return value
        }
        
        if let firstError = firstError { throw firstError }
        return nil
    }
    
    func decodeForTypeConversion<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if type is Bool.Type || type is Bool?.Type {
            if let int = try? decodeIfPresent(Int.self, forKey: codingKey) {
                return (int != 0) as? T
            } else if let string = try? decodeIfPresent(String.self, forKey: codingKey) {
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
        } else if type is Int.Type || type is Int?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int(string) { return value as? T }
        } else if type is Int8.Type || type is Int8?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int8(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int8(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int8(string) { return value as? T }
        } else if type is Int16.Type || type is Int16?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int16(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int16(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int16(string) { return value as? T }
        } else if type is Int32.Type || type is Int32?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int32(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int32(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int32(string) { return value as? T }
        } else if type is Int64.Type || type is Int64?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return Int64(bool ? 1 : 0) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return Int64(double) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Int64(string) { return value as? T }
        } else if type is UInt.Type || type is UInt?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt(string) { return value as? T }
        } else if type is UInt8.Type || type is UInt8?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt8(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt8(string) { return value as? T }
        } else if type is UInt16.Type || type is UInt16?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt16(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt16(string) { return value as? T }
        } else if type is UInt32.Type || type is UInt32?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt32(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt32(string) { return value as? T }
        } else if type is UInt64.Type || type is UInt64?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return UInt64(bool ? 1 : 0) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = UInt64(string) { return value as? T }
        } else if type is Double.Type || type is Double?.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Double(int64) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Double(string) { return value as? T }
        } else if type is Float.Type || type is Float?.Type {
            if      let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return Float(int64) as? T }
            else if let string = try? decodeIfPresent(String.self, forKey: codingKey), let value = Float(string) { return value as? T }
        } else if type is String.Type || type is String?.Type {
            if      let bool   = try? decodeIfPresent(Bool.self,   forKey: codingKey) { return String(describing: bool) as? T }
            else if let int64  = try? decodeIfPresent(Int64.self,  forKey: codingKey) { return String(describing: int64) as? T }
            else if let double = try? decodeIfPresent(Double.self, forKey: codingKey) { return String(describing: double) as? T }
        }
        
        for converter in WrapperGlobal._codableDecodingConverters {
            if let value = try? converter.decode(self, codingKey: codingKey, as: type) {
                return value
            }
        }
        if let converter = self as? CodableDecodingConverter,
           let value = try? converter.decode(self, codingKey: codingKey, as: type) {
            return value
        }
        
        return nil
    }
}

// MARK: - CodableDecodingConverter
public protocol CodableDecodingConverter {
    func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) throws -> T?
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
