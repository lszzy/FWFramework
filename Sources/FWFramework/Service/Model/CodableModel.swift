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
/// KeyMappable模式二：MappedValueMacro模式(需引入FWExtensionMacros子模块)
/// 1. 标记class或struct为自动映射存储属性宏，使用方式：@MappedValueMacro
/// 2. 可自定义字段映射规则，使用方式：@MappedValue("name1", "name2")
/// 3. 以下划线开头或结尾的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
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
public protocol KeyMappable {}

public extension KeyMappable where Self: Codable & ObjectType {
    func encode(to encoder: Encoder) throws {
        try encodeMirror(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        try decodeMirror(from: decoder)
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
