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
/// [ExCodable](https://github.com/iwill/ExCodable)
public extension KeyMappable where Root == Self, Self: CodableModel {
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, with: Self.keyMapping)
        try encodeMirror(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        try decode(from: decoder, with: Self.keyMapping)
        try decodeMirror(from: decoder)
    }
}

public extension KeyMappable where Root == Self, Self: CodableModel {
    func encode(to encoder: Encoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.encode?(self, encoder) }
    }
    
    mutating func decode(from decoder: Decoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.decode?(&self, decoder) }
    }
    
    func decodeReference(from decoder: Decoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.decodeReference?(self, decoder) }
    }
    
    func encodeMirror(to encoder: Encoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? EncodableMappedValue) {
                    try wrapper.encode(to: encoder, label: child.label!.dropFirst())
                } else {
                    try (child.value as? EncodableAnyMappedValue)?.encode(to: encoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
    
    func decodeMirror(from decoder: Decoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = (child.value as? DecodableMappedValue) {
                    try wrapper.decode(from: decoder, label: child.label!.dropFirst())
                } else {
                    try (child.value as? DecodableAnyMappedValue)?.decode(from: decoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
}

// MARK: - KeyMap
public extension KeyMap where Root: CodableModel {
    convenience init<Value: Codable>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafe(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            do {
                if let value = try decoder.decodeSafe(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafe(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            do {
                if let value = try decoder.decodeSafe(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value: Codable>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafe(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            do {
                if let value = try decoder.decodeSafe(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        })
    }
    
    convenience init<Value: Codable, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafe(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            do {
                if let value = try decoder.decodeSafe(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        })
    }
    
    convenience init<Value>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            do {
                if let value = try decoder.decodeSafeAny(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value, Key: CodingKey>(_ keyPath: WritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: { root, decoder in
            do {
                if let value = try decoder.decodeSafeAny(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        }, decodeReference: nil)
    }
    
    convenience init<Value>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: String ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            do {
                if let value = try decoder.decodeSafeAny(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        })
    }
    
    convenience init<Value, Key: CodingKey>(ref keyPath: ReferenceWritableKeyPath<Root, Value>, to codingKeys: Key ...) {
        self.init(encode: { root, encoder in
            try encoder.encodeSafeAny(root[keyPath: keyPath], for: codingKeys.first!)
        }, decode: nil, decodeReference: { root, decoder in
            do {
                if let value = try decoder.decodeSafeAny(codingKeys, as: Value.self, throws: true) {
                    root[keyPath: keyPath] = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(root[keyPath: keyPath]) {
                    let value: Value? = nil
                    root[keyPath: keyPath] = (value as Any) as! Value
                }
            }
        })
    }
}

// MARK: - MappedValue
public extension MappedValue {
    convenience init(wrappedValue: Value, _ stringKey: String? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKey.map { [$0] }, encode: encode, decode: decode)
    }
    
    convenience init(wrappedValue: Value, _ stringKeys: String..., encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKeys, encode: encode, decode: decode)
    }
    
    convenience init(wrappedValue: Value, _ codingKeys: CodingKey..., encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)? = nil, decode: ((_ decoder: Decoder) throws -> Value?)? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: codingKeys.map { $0.stringValue }, encode: encode, decode: decode)
    }
}

public protocol EncodableMappedValue {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws
}

extension MappedValue: EncodableMappedValue where Value: Encodable {
    public func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws {
        if let encode = encode {
            try encode(encoder, wrappedValue)
        } else {
            let value = Optional<Any>.deepUnwrap(wrappedValue)
            if value != nil {
                try encoder.encodeSafe(wrappedValue, for: stringKeys?.first ?? String(label))
            }
        }
    }
}

public protocol DecodableMappedValue {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws
}

extension MappedValue: DecodableMappedValue where Value: Decodable {
    public func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws {
        if let decode = decode {
            if let value = try decode(decoder) {
                wrappedValue = value
            }
        } else {
            do {
                if let value = try decoder.decodeSafe(stringKeys ?? [String(label)], as: type(of: wrappedValue), throws: true) {
                    wrappedValue = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(wrappedValue) {
                    let value: Value? = nil
                    wrappedValue = (value as Any) as! Value
                }
            }
        }
    }
}

public protocol EncodableAnyMappedValue {
    func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws
}

extension MappedValue: EncodableAnyMappedValue {
    public func encode<Label: StringProtocol>(to encoder: Encoder, label: Label) throws {
        if let encode = encode {
            try encode(encoder, wrappedValue)
        } else {
            let value = Optional<Any>.deepUnwrap(wrappedValue)
            if value != nil {
                var container = encoder.container(keyedBy: AnyCodingKey.self)
                try container.encodeAnyIfPresent(wrappedValue, as: type(of: wrappedValue), forKey: AnyCodingKey(label))
            }
        }
    }
}

public protocol DecodableAnyMappedValue {
    func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws
}

extension MappedValue: DecodableAnyMappedValue {
    public func decode<Label: StringProtocol>(from decoder: Decoder, label: Label) throws {
        if let decode = decode {
            if let value = try decode(decoder) {
                wrappedValue = value
            }
        } else {
            do {
                if let value = try decoder.decodeSafeAny(stringKeys ?? [String(label)], as: type(of: wrappedValue), throws: true) {
                    wrappedValue = value
                }
            } catch {
                /// 当值是可选类型、且键值存在但解析失败时，重置wrappedValue为nil
                if Optional<Any>.isOptional(wrappedValue) {
                    let value: Value? = nil
                    wrappedValue = (value as Any) as! Value
                }
            }
        }
    }
}
