//
//  Stdlib.swift
//  FWFramework
//
//  Created by wuyong on 2024/4/15.
//

import Foundation

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 安全字符串，不为nil
    public static func safeString(_ value: Any?) -> String {
        String.fw.safeString(value)
    }

    /// 安全数字，不为nil
    public static func safeNumber(_ value: Any?) -> NSNumber {
        NSNumber.fw.safeNumber(value)
    }

    /// 安全Int，不为nil
    public static func safeInt(_ value: Any?) -> Int {
        NSNumber.fw.safeNumber(value).intValue
    }

    /// 安全Bool，不为nil
    public static func safeBool(_ value: Any?) -> Bool {
        NSNumber.fw.safeNumber(value).boolValue
    }

    /// 安全Float，不为nil
    public static func safeFloat(_ value: Any?) -> Float {
        NSNumber.fw.safeNumber(value).floatValue
    }

    /// 安全Double，不为nil
    public static func safeDouble(_ value: Any?) -> Double {
        NSNumber.fw.safeNumber(value).doubleValue
    }

    /// 安全URL，不为nil，不兼容文件路径(需fileURLWithPath)
    public static func safeURL(_ value: Any?) -> URL {
        URL.fw.safeURL(value)
    }

    /// 获取安全值
    public static func safeValue<T: BasicType>(_ value: T?) -> T {
        value.safeValue
    }

    /// 判断是否不为空
    public static func isNotEmpty<T: BasicType>(_ value: T?) -> Bool {
        value.isNotEmpty
    }

    /// 判断是否为nil，兼容嵌套Optional
    public static func isNil(_ value: Any?) -> Bool {
        Optional<Any>.isNil(value)
    }
}

// MARK: - Wrapper
/// 包装器安全转换，不为nil
extension Wrapper {
    public var safeInt: Int { safeNumber.intValue }
    public var safeBool: Bool { safeNumber.boolValue }
    public var safeFloat: Float { safeNumber.floatValue }
    public var safeDouble: Double { safeNumber.doubleValue }
    public var safeString: String { String.fw.safeString(base) }
    public var safeNumber: NSNumber { NSNumber.fw.safeNumber(base) }
    public var safeArray: [Any] { (base as? [Any]) ?? [] }
    public var safeDictionary: [AnyHashable: Any] { (base as? [AnyHashable: Any]) ?? [:] }
}

// MARK: - Wrapper+Data
extension Wrapper where Base == Data {
    /// 转换为UTF8字符串
    public var utf8String: String? { String(data: base, encoding: .utf8) }
    /// 转换为UInt8数组
    public var uint8Array: Array<UInt8> { Array(base) }
    /// 转换为bytes内容指针
    public var bytesPointer: UnsafeRawPointer { (base as NSData).bytes }
    /// 返回bytes内容的长度
    public var bytesLength: Int { (base as NSData).length }
}

// MARK: - Wrapper+String
extension Wrapper where Base == String {
    /// 安全字符串，不为nil
    public static func safeString(_ value: Any?) -> String {
        guard let value, !(value is NSNull) else { return "" }
        if let string = value as? String { return string }
        if let data = value as? Data { return String(data: data, encoding: .utf8) ?? "" }
        if let url = value as? URL { return url.absoluteString }
        if let object = value as? NSObject { return object.description }
        if let clazz = value as? AnyClass { return NSStringFromClass(clazz) }
        if let proto = value as? Protocol { return NSStringFromProtocol(proto) }
        if let type = value as? Any.Type { return String(describing: type as AnyObject) }
        return String(describing: value)
    }

    /// 去掉首尾空白字符
    public var trimString: String {
        base.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 首字母大写
    public var ucfirstString: String {
        String(base.prefix(1).uppercased() + base.dropFirst())
    }

    /// 首字母小写
    public var lcfirstString: String {
        String(base.prefix(1).lowercased() + base.dropFirst())
    }

    /// 驼峰转下划线
    public var underlineString: String {
        guard base.count > 0 else { return base }
        var result = ""
        let str = base as NSString
        for i in 0..<str.length {
            let cString = String(format: "%c", str.character(at: i))
            let cStringLower = cString.lowercased()
            if cString == cStringLower {
                result.append(contentsOf: cStringLower)
            } else {
                result.append(contentsOf: "_")
                result.append(contentsOf: cStringLower)
            }
        }
        return result
    }

    /// 下划线转驼峰
    public var camelString: String {
        guard base.count > 0 else { return base }
        var result = ""
        let comps = base.components(separatedBy: "_")
        for i in 0..<comps.count {
            let comp = comps[i] as NSString
            if i > 0 && comp.length > 0 {
                result.append(String(format: "%c", comp.character(at: 0)).uppercased())
                if comp.length > 1 {
                    result.append(comp.substring(from: 1))
                }
            } else {
                result.append(comp as String)
            }
        }
        return result
    }

    /// 转换为UTF8数据
    public var utf8Data: Data? {
        base.data(using: .utf8)
    }

    /// 转换为URL
    public var url: URL? {
        URL.fw.url(string: base)
    }

    /// 转换为文件URL
    public var fileURL: URL {
        URL(fileURLWithPath: base)
    }

    /// 转换为NSNumber
    public var number: NSNumber? {
        let boolNumbers = ["true": true, "false": false, "yes": true, "no": false]
        let nilNumbers = ["nil", "null", "(null)", "<null>"]
        let lowerStr = base.lowercased()
        if let value = boolNumbers[lowerStr] { return NSNumber(value: value) }
        if nilNumbers.contains(lowerStr) { return nil }

        guard let cstring = base.cString(using: .utf8) else { return nil }
        if base.rangeOfCharacter(from: CharacterSet(charactersIn: ".")) != nil {
            let cnumber = atof(cstring)
            if cnumber.isNaN || cnumber.isInfinite { return nil }
            return NSNumber(value: cnumber)
        } else {
            return NSNumber(value: atoll(cstring))
        }
    }

    /// 计算长度，中文为1，英文为0.5，表情为2
    public var unicodeLength: Int {
        var length = 0
        let str = base as NSString
        for i in 0..<str.length {
            length += str.character(at: i) > 0xFF ? 2 : 1
        }
        return Int(ceil(Double(length) / 2.0))
    }

    /// 截取字符串，中文为1，英文为0.5，表情为2
    public func unicodeSubstring(_ length: Int) -> String {
        let length = length * 2
        let str = base as NSString

        var i = 0
        var len = 0
        while i < str.length {
            len += str.character(at: i) > 0xFF ? 2 : 1
            i += 1
            if i >= str.length { return base }

            if len == length {
                return str.substring(to: i)
            } else if len > length {
                if i - 1 <= 0 { return "" }
                return str.substring(to: i - 1)
            }
        }
        return base
    }

    /// 从指定位置截取子串
    public func substring(from index: Int) -> String {
        substring(with: min(index, base.count)..<base.count)
    }

    /// 截取子串到指定位置
    public func substring(to index: Int) -> String {
        substring(with: 0..<max(0, index))
    }

    /// 截取指定范围的子串
    public func substring(with range: NSRange) -> String {
        guard let range = Range<Int>(range) else { return "" }
        return substring(with: range)
    }

    /// 截取指定范围的子串
    public func substring(with range: Range<Int>) -> String {
        guard range.lowerBound >= 0, range.upperBound >= range.lowerBound else { return "" }
        let range = Range(uncheckedBounds: (lower: max(0, min(range.lowerBound, base.count)), upper: max(0, min(range.upperBound, base.count))))
        let start = base.index(base.startIndex, offsetBy: range.lowerBound)
        let end = base.index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(base[start..<end])
    }
}

// MARK: - Wrapper+NSNumber
extension Wrapper where Base: NSNumber {
    /// 安全数字，不为nil
    public static func safeNumber(_ value: Any?) -> NSNumber {
        guard let value else { return NSNumber(value: 0) }
        if let number = value as? NSNumber { return number }
        return String.fw.safeString(value).fw.number ?? NSNumber(value: 0)
    }

    /// 安全Int，不为nil
    public static func safeInt(_ value: Any?) -> Int {
        safeNumber(value).intValue
    }

    /// 安全Bool，不为nil
    public static func safeBool(_ value: Any?) -> Bool {
        safeNumber(value).boolValue
    }

    /// 安全Float，不为nil
    public static func safeFloat(_ value: Any?) -> Float {
        safeNumber(value).floatValue
    }

    /// 安全Double，不为nil
    public static func safeDouble(_ value: Any?) -> Double {
        safeNumber(value).doubleValue
    }
}

// MARK: - Wrapper+URL
extension Wrapper where Base == URL {
    /// 安全URL，不为nil，不兼容文件路径(需fileURLWithPath)
    public static func safeURL(_ value: Any?) -> URL {
        guard let value else { return URL() }
        if let url = value as? URL { return url }
        if let url = url(string: String.fw.safeString(value)) { return url }
        return URL()
    }

    /// 生成URL，中文自动URL编码
    public static func url(string: String?) -> URL? {
        guard let string else { return nil }
        if let url = URL(string: string) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString)
    }

    /// 生成URL，中文自动URL编码，支持基准URL
    public static func url(string: String?, relativeTo baseURL: URL?) -> URL? {
        guard let string else { return nil }
        if let url = URL(string: string, relativeTo: baseURL) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString, relativeTo: baseURL)
    }
}

// MARK: - Optional+Extension
/// 可选类安全转换，不为nil
extension Optional {
    public var safeInt: Int { safeNumber.intValue }
    public var safeBool: Bool { safeNumber.boolValue }
    public var safeFloat: Float { safeNumber.floatValue }
    public var safeDouble: Double { safeNumber.doubleValue }
    public var safeString: String { String.fw.safeString(self) }
    public var safeNumber: NSNumber { NSNumber.fw.safeNumber(self) }
    public var safeArray: [Any] { (self as? [Any]) ?? [] }
    public var safeDictionary: [AnyHashable: Any] { (self as? [AnyHashable: Any]) ?? [:] }

    public var int: Int? { number?.intValue }
    public var bool: Bool? { number?.boolValue }
    public var float: Float? { number?.floatValue }
    public var double: Double? { number?.doubleValue }
    public var string: String? {
        guard let value = self else { return nil }
        return String.fw.safeString(value)
    }

    public var number: NSNumber? {
        guard let value = self else { return nil }
        return NSNumber.fw.safeNumber(value)
    }

    public var array: [Any]? { self as? [Any] }
    public var dictionary: [AnyHashable: Any]? { self as? [AnyHashable: Any] }

    public var isNil: Bool { Optional<Any>.isNil(self) }
    public static func isNil(_ value: Wrapped?) -> Bool {
        if let value { return deepUnwrap(value) == nil }
        return true
    }

    public static func isOptional(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional
    }

    public static func deepUnwrap(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle != .optional {
            return value
        }
        if let child = mirror.children.first {
            return deepUnwrap(child.value)
        }
        return nil
    }

    public func then<T>(_ block: (Wrapped) throws -> T?) rethrows -> T? {
        guard let value = self else { return nil }
        return try block(value)
    }

    public func filter(_ predicate: (Wrapped) -> Bool) -> Wrapped? {
        guard let value = self, predicate(value) else { return nil }
        return value
    }

    public func or(_ defaultValue: @autoclosure () -> Wrapped) -> Wrapped {
        guard let value = self else { return defaultValue() }
        return value
    }

    public func or(_ defaultValue: @autoclosure () -> Wrapped, _ block: (Wrapped) -> Wrapped) -> Wrapped {
        guard let value = self else { return defaultValue() }
        return block(value)
    }
}

// MARK: - ObjectType
public protocol ObjectType {
    init()
}

public protocol BasicType: ObjectType {
    var isNotEmpty: Bool { get }
}

extension BasicType where Self: Equatable {
    public var isNotEmpty: Bool { self != .init() }
}

extension Optional where Wrapped: ObjectType {
    public var safeValue: Wrapped { if let value = self { return value } else { return .init() } }
}

extension Optional where Wrapped: BasicType {
    public var isNotEmpty: Bool { if let value = self { return value.isNotEmpty } else { return false } }
}

// MARK: - ObjectType+Extension
extension Int: BasicType {}
extension Int8: BasicType {}
extension Int16: BasicType {}
extension Int32: BasicType {}
extension Int64: BasicType {}
extension UInt: BasicType {}
extension UInt8: BasicType {}
extension UInt16: BasicType {}
extension UInt32: BasicType {}
extension UInt64: BasicType {}
extension Bool: BasicType {}
extension Float: BasicType {
    public var isValid: Bool { !isNaN && !isInfinite }
}

extension Double: BasicType {
    public var isValid: Bool { !isNaN && !isInfinite }
}

extension URL: BasicType {
    public init() { self = (NSURL(string: "") ?? NSURL()) as URL }
}

extension Data: BasicType {}
extension Date: BasicType {}
extension String: BasicType {}
extension Array: BasicType {
    public var isNotEmpty: Bool { !isEmpty }
    public func safeElement(_ index: Int) -> Element? {
        index >= 0 && index < endIndex ? self[index] : nil
    }

    public subscript(safe index: Int) -> Element? {
        safeElement(index)
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

extension Set: BasicType {}
extension Dictionary: BasicType {
    public var isNotEmpty: Bool { !isEmpty }
    public func has(key: Key) -> Bool {
        index(forKey: key) != nil
    }

    public mutating func removeAll<S: Sequence>(keys: S) where S.Element == Key {
        keys.forEach { removeValue(forKey: $0) }
    }
}

extension Decimal: BasicType {
    public var isValid: Bool { !isNaN && !isInfinite }
}

extension CGFloat: BasicType {
    public var isValid: Bool { !isNaN && !isInfinite }
    public var isNotEmpty: Bool { self != .zero }
}

extension CGPoint {
    public var isValid: Bool { x.isValid && y.isValid }
    public var isNotEmpty: Bool { self != .zero }
}

extension CGSize {
    public var isValid: Bool { width.isValid && height.isValid }
    public var isNotEmpty: Bool { self != .zero }
}

extension CGRect {
    public var isValid: Bool { !isNull && !isInfinite && origin.isValid && size.isValid }
    public var isNotEmpty: Bool { self != .zero }
}
