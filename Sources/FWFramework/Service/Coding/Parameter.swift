//
//  Parameter.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal+SafeValue
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
    
}

// MARK: - WrapperGlobal+SafeType
extension WrapperGlobal {
    /// 获取安全值
    public static func safeValue<T: SafeType>(_ value: T?) -> T {
        return value.safeValue
    }

    /// 判断是否为空
    public static func isEmpty<T: SafeType>(_ value: T?) -> Bool {
        return value.isEmpty
    }
    
    /// 判断是否为none，兼容嵌套Optional
    public static func isNone(_ value: Any?) -> Bool {
        return Optional<Any>.isNone(value)
    }
}

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

// MARK: - SafeValue
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
    public var safeJSON: JSON { return JSON(self) }
    
    public static func isNone(_ value: Wrapped?) -> Bool {
        return value == nil || value._plainValue() == nil
    }
    public var isSome: Bool { return self != nil }
    public var isNone: Bool { return !isSome }
    @discardableResult
    public func onSome(_ block: (Wrapped) -> Void) -> Self {
        if let this = self { block(this) }
        return self
    }
    @discardableResult
    public func onNone(_ block: () -> Void) -> Self {
        if isNone { block() }
        return self
    }
    public func or(_ defaultValue: @autoclosure () -> Wrapped) -> Wrapped {
        return self ?? defaultValue()
    }
    public func then<T>(_ optional: @autoclosure () -> T?) -> T? {
        guard self != nil else { return nil }
        return optional()
    }
    public func then<T>(_ block: (Wrapped) throws -> T?) rethrows -> T? {
        guard let this = self else { return nil }
        return try block(this)
    }
    public func filter(_ condition: (Wrapped) -> Bool) -> Self {
        return map(condition) == .some(true) ? self : .none
    }
}

// MARK: - SafeType
public protocol SafeType: SafeCodableModel {
    static var safeValue: Self { get }
    var isEmpty: Bool { get }
    init()
}

extension SafeType {
    public var isNotEmpty: Bool { return !self.isEmpty }
}

extension Optional where Wrapped: SafeType {
    public static var safeValue: Wrapped { return .safeValue }
    public var isEmpty: Bool { if let value = self { return value.isEmpty } else { return true } }
    public var isNotEmpty: Bool { if let value = self { return !value.isEmpty } else { return false } }
    public var safeValue: Wrapped { if let value = self { return value } else { return .safeValue } }
}

extension Int: SafeType {
    public static var safeValue: Int = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int8: SafeType {
    public static var safeValue: Int8 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int16: SafeType {
    public static var safeValue: Int16 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int32: SafeType {
    public static var safeValue: Int32 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int64: SafeType {
    public static var safeValue: Int64 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt: SafeType {
    public static var safeValue: UInt = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt8: SafeType {
    public static var safeValue: UInt8 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt16: SafeType {
    public static var safeValue: UInt16 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt32: SafeType {
    public static var safeValue: UInt32 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt64: SafeType {
    public static var safeValue: UInt64 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Float: SafeType {
    public static var safeValue: Float = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension Double: SafeType {
    public static var safeValue: Double = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension Bool: SafeType {
    public static var safeValue: Bool = false
    public var isEmpty: Bool { return self == .safeValue }
}
extension URL: SafeType {
    public static var safeValue: URL = NSURL() as URL
    public var isEmpty: Bool { return absoluteString.isEmpty }
    public init() {
        self.init(string: " ")!
        self = NSURL() as URL
    }
}
extension Data: SafeType {
    public static var safeValue: Data = Data()
}
extension String: SafeType {
    public static var safeValue: String = ""
}
extension Array: SafeType {
    public static var safeValue: Array<Element> { return [] }
    public func safeElement(_ index: Int) -> Element? {
        return index >= 0 && index < endIndex ? self[index] : nil
    }
    public subscript(safe index: Int) -> Element? {
        return safeElement(index)
    }
}
extension Array {
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
extension Set: SafeType {
    public static var safeValue: Set<Element> { return [] }
}
extension Dictionary: SafeType {
    public static var safeValue: Dictionary<Key, Value> { return [:] }
}
extension Dictionary {
    public func has(key: Key) -> Bool {
        return index(forKey: key) != nil
    }
    public mutating func removeAll<S: Sequence>(keys: S) where S.Element == Key {
        keys.forEach { removeValue(forKey: $0) }
    }
}
extension CGFloat: SafeType {
    public static var safeValue: CGFloat = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return !isNaN && !isInfinite }
}
extension CGPoint: SafeType {
    public static var safeValue: CGPoint = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return x.isValid && y.isValid }
}
extension CGSize: SafeType {
    public static var safeValue: CGSize = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return width.isValid && height.isValid }
}
extension CGRect: SafeType {
    public static var safeValue: CGRect = .zero
    public var isEmpty: Bool { return self == .safeValue }
    public var isValid: Bool { return !isNull && !isInfinite && origin.isValid && size.isValid }
}

// MARK: - DataParameter
public protocol DataParameter {
    var dataValue: Data { get }
}

extension Data: DataParameter, StringParameter {
    public var dataValue: Data { self }
    public var stringValue: String { String(data: self, encoding: .utf8) ?? .init() }
}

// MARK: - StringParameter
public protocol StringParameter {
    var stringValue: String { get }
}

extension String: StringParameter, DataParameter, URLParameter, URLRequestParameter {
    public var stringValue: String { self }
    public var dataValue: Data { data(using: .utf8) ?? .init() }
    public var urlValue: URL { URL.fw_url(string: self) ?? NSURL() as URL }
    public var urlRequestValue: URLRequest { URLRequest(url: urlValue) }
}

// MARK: - URLParameter
public protocol URLParameter {
    var urlValue: URL { get }
}

extension URL: URLParameter, StringParameter, URLRequestParameter {
    public var urlValue: URL { self }
    public var stringValue: String { absoluteString }
    public var urlRequestValue: URLRequest { URLRequest(url: self) }
}

// MARK: - URLRequestParameter
public protocol URLRequestParameter {
    var urlRequestValue: URLRequest { get }
}

extension URLRequest: URLRequestParameter, URLParameter, StringParameter {
    public var urlRequestValue: URLRequest { self }
    public var urlValue: URL { url ?? NSURL() as URL }
    public var stringValue: String { url?.absoluteString ?? .init() }
}

// MARK: - ArrayParameter
public protocol ArrayParameter<E> {
    associatedtype E
    var arrayValue: Array<E> { get }
}

extension Array: ArrayParameter {
    public var arrayValue: Array<Element> { self }
}

// MARK: - DictionaryParameter
public protocol DictionaryParameter<K, V> where K: Hashable {
    associatedtype K
    associatedtype V
    var dictionaryValue: Dictionary<K, V> { get }
}

extension Dictionary: DictionaryParameter {
    public var dictionaryValue: Dictionary<Key, Value> { self }
}

// MARK: - ParameterProtocol
public protocol ParameterProtocol: DictionaryParameter {
    static func fromDictionary(_ dict: [AnyHashable: Any]) -> Self
}

extension ParameterProtocol {
    public var dictionaryValue: [AnyHashable: Any] {
        NSObject.fw_mirrorDictionary(self)
    }
}

extension ParameterProtocol where Self: JSONModel {
    public static func fromDictionary(_ dict: [AnyHashable: Any]) -> Self {
        return safeDeserialize(from: dict)
    }
}
