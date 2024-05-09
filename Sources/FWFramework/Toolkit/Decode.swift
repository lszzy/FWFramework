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
        guard JSONSerialization.isValidJSONObject(object) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "JSON is invalid."))
        }
        return try JSONSerialization.data(withJSONObject: object, options: options)
    }
    
    /// json数据解码为Foundation对象，失败时抛异常
    public static func jsonDecode(_ data: Data, options: JSONSerialization.ReadingOptions = []) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: options)
        } catch {
            guard (error as NSError).code == 3840 else { throw error }
            
            let string = String(data: data, encoding: .utf8)
            guard let escapeData = string?.fw.escapeJson.data(using: .utf8) else { throw error }
            if escapeData.count == data.count { throw error }
            return try JSONSerialization.jsonObject(with: escapeData, options: options)
        }
    }
    
    /// json数据解码为Foundation对象
    public var jsonDecode: Any? {
        return try? Data.fw.jsonDecode(base)
    }
    
    /// base64编码
    public var base64Encode: Data {
        return base.base64EncodedData()
    }
    
    /// base64解码
    public var base64Decode: Data? {
        return Data(base64Encoded: base, options: .ignoreUnknownCharacters)
    }
    
    /// 将对象归档为data数据
    public static func archivedData(_ object: Any?) -> Data? {
        guard let object = object else { return nil }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        return data
    }
    
    /// 将数据解档为指定类型对象，需实现NSSecureCoding，推荐使用
    public func unarchivedObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        let object = try? NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: base)
        return object
    }
    
    /// 将数据解档为对象
    public func unarchivedObject() -> Any? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: base) else { return nil }
        unarchiver.requiresSecureCoding = false
        let object = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        return object
    }
    
    /// 将对象归档保存到文件
    @discardableResult
    public static func archiveObject(_ object: Any, toFile path: String) -> Bool {
        guard let data = archivedData(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
    
    /// 从文件解档指定类型对象，需实现NSSecureCoding，推荐使用
    public static func unarchivedObject<T>(_ clazz: T.Type, withFile path: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject(clazz)
    }
    
    /// 从文件解档对象
    public static func unarchivedObject(withFile path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject()
    }
}

// MARK: - Wrapper+String
extension Wrapper where Base == String {
    /// Foundation对象编码为json字符串
    public static func jsonEncode(_ object: Any, options: JSONSerialization.WritingOptions = []) -> String? {
        guard let data = try? Data.fw.jsonEncode(object, options: options) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
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
        if let data = Data(base64Encoded: base, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        
        let remainder = base.count % 4
        guard remainder > 0 else { return nil }
        
        let padding = String(repeating: "=", count: 4 - remainder)
        guard let data = Data(base64Encoded: base + padding, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
    public var unicodeEncode: String {
        var result = ""
        let str = base as NSString
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
    public var unicodeDecode: String {
        var str = base.replacingOccurrences(of: "\\u", with: "\\U")
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
    public var urlEncodeComponent: String? {
        return base.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted)
    }
    
    /// url参数解码，适用于query参数解码
    ///
    /// 示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
    ///      http://test.com?id=我是中文
    public var urlDecodeComponent: String? {
        return CFURLCreateStringByReplacingPercentEscapes(nil, base as CFString, "" as CFString) as String?
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
    
    /// 字典编码为URL参数字符串
    public static func queryEncode(_ dict: [String: Any]) -> String {
        var result = ""
        for (key, value) in dict {
            if result.count > 0 { result.append("&") }
            let string = String.fw.safeString(value).addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]").inverted) ?? ""
            result.append("\(key)=\(string)")
        }
        return result
    }
    
    /// URL参数字符串解码为字典，支持完整URL
    public var queryDecode: [String: String] {
        var result: [String: String] = [:]
        var queryString = base
        if let url = URL.fw.url(string: base), let scheme = url.scheme, scheme.count > 0 {
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
    public var md5Encode: String {
        let data = base.data(using: .utf8) ?? .init()
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// 中文转拼音
    public var pinyinString: String {
        if base.isEmpty { return base }
        let mutableString = NSMutableString(string: base)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        let pinyinStr = mutableString.folding(options: .diacriticInsensitive, locale: .current)
        return pinyinStr.lowercased()
    }
    
    /// 中文转拼音并进行比较
    public func pinyinCompare(_ string: String) -> ComparisonResult {
        let pinyin1 = pinyinString
        let pinyin2 = string.fw.pinyinString
        return pinyin1.compare(pinyin2)
    }
    
    /// 是否包含Emoji表情
    public var containsEmoji: Bool {
        for scalar in base.unicodeScalars {
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
    public var escapeJson: String {
        guard let regex = try? NSRegularExpression(pattern: "(\\\\UD[8-F][0-F][0-F])(\\\\UD[8-F][0-F][0-F])?", options: .caseInsensitive) else { return base }
        let matches = regex.matches(in: base, options: [], range: NSMakeRange(0, base.count))
        if matches.count < 1 { return base }
        
        // 倒序循环，避免replace越界
        var string = base as NSString
        for i in (0 ..< matches.count).reversed() {
            let range = matches[i].range
            let substr = string.substring(with: range).uppercased() as NSString
            if range.length == 12 && substr.character(at: 3) <= 66 && substr.character(at: 9) > 66 { continue }
            string = string.replacingCharacters(in: range, with: "") as NSString
        }
        return string as String
    }
}

// MARK: - Wrapper+URL
extension Wrapper where Base == URL {
    /// 获取当前query的参数字典，不含空值
    public var queryParameters: [String: String] {
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
    
    /// 获取基准URI字符串，不含path|query|fragment等，包含scheme|host|port等
    public var baseURI: String? {
        let string = base.absoluteString
        guard let components = URLComponents(string: string),
              let range = components.rangeOfPath else { return nil }
        return String(string.prefix(upTo: range.lowerBound))
    }
    
    /// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
    public var pathURI: String? {
        let string = base.absoluteString
        guard let components = URLComponents(string: string),
              let range = components.rangeOfPath else { return nil }
        return String(string[range])
    }
    
    /// 添加query参数字典并返回新的URL
    public func appendingQueryParameters(_ parameters: [String: String]) -> URL {
        var urlComponents = URLComponents(url: base, resolvingAgainstBaseURL: true) ?? .init()
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + parameters.map { URLQueryItem(name: $0, value: $1) }
        return urlComponents.url ?? URL()
    }
    
    /// 获取指定query参数值
    public func queryValue(for key: String) -> String? {
        URLComponents(url: base, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == key }?
            .value
    }
}
