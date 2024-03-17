//
//  KeyMappable.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - KeyMappable
/// 通用Key键名映射协议，需至少实现一种映射方法，推荐使用
public protocol KeyMappable {
    associatedtype Root = Self where Root: KeyMappable
    
    /// 模型Key键名映射声明，优先级中
    static var keyMapping: [KeyMap<Root>] { get }
    
    /// 映射值到指定Key，优先级高
    func mappingValue(_ value: Any, forKey key: String) -> Bool
}

public extension KeyMappable where Root == Self {
    static var keyMapping: [KeyMap<Root>] { [] }
    
    func mappingValue(_ value: Any, forKey key: String) -> Bool { false }
}

// MARK: - KeyMap
/// 模型Key键名映射类，优先级低
public final class KeyMap<Root: KeyMappable> {
    let match: ((_ root: Root, _ property: String) -> Bool)?
    let write: ((_ root: inout Root, _ value: Any) -> Void)?
    let writeReference: ((_ root: Root, _ value: Any) -> Void)?
    init(match: @escaping (_ root: Root, _ property: String) -> Bool,
                 write: ((_ root: inout Root, _ value: Any) -> Void)?,
                 writeReference: ((_ root: Root, _ value: Any) -> Void)?) {
        (self.match, self.write, self.writeReference) = (match, write, writeReference)
        (self.encode, self.decode, self.decodeReference) = (nil, nil, nil)
    }
    
    let encode: ((_ root: Root, _ encoder: Encoder) throws -> Void)?
    let decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?
    let decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?
    init(encode: @escaping (_ root: Root, _ encoder: Encoder) throws -> Void,
         decode: ((_ root: inout Root, _ decoder: Decoder) throws -> Void)?,
         decodeReference: ((_ root: Root, _ decoder: Decoder) throws -> Void)?) {
        (self.encode, self.decode, self.decodeReference) = (encode, decode, decodeReference)
        (self.match, self.write, self.writeReference) = (nil, nil, nil)
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
    
    init(wrappedValue: Value, stringKeys: [String]? = nil) {
        (self.wrappedValue, self.stringKeys) = (wrappedValue, stringKeys)
        (self.encode, self.decode) = (nil, nil)
    }
    
    init(wrappedValue: Value, stringKeys: [String]? = nil, encode: ((_ encoder: Encoder, _ value: Value) throws -> Void)?, decode: ((_ decoder: Decoder) throws -> Value?)?) {
        (self.wrappedValue, self.stringKeys, self.encode, self.decode) = (wrappedValue, stringKeys, encode, decode)
    }
    
    public convenience init(wrappedValue: Value, _ stringKey: String? = nil) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKey.map { [$0] })
    }
    
    public convenience init(wrappedValue: Value, _ stringKeys: String...) {
        self.init(wrappedValue: wrappedValue, stringKeys: stringKeys)
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

// MARK: - IgnoredValue
/// 忽略映射Key注解
@propertyWrapper
public final class IgnoredValue<Value> {
    public var wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension IgnoredValue: Equatable where Value: Equatable {
    public static func == (lhs: IgnoredValue<Value>, rhs: IgnoredValue<Value>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension IgnoredValue: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { String(describing: wrappedValue) }
    public var debugDescription: String { description }
}
