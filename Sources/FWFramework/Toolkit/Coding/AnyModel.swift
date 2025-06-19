//
//  AnyModel.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/26.
//

import Foundation

// MARK: - AnyModel
/// 通用编码模型协议，默认兼容BasicTypelJSON|CodableMode|SmartModel，可扩展
public protocol AnyModel: ObjectType {
    /// 从Object解码成可选Model，当object为字典和数组时支持具体路径
    static func decodeModel(from object: Any?, designatedPath: String?) -> Self?
    /// 从Object安全解码成Model，当object为字典和数组时支持具体路径
    static func decodeSafeModel(from object: Any?, designatedPath: String?) -> Self
    /// 从Model编码成Object
    func encodeObject() -> Any?
}

extension AnyModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        return object as? Self
    }

    /// 默认实现从Object安全解码成Model，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Self {
        decodeModel(from: object, designatedPath: designatedPath) ?? .init()
    }

    /// 默认实现从Model编码成Object
    public func encodeObject() -> Any? {
        self
    }

    /// 获取内部对象，兼容字典、数组等
    public static func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
        var result: Any? = object
        var abort = false
        if let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 {
            var next = object
            for seg in paths {
                if seg.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" || abort {
                    continue
                }
                if let index = Int(seg), index >= 0 {
                    if let array = next as? [Any], index < array.count {
                        let _next = array[index]
                        result = _next
                        next = _next
                    } else {
                        abort = true
                    }
                } else {
                    if let _next = (next as? [String: Any])?[seg] {
                        result = _next
                        next = _next
                    } else {
                        abort = true
                    }
                }
            }
        }
        return abort ? nil : result
    }
}

extension AnyModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
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

extension AnyModel where Self: BasicType {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        return object as? Self
    }

    /// 默认实现从Model编码成Object
    public func encodeObject() -> Any? {
        self
    }
}

// MARK: - AnyModel+JSON
/// 默认实现编码模型协议
extension JSON: AnyModel {}

extension AnyModel where Self == JSON {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        return object != nil ? JSON(object) : nil
    }

    /// 默认实现从Model编码成Object
    public func encodeObject() -> Any? {
        let object = (self as JSON).object
        return !(object is NSNull) ? object : nil
    }
}

// MARK: - Array+AnyModel
extension Array where Element: AnyModel {
    /// 从Object解码成可选Model数组，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        if let array = object as? [Any] {
            return array.compactMap { Element.decodeModel(from: $0) }
        }
        return nil
    }

    /// 从Object安全解码成Model数组，当object为字典和数组时支持具体路径
    public static func decodeSafeModel(from object: Any?, designatedPath: String? = nil) -> Self {
        decodeModel(from: object, designatedPath: designatedPath) ?? []
    }

    /// 从数组Model编码成Object
    public func encodeObject() -> Any? {
        compactMap { $0.encodeObject() }
    }
}
