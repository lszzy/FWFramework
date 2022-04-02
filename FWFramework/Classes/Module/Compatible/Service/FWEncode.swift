//
//  FWEncode.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
import CommonCrypto
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - FWSafeBridge

extension FWWrapper where T == Data {
    /// json数据解码为Foundation对象
    public var jsonDecode: Any? {
        return (self.base as NSData).fw.jsonDecode
    }
    /// base64编码
    public var base64Encode: Data {
        return base.base64EncodedData()
    }
    /// base64解码
    public var base64Decode: Data? {
        return Data(base64Encoded: self.base, options: .ignoreUnknownCharacters)
    }
    /// 转换为UTF8字符串
    public var utf8String: String? {
        return String(data: self.base, encoding: .utf8)
    }
}

extension FWWrapper where T == Data.Type {
    /// Foundation对象编码为json数据
    public func jsonEncode(_ object: Any) -> Data? {
        return try? JSONSerialization.data(withJSONObject: object)
    }
}

extension FWWrapper where T == String {
    /// json字符串解码为Foundation对象
    public var jsonDecode: Any? {
        guard let data = base.data(using: .utf8) else { return nil }
        return data.fw.jsonDecode
    }
    /// base64编码
    public var base64Encode: String? {
        guard let data = base.data(using: .utf8) else { return nil }
        return String(data: data.base64EncodedData(), encoding: .utf8)
    }
    /// base64解码
    public var base64Decode: String? {
        guard let data = Data(base64Encoded: base, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    /// 计算长度，中文为1，英文为0.5，表情为2
    public var unicodeLength: UInt {
        return (self.base as NSString).fw.unicodeLength()
    }
    /// 截取字符串，中文为1，英文为0.5，表情为2
    public func unicodeSubstring(_ length: UInt) -> String {
        return (self.base as NSString).fw.unicodeSubstring(length)
    }
    /// Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
    public var unicodeEncode: String {
        return (self.base as NSString).fw.unicodeEncode()
    }
    /// Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
    public var unicodeDecode: String {
        return (self.base as NSString).fw.unicodeDecode()
    }
    /// url参数编码，适用于query参数编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var urlEncodeComponent: String? {
        return base.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted)
    }
    /// url参数解码，适用于query参数解码
    ///
    /// 示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var urlDecodeComponent: String? {
        return CFURLCreateStringByReplacingPercentEscapes(nil, self.base as CFString, "" as CFString) as String?
    }
    /// url编码，适用于整个url编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var urlEncode: String? {
        return base.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    /// url解码，适用于整个url解码
    ///
    /// 示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var urlDecode: String? {
        return base.removingPercentEncoding
    }
    /// URL参数字符串解码为字典，支持完整URL
    public var queryDecode: [String: String] {
        return (self.base as NSString).fw.queryDecode()
    }
    /// md5编码
    public var md5Encode: String {
        let utf8 = base.cString(using: .utf8)
        let length = CC_LONG(base.lengthOfBytes(using: .utf8))
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, length, &digest)
        return digest.reduce("") { $0 + String(format: "%02x", $1) }
    }
    /// 文件md5编码
    public var md5EncodeFile: String? {
        guard let file = FileHandle(forReadingAtPath: self.base) else { return nil }
        defer { file.closeFile() }
        
        var ctx = CC_MD5_CTX()
        CC_MD5_Init(&ctx)
        while case let data = file.readData(ofLength: 1024 * 64), data.count > 0 {
            _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                CC_MD5_Update(&ctx, bytes.baseAddress, CC_LONG(data.count))
            }
        }
        
        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digest.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            CC_MD5_Final(bytes.bindMemory(to: UInt8.self).baseAddress, &ctx)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    /// 去掉首尾空白字符
    public var trimString: String {
        return base.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// 过滤JSON解码特殊字符
    ///
    /// 兼容\uD800-\uDFFF引起JSON解码报错3840问题，不报错时无需调用
    /// 规则：只允许以\uD800-\uDBFF高位开头，紧跟\uDC00-\uDFFF低位；其他全不允许
    /// 参考：https://github.com/SBJson/SBJson/blob/trunk/Classes/SBJson5StreamTokeniser.m
    public var escapeJson: String {
        return (self.base as NSString).fw.escapeJson
    }
    /// 转换为UTF8数据
    public var utf8Data: Data? {
        return self.base.data(using: .utf8)
    }
    /// 转换为URL
    public var url: URL? {
        return URL.fw.url(string: self.base)
    }
    /// 转换为NSNumber
    public var number: NSNumber? {
        return (self.base as NSString).fw.number
    }
    /// 从指定位置截取子串
    public func substring(from index: Int) -> String {
        return (self.base as NSString).fw.substring(from: index) ?? ""
    }
    /// 截取子串到指定位置
    public func substring(to index: Int) -> String {
        return (self.base as NSString).fw.substring(to: index) ?? ""
    }
    /// 截取指定范围的子串
    public func substring(with range: NSRange) -> String {
        return (self.base as NSString).fw.substring(with: range) ?? ""
    }
    /// 截取指定范围的子串
    public func substring(with range: Range<Int>) -> String {
        return substring(with: NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound))
    }
}

extension FWWrapper where T == String.Type {
    /// Foundation对象编码为json字符串
    public func jsonEncode(_ object: Any) -> String? {
        guard let data = Data.fw.jsonEncode(object) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    /// 字典编码为URL参数字符串
    public func queryEncode(_ dict: [String: Any]) -> String {
        return NSString.fw.queryEncode(dict)
    }
}

extension FWWrapper where T == URL {
    /// 获取当前query的参数字典，不含空值
    public var queryDictionary: [String: String] {
        var components = URLComponents(string: base.absoluteString)
        if components == nil, let string = base.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            components = URLComponents(string: string)
        }
        var result: [String: String] = [:]
        // queryItems.value会自动进行URL参数解码
        let queryItems = components?.queryItems ?? []
        for item in queryItems {
            result[item.name] = item.value
        }
        return result
    }
    /// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
    public var pathURI: String? {
        let string = base.absoluteString
        guard let components = URLComponents(string: string),
              let range = components.rangeOfPath else { return nil }
        return String(string[range])
    }
}

extension FWWrapper where T == URL.Type {
    /// 生成URL，中文自动URL编码
    public func url(string: String?) -> URL? {
        guard let string = string else { return nil }
        if let url = URL(string: string) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString)
    }
    /// 生成URL，中文自动URL编码，支持基准URL
    public func url(string: String?, relativeTo baseURL: URL?) -> URL? {
        guard let string = string else { return nil }
        if let url = URL(string: string, relativeTo: baseURL) { return url }
        // 如果生成失败，自动URL编码再试
        guard let encodeString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encodeString, relativeTo: baseURL)
    }
}

// MARK: - FWSafeUnwrappable

/// 获取安全值
public func FWSafeValue<T: FWSafeUnwrappable>(_ value: T?) -> T {
    return value.safeValue
}

/// 判断是否为空
public func FWIsEmpty<T: FWSafeUnwrappable>(_ value: T?) -> Bool {
    return value.isEmpty
}

/// 判断是否为nil
public func FWIsNil(_ value: Any?) -> Bool {
    return value.isNil
}

public protocol FWSafeUnwrappable {
    static var safeValue: Self { get }
    var isEmpty: Bool { get }
}

extension FWSafeUnwrappable {
    public var asInt: Int { return asNumber.intValue }
    public var asBool: Bool { return asNumber.boolValue }
    public var asFloat: Float { return asNumber.floatValue }
    public var asDouble: Double { return asNumber.doubleValue }
    public var asString: String { return FWSafeString(self) }
    public var asNumber: NSNumber { return FWSafeNumber(self) }
    public var asArray: [Any] { return (self as? [Any]) ?? .safeValue }
    public var asDicationary: [AnyHashable: Any] { return (self as? [AnyHashable: Any]) ?? .safeValue }
}

extension Optional where Wrapped: FWSafeUnwrappable {
    public var safeValue: Wrapped { if let value = self { return value } else { return .safeValue } }
    public var isEmpty: Bool { if let value = self { return value.isEmpty } else { return true } }
}

extension Optional {
    public var isNil: Bool { return self == nil }
    
    public var asInt: Int { return asNumber.intValue }
    public var asBool: Bool { return asNumber.boolValue }
    public var asFloat: Float { return asNumber.floatValue }
    public var asDouble: Double { return asNumber.doubleValue }
    public var asString: String { return FWSafeString(self) }
    public var asNumber: NSNumber { return FWSafeNumber(self) }
    public var asArray: [Any] { return (self as? [Any]) ?? .safeValue }
    public var asDicationary: [AnyHashable: Any] { return (self as? [AnyHashable: Any]) ?? .safeValue }
}

extension Int: FWSafeUnwrappable {
    public static var safeValue: Int = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int8: FWSafeUnwrappable {
    public static var safeValue: Int8 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int16: FWSafeUnwrappable {
    public static var safeValue: Int16 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int32: FWSafeUnwrappable {
    public static var safeValue: Int32 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Int64: FWSafeUnwrappable {
    public static var safeValue: Int64 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt: FWSafeUnwrappable {
    public static var safeValue: UInt = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt8: FWSafeUnwrappable {
    public static var safeValue: UInt8 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt16: FWSafeUnwrappable {
    public static var safeValue: UInt16 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt32: FWSafeUnwrappable {
    public static var safeValue: UInt32 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension UInt64: FWSafeUnwrappable {
    public static var safeValue: UInt64 = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Float: FWSafeUnwrappable {
    public static var safeValue: Float = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Double: FWSafeUnwrappable {
    public static var safeValue: Double = .zero
    public var isEmpty: Bool { return self == .safeValue }
}
extension Bool: FWSafeUnwrappable {
    public static var safeValue: Bool = false
    public var isEmpty: Bool { return self == .safeValue }
}
extension String: FWSafeUnwrappable {
    public static var safeValue: String = ""
}
extension Array: FWSafeUnwrappable {
    public static var safeValue: Array<Element> { return [] }
}
extension Set: FWSafeUnwrappable {
    public static var safeValue: Set<Element> { return [] }
}
extension Dictionary: FWSafeUnwrappable {
    public static var safeValue: Dictionary<Key, Value> { return [:] }
}
