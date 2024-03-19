//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - CodableModel
/// 通用安全编解码Codable模型协议，需实现KeyMappable，可任选一种模式使用
///
/// 模式一：MappedValue模式，与KeyMapping模式冲突
/// 1. 支持Codable类型字段，使用方式：@MappedValue
/// 2. 支持多字段映射，使用方式：@MappedValue("name1", "name2")
/// 3. 支持Any类型字段，使用方式：@MappedValue
/// 4. 未标记MappedValue的字段自动忽略
///
/// 模式二：KeyMapping模式，与MappedValue模式冲突
/// 1. 完整自定义映射字段列表，使用方式：static let keyMapping: [KeyMap<Self>] = [...]
/// 2. 支持多字段映射，使用方式：KeyMap(\.name, to: "name1", "name2")
/// 3. 支持Any类型，使用方式同上，加入keyMapping即可
/// 4. 未加入keyMapping的字段自动忽略
///
/// 模式三：自定义模式
/// 1. 需完整实现Codable协议的encode和decode方法
/// 2. 实现时可调用MappedValue模式、KeyMapping模式相关解析方法
/// 3. 也可调用Codable协议相关解析方法，如encodeSafe|decodeSafe等
public protocol CodableModel: Codable, KeyMappable, AnyModel {}

extension CodableModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

// MARK: - KeyMappable
/// 通用Key键名映射协议，兼容Codable、CodableModel、JSONModel，推荐使用
///
/// [ExCodable](https://github.com/iwill/ExCodable)
public protocol KeyMappable {
    associatedtype Root = Self where Root: KeyMappable
    
    /// 模型Key键名映射声明，默认为空不生效
    static var keyMapping: [KeyMap<Root>] { get }
}

public extension KeyMappable where Root == Self {
    static var keyMapping: [KeyMap<Root>] { [] }
}

public extension KeyMappable where Root == Self, Self: Codable & ObjectType {
    func encode(to encoder: Encoder) throws {
        try encodeModel(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        try decodeModel(from: decoder)
    }
    
    func encodeModel(to encoder: Encoder) throws {
        // 模式一：KeyMapping模式
        let keyMapping = Self.keyMapping
        if !keyMapping.isEmpty {
            try keyMapping.forEach { try $0.encode(self, to: encoder) }
        // 模式二：MappedValue模式
        } else {
            try encodeMirror(to: encoder)
        }
    }
    
    mutating func decodeModel(from decoder: Decoder) throws {
        // 模式一：KeyMapping模式
        let keyMapping = Self.keyMapping
        if !keyMapping.isEmpty {
            try keyMapping.forEach { try $0.decode(&self, from: decoder) }
        // 模式二：MappedValue模式
        } else {
            try decodeMirror(from: decoder)
        }
    }
    
    func encodeMirror(to encoder: Encoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = child.value as? EncodableMappedValue {
                    try wrapper.encode(to: encoder, label: child.label!.dropFirst())
                } else if let wrapper = child.value as? EncodableAnyMappedValue {
                    try wrapper.encode(to: encoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
    
    func decodeMirror(from decoder: Decoder) throws {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = child.value as? DecodableMappedValue {
                    try wrapper.decode(from: decoder, label: child.label!.dropFirst())
                } else if let wrapper = child.value as? DecodableAnyMappedValue {
                    try wrapper.decode(from: decoder, label: child.label!.dropFirst())
                }
            }
            mirror = mirror.superclassMirror
        }
    }
}

// MARK: - KeyMap
/// 模型Key键名映射类
public final class KeyMap<Root: KeyMappable> {
    let encode: ((_ root: Root, _ encoder: Encoder) throws -> Void)?
    let decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?
    let decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?
    init(encode: @escaping (_ root: Root, _ encoder: Encoder) throws -> Void,
         decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?,
         decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?) {
        (self.encode, self.decode, self.decodeReference) = (encode, decode, decodeReference)
        (self.match, self.mapping, self.mappingReference) = (nil, nil, nil)
    }
    
    let match: ((_ root: Root, _ property: String) -> Bool)?
    let mapping: ((_ root: inout Root, _ value: Any) -> Void)?
    let mappingReference: ((_ root: Root, _ value: Any) -> Void)?
    init(match: @escaping (_ root: Root, _ property: String) -> Bool,
         mapping: ((_ root: inout Root, _ value: Any) -> Void)?,
         mappingReference: ((_ root: Root, _ value: Any) -> Void)?) {
        (self.match, self.mapping, self.mappingReference) = (match, mapping, mappingReference)
        (self.encode, self.decode, self.decodeReference) = (nil, nil, nil)
    }
}

public extension KeyMap where Root: Codable & ObjectType {
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
    
    func encode(_ root: Root, to encoder: Encoder) throws {
        try encode?(root, encoder)
    }
    
    func decode(_ root: inout Root, from decoder: Decoder) throws {
        try decode?(&root, decoder)
    }
    
    func decodeReference(_ root: Root, from decoder: Decoder) throws {
        try decodeReference?(root, decoder)
    }
}

// MARK: - MappedValue
/// 映射属性注解
@propertyWrapper
public final class MappedValue<Value> {
    let stringKeys: [String]?
    public var wrappedValue: Value
    
    let encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?
    let decode: ((_ decoder: Decoder) throws -> Value?)?
    
    init(wrappedValue: Value, stringKeys: [String]?, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
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

extension MappedValue: Equatable where Value: Equatable {
    public static func == (lhs: MappedValue<Value>, rhs: MappedValue<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension MappedValue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { String(describing: wrappedValue) }
    public var debugDescription: String { description }
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
                try encoder.encodeSafeAny(wrappedValue, for: stringKeys?.first ?? String(label))
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
