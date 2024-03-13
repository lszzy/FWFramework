//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyModel
/// 通用编码模型协议，默认兼容BasicTypelJSON|CodableMode|JSONModel，可扩展
public protocol AnyModel: SafeType {
    /// 从Object解码成可选Model，当object为字典和数组时支持具体路径
    static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Self?
    /// 从Object安全解码成Model，当object为字典和数组时支持具体路径
    static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Self
    /// 从Model编码成Object
    func encodeAnyObject() -> Any?
}

extension AnyModel {
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

// MARK: - AnyModel+BasicType
extension Int: AnyModel {}
extension Int8: AnyModel {}
extension Int16: AnyModel {}
extension Int32: AnyModel {}
extension Int64: AnyModel {}
extension UInt: AnyModel {}
extension UInt8: AnyModel {}
extension UInt16: AnyModel {}
extension UInt32: AnyModel {}
extension UInt64: AnyModel {}
extension Bool: AnyModel {}
extension Float: AnyModel {}
extension Double: AnyModel {}
extension URL: AnyModel {}
extension Data: AnyModel {}
extension Date: AnyModel {}
extension String: AnyModel {}
extension Array: AnyModel {}
extension Set: AnyModel {}
extension Dictionary: AnyModel {}
extension CGFloat: AnyModel {}
extension CGPoint: AnyModel {}
extension CGSize: AnyModel {}
extension CGRect: AnyModel {}

extension AnyModel where Self: BasicType {
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

// MARK: - AnyModel+CodableModel
/// 通用Codable编码模型协议，默认未实现SafeCodableModel(实现init即可)
public protocol CodableModel: Codable, AnyModel {}

extension CodableModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

extension AnyModel where Self: CodableModel {
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

// MARK: - AnyModel+JSON
/// 默认实现编码模型协议
extension JSON: AnyModel {}

extension AnyModel where Self == JSON {
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

// MARK: - AnyModel+JSONModel
extension AnyModel where Self: JSONModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeAnyModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        return deserializeAny(from: object, designatedPath: designatedPath)
    }
    
    /// 默认实现从Model编码成Object
    public func encodeAnyObject() -> Any? {
        return toJSON()
    }
}

extension AnyModel where Self: JSONModelCustomTransformable {
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

extension AnyModel where Self: JSONModelEnum {
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

// MARK: - AnyModel+Array
extension Array where Element: AnyModel {
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
