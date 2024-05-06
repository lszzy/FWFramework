//
//  Encode.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import CryptoKit

// MARK: - Wrapper+Data
extension Wrapper where Base == Data {
    /// Foundation对象编码为json数据，失败时抛异常
    public static func jsonEncode(_ object: Any, options: JSONSerialization.WritingOptions = []) throws -> Data {
        return try Base.fw_jsonEncode(object, options: options)
    }
    
    /// json数据解码为Foundation对象，失败时抛异常
    public static func jsonDecode(_ data: Data, options: JSONSerialization.ReadingOptions = []) throws -> Any {
        return try Base.fw_jsonDecode(data, options: options)
    }
    
    /// json数据解码为Foundation对象
    public var jsonDecode: Any? {
        return base.fw_jsonDecode
    }
    
    /// base64编码
    public var base64Encode: Data {
        return base.fw_base64Encode
    }
    
    /// base64解码
    public var base64Decode: Data? {
        return base.fw_base64Decode
    }
    
    /// 将对象归档为data数据
    public static func archivedData(_ object: Any?) -> Data? {
        return Base.fw_archivedData(object)
    }
    
    /// 将数据解档为指定类型对象，需实现NSSecureCoding，推荐使用
    public func unarchivedObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        return base.fw_unarchivedObject(clazz)
    }
    
    /// 将数据解档为对象
    public func unarchivedObject() -> Any? {
        return base.fw_unarchivedObject()
    }
    
    /// 将对象归档保存到文件
    @discardableResult
    public static func archiveObject(_ object: Any, toFile path: String) -> Bool {
        return Base.fw_archiveObject(object, toFile: path)
    }
    
    /// 从文件解档指定类型对象，需实现NSSecureCoding，推荐使用
    public static func unarchivedObject<T>(_ clazz: T.Type, withFile path: String) -> T? where T : NSObject, T : NSCoding {
        return Base.fw_unarchivedObject(clazz, withFile: path)
    }
    
    /// 从文件解档对象
    public static func unarchivedObject(withFile path: String) -> Any? {
        return Base.fw_unarchivedObject(withFile: path)
    }
}

// MARK: - Wrapper+String
extension Wrapper where Base == String {
    /// Foundation对象编码为json字符串
    public static func jsonEncode(_ object: Any, options: JSONSerialization.WritingOptions = []) -> String? {
        return Base.fw_jsonEncode(object, options: options)
    }
    
    /// json字符串解码为Foundation对象
    public var jsonDecode: Any? {
        base.fw_jsonDecode
    }
    
    /// base64编码
    public var base64Encode: String? {
        return base.fw_base64Encode
    }
    
    /// base64解码
    public var base64Decode: String? {
        return base.fw_base64Decode
    }
    
    /// Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
    public var unicodeEncode: String {
        return base.fw_unicodeEncode
    }
    
    /// Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
    public var unicodeDecode: String {
        return base.fw_unicodeDecode
    }
    
    /// url参数编码，适用于query参数编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var urlEncodeComponent: String? {
        return base.fw_urlEncodeComponent
    }
    
    /// url参数解码，适用于query参数解码
    ///
    /// 示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var urlDecodeComponent: String? {
        return base.fw_urlDecodeComponent
    }
    
    /// url编码，适用于整个url编码
    ///
    /// 示例：http://test.com?id=我是中文 =>
    ///      http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
    public var urlEncode: String? {
        return base.fw_urlEncode
    }
    
    /// url解码，适用于整个url解码
    ///
    /// 示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var urlDecode: String? {
        return base.fw_urlDecode
    }
    
    /// 字典编码为URL参数字符串
    public static func queryEncode(_ dict: [String: Any]) -> String {
        return Base.fw_queryEncode(dict)
    }
    
    /// URL参数字符串解码为字典，支持完整URL
    public var queryDecode: [String: String] {
        return base.fw_queryDecode
    }
    
    /// md5编码
    public var md5Encode: String {
        return base.fw_md5Encode
    }
    
    /// 中文转拼音
    public var pinyinString: String {
        return base.fw_pinyinString
    }
    
    /// 中文转拼音并进行比较
    public func pinyinCompare(_ string: String) -> ComparisonResult {
        return base.fw_pinyinCompare(string)
    }
    
    /// 是否包含Emoji表情
    public var containsEmoji: Bool {
        return base.fw_containsEmoji
    }
    
    /// 过滤JSON解码特殊字符
    ///
    /// 兼容\uD800-\uDFFF引起JSON解码报错3840问题，不报错时无需调用
    /// 规则：只允许以\uD800-\uDBFF高位开头，紧跟\uDC00-\uDFFF低位；其他全不允许
    /// 参考：https://github.com/SBJson/SBJson/blob/trunk/Classes/SBJson5StreamTokeniser.m
    public var escapeJson: String {
        return base.fw_escapeJson
    }
}

// MARK: - Wrapper+URL
extension Wrapper where Base == URL {
    /// 获取当前query的参数字典，不含空值
    public var queryParameters: [String: String] {
        return base.fw_queryParameters
    }
    
    /// 获取基准URI字符串，不含path|query|fragment等，包含scheme|host|port等
    public var baseURI: String? {
        return base.fw_baseURI
    }
    
    /// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
    public var pathURI: String? {
        return base.fw_pathURI
    }
    
    /// 添加query参数字典并返回新的URL
    public func appendingQueryParameters(_ parameters: [String: String]) -> URL {
        return base.fw_appendingQueryParameters(parameters)
    }
    
    /// 获取指定query参数值
    public func queryValue(for key: String) -> String? {
        return base.fw_queryValue(for: key)
    }
}

// MARK: - Encode
@_spi(FW) extension Data {
    /// Foundation对象编码为json数据，失败时抛异常
    public static func fw_jsonEncode(_ object: Any, options: JSONSerialization.WritingOptions = []) throws -> Data {
        guard JSONSerialization.isValidJSONObject(object) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "JSON is invalid."))
        }
        return try JSONSerialization.data(withJSONObject: object, options: options)
    }
    
    /// json数据解码为Foundation对象，失败时抛异常
    public static func fw_jsonDecode(_ data: Data, options: JSONSerialization.ReadingOptions = []) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: options)
        } catch {
            guard (error as NSError).code == 3840 else { throw error }
            
            let string = String(data: data, encoding: .utf8)
            guard let escapeData = string?.fw_escapeJson.data(using: .utf8) else { throw error }
            if escapeData.count == data.count { throw error }
            return try JSONSerialization.jsonObject(with: escapeData, options: options)
        }
    }
    
    /// json数据解码为Foundation对象
    public var fw_jsonDecode: Any? {
        return try? Data.fw_jsonDecode(self)
    }
    
    /// base64编码
    public var fw_base64Encode: Data {
        return self.base64EncodedData()
    }
    
    /// base64解码
    public var fw_base64Decode: Data? {
        return Data(base64Encoded: self, options: .ignoreUnknownCharacters)
    }
    
    /// 将对象归档为data数据
    public static func fw_archivedData(_ object: Any?) -> Data? {
        guard let object = object else { return nil }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        return data
    }
    
    /// 将数据解档为指定类型对象，需实现NSSecureCoding，推荐使用
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
    
    /// 从文件解档指定类型对象，需实现NSSecureCoding，推荐使用
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
    /// Foundation对象编码为json字符串
    public static func fw_jsonEncode(_ object: Any, options: JSONSerialization.WritingOptions = []) -> String? {
        guard let data = try? Data.fw_jsonEncode(object, options: options) else { return nil }
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
            let string = String.fw.safeString(value).addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted) ?? ""
            result.append("\(key)=\(string)")
        }
        return result
    }
    
    /// URL参数字符串解码为字典，支持完整URL
    public var fw_queryDecode: [String: String] {
        var result: [String: String] = [:]
        var queryString = self
        if let url = URL.fw.url(string: self), let scheme = url.scheme, scheme.count > 0 {
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
        let data = self.data(using: .utf8) ?? .init()
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
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
}

@_spi(FW) extension URL {
    /// 获取当前query的参数字典，不含空值
    public var fw_queryParameters: [String: String] {
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
    
    /// 添加query参数字典并返回新的URL
    public func fw_appendingQueryParameters(_ parameters: [String: String]) -> URL {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) ?? .init()
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + parameters.map { URLQueryItem(name: $0, value: $1) }
        return urlComponents.url ?? URL()
    }
    
    /// 获取指定query参数值
    public func fw_queryValue(for key: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == key }?
            .value
    }
}
