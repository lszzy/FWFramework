//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyCodableModel
/// 通用编码模型协议，默认兼容BasicCodableTypelJSON|CodableMode|JSONModel，可扩展
public protocol AnyCodableModel: AnyCodableType {
    /// 从Object解码成可选Model，当object为字典和数组时支持具体路径
    static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Self?
    /// 从Object安全解码成Model，当object为字典和数组时支持具体路径
    static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Self
    /// 从Model编码成Object
    func encodeAnyObject() -> Any?
}

extension AnyCodableModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = NSObject.getInnerObject(inside: object, by: designatedPath)
        return object as? Self
    }
    
    /// 默认实现从Object安全解码成Model，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Self {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? .init()
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self
    }
}

// MARK: - AnyCodableModel+BasicCodableType
extension Int: AnyCodableModel {}
extension Int8: AnyCodableModel {}
extension Int16: AnyCodableModel {}
extension Int32: AnyCodableModel {}
extension Int64: AnyCodableModel {}
extension UInt: AnyCodableModel {}
extension UInt8: AnyCodableModel {}
extension UInt16: AnyCodableModel {}
extension UInt32: AnyCodableModel {}
extension UInt64: AnyCodableModel {}
extension Bool: AnyCodableModel {}
extension Float: AnyCodableModel {}
extension Double: AnyCodableModel {}
extension URL: AnyCodableModel {}
extension Data: AnyCodableModel {}
extension Date: AnyCodableModel {}
extension String: AnyCodableModel {}
extension Array: AnyCodableModel {}
extension Set: AnyCodableModel {}
extension Dictionary: AnyCodableModel {}
extension CGFloat: AnyCodableModel {}
extension CGPoint: AnyCodableModel {}
extension CGSize: AnyCodableModel {}
extension CGRect: AnyCodableModel {}

extension AnyCodableModel where Self: BasicCodableType {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = NSObject.getInnerObject(inside: object, by: designatedPath)
        return object as? Self
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self
    }
}

// MARK: - AnyCodableModel+CodableModel
/// 通用Codable编码模型协议，默认未实现SafeCodableModel(实现init即可)
public protocol CodableModel: Codable, AnyCodableModel {}

extension CodableModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

extension AnyCodableModel where Self: CodableModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = NSObject.getInnerObject(inside: object, by: designatedPath)
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
extension JSON: AnyCodableModel {}

extension AnyCodableModel where Self == JSON {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = NSObject.getInnerObject(inside: object, by: designatedPath)
        return object != nil ? JSON(object) : nil
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return self.object
    }
}

// MARK: - AnyCodableModel+JSONModel
extension AnyCodableModel where Self: JSONModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension AnyCodableModel where Self: JSONModelCustomTransformable {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        if let object = NSObject.getInnerObject(inside: object, by: designatedPath) {
            return transform(from: object)
        }
        return nil
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return plainValue()
    }
}

extension AnyCodableModel where Self: JSONModelEnum {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        if let object = NSObject.getInnerObject(inside: object, by: designatedPath) {
            return transform(from: object)
        }
        return nil
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return plainValue()
    }
}

// MARK: - AnyCodableModel+Array
extension Array where Element: AnyCodableModel {
    /// 从Object解码成可选Model数组，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Array<Element>? {
        let object = NSObject.getInnerObject(inside: object, by: designatedPath)
        if let array = object as? [Any] {
            return array.compactMap { Element.decodeAnyModel(from: $0) }
        }
        return nil
    }
    
    /// 从Object安全解码成Model数组，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Array<Element> {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? []
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return compactMap { $0.encodeAnyObject() }
    }
}

extension Array where Element: JSONModel {
    /// 默认实现从Object解码成可选Model数组，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Array<Element>? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}
