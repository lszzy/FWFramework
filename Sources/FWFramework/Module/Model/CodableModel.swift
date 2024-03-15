//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - CodableModel
/// 通用Codable编码模型协议，默认未实现init方法
public protocol CodableModel: Codable, AnyModel {}

extension CodableModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
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

fileprivate protocol EncodableAnyPropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws
}

extension CodableValue: EncodableAnyPropertyWrapper {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label, nonnull: Bool, throws: Bool) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else {
            let value = deepUnwrap(wrappedValue)
            if value != nil || self.nonnull ?? nonnull {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encodeAnyIfPresent(wrappedValue, as: type(of: wrappedValue), forKey: AnyCodingKey(label))
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
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            if let value = try container.decodeAnyIfPresent(type(of: wrappedValue), forKey: AnyCodingKey(label)) {
                wrappedValue = value
            }
        }
    }
}

// MARK: - AutoCodable
public protocol AutoCodable: Codable, ObjectType {}

public extension AutoCodable {
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
    }
    
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
    
    internal func encodeAny<T>(_ value: T?, for stringKey: String, nonnull: Bool = false, throws: Bool = false) throws {
        
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encodeAny(value, for: AnyCodingKey(stringKey), nonnull: nonnull, throws: `throws`)
            return
        }
        
        let keys = stringKey.split(separator: dot).map { AnyCodingKey($0) }
        var container = self.container(keyedBy: AnyCodingKey.self)
        for key in keys.dropLast() {
            container = container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
        }
        
        let codingKey = keys.last!
        do {
            if nonnull { try container.encodeAny(value!, as: T.self, forKey: codingKey) }
            else { try container.encodeAnyIfPresent(value, as: T.self, forKey: codingKey) }
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
    
    internal func encodeAny<T, K: CodingKey>(_ value: T?, for codingKey: K, nonnull: Bool = false, throws: Bool = false) throws {
        var container = self.container(keyedBy: K.self)
        do {
            if nonnull { try container.encodeAny(value!, as: T.self, forKey: codingKey) }
            else { try container.encodeAnyIfPresent(value, as: T.self, forKey: codingKey) }
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
    
    internal func decodeAny<T>(_ stringKeys: [String], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        return try decodeAny(stringKeys.map { AnyCodingKey($0) }, as: type, nonnull: nonnull, throws: `throws`)
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
    
    internal func decodeAny<T, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self, nonnull: Bool = false, throws: Bool = false) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return try container.decodeAnyForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`)
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
    
    func decodeAnyForAlternativeKeys<T>(_ codingKeys: [Self.Key], as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            let codingKey = codingKeys.first!
            if let value = try decodeAnyForNestedKeys(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
                return value
            }
        }
        catch { firstError = error }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = try? decodeAnyForAlternativeKeys(codingKeys, as: type, nonnull: nonnull, throws: `throws`) {
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
    
    func decodeAnyForNestedKeys<T>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = try decodeAnyForValue(codingKey, as: type, nonnull: nonnull, throws: `throws`) {
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
               let value = try? container.decodeAnyForNestedKeys(codingKey as! Self.Key, as: type, nonnull: nonnull, throws: `throws`) {
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
    
    func decodeAnyForValue<T>(_ codingKey: Self.Key, as type: T.Type = T.self, nonnull: Bool, throws: Bool) throws -> T? {
        
        var firstError: Error?
        do {
            if let value = (nonnull
                            ? (`throws` ? try decodeAny(type, forKey: codingKey) : try? decodeAny(type, forKey: codingKey))
                            : (`throws` ? try decodeAnyIfPresent(type, forKey: codingKey) : try? decodeAnyIfPresent(type, forKey: codingKey))) {
                return value
            }
        }
        catch { firstError = error }
        
        if contains(codingKey),
           let value = try? decodeAnyIfPresent(type, forKey: codingKey) {
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

// MARK: - MappableCodable
public protocol MappableCodable: Codable, ObjectType {
    associatedtype Root = Self where Root: MappableCodable
    
    static var keyMapping: [KeyMapper<Root>] { get }
}

public extension MappableCodable where Root == Self {
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder, with: Self.keyMapping)
    }
}

public extension MappableCodable {
    func encode(to encoder: Encoder, with keyMapping: [KeyMapper<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.encode(self, encoder, nonnull, `throws`) }
    }
    
    mutating func decode(from decoder: Decoder, with keyMapping: [KeyMapper<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.decode?(&self, decoder, nonnull, `throws`) }
    }
    
    func decodeReference(from decoder: Decoder, with keyMapping: [KeyMapper<Self>], nonnull: Bool = false, throws: Bool = false) throws {
        try keyMapping.forEach { try $0.decodeReference?(self, decoder, nonnull, `throws`) }
    }
}

public final class KeyMapper<Root: Codable> {
    fileprivate let encode: (_ root: Root, _ encoder: Encoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void
    fileprivate let decode: ((_ root: inout Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?
    fileprivate let decodeReference: ((_ root: Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?
    private init(encode: @escaping (_ root: Root, _ encoder: Encoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void,
                 decode: ((_ root: inout Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?,
                 decodeReference: ((_ root: Root, _ decoder: Decoder, _ nonnullAll: Bool, _ throwsAll: Bool) throws -> Void)?) {
        (self.encode, self.decode, self.decodeReference) = (encode, decode, decodeReference)
    }
}

public extension KeyMapper {
    convenience init<Value: Codable>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value: Codable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decode(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decodeAny(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decodeAny(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decodeAny(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ..., nonnull: Bool? = nil, throws: Bool? = nil) {
        self.init(encode: { root, encoder, nonnullAll, throwsAll in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll)
        }, decode: nil, decodeReference: { root, decoder, nonnullAll, throwsAll in
            if let value: Value = try decoder.decodeAny(codingKeys, nonnull: nonnull ?? nonnullAll, throws: `throws` ?? throwsAll) {
                root[keyPath: keyPath] = value
            }
        })
    }
}
