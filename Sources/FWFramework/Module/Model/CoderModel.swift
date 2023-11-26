//
//  CoderModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyCoderModel
/// 通用编码模型协议，默认兼容SafeType|NSObject|Codable|JSON|JSONModel，可扩展
public protocol AnyCoderModel {
    /// 从Object解码成可选Model
    static func decodeAnyModel(from object: Any?) -> Self?
    /// 从Object安全解码成Model
    static func safeDecodeAnyModel(from object: Any?) -> Self
    /// 解码失败时创建安全Model
    static func safeAnyModel() -> Self
    
    /// 从Model编码成Object
    func encodeAnyObject() -> Any?
}

extension AnyCoderModel {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return object as? Self
    }
    
    /// 默认实现从Object安全解码成Model
    public static func safeDecodeAnyModel(from object: Any?) -> Self {
        return decodeAnyModel(from: object) ?? safeAnyModel()
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self
    }
}

// MARK: - AnyCoderModel+Array
extension Array where Element: AnyCoderModel {
    /// 从Object解码成可选Model数组
    public static func decodeAnyModel(from object: Any?) -> Array<Element>? {
        if let array = object as? [Any] {
            return array.compactMap { Element.decodeAnyModel(from: $0) }
        }
        return nil
    }
    
    /// 从Object安全解码成Model数组
    public static func safeDecodeAnyModel(from object: Any?) -> Array<Element> {
        return decodeAnyModel(from: object) ?? safeAnyModel()
    }
    
    /// 解码失败时创建安全Model数组
    public static func safeAnyModel() -> Array<Element> {
        return []
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return compactMap { $0.encodeAnyObject() }
    }
}

// MARK: - AnyCoderModel+SafeType
/// 默认实现编码模型协议
extension Int: AnyCoderModel {}
extension Int8: AnyCoderModel {}
extension Int16: AnyCoderModel {}
extension Int32: AnyCoderModel {}
extension Int64: AnyCoderModel {}
extension UInt: AnyCoderModel {}
extension UInt8: AnyCoderModel {}
extension UInt16: AnyCoderModel {}
extension UInt32: AnyCoderModel {}
extension UInt64: AnyCoderModel {}
extension Float: AnyCoderModel {}
extension Double: AnyCoderModel {}
extension Bool: AnyCoderModel {}
extension URL: AnyCoderModel {}
extension Data: AnyCoderModel {}
extension String: AnyCoderModel {}
extension Array: AnyCoderModel {}
extension Set: AnyCoderModel {}
extension Dictionary: AnyCoderModel {}
extension CGFloat: AnyCoderModel {}
extension CGPoint: AnyCoderModel {}
extension CGSize: AnyCoderModel {}
extension CGRect: AnyCoderModel {}

extension AnyCoderModel where Self: SafeType {
    /// 默认实现解码失败时创建安全Model
    public static func safeAnyModel() -> Self {
        return .safeValue
    }
}

// MARK: - AnyCoderModel+NSObject
/// 默认实现编码模型协议
extension NSObject: AnyCoderModel {}

extension AnyCoderModel where Self: NSObject {
    /// 默认实现解码失败时创建安全Model
    public static func safeAnyModel() -> Self {
        return .init()
    }
}

// MARK: - AnyCoderModel+Codable
extension AnyCoderModel where Self: Codable {
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


// MARK: - AnyCoderModel+JSON
/// 默认实现编码模型协议
extension JSON: AnyCoderModel {}

extension AnyCoderModel where Self == JSON {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return object != nil ? JSON(object) : nil
    }
    
    /// 默认实现解码失败时创建安全Model
    public static func safeAnyModel() -> Self {
        return .null
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self.object
    }
}

// MARK: - AnyCoderModel+JSONModel
/// 通用JSONModel编码模型协议
public typealias AnyJSONModel = AnyCoderModel & JSONModel

extension AnyCoderModel where Self: JSONModel {
    /// 默认实现从Object解码成可选Model
    public static func decodeAnyModel(from object: Any?) -> Self? {
        return decodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object解码成可选Model，支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Self? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 默认实现从Object安全解码成Model
    public static func safeDecodeAnyModel(from object: Any?) -> Self {
        return safeDecodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object安全解码成Model，支持具体路径
    public static func safeDecodeAnyModel(from object: Any?, designatedPath: String?) -> Self {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? safeAnyModel()
    }
    
    /// 默认实现解码失败时创建安全Model
    public static func safeAnyModel() -> Self {
        return .init()
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension Array where Element: AnyJSONModel {
    /// 从Object解码成可选Model数组
    public static func decodeAnyModel(from object: Any?) -> Array<Element>? {
        return decodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object解码成可选Model数组，支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Array<Element>? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 从Object安全解码成Model数组
    public static func safeDecodeAnyModel(from object: Any?) -> Array<Element> {
        return safeDecodeAnyModel(from: object, designatedPath: nil)
    }
    
    /// 从Object安全解码成Model数组，支持具体路径
    public static func safeDecodeAnyModel(from object: Any?, designatedPath: String?) -> Array<Element> {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? safeAnyModel()
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}
