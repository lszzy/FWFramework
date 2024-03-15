//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - CodableModel
/// 通用Codable编码模型协议，使用方法类似Codable
public protocol CodableModel: Codable, AnyModel {}

extension CodableModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

// MARK: - KeyMappable
/// 通用Codable键名映射协议，需至少实现一种映射方法
public protocol KeyMappable: Codable, ObjectType {
    associatedtype Root = Self where Root: KeyMappable
    
    static var keyMapping: [KeyMapper<Root>] { get }
}

public extension KeyMappable where Root == Self {
    static var keyMapping: [KeyMapper<Root>] { [] }
    
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
        try encodeWrapper(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder, with: Self.keyMapping)
        try decodeWrapper(from: decoder)
    }
}

public extension KeyMappable {
    func encode(to encoder: Encoder, with keyMapping: [KeyMapper<Self>]) throws {
        try keyMapping.forEach { try $0.encode(self, encoder) }
    }
    
    mutating func decode(from decoder: Decoder, with keyMapping: [KeyMapper<Self>]) throws {
        try keyMapping.forEach { try $0.decode?(&self, decoder) }
    }
    
    func decodeReference(from decoder: Decoder, with keyMapping: [KeyMapper<Self>]) throws {
        try keyMapping.forEach { try $0.decodeReference?(self, decoder) }
    }
    
    func encodeWrapper(to encoder: Encoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? EncodablePropertyWrapper) {
                    try wrapper.encode(to: encoder, label: child.label!.dropFirst())
                } else {
                    try (child.value as? EncodableAnyPropertyWrapper)?.encode(to: encoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
    
    func decodeWrapper(from decoder: Decoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? DecodablePropertyWrapper) {
                    try wrapper.decode(from: decoder, label: child.label!.dropFirst())
                } else {
                    try (child.value as? DecodableAnyPropertyWrapper)?.decode(from: decoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
}

// MARK: - KeyMapper
public final class KeyMapper<Root: Codable> {
    fileprivate let encode: (_ root: Root, _ encoder: Encoder) throws -> Void
    fileprivate let decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?
    fileprivate let decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?
    private init(encode: @escaping (_ root: Root, _ encoder: Encoder) throws -> Void,
                 decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?,
                 decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?) {
        (self.encode, self.decode, self.decodeReference) = (encode, decode, decodeReference)
    }
}

public extension KeyMapper {
    convenience init<Value: Codable>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            if let value: Value = try decoder.decode(codingKeys) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            if let value: Value = try decoder.decode(codingKeys) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            if let value: Value = try decoder.decode(codingKeys) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value: Codable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encode(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            if let value: Value = try decoder.decode(codingKeys) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            if let value: Value = try decoder.decodeAny(codingKeys) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            if let value: Value = try decoder.decodeAny(codingKeys) {
                root[keyPath: keyPath] = value
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            if let value: Value = try decoder.decodeAny(codingKeys) {
                root[keyPath: keyPath] = value
            }
        })
    }
    
    convenience init<Value, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            if let value: Value = try decoder.decodeAny(codingKeys) {
                root[keyPath: keyPath] = value
            }
        })
    }
}

// MARK: - MappableValue
/// Codable属性注解，解析成功且不为nil时才会覆盖默认值
///
/// https://github.com/iwill/ExCodable
@propertyWrapper
public final class MappableValue<Value> {
    fileprivate let stringKeys: [String]?
    fileprivate let encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?
    public var wrappedValue: Value
    
    private init(wrappedValue: Value, stringKeys: [String]? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
        (self.wrappedValue, self.stringKeys, self.encode, self.decode) = (wrappedValue, stringKeys, encode, decode)
    }
    
    public convenience init(wrappedValue: Value, _ stringKey: String? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKey.map { [$0] }, encode: encode, decode: decode)
    }
    
    public convenience init(wrappedValue: Value, _ stringKeys: String..., encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKeys, encode: encode, decode: decode)
    }
    
    public convenience init(wrappedValue: Value, _ codingKeys: CodingKey..., encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: codingKeys.map { $0.stringValue }, encode: encode, decode: decode)
    }
}

extension MappableValue: Equatable where Value: Equatable {
    public static func == (lhs: MappableValue<Value>, rhs: MappableValue<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension MappableValue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { String(describing: wrappedValue) }
    public var debugDescription: String { description }
}

fileprivate protocol EncodablePropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws
}

extension MappableValue: EncodablePropertyWrapper where Value: Encodable {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else {
            let value = deepUnwrap(wrappedValue)
            if value != nil {
                try encoder.encode(wrappedValue, for: stringKeys?.first ?? String(label))
            }
        }
    }
}

fileprivate protocol EncodableAnyPropertyWrapper {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws
}

extension MappableValue: EncodableAnyPropertyWrapper {
    fileprivate func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws {
        if encode != nil { try encode!(encoder, wrappedValue) }
        else {
            let value = deepUnwrap(wrappedValue)
            if value != nil {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encodeAnyIfPresent(wrappedValue, as: type(of: wrappedValue), forKey: AnyCodingKey(label))
            }
        }
    }
}

fileprivate protocol DecodablePropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws
}

extension MappableValue: DecodablePropertyWrapper where Value: Decodable {
    fileprivate func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws {
        let value = decode != nil ? try decode!(decoder) : try decoder.decode(stringKeys ?? [String(label)])
        if let value = value {
            wrappedValue = value
        }
    }
}

fileprivate protocol DecodableAnyPropertyWrapper {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws
}

extension MappableValue: DecodableAnyPropertyWrapper {
    fileprivate func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws {
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

public extension Encoder {
    subscript<T: Encodable>(stringKey: String) -> T? { get { return nil }
        nonmutating set { try? encode(newValue, for: stringKey) }
    }
    
    subscript<T: Encodable, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { try? encode(newValue, for: codingKey) }
    }
    
    subscript<T>(stringKey: String) -> T? { get { return nil }
        nonmutating set { try? encodeAny(newValue, for: stringKey) }
    }
    
    subscript<T, K: CodingKey>(codingKey: K) -> T? { get { return nil }
        nonmutating set { try? encodeAny(newValue, for: codingKey) }
    }
}

public extension Decoder {
    subscript<T: Decodable>(stringKeys: [String]) -> T? {
        return try? decode(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable>(stringKeys: String ...) -> T? {
        return try? decode(stringKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: [K]) -> T? {
        return try? decode(codingKeys, as: T.self)
    }
    
    subscript<T: Decodable, K: CodingKey>(codingKeys: K ...) -> T? {
        return try? decode(codingKeys, as: T.self)
    }
    
    subscript<T>(stringKeys: [String]) -> T? {
        return try? decodeAny(stringKeys, as: T.self)
    }
    
    subscript<T>(stringKeys: String ...) -> T? {
        return try? decodeAny(stringKeys, as: T.self)
    }
    
    subscript<T, K: CodingKey>(codingKeys: [K]) -> T? {
        return try? decodeAny(codingKeys, as: T.self)
    }
    
    subscript<T, K: CodingKey>(codingKeys: K ...) -> T? {
        return try? decodeAny(codingKeys, as: T.self)
    }
}

public extension Encoder {
    func encode<T: Encodable>(_ value: T?, for stringKey: String) throws {
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encode(value, for: AnyCodingKey(stringKey))
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
    
    func encodeAny<T>(_ value: T?, for stringKey: String) throws {
        let dot: Character = "."
        guard stringKey.contains(dot), stringKey.count > 1 else {
            try encodeAny(value, for: AnyCodingKey(stringKey))
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
    
    func encode<T: Encodable, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        var container = self.container(keyedBy: K.self)
        do {
            try container.encodeIfPresent(value, forKey: codingKey)
        } catch {}
    }
    
    func encodeAny<T, K: CodingKey>(_ value: T?, for codingKey: K) throws {
        var container = self.container(keyedBy: K.self)
        do {
            try container.encodeAnyIfPresent(value, as: T.self, forKey: codingKey)
        } catch {}
    }
}

public extension Decoder {
    func decode<T: Decodable>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T? {
        return try decode(stringKeys, as: type)
    }
    
    func decode<T: Decodable>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T? {
        return try decode(stringKeys.map { AnyCodingKey($0) }, as: type)
    }
    
    func decodeAny<T>(_ stringKeys: String ..., as type: T.Type = T.self) throws -> T? {
        return try decodeAny(stringKeys, as: type)
    }
    
    func decodeAny<T>(_ stringKeys: [String], as type: T.Type = T.self) throws -> T? {
        return try decodeAny(stringKeys.map { AnyCodingKey($0) }, as: type)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T? {
        return try decode(codingKeys, as: type)
    }
    
    func decode<T: Decodable, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return container.decodeForAlternativeKeys(codingKeys, as: type)
        } catch {}
        return nil
    }
    
    func decodeAny<T, K: CodingKey>(_ codingKeys: K ..., as type: T.Type = T.self) throws -> T? {
        return try decodeAny(codingKeys, as: type)
    }
    
    func decodeAny<T, K: CodingKey>(_ codingKeys: [K], as type: T.Type = T.self) throws -> T? {
        do {
            let container = try self.container(keyedBy: K.self)
            return container.decodeAnyForAlternativeKeys(codingKeys, as: type)
        } catch {}
        return nil
    }
}

fileprivate extension KeyedDecodingContainer {
    func decodeForAlternativeKeys<T: Decodable>(_ codingKeys: [Self.Key], as type: T.Type = T.self) -> T? {
        let codingKey = codingKeys.first!
        if let value = decodeForNestedKeys(codingKey, as: type) {
            return value
        }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = decodeForAlternativeKeys(codingKeys, as: type) {
            return value
        }
        
        return nil
    }
    
    func decodeAnyForAlternativeKeys<T>(_ codingKeys: [Self.Key], as type: T.Type = T.self) -> T? {
        let codingKey = codingKeys.first!
        if let value = decodeAnyForNestedKeys(codingKey, as: type) {
            return value
        }
        
        let codingKeys = Array(codingKeys.dropFirst())
        if !codingKeys.isEmpty,
           let value = decodeAnyForAlternativeKeys(codingKeys, as: type) {
            return value
        }
        
        return nil
    }
    
    func decodeForNestedKeys<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = decodeForValue(codingKey, as: type) {
            return value
        }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? AnyCodingKey,
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { AnyCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = container.decodeForNestedKeys(codingKey as! Self.Key, as: type) {
                return value
            }
        }
        
        return nil
    }
    
    func decodeAnyForNestedKeys<T>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = decodeAnyForValue(codingKey, as: type) {
            return value
        }
        
        let dot: Character = "."
        if let exCodingKey = codingKey as? AnyCodingKey,
           exCodingKey.intValue == nil && exCodingKey.stringValue.contains(dot) {
            let keys = exCodingKey.stringValue.split(separator: dot).map { AnyCodingKey($0) }
            if !keys.isEmpty,
               let container = nestedContainer(with: keys.dropLast()),
               let codingKey = keys.last,
               let value = container.decodeAnyForNestedKeys(codingKey as! Self.Key, as: type) {
                return value
            }
        }
        
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
    
    func decodeForValue<T: Decodable>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = try? decodeIfPresent(type, forKey: codingKey) {
            return value
        }
        
        if contains(codingKey),
           let value = decodeForTypeConversion(codingKey, as: type) {
            return value
        }
        
        return nil
    }
    
    func decodeAnyForValue<T>(_ codingKey: Self.Key, as type: T.Type = T.self) -> T? {
        if let value = try? decodeAnyIfPresent(type, forKey: codingKey) {
            return value
        }
        
        if contains(codingKey),
           let value = try? decodeAnyIfPresent(type, forKey: codingKey) {
            return value
        }
        
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

private var _codableDecodingConverters: [CodableDecodingConverter] = []

public protocol CodableDecodingConverter {
    func decode<T: Decodable, K: CodingKey>(_ container: KeyedDecodingContainer<K>, codingKey: K, as type: T.Type) throws -> T?
}

public func register(_ decodingConverter: CodableDecodingConverter) {
    _codableDecodingConverters.append(decodingConverter)
}
