//
//  Codable.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 安全字符串，不为nil
    public static func safeString(_ value: Any?) -> String {
        return String.fw_safeString(value)
    }

    /// 安全数字，不为nil
    public static func safeNumber(_ value: Any?) -> NSNumber {
        return NSNumber.fw_safeNumber(value)
    }

    /// 安全URL，不为nil，不兼容文件路径(需fileURLWithPath)
    public static func safeURL(_ value: Any?) -> URL {
        return URL.fw_safeURL(value)
    }
    
    /// 获取安全值
    public static func safeValue<T: BasicCodableType>(_ value: T?) -> T {
        return value.safeValue
    }

    /// 判断是否不为空
    public static func isNotEmpty<T: BasicCodableType>(_ value: T?) -> Bool {
        return value.isNotEmpty
    }
    
    /// 判断是否为nil，兼容嵌套Optional
    public static func isNil(_ value: Any?) -> Bool {
        return Optional<Any>.isNil(value)
    }
}

// MARK: - Codable+Extension
@_spi(FW) extension String {
    /// 安全字符串，不为nil
    public static func fw_safeString(_ value: Any?) -> String {
        guard let value = value, !(value is NSNull) else { return "" }
        if let string = value as? String { return string }
        if let data = value as? Data { return String(data: data, encoding: .utf8) ?? "" }
        if let url = value as? URL { return url.absoluteString }
        if let object = value as? NSObject { return object.description }
        if let clazz = value as? AnyClass { return NSStringFromClass(clazz) }
        if let proto = value as? Protocol { return NSStringFromProtocol(proto) }
        return String(describing: value)
    }
    
    /// 转换为UTF8数据
    public var fw_utf8Data: Data? {
        return self.data(using: .utf8)
    }
    
    /// 转换为URL
    public var fw_url: URL? {
        return URL.fw_url(string: self)
    }
    
    /// 转换为文件URL
    public var fw_fileURL: URL {
        return URL(fileURLWithPath: self)
    }
    
    /// 转换为NSNumber
    public var fw_number: NSNumber? {
        let boolNumbers = ["true": true, "false": false, "yes": true, "no": false]
        let nilNumbers = ["nil", "null", "(null)", "<null>"]
        let lowerStr = self.lowercased()
        if let value = boolNumbers[lowerStr] { return NSNumber(value: value) }
        if nilNumbers.contains(lowerStr) { return nil }
        
        guard let cstring = self.cString(using: .utf8) else { return nil }
        if self.rangeOfCharacter(from: CharacterSet(charactersIn: ".")) != nil {
            let cnumber = atof(cstring)
            if cnumber.isNaN || cnumber.isInfinite { return nil }
            return NSNumber(value: cnumber)
        } else {
            return NSNumber(value: atoll(cstring))
        }
    }
}

@_spi(FW) extension NSNumber {
    /// 安全数字，不为nil
    public static func fw_safeNumber(_ value: Any?) -> NSNumber {
        guard let value = value else { return NSNumber(value: 0) }
        if let number = value as? NSNumber { return number }
        return String.fw_safeString(value).fw_number ?? NSNumber(value: 0)
    }
}

@_spi(FW) extension URL {
    /// 安全URL，不为nil，不兼容文件路径(需fileURLWithPath)
    public static func fw_safeURL(_ value: Any?) -> URL {
        guard let value = value else { return NSURL() as URL }
        if let url = value as? URL { return url }
        if let url = URL.fw_url(string: String.fw_safeString(value)) { return url }
        return NSURL() as URL
    }
    
    /// 生成URL，中文自动URL编码
    public static func fw_url(string: String?) -> URL? {
        guard let string = string else { return nil }
        if let url = URL(string: string) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString)
    }
    
    /// 生成URL，中文自动URL编码，支持基准URL
    public static func fw_url(string: String?, relativeTo baseURL: URL?) -> URL? {
        guard let string = string else { return nil }
        if let url = URL(string: string, relativeTo: baseURL) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString, relativeTo: baseURL)
    }
}

/// 可选类安全转换，不为nil
extension Optional {
    public var safeInt: Int { return safeNumber.intValue }
    public var safeBool: Bool { return safeNumber.boolValue }
    public var safeFloat: Float { return safeNumber.floatValue }
    public var safeDouble: Double { return safeNumber.doubleValue }
    public var safeString: String { return String.fw_safeString(self) }
    public var safeNumber: NSNumber { return NSNumber.fw_safeNumber(self) }
    public var safeArray: [Any] { return (self as? [Any]) ?? [] }
    public var safeDictionary: [AnyHashable: Any] { return (self as? [AnyHashable: Any]) ?? [:] }
    
    public var isNil: Bool { return self == nil }
    public static func isNil(_ value: Wrapped?) -> Bool {
        return value == nil || value._plainValue() == nil
    }
    public func then<T>(_ block: (Wrapped) throws -> T?) rethrows -> T? {
        guard let this = self else { return nil }
        return try block(this)
    }
}

// MARK: - AnyCodableType
public protocol AnyCodableType {
    init()
}

public protocol BasicCodableType: AnyCodableType {
    var isNotEmpty: Bool { get }
}

extension BasicCodableType where Self: Equatable {
    public var isNotEmpty: Bool { return self != .init() }
}

extension Optional where Wrapped: AnyCodableType {
    public var safeValue: Wrapped { if let value = self { return value } else { return .init() } }
}
extension Optional where Wrapped: BasicCodableType {
    public var isNotEmpty: Bool { if let value = self { return value.isNotEmpty } else { return false } }
}

// MARK: - AnyCodableType+Extension
extension Int: BasicCodableType {}
extension Int8: BasicCodableType {}
extension Int16: BasicCodableType {}
extension Int32: BasicCodableType {}
extension Int64: BasicCodableType {}
extension UInt: BasicCodableType {}
extension UInt8: BasicCodableType {}
extension UInt16: BasicCodableType {}
extension UInt32: BasicCodableType {}
extension UInt64: BasicCodableType {}
extension Bool: BasicCodableType {}
extension Float: BasicCodableType {
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension Double: BasicCodableType {
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension URL: BasicCodableType {
    public init() {
        self.init(string: " ")!
        self = NSURL() as URL
    }
}
extension Data: BasicCodableType {}
extension String: BasicCodableType {}
extension Array: BasicCodableType {
    public var isNotEmpty: Bool { return !isEmpty }
    public func safeElement(_ index: Int) -> Element? {
        return index >= 0 && index < endIndex ? self[index] : nil
    }
    public subscript(safe index: Int) -> Element? {
        return safeElement(index)
    }
    public mutating func safeSwap(from index: Index, to otherIndex: Index) {
        guard index != otherIndex else { return }
        guard startIndex..<endIndex ~= index else { return }
        guard startIndex..<endIndex ~= otherIndex else { return }
        swapAt(index, otherIndex)
    }
}
extension Array where Element: Equatable {
    @discardableResult
    public mutating func removeAll(_ item: Element) -> [Element] {
        removeAll(where: { $0 == item })
        return self
    }
    @discardableResult
    public mutating func removeAll(_ items: [Element]) -> [Element] {
        guard !items.isEmpty else { return self }
        removeAll(where: { items.contains($0) })
        return self
    }
}
extension Set: BasicCodableType {}
extension Dictionary: BasicCodableType {
    public var isNotEmpty: Bool { return !isEmpty }
    public func has(key: Key) -> Bool {
        return index(forKey: key) != nil
    }
    public mutating func removeAll<S: Sequence>(keys: S) where S.Element == Key {
        keys.forEach { removeValue(forKey: $0) }
    }
}
extension CGFloat: BasicCodableType {
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension CGPoint: BasicCodableType {
    public var isValid: Bool { return x.isValid && y.isValid }
}
extension CGSize: BasicCodableType {
    public var isValid: Bool { return width.isValid && height.isValid }
}
extension CGRect: BasicCodableType {
    public var isValid: Bool { return !isNull && !isInfinite && origin.isValid && size.isValid }
}

// MARK: - AnyParameter
public protocol AnyParameter {}

public protocol DataParameter: AnyParameter {
    var dataValue: Data { get }
}

public protocol StringParameter: AnyParameter {
    var stringValue: String { get }
}

public protocol AttributedStringParameter: AnyParameter {
    var attributedStringValue: NSAttributedString { get }
}

public protocol URLParameter: AnyParameter {
    var urlValue: URL { get }
}

public protocol URLRequestParameter: AnyParameter {
    var urlRequestValue: URLRequest { get }
}

public protocol ArrayParameter<E>: AnyParameter {
    associatedtype E
    var arrayValue: Array<E> { get }
}

public protocol DictionaryParameter<K, V>: AnyParameter where K: Hashable {
    associatedtype K
    associatedtype V
    var dictionaryValue: Dictionary<K, V> { get }
}

public protocol ObjectParameter: DictionaryParameter {
    init(dictionaryValue: [AnyHashable: Any])
}

// MARK: - AnyParameter+Extension
extension Data: DataParameter, StringParameter {
    public var dataValue: Data { self }
    public var stringValue: String { String(data: self, encoding: .utf8) ?? .init() }
}

extension String: StringParameter, AttributedStringParameter, DataParameter, URLParameter, URLRequestParameter {
    public var stringValue: String { self }
    public var attributedStringValue: NSAttributedString { NSAttributedString(string: self) }
    public var dataValue: Data { data(using: .utf8) ?? .init() }
    public var urlValue: URL { URL.fw_url(string: self) ?? NSURL() as URL }
    public var urlRequestValue: URLRequest { URLRequest(url: urlValue) }
}

extension NSAttributedString: AttributedStringParameter, StringParameter {
    public var attributedStringValue: NSAttributedString { self }
    public var stringValue: String { string }
}

extension URL: URLParameter, StringParameter, URLRequestParameter {
    public var urlValue: URL { self }
    public var stringValue: String { absoluteString }
    public var urlRequestValue: URLRequest { URLRequest(url: self) }
}

extension URLRequest: URLRequestParameter, URLParameter, StringParameter {
    public var urlRequestValue: URLRequest { self }
    public var urlValue: URL { url ?? NSURL() as URL }
    public var stringValue: String { url?.absoluteString ?? .init() }
}

extension Array: ArrayParameter {
    public var arrayValue: Array<Element> { self }
}

extension Dictionary: DictionaryParameter {
    public var dictionaryValue: Dictionary<Key, Value> { self }
}

extension ObjectParameter {
    public var dictionaryValue: [AnyHashable: Any] {
        NSObject.fw_mirrorDictionary(self)
    }
}

extension ObjectParameter where Self: JSONModel {
    public init(dictionaryValue: [AnyHashable: Any]) {
        self.init()
        merge(from: dictionaryValue)
    }
}
