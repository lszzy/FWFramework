//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - CodableModel
/// 通用Codable模型协议，默认未实现KeyMappable，使用方式同Codable一致；
/// CodableModel可实现KeyMappable，并选择以下模式使用，推荐方式
///
/// KeyMappable模式一：MappedValue模式
/// 1. 支持Codable类型字段，使用方式：@MappedValue
/// 2. 支持多字段映射，使用方式：@MappedValue("name1", "name2")
/// 3. 支持Any类型字段，使用方式：@MappedValue
/// 4. 未标记MappedValue的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
///
/// KeyMappable模式二：MappedValueMacro模式(需引入FWMacro子模块)
/// 1. 标记class或struct为自动映射存储属性宏，使用方式：@MappedValueMacro
/// 2. 可自定义字段映射规则，使用方式：@MappedValue("name1", "name2")
/// 3. 可忽略指定字段，使用方式：@MappedValue(ignored: true)
///
/// KeyMappable模式三：自定义模式
/// 1. 需完整实现Codable协议的encode和decode协议方法
public protocol CodableModel: Codable, AnyModel {}

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
        try encodeValue(to: encoder, with: Self.keyMapping)
        try encodeMirror(to: encoder)
    }
    
    mutating func decodeModel(from decoder: Decoder) throws {
        try decodeValue(from: decoder, with: Self.keyMapping)
        try decodeMirror(from: decoder)
    }
    
    func encodeValue(to encoder: Encoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.encode(self, to: encoder) }
    }
    
    mutating func decodeValue(from decoder: Decoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.decode(&self, from: decoder) }
    }
    
    func decodeReference(from decoder: Decoder, with keyMapping: [KeyMap<Self>]) throws {
        try keyMapping.forEach { try $0.decodeReference(self, from: decoder) }
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
        (self.encode, self.decode, self.decodeReference, self.mappingKeys, self.mapping, self.mappingReference) = (encode, decode, decodeReference, [], nil, nil)
    }
    
    let mappingKeys: [String]
    let mapping: ((_ root: inout Root, _ value: Any) -> Void)?
    let mappingReference: ((_ root: Root, _ value: Any) -> Void)?
    init(mappingKeys: [String],
         mapping: ((_ root: inout Root, _ value: Any) -> Void)?,
         mappingReference: ((_ root: Root, _ value: Any) -> Void)?) {
        (self.encode, self.decode, self.decodeReference, self.mappingKeys, self.mapping, self.mappingReference) = (nil, nil, nil, mappingKeys, mapping, mappingReference)
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
    let ignored: Bool
    public var wrappedValue: Value
    
    let encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?
    let decode: ((_ decoder: Decoder) throws -> Value?)?
    
    init(wrappedValue: Value, stringKeys: [String]?, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
        (self.wrappedValue, self.stringKeys, self.ignored, self.encode, self.decode) = (wrappedValue, stringKeys, false, encode, decode)
    }
    
    public init(wrappedValue: Value, ignored: Bool) {
        (self.wrappedValue, self.stringKeys, self.ignored, self.encode, self.decode) = (wrappedValue, nil, ignored, nil, nil)
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
        guard !ignored else { return }
        
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
        guard !ignored else { return }
        
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
        guard !ignored else { return }
        
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
        guard !ignored else { return }
        
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
