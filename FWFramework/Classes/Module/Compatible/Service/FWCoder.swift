//
//  FWCoder.swift
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

extension FWWrapper where Base == Data {
    public static func encoded<T>(_ value: T, using encoder: FWAnyEncoder = JSONEncoder()) throws -> Data where T : Encodable {
        return try encoder.encode(value)
    }
}

extension FWWrapper where Base == Encoder {
    public func encodeSingle<T: Encodable>(_ value: T) throws {
        var container = base.singleValueContainer()
        try container.encode(value)
    }

    public func encode<T: Encodable>(_ value: T, for key: String) throws {
        try encode(value, for: FWAnyCodingKey(key))
    }

    public func encode<T: Encodable, K: CodingKey>(_ value: T, for key: K) throws {
        var container = base.container(keyedBy: K.self)
        try container.encode(value, forKey: key)
    }

    public func encode<F: FWAnyDateFormatter>(_ date: Date, for key: String, using formatter: F) throws {
        try encode(date, for: FWAnyCodingKey(key), using: formatter)
    }

    public func encode<K: CodingKey, F: FWAnyDateFormatter>(_ date: Date, for key: K, using formatter: F) throws {
        let string = formatter.string(from: date)
        try encode(string, for: key)
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

extension FWWrapper where Base == Data {
    public func decoded<T: Decodable>(as type: T.Type = T.self,
                                      using decoder: FWAnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: self.base)
    }
}

extension FWWrapper where Base == Decoder {
    public func decodeSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        let container = try base.singleValueContainer()
        return try container.decode(type)
    }

    public func decode<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try decode(FWAnyCodingKey(key), as: type)
    }

    public func decode<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        let container = try base.container(keyedBy: K.self)
        return try container.decode(type, forKey: key)
    }

    public func decodeIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try decodeIf(FWAnyCodingKey(key), as: type)
    }

    public func decodeIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        let container = try base.container(keyedBy: K.self)
        return try container.decodeIfPresent(type, forKey: key)
    }

    public func decode<F: FWAnyDateFormatter>(_ key: String, using formatter: F) throws -> Date {
        return try decode(FWAnyCodingKey(key), using: formatter)
    }

    public func decode<K: CodingKey, F: FWAnyDateFormatter>(_ key: K, using formatter: F) throws -> Date {
        let container = try base.container(keyedBy: K.self)
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
    
    public func jsonSingle() throws -> FWJSON {
        return try decodeSingle(as: FWJSON.self)
    }
    
    public func json(_ key: String) throws -> FWJSON {
        return try decodeIf(key, as: FWJSON.self) ?? FWJSON.null
    }
    
    public func json<K: CodingKey>(_ key: K) throws -> FWJSON {
        return try decodeIf(key, as: FWJSON.self) ?? FWJSON.null
    }

    public func jsonIf(_ key: String) throws -> FWJSON? {
        return try decodeIf(key, as: FWJSON.self)
    }

    public func jsonIf<K: CodingKey>(_ key: K) throws -> FWJSON? {
        return try decodeIf(key, as: FWJSON.self)
    }
    
    // MARK: - Value
    
    public func valueSingle<T: Decodable>(as type: T.Type = T.self) throws -> T {
        if let value = value(with: try decodeSingle(as: FWJSON.self), as: type) {
            return value
        }
        return try decodeSingle(as: type)
    }
    
    public func value<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T {
        return try value(FWAnyCodingKey(key), as: type)
    }

    public func value<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T {
        if let value = value(with: try decodeIf(key, as: FWJSON.self) ?? FWJSON.null, as: type) {
            return value
        }
        return try decode(key, as: type)
    }

    public func valueIf<T: Decodable>(_ key: String, as type: T.Type = T.self) throws -> T? {
        return try valueIf(FWAnyCodingKey(key), as: type)
    }

    public func valueIf<T: Decodable, K: CodingKey>(_ key: K, as type: T.Type = T.self) throws -> T? {
        if let json = try decodeIf(key, as: FWJSON.self), let value = value(with: json, as: type) {
            return value
        }
        return try decodeIf(key, as: type)
    }
    
    private func value<T>(with json: FWJSON, as type: T.Type) -> T? {
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
