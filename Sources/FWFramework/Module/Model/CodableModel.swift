//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyCodableModel
/// 通用编码模型协议，默认兼容SafeType|NSObject|Codable|JSON|JSONModel，可扩展
public protocol AnyCodableModel {
    /// 从Object解码成可选Model
    static func decodeAnyModel(from object: Any?) -> Self?
    /// 从Model编码成Object
    func encodeAnyObject() -> Any?
}

/// 通用安全编码模型协议，解码失败时返回默认Model
public protocol SafeCodableModel: AnyCodableModel {
    /// 从Object安全解码成Model
    static func decodeSafeModel(from object: Any?) -> Self
    /// 解码失败时创建默认Model
    init()
}

extension AnyCodableModel {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return object as? Self
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self
    }
}

extension SafeCodableModel {
    /// 默认实现从Object安全解码成Model
    public static func decodeSafeModel(from object: Any?) -> Self {
        return decodeAnyModel(from: object) ?? .init()
    }
}

// MARK: - AnyCodableModel+Array
extension Array where Element: AnyCodableModel {
    /// 从Object解码成可选Model数组
    public static func decodeAnyModel(from object: Any?) -> Array<Element>? {
        if let array = object as? [Any] {
            return array.compactMap { Element.decodeAnyModel(from: $0) }
        }
        return nil
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return compactMap { $0.encodeAnyObject() }
    }
}

extension Array where Element: SafeCodableModel {
    /// 从Object安全解码成Model数组
    public static func decodeSafeModel(from object: Any?) -> Array<Element> {
        return decodeAnyModel(from: object) ?? []
    }
}

// MARK: - AnyCodableModel+SafeType
/// 默认实现编码模型协议
extension Int: SafeCodableModel {}
extension Int8: SafeCodableModel {}
extension Int16: SafeCodableModel {}
extension Int32: SafeCodableModel {}
extension Int64: SafeCodableModel {}
extension UInt: SafeCodableModel {}
extension UInt8: SafeCodableModel {}
extension UInt16: SafeCodableModel {}
extension UInt32: SafeCodableModel {}
extension UInt64: SafeCodableModel {}
extension Float: SafeCodableModel {}
extension Double: SafeCodableModel {}
extension Bool: SafeCodableModel {}
extension URL: SafeCodableModel {}
extension Data: SafeCodableModel {}
extension String: SafeCodableModel {}
extension Array: SafeCodableModel {}
extension Set: SafeCodableModel {}
extension Dictionary: SafeCodableModel {}
extension CGFloat: SafeCodableModel {}
extension CGPoint: SafeCodableModel {}
extension CGSize: SafeCodableModel {}
extension CGRect: SafeCodableModel {}
extension NSObject: SafeCodableModel {}

// MARK: - AnyCodableModel+Codable
extension AnyCodableModel where Self: Codable {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        var data: Data? = object as? Data
        if data == nil, let object = object {
            if let string = object as? String {
                data = string.data(using: .utf8)
            } else {
                data = Data.fw_jsonEncode(object)
            }
        }
        return try? data?.fw_decoded(as: self)
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        let data = try? Data.fw_encoded(self)
        return data?.fw_jsonDecode
    }
}


// MARK: - AnyCodableModel+JSON
/// 默认实现编码模型协议
extension JSON: SafeCodableModel {}

extension AnyCodableModel where Self == JSON {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return object != nil ? JSON(object) : nil
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self.object
    }
}

// MARK: - AnyCodableModel+JSONModel
/// 通用JSONModel编码模型协议
public typealias AnyJSONModel = SafeCodableModel & JSONModel

extension AnyCodableModel where Self: JSONModel {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return decodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object解码成可选Model，支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Self? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension SafeCodableModel where Self: JSONModel {
    /// 默认实现从Object安全解码成Model
    public static func decodeSafeModel(from object: Any?) -> Self {
        return decodeSafeModel(from: object, designatedPath: nil)
    }
    
    /// 从Object安全解码成Model，支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Self {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? .init()
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension Array where Element: AnyCodableModel & JSONModel {
    /// 从Object解码成可选Model数组
    public static func decodeAnyModel(from object: Any?) -> Array<Element>? {
        return decodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object解码成可选Model数组，支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Array<Element>? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension Array where Element: SafeCodableModel & JSONModel {
    /// 从Object安全解码成Model数组
    public static func decodeSafeModel(from object: Any?) -> Array<Element> {
        return decodeSafeModel(from: object, designatedPath: nil)
    }
    
    /// 从Object安全解码成Model数组，支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Array<Element> {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? []
    }
}
