//
//  MappableModel.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/9.
//

import Foundation
import ObjectMapper
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - MappableModel
/// 通用Mappable模型，兼容AnyModel、AnyArchivable等协议
public protocol MappableModel: Mappable, AnyModel {}

// MARK: - MappableModel+AnyArchivable
extension AnyArchivable where Self: MappableModel {
    public static func archiveDecode(_ data: Data?) -> Self? {
        guard let data, let string = String(data: data, encoding: .utf8) else { return nil }
        return .init(JSONString: string)
    }

    public func archiveEncode() -> Data? {
        toJSONString()?.data(using: .utf8)
    }
}

// MARK: - AnyModel+MappableModel
extension AnyModel where Self: MappableModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        if let dict = object as? [String: Any] {
            return .init(JSON: dict)
        }

        var string = object as? String
        if string == nil, let data = object as? Data {
            string = String(data: data, encoding: .utf8)
        }
        guard let string else { return nil }
        return .init(JSONString: string)
    }

    /// 默认实现从Model编码成Object
    public func encodeObject() -> Any? {
        toJSON()
    }
}

// MARK: - MappableModel+Array
extension Array where Element: MappableModel {
    /// 默认实现从Object解码成可选Model数组，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        let object = getInnerObject(inside: object, by: designatedPath)
        if let array = object as? [[String: Any]] {
            return .init(JSONArray: array)
        }

        var string = object as? String
        if string == nil, let data = object as? Data {
            string = String(data: data, encoding: .utf8)
        }
        guard let string else { return nil }
        return .init(JSONString: string)
    }

    /// 从数组Model编码成Object
    public func encodeObject() -> Any? {
        toJSON()
    }
}
