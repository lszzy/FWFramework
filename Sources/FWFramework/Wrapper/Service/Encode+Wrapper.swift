//
//  Encode+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

/// 包装器安全转换，不为nil
extension Wrapper {
    public var safeInt: Int { return safeNumber.intValue }
    public var safeBool: Bool { return safeNumber.boolValue }
    public var safeFloat: Float { return safeNumber.floatValue }
    public var safeDouble: Double { return safeNumber.doubleValue }
    public var safeString: String { return String.fw_safeString(base) }
    public var safeNumber: NSNumber { return NSNumber.fw_safeNumber(base) }
    public var safeArray: [Any] { return (base as? [Any]) ?? [] }
    public var safeDictionary: [AnyHashable: Any] { return (base as? [AnyHashable: Any]) ?? [:] }
    public var safeJSON: JSON { return JSON(base) }
}

extension Wrapper where Base == Data {
    /// Foundation对象编码为json数据
    public static func jsonEncode(_ object: Any) -> Data? {
        return Base.fw_jsonEncode(object)
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
    
    /// 转换为UTF8字符串
    public var utf8String: String? {
        return base.fw_utf8String
    }
    
    /// 将对象归档为data数据
    public static func archivedData(_ object: Any?) -> Data? {
        return Base.fw_archivedData(object)
    }
    
    /// 将数据解档为指定类型对象，推荐使用
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
    
    /// 从文件解档指定类型对象，推荐使用
    public static func unarchivedObject<T>(_ clazz: T.Type, withFile path: String) -> T? where T : NSObject, T : NSCoding {
        return Base.fw_unarchivedObject(clazz, withFile: path)
    }
    
    /// 从文件解档对象
    public static func unarchivedObject(withFile path: String) -> Any? {
        return Base.fw_unarchivedObject(withFile: path)
    }
}

extension Wrapper where Base == String {
    /// 安全字符串，不为nil
    public static func safeString(_ value: Any?) -> String {
        return Base.fw_safeString(value)
    }
    
    /// Foundation对象编码为json字符串
    public static func jsonEncode(_ object: Any) -> String? {
        return Base.fw_jsonEncode(object)
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
    
    /// 计算长度，中文为1，英文为0.5，表情为2
    public var unicodeLength: Int {
        return base.fw_unicodeLength
    }
    
    /// 截取字符串，中文为1，英文为0.5，表情为2
    public func unicodeSubstring(_ length: Int) -> String {
        return base.fw_unicodeSubstring(length)
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
    
    /// 文件md5编码
    public var md5EncodeFile: String? {
        return base.fw_md5EncodeFile
    }
    
    /// 去掉首尾空白字符
    public var trimString: String {
        return base.fw_trimString
    }
    
    /// 首字母大写
    public var ucfirstString: String {
        return base.fw_ucfirstString
    }
    
    /// 首字母小写
    public var lcfirstString: String {
        return base.fw_lcfirstString
    }
    
    /// 驼峰转下划线
    public var underlineString: String {
        return base.fw_underlineString
    }
    
    /// 下划线转驼峰
    public var camelString: String {
        return base.fw_camelString
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
    
    /// 转换为UTF8数据
    public var utf8Data: Data? {
        return base.fw_utf8Data
    }
    
    /// 转换为URL
    public var url: URL? {
        return base.fw_url
    }
    
    /// 转换为NSNumber
    public var number: NSNumber? {
        return base.fw_number
    }
    
    /// 从指定位置截取子串
    public func substring(from index: Int) -> String {
        return base.fw_substring(from: index)
    }
    
    /// 截取子串到指定位置
    public func substring(to index: Int) -> String {
        return base.fw_substring(to: index)
    }
    
    /// 截取指定范围的子串
    public func substring(with range: NSRange) -> String {
        return base.fw_substring(with: range)
    }
    
    /// 截取指定范围的子串
    public func substring(with range: Range<Int>) -> String {
        return base.fw_substring(with: range)
    }
}

extension Wrapper where Base: NSNumber {
    /// 安全数字，不为nil
    public static func safeNumber(_ value: Any?) -> NSNumber {
        return Base.fw_safeNumber(value)
    }
}

extension Wrapper where Base == URL {
    /// 安全URL，不为nil
    public static func safeURL(_ value: Any?) -> URL {
        return Base.fw_safeURL(value)
    }
    
    /// 生成URL，中文自动URL编码
    public static func url(string: String?) -> URL? {
        return Base.fw_url(string: string)
    }
    
    /// 生成URL，中文自动URL编码，支持基准URL
    public static func url(string: String?, relativeTo baseURL: URL?) -> URL? {
        return Base.fw_url(string: string, relativeTo: baseURL)
    }
    
    /// 获取当前query的参数字典，不含空值
    public var queryDictionary: [String: String] {
        return base.fw_queryDictionary
    }
    
    /// 获取基准URI字符串，不含path|query|fragment等，包含scheme|host|port等
    public var baseURI: String? {
        return base.fw_baseURI
    }
    
    /// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
    public var pathURI: String? {
        return base.fw_pathURI
    }
}

extension Wrapper where Base: NSObject {
    
    /// 非递归方式获取任意对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public static func mirrorDictionary(_ object: Any?) -> [String: Any] {
        return Base.fw_mirrorDictionary(object)
    }
    
    /// 非递归方式获取当前对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public var mirrorDictionary: [String: Any] {
        return base.fw_mirrorDictionary
    }
    
}
