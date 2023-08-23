//
//  Encode.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import CommonCrypto

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

    /// 安全URL，不为nil
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

// MARK: - Encode
@_spi(FW) extension Data {
    /// Foundation对象编码为json数据
    public static func fw_jsonEncode(_ object: Any) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        return try? JSONSerialization.data(withJSONObject: object)
    }
    
    /// json数据解码为Foundation对象
    public var fw_jsonDecode: Any? {
        do {
            return try JSONSerialization.jsonObject(with: self, options: .allowFragments)
        } catch {
            guard (error as NSError).code == 3840 else { return nil }
            
            let string = String(data: self, encoding: .utf8)
            guard let data = string?.fw_escapeJson.data(using: .utf8) else { return nil }
            if data.count == self.count { return nil }
            return try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
    }
    
    /// base64编码
    public var fw_base64Encode: Data {
        return self.base64EncodedData()
    }
    
    /// base64解码
    public var fw_base64Decode: Data? {
        return Data(base64Encoded: self, options: .ignoreUnknownCharacters)
    }
    
    /// 转换为UTF8字符串
    public var fw_utf8String: String? {
        return String(data: self, encoding: .utf8)
    }
    
    /// 将对象归档为data数据
    public static func fw_archivedData(_ object: Any?) -> Data? {
        guard let object = object else { return nil }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        return data
    }
    
    /// 将数据解档为指定类型对象，推荐使用
    public func fw_unarchivedObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: self)
        return object
    }
    
    /// 将数据解档为对象
    public func fw_unarchivedObject() -> Any? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: self) else { return nil }
        unarchiver.requiresSecureCoding = false
        let object = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        return object
    }
    
    /// 将对象归档保存到文件
    @discardableResult
    public static func fw_archiveObject(_ object: Any, toFile path: String) -> Bool {
        guard let data = fw_archivedData(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
    
    /// 从文件解档指定类型对象，推荐使用
    public static func fw_unarchivedObject<T>(_ clazz: T.Type, withFile path: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw_unarchivedObject(clazz)
    }
    
    /// 从文件解档对象
    public static func fw_unarchivedObject(withFile path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw_unarchivedObject()
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
    
    /// Foundation对象编码为json字符串
    public static func fw_jsonEncode(_ object: Any) -> String? {
        guard let data = Data.fw_jsonEncode(object) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// json字符串解码为Foundation对象
    public var fw_jsonDecode: Any? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.fw_jsonDecode
    }
    
    /// base64编码
    public var fw_base64Encode: String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return String(data: data.base64EncodedData(), encoding: .utf8)
    }
    
    /// base64解码
    public var fw_base64Decode: String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        
        let remainder = self.count % 4
        guard remainder > 0 else { return nil }
        
        let padding = String(repeating: "=", count: 4 - remainder)
        guard let data = Data(base64Encoded: self + padding, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 计算长度，中文为1，英文为0.5，表情为2
    public var fw_unicodeLength: Int {
        var length: Int = 0
        let str = self as NSString
        for i in 0 ..< str.length {
            length += str.character(at: i) > 0xff ? 2 : 1
        }
        return Int(ceil(Double(length) / 2.0))
    }
    
    /// 截取字符串，中文为1，英文为0.5，表情为2
    public func fw_unicodeSubstring(_ length: Int) -> String {
        let length = length * 2
        let str = self as NSString
        
        var i: Int = 0
        var len: Int = 0
        while i < str.length {
            len += str.character(at: i) > 0xff ? 2 : 1
            i += 1
            if i >= str.length { return self }
            
            if len == length {
                return str.substring(to: i)
            } else if len > length {
                if i - 1 <= 0 { return "" }
                return str.substring(to: i - 1)
            }
        }
        return self
    }
    
    /// Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
    public var fw_unicodeEncode: String {
        var result = ""
        let str = self as NSString
        for i in 0 ..< str.length {
            let character = str.character(at: i)
            // 判断是否为英文或数字
            if (character >= 48 && character <= 57) ||
                (character >= 97 && character <= 122) ||
                (character >= 65 && character <= 90) {
                result.append(str.substring(with: NSMakeRange(i, 1)))
            } else {
                result.append(String(format: "\\u%.4x", character))
            }
        }
        return result
    }
    
    /// Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
    public var fw_unicodeDecode: String {
        var str = self.replacingOccurrences(of: "\\u", with: "\\U")
        str = str.replacingOccurrences(of: "\"", with: "\\\"")
        str = "\"".appending(str).appending("\"")
        guard let data = str.data(using: .utf8) else { return "" }
        
        guard let result = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? String else { return "" }
        return result.replacingOccurrences(of: "\\r\\n", with: "\n")
    }
    
    /// url参数编码，适用于query参数编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var fw_urlEncodeComponent: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted)
    }
    
    /// url参数解码，适用于query参数解码
    ///
    /// 示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var fw_urlDecodeComponent: String? {
        return CFURLCreateStringByReplacingPercentEscapes(nil, self as CFString, "" as CFString) as String?
    }
    
    /// url编码，适用于整个url编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var fw_urlEncode: String? {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    /// url解码，适用于整个url解码
    ///
    /// 示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var fw_urlDecode: String? {
        return self.removingPercentEncoding
    }
    
    /// 字典编码为URL参数字符串
    public static func fw_queryEncode(_ dict: [String: Any]) -> String {
        var result = ""
        for (key, value) in dict {
            if result.count > 0 { result.append("&") }
            let string = String.fw_safeString(value).addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted) ?? ""
            result.append("\(key)=\(string)")
        }
        return result
    }
    
    /// URL参数字符串解码为字典，支持完整URL
    public var fw_queryDecode: [String: String] {
        var result: [String: String] = [:]
        var queryString = self
        if let url = URL.fw_url(string: self), let scheme = url.scheme, scheme.count > 0 {
            queryString = url.query ?? ""
        }
        let parameters = queryString.components(separatedBy: "&")
        for parameter in parameters {
            let contents = parameter.components(separatedBy: "=")
            guard contents.count == 2 else { continue }
            result[contents[0]] = contents[1].removingPercentEncoding
        }
        return result
    }
    
    /// md5编码
    public var fw_md5Encode: String {
        let utf8 = self.cString(using: .utf8)
        let length = CC_LONG(self.lengthOfBytes(using: .utf8))
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(utf8, length, &digest)
        return digest.reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    /// 文件md5编码
    public var fw_md5EncodeFile: String? {
        guard let file = FileHandle(forReadingAtPath: self) else { return nil }
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
    public var fw_trimString: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 首字母大写
    public var fw_ucfirstString: String {
        return String(prefix(1).uppercased() + dropFirst())
    }
    
    /// 首字母小写
    public var fw_lcfirstString: String {
        return String(prefix(1).lowercased() + dropFirst())
    }
    
    /// 驼峰转下划线
    public var fw_underlineString: String {
        guard self.count > 0 else { return self }
        var result = ""
        let str = self as NSString
        for i in 0 ..< str.length {
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
    public var fw_camelString: String {
        guard self.count > 0 else { return self }
        var result = ""
        let comps = self.components(separatedBy: "_")
        for i in 0 ..< comps.count {
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
    
    /// 中文转拼音
    public var fw_pinyinString: String {
        if self.isEmpty { return self }
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        let pinyinStr = mutableString.folding(options: .diacriticInsensitive, locale: .current)
        return pinyinStr.lowercased()
    }
    
    /// 中文转拼音并进行比较
    public func fw_pinyinCompare(_ string: String) -> ComparisonResult {
        let pinyin1 = self.fw_pinyinString
        let pinyin2 = string.fw_pinyinString
        return pinyin1.compare(pinyin2)
    }
    
    /// 是否包含Emoji表情
    public var fw_containsEmoji: Bool {
        for scalar in self.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F,
                 0x1F300...0x1F5FF,
                 0x1F680...0x1F6FF,
                 0x1F1E6...0x1F1FF,
                 0x2600...0x26FF,
                 0x2700...0x27BF,
                 0xE0020...0xE007F,
                 0xFE00...0xFE0F,
                 0x1F900...0x1F9FF,
                 127_000...127_600,
                 65024...65039,
                 9100...9300,
                 8400...8447:
                return true
            default:
                continue
            }
        }
        return false
    }
    
    /// 过滤JSON解码特殊字符
    ///
    /// 兼容\uD800-\uDFFF引起JSON解码报错3840问题，不报错时无需调用
    /// 规则：只允许以\uD800-\uDBFF高位开头，紧跟\uDC00-\uDFFF低位；其他全不允许
    /// 参考：https://github.com/SBJson/SBJson/blob/trunk/Classes/SBJson5StreamTokeniser.m
    public var fw_escapeJson: String {
        guard let regex = try? NSRegularExpression(pattern: "(\\\\UD[8-F][0-F][0-F])(\\\\UD[8-F][0-F][0-F])?", options: .caseInsensitive) else { return self }
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count))
        if matches.count < 1 { return self }
        
        // 倒序循环，避免replace越界
        var string = self as NSString
        for i in (0 ..< matches.count).reversed() {
            let range = matches[i].range
            let substr = string.substring(with: range).uppercased() as NSString
            if range.length == 12 && substr.character(at: 3) <= 66 && substr.character(at: 9) > 66 { continue }
            string = string.replacingCharacters(in: range, with: "") as NSString
        }
        return string as String
    }
    
    /// 转换为UTF8数据
    public var fw_utf8Data: Data? {
        return self.data(using: .utf8)
    }
    
    /// 转换为URL
    public var fw_url: URL? {
        return URL.fw_url(string: self)
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
    
    /// 从指定位置截取子串
    public func fw_substring(from index: Int) -> String {
        return fw_substring(with: min(index, self.count) ..< self.count)
    }
    
    /// 截取子串到指定位置
    public func fw_substring(to index: Int) -> String {
        return fw_substring(with: 0 ..< max(0, index))
    }
    
    /// 截取指定范围的子串
    public func fw_substring(with range: NSRange) -> String {
        guard let range = Range<Int>(range) else { return "" }
        return fw_substring(with: range)
    }
    
    /// 截取指定范围的子串
    public func fw_substring(with range: Range<Int>) -> String {
        guard range.lowerBound >= 0, range.upperBound >= range.lowerBound else { return "" }
        let range = Range(uncheckedBounds: (lower: max(0, min(range.lowerBound, self.count)), upper: max(0, min(range.upperBound, self.count))))
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
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
    /// 安全URL，不为nil
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
    
    /// 获取当前query的参数字典，不含空值
    public var fw_queryDictionary: [String: String] {
        var components = URLComponents(string: self.absoluteString)
        if components == nil, let string = self.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
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
    
    /// 获取基准URI字符串，不含path|query|fragment等，包含scheme|host|port等
    public var fw_baseURI: String? {
        let string = self.absoluteString
        guard let components = URLComponents(string: string),
              let range = components.rangeOfPath else { return nil }
        return String(string.prefix(upTo: range.lowerBound))
    }
    
    /// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
    public var fw_pathURI: String? {
        let string = self.absoluteString
        guard let components = URLComponents(string: string),
              let range = components.rangeOfPath else { return nil }
        return String(string[range])
    }
}

@_spi(FW) extension NSObject {
    
    /// 非递归方式获取任意对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public static func fw_mirrorDictionary(_ object: Any?) -> [String: Any] {
        guard let object = object else { return [:] }
        var mirror = Mirror(reflecting: object)
        var children: [Mirror.Child] = []
        children += mirror.children
        while let superclassMirror = mirror.superclassMirror,
              superclassMirror.subjectType != NSObject.self {
            children += superclassMirror.children
            mirror = superclassMirror
        }
        
        var result: [String: Any] = [:]
        children.forEach { child in
            if let label = child.label, !label.isEmpty, !label.hasPrefix("_"),
               !Optional<Any>.isNone(child.value) {
                result[label] = child.value
            }
        }
        return result
    }
    
    /// 非递归方式获取当前对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public var fw_mirrorDictionary: [String: Any] {
        return NSObject.fw_mirrorDictionary(self)
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
public protocol SafeType {
    static var safeValue: Self { get }
    var isEmpty: Bool { get }
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
extension Set: SafeType {
    public static var safeValue: Set<Element> { return [] }
}
extension Dictionary: SafeType {
    public static var safeValue: Dictionary<Key, Value> { return [:] }
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
