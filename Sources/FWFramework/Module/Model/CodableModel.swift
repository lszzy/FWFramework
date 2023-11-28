//
//  CodableModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyCodableModel
/// 通用编码模型协议，默认兼容SafeTypelJSON|CodableMode|JSONModel，可扩展
public protocol AnyCodableModel {
    /// 从Object解码成可选Model，当object为字典和数组时支持具体路径
    static func decodeAnyModel(from object: Any?, designatedPath: String?) -> Self?
    /// 从Model编码成Object
    func encodeAnyObject() -> Any?
}

/// 通用安全编码模型协议，解码失败时返回默认Model
public protocol SafeCodableModel: AnyCodableModel {
    /// 从Object安全解码成Model，当object为字典和数组时支持具体路径
    static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Self
    /// 解码失败时创建默认Model
    init()
}

extension AnyCodableModel {
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

extension SafeCodableModel {
    /// 默认实现从Object安全解码成Model，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Self {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? .init()
    }
}

// MARK: - AnyCodableModel+SafeType
extension AnyCodableModel where Self: SafeType {
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
extension JSON: SafeCodableModel {}

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
    
    /// 从数组Model编码成Object
    public func encodeAnyObject() -> Any? {
        return compactMap { $0.encodeAnyObject() }
    }
}

extension Array where Element: SafeCodableModel {
    /// 从Object安全解码成Model数组，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Array<Element> {
        return decodeAnyModel(from: object, designatedPath: designatedPath) ?? []
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
