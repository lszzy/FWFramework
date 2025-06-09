//
//  SmartModel.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/2.
//

import Foundation
import UIKit

// MARK: - SmartModel
/// 智能解析Codable模型，兼容AnyModel、AnyArchivable等协议，推荐使用
public protocol SmartModel: SmartCodable, AnyModel {}

extension SmartModel where Self: AnyObject {
    /// 获取对象的内存hash字符串
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

// MARK: - SmartModelConfiguration
public class SmartModelConfiguration: @unchecked Sendable {
    public static let shared = SmartModelConfiguration()

    public var decodingOptions: Set<SmartDecodingOption>?
    public var encodingOptions: Set<SmartEncodingOption>?
}

// MARK: - AnyModel+SmartModel
extension AnyModel where Self: SmartModel {
    /// 默认实现从Object解码成可选Model，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        deserializeAny(from: object, designatedPath: designatedPath)
    }

    /// 默认实现从Model编码成Object
    public func encodeObject() -> Any? {
        toDictionary()
    }
}

// MARK: - Array+SmartModel
extension Array where Element: SmartModel {
    /// 默认实现从Object解码成可选Model数组，当object为字典和数组时支持具体路径
    public static func decodeModel(from object: Any?, designatedPath: String? = nil) -> Self? {
        deserializeAny(from: object, designatedPath: designatedPath)
    }

    /// 从数组Model编码成Object
    public func encodeObject() -> Any? {
        toArray()
    }
}

// MARK: - SmartModel+AnyArchivable
extension AnyArchivable where Self: SmartModel {
    public static func archiveDecode(_ data: Data?) -> Self? {
        deserialize(from: data)
    }

    public func archiveEncode() -> Data? {
        toJSONString()?.data(using: .utf8)
    }
}

// MARK: - SmartModel+SmartDecodable
extension SmartDecodable {
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        if let dict = object as? [String: Any] {
            return deserialize(from: dict, designatedPath: designatedPath, options: options)
        } else if let data = object as? Data {
            return deserialize(from: data, designatedPath: designatedPath, options: options)
        } else {
            return deserialize(from: object as? String, designatedPath: designatedPath, options: options)
        }
    }
}

extension Array where Element: SmartDecodable {
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        if let array = object as? [Any] {
            return deserialize(from: array, designatedPath: designatedPath, options: options)
        } else if let data = object as? Data {
            return deserialize(from: data, designatedPath: designatedPath, options: options)
        } else {
            return deserialize(from: object as? String, designatedPath: designatedPath, options: options)
        }
    }
}

extension SmartDecodable where Self: SmartEncodable {
    public mutating func mergeAny(from object: Any?, designatedPath: String? = nil) {
        if let dict = object as? [String: Any] {
            SmartUpdater.update(&self, from: dict)
        } else if let data = object as? Data {
            SmartUpdater.update(&self, from: data)
        } else {
            SmartUpdater.update(&self, from: object as? String)
        }
    }
}

// MARK: - SmartCodable
/// [SmartCodable](https://github.com/intsig171/SmartCodable)
///
/// SmartCodable改动如下：
/// 1. 兼容DefaultCaseCodable
/// 2. 移除Defaultable，改为BasicType
/// 3. 新增SmartModelConfiguration全局配置
/// 4. 移除useMappedKeys参数，默认true
/// 5. 优化getInnerObject方法，兼容数组索引
/// 6. Array元素为SmartCodable时不实现SmartCodable
public typealias SmartCodable = SmartDecodable & SmartEncodable

// MARK: - SmartDecodable
public protocol SmartDecodable: Decodable {
    /// Callback invoked after successful decoding for post-processing
    mutating func didFinishMapping()

    /// Defines key mapping transformations during decoding
    /// First non-null mapping is preferred
    static func mappingForKey() -> [SmartKeyTransformer]?

    /// Defines value transformation strategies during decoding
    static func mappingForValue() -> [SmartValueTransformer]?

    init()
}

extension SmartDecodable {
    public mutating func didFinishMapping() {}
    public static func mappingForKey() -> [SmartKeyTransformer]? { nil }
    public static func mappingForValue() -> [SmartValueTransformer]? { nil }
}

/// Options for SmartCodable parsing
public enum SmartDecodingOption: Hashable {
    /// The default policy for date is ReferenceDate (January 1, 2001 00:00:00 UTC), in seconds.
    case date(JSONDecoder.DateDecodingStrategy)

    case data(JSONDecoder.SmartDataDecodingStrategy)

    case float(JSONDecoder.NonConformingFloatDecodingStrategy)

    /// The mapping strategy for keys during parsing
    case key(JSONDecoder.SmartKeyDecodingStrategy)

    /// 附加用于日志系统的上下文信息，例如网络请求的 URL、参数、调用位置等。
    case logContext(header: String, footer: String)

    /// Handles the hash value, ignoring the impact of associated values.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .date:
            hasher.combine(0)
        case .data:
            hasher.combine(1)
        case .float:
            hasher.combine(2)
        case .key:
            hasher.combine(3)
        case .logContext:
            hasher.combine(4)
        }
    }

    public static func ==(lhs: SmartDecodingOption, rhs: SmartDecodingOption) -> Bool {
        switch (lhs, rhs) {
        case (.date, .date):
            return true
        case (.data, .data):
            return true
        case (.float, .float):
            return true
        case (.key, .key):
            return true
        case (.logContext, .logContext):
            return true
        default:
            return false
        }
    }
}

extension SmartDecodable {
    /// Deserializes into a model
    /// - Parameter dict: Dictionary
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from dict: [String: Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let _dict = dict else {
            logNilValue(for: "Dictionary", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: _dict, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into a model
    /// - Parameter json: JSON string
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let _json = json else {
            logNilValue(for: "JSON String", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: _json, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into a model
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let data else {
            logNilValue(for: "Data", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: data, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return _data._deserializeDict(type: Self.self, options: options)
    }

    /// Deserializes into a model
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Model
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let data else {
            logNilValue(for: "Data", on: Self.self)
            return nil
        }

        guard let _tranData = data.tranformToJSONData(type: Self.self) else {
            return nil
        }

        guard let _data = getInnerData(inside: _tranData, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return _data._deserializeDict(type: Self.self, options: options)
    }
}

extension Array where Element: SmartDecodable {
    /// Deserializes into an array of models
    /// - Parameter array: Array
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from array: [Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let _arr = array else {
            logNilValue(for: "Array", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: _arr, by: nil) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into an array of models
    /// - Parameter json: JSON string
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Only one enumeration item is allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let _json = json else {
            logNilValue(for: "JSON String", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: _json, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into an array of models
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let data else {
            logNilValue(for: "Data", on: Self.self)
            return nil
        }

        guard let _data = getInnerData(inside: data, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return _data._deserializeArray(type: Self.self, options: options)
    }

    /// Deserializes into an array of models
    /// - Parameter data: Data
    /// - Parameter designatedPath: Specifies the data path to decode
    /// - Parameter options: Decoding strategy
    ///   Duplicate enumeration items are not allowed, e.g., multiple keyStrategies cannot be passed in [only the first one is effective].
    /// - Returns: Array of models
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let data else {
            logNilValue(for: "Data", on: Self.self)
            return nil
        }

        guard let _tranData = data.tranformToJSONData(type: Self.self) else {
            return nil
        }

        guard let _data = getInnerData(inside: _tranData, by: designatedPath) else {
            logDataExtractionFailure(forPath: designatedPath, type: Self.self)
            return nil
        }

        return _data._deserializeArray(type: Self.self, options: options)
    }
}

extension Data {
    private func createDecoder<T>(type: T.Type, options: Set<SmartDecodingOption>? = nil) -> JSONDecoder {
        let _decoder = SmartJSONDecoder()

        if let _options = options ?? SmartModelConfiguration.shared.decodingOptions {
            for _option in _options {
                switch _option {
                case let .data(strategy):
                    _decoder.smartDataDecodingStrategy = strategy

                case let .date(strategy):
                    _decoder.smartDateDecodingStrategy = strategy

                case let .float(strategy):
                    _decoder.nonConformingFloatDecodingStrategy = strategy

                case let .key(strategy):
                    _decoder.smartKeyDecodingStrategy = strategy

                case let .logContext(header, footer):
                    var userInfo = _decoder.userInfo
                    if let headerKey = CodingUserInfoKey.logContextHeader {
                        userInfo.updateValue(header, forKey: headerKey)
                    }

                    if let footerKey = CodingUserInfoKey.logContextFooter {
                        userInfo.updateValue(footer, forKey: footerKey)
                    }
                    _decoder.userInfo = userInfo
                }
            }
        }

        return _decoder
    }

    fileprivate func _deserializeDict<T>(type: T.Type, options: Set<SmartDecodingOption>? = nil) -> T? where T: SmartDecodable {
        do {
            let _decoder = createDecoder(type: type, options: options)
            var obj = try _decoder.decode(type, from: self)
            obj.didFinishMapping()
            return obj
        } catch {
            return nil
        }
    }

    fileprivate func _deserializeArray<T>(type: [T].Type, options: Set<SmartDecodingOption>? = nil) -> [T]? where T: SmartDecodable {
        do {
            let _decoder = createDecoder(type: type, options: options)
            let decodeValue = try _decoder.decode(type, from: self)
            return decodeValue
        } catch {
            return nil
        }
    }

    fileprivate func toObject() -> Any? {
        let jsonObject = try? JSONSerialization.jsonObject(with: self, options: .allowFragments)
        return jsonObject
    }

    /// 将Plist Data 转成 JSON Data
    fileprivate func tranformToJSONData(type: Any.Type) -> Data? {
        guard let jsonObject = try? PropertyListSerialization.propertyList(from: self, options: [], format: nil) else {
            SmartSentinel.monitorAndPrint(debugDescription: "Failed to convert PropertyList Data to JSON Data.", in: type)
            return nil
        }

        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            SmartSentinel.monitorAndPrint(debugDescription: "Failed to convert PropertyList Data to JSON Data.", in: type)
            return nil
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            return jsonData
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "Failed to convert PropertyList Data to JSON Data. ", error: error, in: type)
            return nil
        }
    }
}

extension Dictionary<String, Any> {
    /// 确保字典中的Value类型都支持JSON序列化。
    func toData() -> Data? {
        let jsonCompatibleDict = toJSONCompatibleDict()
        guard JSONSerialization.isValidJSONObject(jsonCompatibleDict) else { return nil }
        return try? JSONSerialization.data(withJSONObject: jsonCompatibleDict)
    }

    private func toJSONCompatibleDict() -> [String: Any] {
        var jsonCompatibleDict: [String: Any] = [:]
        for (key, value) in self {
            jsonCompatibleDict[key] = convertToJSONCompatible(value: value)
        }
        return jsonCompatibleDict
    }

    /// 目前只处理了Data类型。如有需要可以继续扩展补充。
    private func convertToJSONCompatible(value: Any) -> Any {
        if let data = value as? Data {
            return data.base64EncodedString()
        } else if let dict = value as? [String: Any] {
            return dict.toJSONCompatibleDict()
        } else if let array = value as? [Any] {
            return array.map { convertToJSONCompatible(value: $0) }
        } else {
            return value
        }
    }

    fileprivate func toJSONString() -> String? {
        guard let data = toData() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Array {
    fileprivate func toData() -> Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        return try? JSONSerialization.data(withJSONObject: self)
    }

    fileprivate func toJSONString() -> String? {
        guard let data = toData() else { return nil }
        if let json = String(data: data, encoding: String.Encoding.utf8) {
            return json
        }
        return nil
    }
}

/// 通过路径获取待解析的信息，再转换成data，提供给decoder解析。
private func getInnerData(inside value: Any?, by designatedPath: String?) -> Data? {
    func toObject(_ value: Any?) -> Any? {
        switch value {
        case let data as Data:
            return data.toObject() // 确保这里 toObject() 方法是有效且能正确处理 Data 的。
        case let json as String:
            return Data(json.utf8).toObject() // 直接使用 Data 初始化器。
        case let dict as [String: Any]:
            return dict
        case let arr as [Any]:
            return arr
        default:
            return nil
        }
    }

    func toData(_ value: Any?) -> Data? {
        switch value {
        case let data as Data:
            return data
        case let str as String:
            return Data(str.utf8)
        case let dict as [String: Any]:
            return dict.toData()
        case let arr as [Any]:
            return arr.toData()
        default:
            break
        }
        return nil
    }

    func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
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

    if let path = designatedPath, !path.isEmpty {
        let obj = toObject(value)
        let inner = getInnerObject(inside: obj, by: path)
        return toData(inner)
    } else {
        return toData(value)
    }
}

private func logNilValue(for valueType: String, on modelType: Any.Type) {
    SmartSentinel.monitorAndPrint(debugDescription: "Decoding \(modelType) failed because input \(valueType) is nil.", in: modelType)
}

private func logDataExtractionFailure(forPath path: String?, type: Any.Type) {
    SmartSentinel.monitorAndPrint(debugDescription: "Decoding \(type) failed because it was unable to extract valid data from path '\(path ?? "nil")'.", in: type)
}

public protocol SmartEncodable: Encodable {
    /// The callback for when mapping is complete
    mutating func didFinishMapping()

    /// The mapping relationship of decoding keys
    static func mappingForKey() -> [SmartKeyTransformer]?

    /// The strategy for decoding values
    static func mappingForValue() -> [SmartValueTransformer]?

    init()
}

/// Options for SmartCodable parsing
public enum SmartEncodingOption: Hashable {
    /// date的默认策略是ReferenceDate（参考日期是指2001年1月1日 00:00:00 UTC），以秒为单位。
    case date(JSONEncoder.DateEncodingStrategy)

    case data(JSONEncoder.SmartDataEncodingStrategy)

    case float(JSONEncoder.NonConformingFloatEncodingStrategy)

    /// The mapping strategy for keys during parsing
    case key(JSONEncoder.SmartKeyEncodingStrategy)

    /// Handles the hash value, ignoring the impact of associated values.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .date:
            hasher.combine(0)
        case .data:
            hasher.combine(1)
        case .float:
            hasher.combine(2)
        case .key:
            hasher.combine(3)
        }
    }

    public static func ==(lhs: SmartEncodingOption, rhs: SmartEncodingOption) -> Bool {
        switch (lhs, rhs) {
        case (.date, .date):
            return true
        case (.data, .data):
            return true
        case (.float, .float):
            return true
        case (.key, .key):
            return true
        default:
            return false
        }
    }
}

extension SmartEncodable {
    /// Serializes into a dictionary
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    ///   -- CodingKeys.array <--- "out_array", 为ture时，使用"out_array"。
    /// - Parameter options: encoding options
    /// - Returns: dictionary

    /// Serializes the object into a dictionary representation.
    ///
    /// - Parameters:
    ///   - useMappedKeys: Determines whether to use source field names defined in `SmartKeyTransformer` during encoding.
    ///     - When `true`: Uses the first field name from `SmartKeyTransformer.from` (e.g., given `property <--- ["json_field", "alt_field"]`, uses `"json_field"`)
    ///     - When `false` (default): Uses the destination property name from `SmartKeyTransformer.to`
    ///   - options: Optional set of encoding configuration options that control serialization behavior
    ///
    /// - Returns: A dictionary representation of the object, or `nil` if encoding fails
    ///
    /// - Example:
    ///   ```
    ///   struct Model: SmartCodable {
    ///       var data: String
    ///       static func mappingForKey() -> [SmartKeyTransformer]? {
    ///           [CodingKeys.data <--- ["json_data", "alt_data"]]
    ///       }
    ///   }
    ///
    ///   let model = Model(data: "value")
    ///   let dict1 = model.toDictionary() // ["data": "value"]
    ///   let dict2 = model.toDictionary(useMappedKeys: true) // ["json_data": "value"]
    ///   ```
    public func toDictionary(options: Set<SmartEncodingOption>? = nil) -> [String: Any]? {
        _transformToJson(self, type: Self.self, options: options)
    }

    /// Serializes into a JSON string
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Parameter options: encoding options
    /// - Parameter prettyPrint: Whether to format print (adds line breaks in the JSON)
    /// - Returns: JSON string
    public func toJSONString(options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toDictionary(options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Self.self)
        }
        return nil
    }
}

extension Array where Element: SmartEncodable {
    /// Serializes into a array
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Returns: array
    public func toArray(options: Set<SmartEncodingOption>? = nil) -> [Any]? {
        _transformToJson(self, type: Element.self, options: options)
    }

    /// Serializes into a JSON string
    /// - Parameter useMappedKeys: Whether to use the mapped key during encoding. The default value is false.
    /// - Parameter options: encoding options
    /// - Parameter prettyPrint: Whether to format print (adds line breaks in the JSON)
    /// - Returns: JSON string
    public func toJSONString(options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toArray(options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Element.self)
        }
        return nil
    }
}

private func _transformToJson<T>(_ some: Encodable, type: Any.Type, options: Set<SmartEncodingOption>? = nil) -> T? {
    let jsonEncoder = SmartJSONEncoder()

    if let _options = options ?? SmartModelConfiguration.shared.encodingOptions {
        for _option in _options {
            switch _option {
            case let .data(strategy):
                jsonEncoder.smartDataEncodingStrategy = strategy

            case let .date(strategy):
                jsonEncoder.dateEncodingStrategy = strategy

            case let .float(strategy):
                jsonEncoder.nonConformingFloatEncodingStrategy = strategy

            case let .key(strategy):
                jsonEncoder.smartKeyEncodingStrategy = strategy
            }
        }
    }

    if let jsonData = try? jsonEncoder.encode(some) {
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
            if let temp = json as? T {
                return temp
            } else {
                SmartSentinel.monitorAndPrint(debugDescription: "\(json)) is not a valid Type, wanted \(T.self) type.", error: nil, in: type)
            }
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "'JSONSerialization.jsonObject(:)' falied", error: nil, in: type)
        }
    }
    return nil
}

private func _transformToJsonString(object: Any, prettyPrint: Bool = false, type: Any.Type) -> String? {
    if JSONSerialization.isValidJSONObject(object) {
        do {
            let options: JSONSerialization.WritingOptions = prettyPrint ? [.prettyPrinted] : []
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: options)
            return String(data: jsonData, encoding: .utf8)

        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "'JSONSerialization.data(:)' falied", error: error, in: type)
        }
    } else {
        SmartSentinel.monitorAndPrint(debugDescription: "\(object)) is not a valid JSON Object", error: nil, in: type)
    }
    return nil
}

public struct SmartUpdater<T: SmartCodable> {
    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A Data object containing the JSON data.
    public static func update(_ dest: inout T, from src: Data?) {
        guard let src else { return }

        guard let dict = try? JSONSerialization.jsonObject(with: src, options: .mutableContainers) as? [String: Any] else {
            return
        }
        update(&dest, from: dict)
    }

    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A String object containing the JSON data.
    public static func update(_ dest: inout T, from src: String?) {
        guard let src else { return }

        guard let data = src.data(using: .utf8) else { return }

        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }

        update(&dest, from: dict)
    }

    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    /// - Parameters:
    ///   - dest: A reference to the target object (the inout keyword indicates that this object will be modified within the method).
    ///   - src: A Dictionary object containing the JSON data.
    public static func update(_ dest: inout T, from src: [String: Any]?) {
        guard let src else { return }
        var destDict = dest.toDictionary() ?? [:]
        updateDict(&destDict, from: src)
        if let model = T.deserialize(from: destDict) {
            dest = model
        }
    }
}

extension SmartUpdater {
    /// 合并字典，将src合并到dest
    /// - Parameters:
    ///   - dest: 目标字典
    ///   - src: 源字典
    fileprivate static func updateDict(_ dest: inout [String: Any], from src: [String: Any]) {
        dest.merge(src) { _, new in
            new
        }
    }
}

// MARK: - SmartType
public protocol SmartCaseDefaultable: RawRepresentable, Codable, CaseIterable {}
extension SmartCaseDefaultable where Self: Decodable, Self.RawValue: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(RawValue.self)
        if let v = Self(rawValue: decoded) {
            self = v
        } else {
            let des = "Cannot initialize \(Self.self) from invalid \(RawValue.self) value `\(decoded)`"
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: des))
        }
    }
}

public protocol SmartAssociatedEnumerable: Codable {
    static var defaultCase: Self { get }
    /// 如果你需要考虑encode，请实现它
    func encodeValue() -> Encodable?
}

extension SmartAssociatedEnumerable {
    public func encodeValue() -> Encodable? { nil }
}

extension SmartAssociatedEnumerable {
    public init(from decoder: Decoder) throws {
        guard let _decoder = decoder as? JSONDecoderImpl else {
            let des = "Cannot initiali"
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: des))
        }

        guard let tranformer = _decoder.cache.valueTransformer(for: _decoder.codingPath.last),
              let decoded = tranformer.tranform(value: _decoder.json) as? Self else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: _decoder.codingPath, debugDescription: "No custom parsing policy is implemented for associated value enumerations"))
        }
        self = decoded
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = encodeValue() {
            try container.encode(value)
        }
    }
}

// MARK: - Sentinel
/// Central logging configuration and utilities
public enum SmartSentinel {
    /// Set debugging mode, default is none.
    /// Note: When not debugging, set to none to reduce overhead.
    public static var debugMode: Level {
        get { FrameworkConfiguration.smartModelMode }
        set { FrameworkConfiguration.smartModelMode = newValue }
    }

    /// 设置回调方法，传递解析完成时的日志记录
    public static func onLogGenerated(handler: @escaping (String) -> Void) {
        handlerQueue.sync {
            logsHandler = handler
        }
    }

    /// Set up different levels of padding
    public static let space: String = "   "
    /// Set the markup for the model
    public static let keyContainerSign: String = "╆━ "

    public static let unKeyContainerSign: String = "╆━ "

    /// Sets the tag for the property
    public static let attributeSign: String = "┆┄ "

    /// 是否满足日志记录的条件
    fileprivate static var isValid: Bool {
        debugMode != .none
    }

    private static var cache: LogCache {
        get { FrameworkConfiguration.smartModelCache }
        set { FrameworkConfiguration.smartModelCache = newValue }
    }

    /// 回调闭包，用于在解析完成时传递日志
    private static var logsHandler: ((String) -> Void)? {
        get { FrameworkConfiguration.smartModelHandler }
        set { FrameworkConfiguration.smartModelHandler = newValue }
    }

    /// 用于同步访问 logsHandler 的队列Add commentMore actions
    private static let handlerQueue = DispatchQueue(label: "com.smartcodable.handler", qos: .utility)
}

extension SmartSentinel {
    static func monitorLog<T>(impl: JSONDecoderImpl, isOptionalLog: Bool = false,
                              forKey key: CodingKey?, value: JSONValue?, type: T.Type) {
        guard SmartSentinel.debugMode != .none else { return }
        guard let key else { return }
        // 如果被忽略了，就不要输出log了。
        let typeString = String(describing: T.self)
        guard !typeString.starts(with: "IgnoredKey<") else { return }

        let className = impl.cache.topSnapshot?.objectTypeName ?? ""
        var path = impl.codingPath
        path.append(key)

        var address = ""
        if let parsingMark = CodingUserInfoKey.parsingMark {
            address = impl.userInfo[parsingMark] as? String ?? ""
        }

        if let entry = value {
            if entry.isNull { // 值为null
                if isOptionalLog { return }
                let error = DecodingError._valueNotFound(key: key, expectation: T.self, codingPath: path)
                SmartSentinel.verboseLog(error, className: className, parsingMark: address)
            } else { // value类型不匹配
                let error = DecodingError._typeMismatch(at: path, expectation: T.self, desc: entry.debugDataTypeDescription)
                SmartSentinel.alertLog(error: error, className: className, parsingMark: address)
            }
        } else { // key不存在或value为nil
            if isOptionalLog { return }
            let error = DecodingError._keyNotFound(key: key, codingPath: path)
            SmartSentinel.verboseLog(error, className: className, parsingMark: address)
        }
    }

    private static func verboseLog(_ error: DecodingError, className: String, parsingMark: String) {
        logIfNeeded(level: .verbose) {
            cache.save(error: error, className: className, parsingMark: parsingMark)
        }
    }

    private static func alertLog(error: DecodingError, className: String, parsingMark: String) {
        logIfNeeded(level: .alert) {
            cache.save(error: error, className: className, parsingMark: parsingMark)
        }
    }

    static func monitorLogs(in name: String, parsingMark: String, impl: JSONDecoderImpl) {
        guard SmartSentinel.isValid else { return }

        var header: String?
        if let key = CodingUserInfoKey.logContextHeader {
            header = impl.userInfo[key] as? String
        }

        var footer: String?
        if let key = CodingUserInfoKey.logContextFooter {
            footer = impl.userInfo[key] as? String
        }

        if let format = cache.formatLogs(parsingMark: parsingMark) {
            let message = getHeader(context: header)
                + name
                + " 👈🏻 👀\n"
                + format
                + getFooter(context: footer)
            print(message)

            handlerQueue.sync {
                if let handler = logsHandler {
                    DispatchQueue.main.async {
                        handler(message)
                    }
                }
            }
        }

        cache.clearCache(parsingMark: parsingMark)
    }
}

extension SmartSentinel {
    static func monitorAndPrint(level: SmartSentinel.Level = .alert, debugDescription: String, error: Error? = nil, in inType: Any.Type?) {
        logIfNeeded(level: level) {
            let decodingError = (error as? DecodingError) ?? DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: debugDescription, underlyingError: error))
            if let logItem = LogItem.make(with: decodingError) {
                let message = getHeader()
                    + (inType != nil ? "\(inType!) 👈🏻 👀\n" : "")
                    + logItem.formartMessage + "\n"
                    + getFooter()
                print(message)

                handlerQueue.sync {
                    if let handler = logsHandler {
                        DispatchQueue.main.async {
                            handler(message)
                        }
                    }
                }
            }
        }
    }
}

extension SmartSentinel {
    /// 生成唯一标记，用来标记是否本次解析。
    static func parsingMark() -> String {
        let mark = "SmartMark" + UUID().uuidString
        return mark
    }
}

extension SmartSentinel {
    public enum Level: Int, Sendable {
        /// 不记录日志
        case none
        /// 详细的日志
        case verbose
        /// 警告日志：仅仅包含类型不匹配的情况
        case alert
    }

    static func getHeader(context: String? = nil) -> String {
        let line = "\n================================  [Smart Sentinel]  ================================\n"

        if let c = context, !c.isEmpty {
            return line + c + "\n\n"

        } else {
            return line
        }
    }

    static func getFooter(context: String? = nil) -> String {
        let line = "====================================================================================\n"

        if let c = context, !c.isEmpty {
            return "\n" + c + "\n" + line
        } else {
            return line
        }
    }

    private static func logIfNeeded(level: SmartSentinel.Level, callback: () -> Void) {
        if SmartSentinel.debugMode.rawValue <= level.rawValue {
            callback()
        }
    }
}

class SafeDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]

    private let lock = NSLock()

    func getValue(forKey key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return dictionary[key]
    }

    func setValue(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        dictionary[key] = value
    }

    func removeValue(forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        dictionary.removeValue(forKey: key)
    }

    /// 新增：按条件批量移除键值对
    func removeValue(where shouldRemove: (Key) -> Bool) {
        lock.lock()
        defer { lock.unlock() }
        dictionary = dictionary.filter { !shouldRemove($0.key) }
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        dictionary.removeAll()
    }

    func getAllValues() -> [Value] {
        lock.lock()
        defer { lock.unlock() }
        return Array(dictionary.values)
    }

    func getAllKeys() -> [Key] {
        lock.lock()
        defer { lock.unlock() }
        return Array(dictionary.keys)
    }

    func updateEach(_ body: (Key, inout Value) throws -> Void) rethrows {
        lock.lock()
        defer { lock.unlock() }
        var updatedDictionary: [Key: Value] = [:]
        for (key, var value) in dictionary {
            try body(key, &value)
            updatedDictionary[key] = value
        }
        dictionary = updatedDictionary
    }
}

struct LogCache {
    private var snapshotDict = SafeDictionary<String, LogContainer>()

    /// Saves a decoding error to the log cache
    mutating func save(error: DecodingError, className: String, parsingMark: String) {
        let log = LogItem.make(with: error)
        cacheLog(log, className: className, parsingMark: parsingMark)
    }

    /// Clears cached logs for a specific parsing session
    mutating func clearCache(parsingMark: String) {
        snapshotDict.removeValue { $0.hasPrefix(parsingMark) }
    }

    /// Formats all logs for a parsing session into a readable string
    mutating func formatLogs(parsingMark: String) -> String? {
        filterLogItem()

        alignTypeNamesInAllSnapshots(parsingMark: parsingMark)

        let keyOrder = sortKeys(snapshotDict.getAllKeys(), parsingMark: parsingMark)

        var lastPath = ""
        let arr = keyOrder.compactMap {
            let container = snapshotDict.getValue(forKey: $0)
            let message = container?.formatMessage(previousPath: lastPath)
            lastPath = container?.path ?? ""
            return message
        }

        if arr.isEmpty { return nil }
        return arr.joined()
    }
}

extension LogCache {
    /// Sorts log keys for consistent output ordering
    func sortKeys(_ array: [String], parsingMark: String) -> [String] {
        //  获取当前解析的keys
        let filterArray = array.filter {
            $0.starts(with: parsingMark)
        }
        guard !filterArray.isEmpty else { return [] }

        let sortedArray = filterArray.sorted()
        return sortedArray
    }

    /// Filters duplicate log items across containers
    mutating func filterLogItem() {
        let pattern = "Index \\d+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        var matchedKeys = snapshotDict.getAllKeys().filter { key in
            let range = NSRange(key.startIndex..<key.endIndex, in: key)
            return regex.firstMatch(in: key, options: [], range: range) != nil
        }

        matchedKeys = matchedKeys.sorted(by: <)

        var allLogs: [LogItem] = []

        let tempDict = snapshotDict
        for key in matchedKeys {
            var lessLogs: [LogItem] = []
            if var snap = snapshotDict.getValue(forKey: key) {
                let logs = snap.logs
                for log in logs {
                    if !allLogs.contains(where: { $0 == log }) {
                        lessLogs.append(log)
                        allLogs.append(log)
                    }
                }

                if lessLogs.isEmpty {
                    tempDict.removeValue(forKey: key)
                } else {
                    snap.logs = lessLogs
                    tempDict.setValue(snap, forKey: key)
                }
            }
        }
        snapshotDict = tempDict
    }

    /// Caches an individual log item
    private mutating func cacheLog(_ log: LogItem?, className: String, parsingMark: String) {
        guard let log else { return }

        let path = log.codingPath
        let key = createKey(path: path, parsingMark: parsingMark)

        // 如果存在相同的typeName和path，则合并logs
        if var existingSnapshot = snapshotDict.getValue(forKey: key) {
            if !existingSnapshot.logs.contains(where: { $0 == log }) {
                existingSnapshot.logs.append(log)
                snapshotDict.setValue(existingSnapshot, forKey: key)
            }
        } else {
            // 创建新的snapshot并添加到字典中
            let newSnapshot = LogContainer(typeName: className, codingPath: path, logs: [log], parsingMark: parsingMark)
            snapshotDict.setValue(newSnapshot, forKey: key)
        }
    }

    /// Creates a unique key for a log entry
    private func createKey(path: [CodingKey], parsingMark: String) -> String {
        let arr = path.map { $0.stringValue }
        return parsingMark + "\(arr.joined(separator: "-"))"
    }

    /// Aligns field names for consistent visual output
    private mutating func alignTypeNamesInAllSnapshots(parsingMark: String) {
        snapshotDict.updateEach { _, snapshot in
            let maxLength = snapshot.logs.max(by: { $0.fieldName.count < $1.fieldName.count })?.fieldName.count ?? 0
            snapshot.logs = snapshot.logs.map { log in
                var modifiedLog = log
                modifiedLog.fieldName = modifiedLog.fieldName.padding(toLength: maxLength, withPad: " ", startingAt: 0)
                return modifiedLog
            }
        }
    }
}

/// Represents a container of related log entries with common coding path
struct LogContainer {
    /// 当前容器的类型（如果是unkeyed，就是Index+X。如果是keyed，就是Model的名称）
    var typeName: String

    /// 容器的路径
    var codingPath: [CodingKey] = []
    var path: String {
        let arr = codingPath.map {
            if let index = $0.intValue {
                return "Index \(index)"
            } else {
                return $0.stringValue
            }
        }
        return arr.joined(separator: "/")
    }

    // 当前容器下，解析错误的属性日志
    var logs: [LogItem] = []

    /// 用来从属哪次解析，以便做聚合
    var parsingMark: String

    var isUnKeyed: Bool {
        codingPath.last?.intValue != nil
    }

    var formatTypeName: String {
        isUnKeyed ? "[\(typeName)]" : typeName
    }

    /** pay attention to it
     1. 每一条path都是完整的解析路径。
     2. 路径中的每一个点都是container（keyed or unkeyed）。
     3. 这是当前container的logs。
     4. container信息包含两部分，
       - 4.1 如何体现容器本身的信息。
       - 4.2 如何体现容器中属性的信息。
     5. 根据path的层级控制tabs（空格）的多少，做到格式化。
     */
    func formatMessage(previousPath: String) -> String {
        var message = ""
        let components = comparePaths(previousPath: previousPath, currentPath: path)
        let commons = components.commons
        let differents = components.differents

        // 即将要显示的container距离左侧的距离
        let currentTabs = String(repeating: SmartSentinel.space, count: commons.count + 1)

        // 容器的信息
        for (index, item) in differents.enumerated() {
            let typeName = item.hasPrefix("Index ") ? "" : ": \(formatTypeName)"

            let sign = isUnKeyed ? SmartSentinel.unKeyContainerSign : SmartSentinel.keyContainerSign
            let containerInfo = "\(sign)\(item)\(typeName)\n"
            let tabs = currentTabs + String(repeating: SmartSentinel.space, count: index)
            message += "\(tabs)\(containerInfo)"
        }

        // 属性信息
        let fieldTabs = currentTabs + String(repeating: SmartSentinel.space, count: differents.count)
        for log in logs {
            message += "\(fieldTabs)\(SmartSentinel.attributeSign)\(log.formartMessage)"
        }

        return message
    }

    private func comparePaths(previousPath: String, currentPath: String) -> (commons: [String], differents: [String]) {
        // 将路径按照斜杠分割为路径点（整体处理空格）
        let previousComponents = previousPath.split(separator: "/")
        let currentComponents = currentPath.split(separator: "/")

        // 用于存储相同路径点
        var commonComponents: [String] = []
        // 找到相同路径点
        for (prev, curr) in zip(previousComponents, currentComponents) {
            if prev == curr {
                commonComponents.append(String(prev))
            } else {
                break
            }
        }
        let differentComponents = currentComponents.dropFirst(commonComponents.count).map { String($0) }
        return (commonComponents, differentComponents)
    }
}

extension LogItem: Equatable {
    static func ==(lhs: LogItem, rhs: LogItem) -> Bool {
        lhs.fieldName == rhs.fieldName &&
            lhs.logType == rhs.logType &&
            lhs.logDetail == rhs.logDetail &&
            areCodingKeysEqual(lhs.codingPath, rhs.codingPath)
    }

    static func areCodingKeysEqual(_ lhs: [CodingKey], _ rhs: [CodingKey]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy {
            let key0 = $0.intValue != nil ? "Index X" : $0.stringValue
            let key1 = $1.intValue != nil ? "Index X" : $1.stringValue
            return key0 == key1
        }
    }
}

struct LogItem {
    /// 字段名称
    var fieldName: String
    /// 错误类型
    private var logType: String
    /// 错误原因
    private var logDetail: String

    private(set) var codingPath: [CodingKey]

    init(fieldName: String, logType: String, logDetail: String, codingPath: [CodingKey]) {
        self.fieldName = fieldName
        self.logType = logType
        self.logDetail = logDetail
        self.codingPath = codingPath
    }

    var formartMessage: String {
        if fieldName.isEmpty {
            return "\(logDetail)"
        } else {
            return "\(fieldName): \(logDetail)\n"
        }
    }
}

extension LogItem {
    static func make(with error: DecodingError) -> LogItem? {
        switch error {
        case let .keyNotFound(key, context):
            let codingPath = context.codingPath.removeFromEnd(1) ?? []
            return LogItem(fieldName: key.stringValue, logType: "MISSING KEY", logDetail: "No value associated with key.", codingPath: codingPath)

        case let .valueNotFound(_, context):
            let codingPath = context.codingPath.removeFromEnd(1) ?? []
            let key = context.codingPath.last?.stringValue ?? ""
            return LogItem(fieldName: key, logType: "NULL VALUE", logDetail: context.debugDescription, codingPath: codingPath)

        case let .typeMismatch(_, context):
            let codingPath = context.codingPath.removeFromEnd(1) ?? []
            let key = context.codingPath.last?.stringValue ?? ""
            return LogItem(fieldName: key, logType: "TYPE MISMATCH", logDetail: context.debugDescription, codingPath: codingPath)

        case let .dataCorrupted(context):
            let codingPath = context.codingPath.removeFromEnd(1) ?? []
            let key = context.codingPath.last?.stringValue ?? ""
            return LogItem(fieldName: key, logType: "DATA CORRUPTED", logDetail: context.debugDescription, codingPath: codingPath)

        default:
            break
        }

        return nil
    }
}

extension Array {
    fileprivate func removeFromEnd(_ count: Int) -> [Element]? {
        guard count >= 0 else { return nil }
        let endIndex = self.count - count
        guard endIndex >= 0 else { return nil }
        return Array(prefix(endIndex))
    }
}

// MARK: - PropertyWrapper
@propertyWrapper
public struct IgnoredKey<T>: Codable {
    /// The underlying value being wrapped
    public var wrappedValue: T

    /// Determines whether this property should be included in encoding
    var isEncodable: Bool = true

    /// Initializes an IgnoredKey with a wrapped value and encoding control
    /// - Parameters:
    ///   - wrappedValue: The initial/default value
    ///   - isEncodable: Whether the property should be included in encoding (default: false)
    public init(wrappedValue: T, isEncodable: Bool = false) {
        self.wrappedValue = wrappedValue
        self.isEncodable = isEncodable
    }

    public init(from decoder: Decoder) throws {
        // Attempt to get default value first
        guard let impl = decoder as? JSONDecoderImpl else {
            self.wrappedValue = try Patcher<T>.defaultForType()
            return
        }

        // Support for custom decoding strategies on IgnoredKey properties
        if let key = impl.codingPath.last {
            if let tranformer = impl.cache.valueTransformer(for: key) {
                if let decoded = tranformer.tranform(value: impl.json) as? T {
                    self.wrappedValue = decoded
                    return
                }
            }
        }

        /// Special handling for SmartJSONDecoder parser - throws exceptions to be handled by container
        if let key = CodingUserInfoKey.parsingMark, let _ = impl.userInfo[key] {
            throw DecodingError.typeMismatch(IgnoredKey<T>.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "\(Self.self) does not participate in the parsing, please ignore it."
            ))
        }

        /// The resolution triggered by the other three parties may be resolved here.
        self.wrappedValue = try impl.smartDecode(type: T.self)
    }

    public func encode(to encoder: Encoder) throws {
        guard isEncodable else { return }

        if let impl = encoder as? JSONEncoderImpl,
           let key = impl.codingPath.last,
           let jsonValue = impl.cache.tranform(from: wrappedValue, with: key),
           let value = jsonValue.peel as? Encodable {
            try value.encode(to: encoder)
            return
        }

        // Manual encoding for Encodable types, nil otherwise
        if let encodableValue = wrappedValue as? Encodable {
            try encodableValue.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

extension JSONDecoderImpl {
    fileprivate func smartDecode<T>(type: T.Type) throws -> T {
        try cache.initialValue(forKey: codingPath.last)
    }
}

/// A marker protocol for property wrappers that need lifecycle callbacks.
protocol PostDecodingHookable {
    /**
     Callback invoked when the wrapped value finishes decoding/mapping.

     - Returns: An optional new instance of the wrapper with processed value
     - Note: Primarily used by property wrappers containing types conforming to SmartDecodable
     */
    func wrappedValueDidFinishMapping() -> Self?
}

/**
 Protocol defining requirements for types that can publish wrapped Codable values.

 Provides a unified interface for any type conforming to this protocol.
 - WrappedValue: The generic type that must conform to Codable
 - createInstance: Attempts to create an instance from any value
 */
public protocol PropertyWrapperInitializable {
    associatedtype WrappedValue

    var wrappedValue: WrappedValue { get }

    init(wrappedValue: WrappedValue)

    static func createInstance(with value: Any) -> Self?
}

@propertyWrapper
public struct SmartDate: Codable {
    public var wrappedValue: Date?
    private var encodeFormat: DateStrategy?

    public init(wrappedValue: Date?, encodeFormat: SmartDate.DateStrategy? = nil) {
        self.wrappedValue = wrappedValue
        self.encodeFormat = encodeFormat
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let raw: Any
        if let double = try? container.decode(Double.self) {
            raw = double
        } else if let string = try? container.decode(String.self) {
            raw = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date value")
        }

        guard let (date, format) = DateParser.parse(raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(raw)")
        }

        self.wrappedValue = date
        if encodeFormat == nil {
            self.encodeFormat = format
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let date = wrappedValue else {
            return try container.encodeNil()
        }

        let format = encodeFormat ?? .timestamp

        switch format {
        case .timestamp:
            try container.encode(date.timeIntervalSince1970)
        case .timestampMilliseconds:
            try container.encode(Int(date.timeIntervalSince1970 * 1000))
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: date))
        case let .formatted(format):
            try container.encode(format.string(from: date))
        }
    }
}

extension SmartDate {
    public enum DateStrategy {
        case timestamp // seconds
        case timestampMilliseconds // milliseconds
        case iso8601
        case formatted(DateFormatter) // custom date format
    }
}

enum DateParser {
    private static let knownFormats: [String] = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd",
        "yyyy/MM/dd",
        "MM/dd/yyyy",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    ]

    // https://developer.apple.com/library/archive/qa/qa1480/_index.html
    private static let locale = Locale(identifier: "en_US_POSIX")

    static func parse(_ raw: Any) -> (Date, SmartDate.DateStrategy)? {
        if let result = parseTimestamp(from: raw) {
            return result
        }

        if let string = raw as? String {
            // try knownFormats
            let formatter = DateFormatter()
            formatter.locale = locale
            for format in knownFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: string) {
                    return (date, .formatted(formatter))
                }
            }

            // 尝试 ISO8601 yyyy-MM-dd'T'HH:mm:ssZ
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: string) {
                return (date, .iso8601)
            }
        }

        return nil
    }

    private static func parseTimestamp(from raw: Any) -> (Date, SmartDate.DateStrategy)? {
        if let double = raw as? Double ?? Double(raw as? String ?? "") {
            if double > 1_000_000_000_000 {
                return (Date(timeIntervalSince1970: double / 1000), .timestampMilliseconds)
            } else {
                return (Date(timeIntervalSince1970: double), .timestamp)
            }
        }
        return nil
    }
}

@propertyWrapper
public struct SmartFlat<T: Codable>: Codable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        do {
            self.wrappedValue = try T(from: decoder)
        } catch {
            self.wrappedValue = try Patcher<T>.defaultForType()
        }
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension SmartFlat: PostDecodingHookable {
    func wrappedValueDidFinishMapping() -> SmartFlat<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartFlat(wrappedValue: temp as! T)
        }
        return nil
    }
}

extension SmartFlat: PropertyWrapperInitializable {
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartFlat? {
        if let value = value as? T {
            return SmartFlat(wrappedValue: value)
        }
        return nil
    }
}

// Used to mark the flat type
protocol FlatType {
    static var isArray: Bool { get }
}

extension SmartFlat: FlatType {
    /// Determines if the wrapped type is an array
    static var isArray: Bool { T.self is _ArrayMark.Type }
}

/**
 Marker protocol for array types with Decodable elements.

 When T is an array with elements conforming to Decodable,
 T.self will be covered by the Array extension, making T.self is _ArrayMark.Type return true.
 */
protocol _ArrayMark {}

/// This extension marks Array types as _ArrayMark when their Element conforms to Decodable.
/// This means only arrays with Decodable elements will be marked as _ArrayMark.
extension Array: _ArrayMark where Element: Decodable {}

@propertyWrapper
public struct SmartHexColor: Codable {
    public var wrappedValue: UIColor?

    private var encodeHexFormat: HexFormat?

    public init(wrappedValue: UIColor?, encodeHexFormat: HexFormat? = nil) {
        self.wrappedValue = wrappedValue
        self.encodeHexFormat = encodeHexFormat
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)

        guard
            let format = SmartHexColor.HexFormat.format(for: hexString),
            let color = SmartHexColor.toColor(from: hexString, format: format)
        else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode SmartHexColor from '\(hexString)'. Supported formats: HexFormat."
            )
        }

        if encodeHexFormat == nil {
            self.encodeHexFormat = format
        }
        self.wrappedValue = color
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let color = wrappedValue else {
            return try container.encodeNil() // 更明确地记录 nil
        }

        let format = encodeHexFormat ?? .rrggbb(.none)

        guard let hexString = SmartHexColor.toHexString(from: color, format: format) else {
            throw EncodingError.invalidValue(
                color,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Failed to convert color to hex string with format \(format)"
                )
            )
        }

        try container.encode(hexString)
    }
}

extension SmartHexColor {
    public static func toColor(from hex: String, format: SmartHexColor.HexFormat) -> UIColor? {
        // 1. 移除前缀
        let hexString = normalizedHexString(from: hex, prefix: format.prefix)

        // 2. 将字符串转换为 UInt64
        guard let hexValue = UInt64(hexString, radix: 16) else { return nil }

        // 3. 按格式解析颜色分量
        func component(_ value: UInt64, shift: Int, mask: UInt64) -> CGFloat {
            CGFloat((value >> shift) & mask) / 255
        }

        let r, g, b, a: CGFloat

        switch format {
        case .rgb:
            r = CGFloat((hexValue >> 8) & 0xF) / 15
            g = CGFloat((hexValue >> 4) & 0xF) / 15
            b = CGFloat(hexValue & 0xF) / 15
            a = 1.0

        case .rgba:
            r = CGFloat((hexValue >> 12) & 0xF) / 15
            g = CGFloat((hexValue >> 8) & 0xF) / 15
            b = CGFloat((hexValue >> 4) & 0xF) / 15
            a = CGFloat(hexValue & 0xF) / 15

        case .rrggbb:
            r = component(hexValue, shift: 16, mask: 0xFF)
            g = component(hexValue, shift: 8, mask: 0xFF)
            b = component(hexValue, shift: 0, mask: 0xFF)
            a = 1.0

        case .rrggbbaa:
            r = component(hexValue, shift: 24, mask: 0xFF)
            g = component(hexValue, shift: 16, mask: 0xFF)
            b = component(hexValue, shift: 8, mask: 0xFF)
            a = component(hexValue, shift: 0, mask: 0xFF)
        }

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// 移除前缀并转小写
    private static func normalizedHexString(from hex: String, prefix: String) -> String {
        let trimmedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !prefix.isEmpty, trimmedHex.hasPrefix(prefix.lowercased()) {
            return String(trimmedHex.dropFirst(prefix.count))
        } else {
            return trimmedHex
        }
    }

    static func toHexString(from color: UIColor, format: SmartHexColor.HexFormat) -> String? {
        guard let components = color.rgbaComponents else { return nil }

        func clamped255(_ value: CGFloat) -> Int {
            min(max(Int(value * 255), 0), 255)
        }

        let r = clamped255(components.r)
        let g = clamped255(components.g)
        let b = clamped255(components.b)
        let a = clamped255(components.a)

        switch format {
        case let .rgb(prefix):
            return prefix.rawValue + String(format: "%01X%01X%01X", r >> 4, g >> 4, b >> 4)

        case let .rgba(prefix):
            return prefix.rawValue + String(format: "%01X%01X%01X%01X", r >> 4, g >> 4, b >> 4, a >> 4)

        case let .rrggbb(prefix):
            return prefix.rawValue + String(format: "%02X%02X%02X", r, g, b)

        case let .rrggbbaa(prefix):
            return prefix.rawValue + String(format: "%02X%02X%02X%02X", r, g, b, a)
        }
    }
}

extension SmartHexColor {
    /// 定义 16 进制颜色代码的格式（支持带 `#` 和不带 `#` 的格式）
    ///
    /// ## 格式说明
    /// - **无透明度**：
    ///   - `RGB`：3 位，例如 `F00`（等价于 `FF0000`）
    ///   - `#RGB`：带 `#` 前缀的 3 位，例如 `#F00`
    ///   - `RRGGBB`：6 位，例如 `FF0000`
    ///   - `#RRGGBB`：带 `#` 前缀的 6 位，例如 `#FF0000`
    ///
    /// - **带透明度**：
    ///   - `RGBA`：4 位，例如 `F008`（等价于 `FF000088`）
    ///   - `#RGBA`：带 `#` 前缀的 4 位，例如 `#F008`
    ///   - `RRGGBBAA`：8 位，例如 `FF000080`
    ///   - `#RRGGBBAA`：带 `#` 前缀的 8 位，例如 `#FF000080`
    ///
    /// > 注意：枚举值名称中的 `hash` 表示格式包含 `#` 前缀。
    public enum HexFormat {
        /// 3 位无透明度（如 `F00`）
        case rgb(Prefix)

        /// 6 位无透明度（如 `FF0000`）
        case rrggbb(Prefix)

        /// 4 位带透明度（如 `F008`）
        case rgba(Prefix)

        /// 8 位带透明度（如 `FF000080`）
        case rrggbbaa(Prefix)

        var prefix: String {
            switch self {
            case let .rgb(prefix):
                return prefix.rawValue
            case let .rrggbb(prefix):
                return prefix.rawValue
            case let .rgba(prefix):
                return prefix.rawValue
            case let .rrggbbaa(prefix):
                return prefix.rawValue
            }
        }

        public enum Prefix {
            case hash
            case zeroX
            case none

            var rawValue: String {
                switch self {
                case .hash:
                    return "#"
                case .zeroX:
                    return "0x"
                case .none:
                    return ""
                }
            }
        }

        /// 根据给定的 hex 字符串，自动识别并返回相应的 `HexFormat`
        static func format(for hexString: String) -> HexFormat? {
            let trimmedHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // 判断是否有前缀并根据不同前缀选择不同的处理方法
            if trimmedHex.hasPrefix("#") {
                let pureHex = String(trimmedHex.dropFirst())
                return detectFormat(from: pureHex, withPrefix: .hash)
            } else if trimmedHex.hasPrefix("0x") {
                let pureHex = String(trimmedHex.dropFirst(2))
                return detectFormat(from: pureHex, withPrefix: .zeroX)
            } else {
                return detectFormat(from: trimmedHex, withPrefix: .none)
            }
        }

        // 自动识别和推断 HexFormat
        private static func detectFormat(from hex: String, withPrefix prefix: Prefix) -> HexFormat? {
            switch hex.count {
            case 3:
                return .rgb(prefix)
            case 4:
                return .rgba(prefix)
            case 6:
                return .rrggbb(prefix)
            case 8:
                return .rrggbbaa(prefix)
            default:
                return nil
            }
        }
    }
}

extension UIColor {
    fileprivate var rgbaComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (r, g, b, a)
    }
}

#if canImport(Combine)
import Combine
import SwiftUI

@propertyWrapper
public struct SmartPublished<Value: Codable>: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Value.self)
        self.wrappedValue = value
        self.publisher = Publisher(wrappedValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    public var wrappedValue: Value {
        // Notify subscribers before value changes
        willSet {
            publisher.subject.send(newValue)
        }
    }

    /// The publisher that exposes the wrapped value's changes
    public var projectedValue: Publisher {
        publisher
    }

    private var publisher: Publisher

    // MARK: - Publisher Implementation

    /**
     The publisher that broadcasts changes to the wrapped value.

     Uses CurrentValueSubject which:
     - Maintains the current value
     - Sends current value to new subscribers
     - More suitable than PassthroughSubject for property wrapper scenarios
     */
    public struct Publisher: Combine.Publisher {
        public typealias Output = Value
        public typealias Failure = Never

        // CurrentValueSubject 是 Combine 中的一种 Subject，它会保存当前值并向新订阅者发送当前值。相比于 PassthroughSubject，它在初始化时就要求有一个初始值，因此更适合这种包装属性的场景。
        var subject: CurrentValueSubject<Value, Never>

        // 这个方法实现了 Publisher 协议，将 subscriber 传递给 subject，从而将订阅者连接到这个发布者上。
        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subject.subscribe(subscriber)
        }

        // Publisher 的构造函数接受一个初始值，并将其传递给 CurrentValueSubject 的初始化方法。
        init(_ output: Output) {
            self.subject = .init(output)
        }
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.publisher = Publisher(wrappedValue)
    }

    /**
     Custom subscript for property wrapper integration with ObservableObject.

     - Parameters:
       - observed: The ObservableObject instance containing this property
       - wrappedKeyPath: Reference to the wrapped value
       - storageKeyPath: Reference to this property wrapper instance
     */
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            // Notify observers before changing value
            if let subject = observed.objectWillChange as? ObservableObjectPublisher {
                subject.send()
                observed[keyPath: storageKeyPath].wrappedValue = newValue
            }
        }
    }
}

extension SmartPublished: PostDecodingHookable {
    /// Handles post-mapping lifecycle events for wrapped values
    func wrappedValueDidFinishMapping() -> SmartPublished<Value>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartPublished(wrappedValue: temp as! Value)
        }
        return nil
    }
}

extension SmartPublished: PropertyWrapperInitializable {
    /// Creates an instance from any value if possible
    public static func createInstance(with value: Any) -> SmartPublished? {
        if let value = value as? Value {
            return SmartPublished(wrappedValue: value)
        }
        return nil
    }
}
#endif

@propertyWrapper
public struct SmartAny<T>: Codable, PropertyWrapperInitializable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public static func createInstance(with value: Any) -> SmartAny<T>? {
        if let value = value as? T {
            return SmartAny(wrappedValue: value)
        }
        return nil
    }

    public init(from decoder: Decoder) throws {
        guard let decoder = decoder as? JSONDecoderImpl else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）"
            ))
        }
        let value = decoder.json
        if let key = decoder.codingPath.last {
            // Note the case where T is nil. nil as? T is true.
            if let tranformer = decoder.cache.valueTransformer(for: key) {
                if let decoded = tranformer.tranform(value: value) as? T {
                    self = .init(wrappedValue: decoded)
                    return
                } else {
                    throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                        codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！"
                    ))
                }
            }
        }

        if let decoded = try? decoder.unwrap(as: SmartAnyImpl.self), let peel = decoded.peel as? T {
            self = .init(wrappedValue: peel)
        } else {
            // 类型检查
            if let _type = T.self as? Decodable.Type {
                if let decoded = try _type.init(from: decoder) as? T {
                    self = .init(wrappedValue: decoded)
                    return
                }
            }

            // Exceptions thrown in the parse container will be compatible.
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！"
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let dict = wrappedValue as? [String: Any] {
            let value = dict.cover
            try container.encode(value)
        } else if let arr = wrappedValue as? [Any] {
            let value = arr.cover
            try container.encode(value)
        } else if let model = wrappedValue as? SmartCodable {
            try container.encode(model)
        } else {
            let value = SmartAnyImpl(from: wrappedValue)
            try container.encode(value)
        }
    }
}

extension SmartAny: PostDecodingHookable {
    func wrappedValueDidFinishMapping() -> SmartAny<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartAny(wrappedValue: temp as! T)
        }
        return nil
    }
}

enum SmartAnyImpl {
    /// In Swift, NSNumber is a composite type that can accommodate various numeric types:
    ///  - All integer types: Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64
    ///  - All floating-point types: Float, Double
    ///  - Boolean type: Bool
    ///
    /// Due to its dynamic nature, it can store different types of numbers and query their specific types at runtime.
    /// This provides a degree of flexibility but also sacrifices the type safety and performance advantages of Swift's native types.
    ///
    /// In the initial implementation, these basic data types were handled separately. For example:
    ///  - case bool(Bool)
    ///  - case double(Double), cgFloat(CGFloat), float(Float)
    ///  - case int(Int), int8(Int8), int16(Int16), int32(Int32), int64(Int64)
    ///  - case uInt(UInt), uInt8(UInt8), uInt16(UInt16), uInt32(UInt32), uInt64(UInt64)
    /// However, during parsing, a situation arises: the data type is forcibly specified, losing the flexibility of NSNumber. For instance, `as? Double` will fail when the data is 5.
    case number(NSNumber)
    case string(String)
    case dict([String: SmartAnyImpl])
    case array([SmartAnyImpl])
    case null(NSNull)

    public init(from value: Any) {
        self = .convertToSmartAny(value)
    }
}

extension Dictionary where Key == String {
    /// Converts from [String: Any] type to [String: SmartAny]
    var cover: [String: SmartAnyImpl] {
        mapValues { SmartAnyImpl(from: $0) }
    }

    /// Unwraps if it exists, otherwise returns itself.
    var peelIfPresent: [String: Any] {
        if let dict = self as? [String: SmartAnyImpl] {
            return dict.peel
        } else {
            return self
        }
    }
}

extension Array {
    var cover: [SmartAnyImpl] {
        map { SmartAnyImpl(from: $0) }
    }

    /// Unwraps if it exists, otherwise returns itself.
    var peelIfPresent: [Any] {
        if let arr = self as? [[String: SmartAnyImpl]] {
            return arr.peel
        } else if let arr = self as? [SmartAnyImpl] {
            return arr.peel
        } else {
            return self
        }
    }
}

extension Dictionary<String, SmartAnyImpl> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [String: Any] {
        mapValues { $0.peel }
    }
}

extension Array<SmartAnyImpl> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [Any] {
        map { $0.peel }
    }
}

extension Array<[String: SmartAnyImpl]> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    public var peel: [Any] {
        map { $0.peel }
    }
}

extension SmartAnyImpl {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    public var peel: Any {
        switch self {
        case let .number(v): return v
        case let .string(v): return v
        case let .dict(v): return v.peel
        case let .array(v): return v.peel
        case .null: return NSNull()
        }
    }
}

extension SmartAnyImpl: Codable {
    public init(from decoder: Decoder) throws {
        guard let decoder = decoder as? JSONDecoderImpl else {
            throw DecodingError.typeMismatch(
                SmartAnyImpl.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected \(Self.self) value, but decoder type mismatch"
                )
            )
        }

        guard let containerAny = try? decoder.singleValueContainer(),
              let container = containerAny as? JSONDecoderImpl.SingleValueContainer else {
            throw DecodingError.typeMismatch(
                SmartAnyImpl.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected \(Self.self) value, but container type mismatch"
                )
            )
        }

        if container.decodeNil() {
            self = .null(NSNull())
        } else if let value = try? decoder.unwrapSmartAny() {
            self = value
        } else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）"
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .string(value):
            try container.encode(value)
        case let .dict(dictValue):
            try container.encode(dictValue)
        case let .array(arrayValue):
            try container.encode(arrayValue)
        case let .number(value):
            /**
             Swift为了与Objective-C的兼容性，提供了自动桥接功能，允许Swift的数值类型和NSNumber之间的无缝转换。这包括：
             所有的整数类型：Int, Int8, Int16, Int32, Int64, UInt, UInt8, UInt16, UInt32, UInt64
             所有的浮点类型：Float, Double
             布尔类型：Bool
             */

            if value === kCFBooleanTrue as NSNumber || value === kCFBooleanFalse as NSNumber {
                if let bool = value as? Bool {
                    try container.encode(bool)
                }
            } else if let double = value as? Double {
                try container.encode(double)
            } else if let float = value as? Float {
                try container.encode(float)
            } else if let cgfloat = value as? CGFloat {
                try container.encode(cgfloat)
            } else if let int = value as? Int {
                try container.encode(int)
            } else if let int8 = value as? Int8 {
                try container.encode(int8)
            } else if let int16 = value as? Int16 {
                try container.encode(int16)
            } else if let int32 = value as? Int32 {
                try container.encode(int32)
            } else if let int64 = value as? Int64 {
                try container.encode(int64)
            } else if let uInt = value as? UInt {
                try container.encode(uInt)
            } else if let uInt8 = value as? UInt8 {
                try container.encode(uInt8)
            } else if let uInt16 = value as? UInt16 {
                try container.encode(uInt16)
            } else if let uInt32 = value as? UInt32 {
                try container.encode(uInt32)
            } else if let uInt64 = value as? UInt64 {
                try container.encode(uInt64)
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "NSNumber contains unsupported type"))
            }
        }
    }
}

extension SmartAnyImpl {
    private static func convertToSmartAny(_ value: Any) -> SmartAnyImpl {
        switch value {
        case let v as NSNumber: return .number(v)
        case let v as String: return .string(v)
        case let v as [String: Any]: return .dict(v.mapValues { convertToSmartAny($0) })
        case let v as SmartCodable:
            if let dict = v.toDictionary() {
                return .dict(dict.mapValues { convertToSmartAny($0) })
            }
        case let v as [Any]: return .array(v.map { convertToSmartAny($0) })
        case is NSNull: return .null(NSNull())
        default: break
        }

        return .null(NSNull())
    }
}

extension JSONDecoderImpl {
    fileprivate func unwrapSmartAny() throws -> SmartAnyImpl {
        if let tranformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = tranformer.tranform(value: json) as? SmartAnyImpl {
                return decoded
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Invalid SmartAny."))
            }
        }

        let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)

        switch json {
        case .null:
            return .null(NSNull())
        case let .string(string):
            return .string(string)
        case let .bool(bool):
            return .number(bool as NSNumber)
        case .object:
            if let temp = container.decodeIfPresent([String: SmartAnyImpl].self) {
                return .dict(temp)
            }
        case .array:
            if let temp = container.decodeIfPresent([SmartAnyImpl].self) {
                return .array(temp)
            }
        case let .number(number):
            if number.contains(".") { // 浮点数
                if number.contains("e") { // 检查字符串中是否包含字符 e，这表示数字可能以科学计数法表示
                    if let temp = container.decodeIfPresent(Decimal.self) as? NSNumber {
                        return .number(temp)
                    }
                } else {
                    if let temp = container.decodeIfPresent(Double.self) as? NSNumber {
                        return .number(temp)
                    }
                }
            } else {
                if let _ = Int64(number) { // 在Int64的范围内
                    if let temp = container.decodeIfPresent(Int8.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt8.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int16.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt16.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int32.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt32.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int64.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt64.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(Int.self) as? NSNumber {
                        return .number(temp)
                    } else if let temp = container.decodeIfPresent(UInt.self) as? NSNumber {
                        return .number(temp)
                    }
                } else {
                    return .string(number)
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: codingPath,
                                  debugDescription: "Invalid SmartAny."))
    }
}

extension JSONDecoderImpl.SingleValueContainer {
    fileprivate func decodeIfPresent(_: Bool.Type) -> Bool? {
        guard case let .bool(bool) = value else {
            return nil
        }

        return bool
    }

    fileprivate func decodeIfPresent(_: String.Type) -> String? {
        guard case let .string(string) = value else {
            return nil
        }
        return string
    }

    fileprivate func decodeIfPresent(_: Double.Type) -> Double? {
        decodeIfPresentFloatingPoint()
    }

    fileprivate func decodeIfPresent(_: Float.Type) -> Float? {
        decodeIfPresentFloatingPoint()
    }

    fileprivate func decodeIfPresent(_: Int.Type) -> Int? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int8.Type) -> Int8? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int16.Type) -> Int16? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int32.Type) -> Int32? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: Int64.Type) -> Int64? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt.Type) -> UInt? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt8.Type) -> UInt8? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt16.Type) -> UInt16? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt32.Type) -> UInt32? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent(_: UInt64.Type) -> UInt64? {
        decodeIfPresentFixedWidthInteger()
    }

    fileprivate func decodeIfPresent<T>(_ type: T.Type) -> T? where T: Decodable {
        if let decoded: T = try? impl.unwrap(as: type) {
            return decoded
        } else {
            return nil
        }
    }

    @inline(__always) private func decodeIfPresentFixedWidthInteger<T: FixedWidthInteger>() -> T? {
        guard let decoded = impl.unwrapFixedWidthInteger(from: value, as: T.self) else {
            return nil
        }
        return decoded
    }

    @inline(__always) private func decodeIfPresentFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() -> T? {
        guard let decoded = impl.unwrapFloatingPoint(from: value, as: T.self) else {
            return nil
        }
        return decoded
    }
}

// MARK: - SmartCoding
/// Global coding/decoding configuration namespace for SmartCodable
public enum SmartCoding {
    /// Number conversion strategy during decoding (default: .strict)
    ///
    /// - Description: Controls how to handle precision loss when converting JSON numbers (e.g., floating-point) to target types (e.g., integer)
    /// - Examples:
    ///   - Converting JSON's 3.14 to Int:
    ///     - .strict:   Returns nil (no precision loss allowed)
    ///     - .truncate: Returns 3 (direct truncation)
    ///     - .rounded:  Returns 3 (rounds to nearest)
    ///
    /// - Note: This only affects decoding process
    public static var numberConversionStrategy: NumberConversionStrategy {
        get { FrameworkConfiguration.smartModelStrategy }
        set { FrameworkConfiguration.smartModelStrategy = newValue }
    }

    /// Numeric type conversion strategy
    public enum NumberConversionStrategy {
        /// Strict mode: Must match exactly, otherwise returns nil (default)
        ///
        /// - Decoding example: Double(3.14) → Int? returns nil
        case strict

        /// Directly truncates decimal portion (e.g., 3.99 → 3)
        ///
        /// - Decoding example: Double(3.99) → Int returns 3
        case truncate

        /// Rounds to nearest integer (e.g., 3.5 → 4, 3.4 → 3)
        ///
        /// - Decoding example: Double(3.6) → Int returns 4
        case rounded
    }
}

// MARK: - Transformer
/// Resolve the mapping relationship of keys
public struct SmartKeyTransformer {
    var from: [String]
    var to: CodingKey
}

infix operator <---
/// Map the data fields corresponding to “from” to model properties corresponding to “to”.
public func <---(to: CodingKey, from: String) -> SmartKeyTransformer {
    to <--- [from]
}

/// When multiple valid fields are mapped to the same property, the first one is used first.
public func <---(to: CodingKey, from: [String]) -> SmartKeyTransformer {
    SmartKeyTransformer(from: from, to: to)
}

public struct SmartValueTransformer {
    var location: CodingKey
    var performer: any ValueTransformable
    public init(location: CodingKey, performer: any ValueTransformable) {
        self.location = location
        self.performer = performer
    }

    /// Transforms a JSON value using the appropriate transformer
    /// - Parameters:
    ///   - value: The JSON value to transform
    ///   - key: The associated coding key (if available)
    /// - Returns: The transformed value or nil if no transformer applies
    func tranform(value: JSONValue) -> Any? {
        performer.transformFromJSON(value.peel)
    }
}

public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON

    /// transform from ’json‘ to ’object‘
    func transformFromJSON(_ value: Any) -> Object?

    /// transform to ‘json’ from ‘object’
    func transformToJSON(_ value: Object) -> JSON?
}

public func <---(location: CodingKey, performer: any ValueTransformable) -> SmartValueTransformer {
    SmartValueTransformer(location: location, performer: performer)
}

/** Fast Transformer
 static func mappingForValue() -> [SmartValueTransformer]? {
     [
         CodingKeys.name <--- FastTransformer<String, String>(fromJSON: { json in
             "abc"
         }, toJSON: { object in
             "123"
         }),
         CodingKeys.subModel <--- FastTransformer<TestEnum, String>(fromJSON: { json in
             TestEnum.man
         }, toJSON: { object in
             object?.rawValue
         }),
     ]
 }
 */
public struct FastTransformer<Object, JSON>: ValueTransformable {
    private let fromJSON: (JSON?) -> Object?
    private let toJSON: ((Object?) -> JSON?)?

    /// 便捷的转换器
    /// - Parameters:
    ///   - fromJSON: json 转 object
    ///   - toJSON:  object 转 json， 如果需要转json，可以不实现。
    public init(fromJSON: @escaping (JSON?) -> Object?, toJSON: ((Object?) -> JSON?)? = nil) {
        self.fromJSON = fromJSON
        self.toJSON = toJSON
    }

    public func transformFromJSON(_ value: Any) -> Object? {
        fromJSON(value as? JSON)
    }

    public func transformToJSON(_ value: Object) -> JSON? {
        toJSON?(value)
    }
}

public struct SmartDataTransformer: ValueTransformable {
    public typealias JSON = String
    public typealias Object = Data

    public init() {}

    public func transformFromJSON(_ value: Any) -> Data? {
        guard let string = value as? String else {
            return nil
        }
        return Data(base64Encoded: string)
    }

    public func transformToJSON(_ value: Data) -> String? {
        value.base64EncodedString()
    }
}

public struct SmartDateTransformer: ValueTransformable {
    public typealias JSON = Any
    public typealias Object = Date

    private var strategy: SmartDate.DateStrategy

    public init(strategy: SmartDate.DateStrategy) {
        self.strategy = strategy
    }

    public func transformFromJSON(_ value: Any) -> Date? {
        guard let (date, _) = DateParser.parse(value) else { return nil }
        return date
    }

    public func transformToJSON(_ value: Date) -> Any? {
        switch strategy {
        case .timestamp:
            return value.timeIntervalSince1970
        case .timestampMilliseconds:
            return value.timeIntervalSince1970 * 1000.0
        case let .formatted(formatter):
            return formatter.string(from: value)
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: value)
        }
    }
}

public struct SmartURLTransformer: ValueTransformable {
    public typealias JSON = String
    public typealias Object = URL
    private let shouldEncodeURLString: Bool
    private let prefix: String?

    /**
      Initializes a URLTransformer with an option to encode the URL string before converting it to NSURL
      - parameter shouldEncodeUrlString: When true (the default value), the string is encoded before being passed
      - returns: an initialized transformer
     */
    public init(prefix: String? = nil, shouldEncodeURLString: Bool = true) {
        self.shouldEncodeURLString = shouldEncodeURLString
        self.prefix = prefix
    }

    public func transformFromJSON(_ value: Any) -> URL? {
        guard var URLString = value as? String else { return nil }
        if let prefix, !URLString.hasPrefix(prefix) {
            URLString = prefix + URLString
        }

        if !shouldEncodeURLString {
            return URL(string: URLString)
        }

        guard let escapedURLString = URLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        return URL(string: escapedURLString)
    }

    public func transformToJSON(_ value: URL) -> String? {
        value.absoluteString
    }
}

// MARK: - Cachable
/// A protocol defining caching capabilities for model snapshots
/// Used to maintain state during encoding/decoding operations
protocol Cachable {
    associatedtype SomeSnapshot: Snapshot

    /// Array of snapshots representing the current parsing stack
    /// - Note: Using an array prevents confusion with multi-level nested models
    var snapshots: [SomeSnapshot] { set get }

    /// The most recent snapshot in the stack (top of stack)
    var topSnapshot: SomeSnapshot? { get }

    /// Caches a new snapshot for the given type
    /// - Parameter type: The model type being processed
    func cacheSnapshot<T>(for type: T.Type)

    /// Removes the snapshot for the given type
    /// - Parameter type: The model type to remove from cache
    mutating func removeSnapshot<T>(for type: T.Type)
}

extension Cachable {
    var topSnapshot: SomeSnapshot? {
        snapshots.last
    }
}

/// Represents a snapshot of model state during encoding/decoding
protocol Snapshot {
    associatedtype ObjectType

    /// The current type being encoded/decoded
    var objectType: ObjectType? { set get }

    /// String representation of the object type
    var objectTypeName: String? { get }

    /// Records the custom transformer for properties
    var transformers: [SmartValueTransformer]? { set get }
}

extension Snapshot {
    var objectTypeName: String? {
        if let t = objectType {
            return String(describing: t)
        }
        return nil
    }
}

// MARK: - JSONValue
enum JSONValue: Equatable {
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    case array([JSONValue])
    case object([String: JSONValue])

    static func make(_ value: Any) -> Self? {
        if let jsonValue = value as? JSONValue {
            return jsonValue
        }

        switch value {
        case is NSNull:
            return .null
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            return .number(number.stringValue)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            let jsonArray = array.compactMap { make($0) }
            return .array(jsonArray)
        case let dictionary as [String: Any]:
            let jsonObject = dictionary.compactMapValues { make($0) }
            return .object(jsonObject)
        default:
            return nil
        }
    }
}

private func _toData(_ value: Any) -> Data? {
    guard JSONSerialization.isValidJSONObject(value) else { return nil }
    return try? JSONSerialization.data(withJSONObject: value)
}

extension JSONValue {
    var isValue: Bool {
        switch self {
        case .array, .object:
            return false
        case .null, .number, .string, .bool:
            return true
        }
    }

    var isNull: Bool {
        switch self {
        case .null:
            return true
        case .array, .object, .number, .string, .bool:
            return false
        }
    }

    var isContainer: Bool {
        switch self {
        case .array, .object:
            return true
        case .null, .number, .string, .bool:
            return false
        }
    }
}

extension JSONValue {
    var debugDataTypeDescription: String {
        switch self {
        case .array:
            return "’Array‘"
        case .bool:
            return "’Bool‘"
        case .number:
            return "’Number‘"
        case .string:
            return "‘String’"
        case .object:
            return "’Dictionary‘"
        case .null:
            return "’null‘"
        }
    }
}

extension JSONValue {
    private func toObjcRepresentation(options: JSONSerialization.ReadingOptions) throws -> Any {
        switch self {
        case let .array(values):
            let array = try values.map { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return array
            }
            return NSMutableArray(array: array, copyItems: false)
        case let .object(object):
            let dictionary = try object.mapValues { try $0.toObjcRepresentation(options: options) }
            if !options.contains(.mutableContainers) {
                return dictionary
            }
            return NSMutableDictionary(dictionary: dictionary, copyItems: false)
        case let .bool(bool):
            return NSNumber(value: bool)
        case let .number(string):
            guard let number = NSNumber.fromJSONNumber(string) else {
                throw JSONParserError.numberIsNotRepresentableInSwift(parsed: string)
            }
            return number
        case .null:
            return NSNull()
        case let .string(string):
            if options.contains(.mutableLeaves) {
                return NSMutableString(string: string)
            }
            return string
        }
    }
}

extension NSNumber {
    static func fromJSONNumber(_ string: String) -> NSNumber? {
        let decIndex = string.firstIndex(of: ".")
        let expIndex = string.firstIndex(of: "e")
        let isInteger = decIndex == nil && expIndex == nil
        let isNegative = string.utf8[string.utf8.startIndex] == UInt8(ascii: "-")
        let digitCount = string[string.startIndex..<(expIndex ?? string.endIndex)].count

        // Try Int64() or UInt64() first
        if isInteger {
            if isNegative {
                if digitCount <= 19, let intValue = Int64(string) {
                    return NSNumber(value: intValue)
                }
            } else {
                if digitCount <= 20, let uintValue = UInt64(string) {
                    return NSNumber(value: uintValue)
                }
            }
        }

        var exp = 0

        if let expIndex {
            let expStartIndex = string.index(after: expIndex)
            if let parsed = Int(string[expStartIndex...]) {
                exp = parsed
            }
        }

        // Decimal holds more digits of precision but a smaller exponent than Double
        // so try that if the exponent fits and there are more digits than Double can hold
        if digitCount > 17, exp >= -128, exp <= 127, let decimal = Decimal(string: string), decimal.isFinite {
            return NSDecimalNumber(decimal: decimal)
        }

        // Fall back to Double() for everything else
        if let doubleValue = Double(string), doubleValue.isFinite {
            return NSNumber(value: doubleValue)
        }

        return nil
    }
}

enum JSONParserError: Swift.Error, Equatable {
    case cannotConvertInputDataToUTF8
    case unexpectedCharacter(ascii: UInt8, characterIndex: Int)
    case unexpectedEndOfFile
    case tooManyNestedArraysOrDictionaries(characterIndex: Int)
    case invalidHexDigitSequence(String, index: Int)
    case unexpectedEscapedCharacter(ascii: UInt8, in: String, index: Int)
    case unescapedControlCharacterInString(ascii: UInt8, in: String, index: Int)
    case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: String, index: Int)
    case couldNotCreateUnicodeScalarFromUInt32(in: String, index: Int, unicodeScalarValue: UInt32)
    case numberWithLeadingZero(index: Int)
    case numberIsNotRepresentableInSwift(parsed: String)
    case singleFragmentFoundButNotAllowed
    case invalidUTF8Sequence(Data, characterIndex: Int)
}

// for encdoe
extension JSONValue {
    struct Writer {
        let options: SmartJSONEncoder.OutputFormatting

        init(options: SmartJSONEncoder.OutputFormatting) {
            self.options = options
        }

        func writeValue(_ value: JSONValue) -> [UInt8] {
            var bytes = [UInt8]()
            if options.contains(.prettyPrinted) {
                writeValuePretty(value, into: &bytes)
            } else {
                writeValue(value, into: &bytes)
            }
            return bytes
        }

        private func writeValue(_ value: JSONValue, into bytes: inout [UInt8]) {
            switch value {
            case .null:
                bytes.append(contentsOf: [UInt8]._null)
            case .bool(true):
                bytes.append(contentsOf: [UInt8]._true)
            case .bool(false):
                bytes.append(contentsOf: [UInt8]._false)
            case let .string(string):
                encodeString(string, to: &bytes)
            case let .number(string):
                bytes.append(contentsOf: string.utf8)
            case let .array(array):
                var iterator = array.makeIterator()
                bytes.append(._openbracket)
                // we don't like branching, this is why we have this extra
                if let first = iterator.next() {
                    writeValue(first, into: &bytes)
                }
                while let item = iterator.next() {
                    bytes.append(._comma)
                    writeValue(item, into: &bytes)
                }
                bytes.append(._closebracket)
            case let .object(dict):
                if options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    writeObject(sorted, into: &bytes)
                } else {
                    writeObject(dict, into: &bytes)
                }
            }
        }

        private func writeObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONValue) {
            var iterator = object.makeIterator()
            bytes.append(._openbrace)
            if let (key, value) = iterator.next() {
                encodeString(key, to: &bytes)
                bytes.append(._colon)
                writeValue(value, into: &bytes)
            }
            while let (key, value) = iterator.next() {
                bytes.append(._comma)
                // key
                encodeString(key, to: &bytes)
                bytes.append(._colon)

                writeValue(value, into: &bytes)
            }
            bytes.append(._closebrace)
        }

        private func addInset(to bytes: inout [UInt8], depth: Int) {
            bytes.append(contentsOf: [UInt8](repeating: ._space, count: depth * 2))
        }

        private func writeValuePretty(_ value: JSONValue, into bytes: inout [UInt8], depth: Int = 0) {
            switch value {
            case .null:
                bytes.append(contentsOf: [UInt8]._null)
            case .bool(true):
                bytes.append(contentsOf: [UInt8]._true)
            case .bool(false):
                bytes.append(contentsOf: [UInt8]._false)
            case let .string(string):
                encodeString(string, to: &bytes)
            case let .number(string):
                bytes.append(contentsOf: string.utf8)
            case let .array(array):
                var iterator = array.makeIterator()
                bytes.append(contentsOf: [._openbracket, ._newline])
                if let first = iterator.next() {
                    addInset(to: &bytes, depth: depth + 1)
                    writeValuePretty(first, into: &bytes, depth: depth + 1)
                }
                while let item = iterator.next() {
                    bytes.append(contentsOf: [._comma, ._newline])
                    addInset(to: &bytes, depth: depth + 1)
                    writeValuePretty(item, into: &bytes, depth: depth + 1)
                }
                bytes.append(._newline)
                addInset(to: &bytes, depth: depth)
                bytes.append(._closebracket)
            case let .object(dict):
                if options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    writePrettyObject(sorted, into: &bytes, depth: depth)
                } else {
                    writePrettyObject(dict, into: &bytes, depth: depth)
                }
            }
        }

        private func writePrettyObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONValue) {
            var iterator = object.makeIterator()
            bytes.append(contentsOf: [._openbrace, ._newline])
            if let (key, value) = iterator.next() {
                addInset(to: &bytes, depth: depth + 1)
                encodeString(key, to: &bytes)
                bytes.append(contentsOf: [._space, ._colon, ._space])
                writeValuePretty(value, into: &bytes, depth: depth + 1)
            }
            while let (key, value) = iterator.next() {
                bytes.append(contentsOf: [._comma, ._newline])
                addInset(to: &bytes, depth: depth + 1)
                // key
                encodeString(key, to: &bytes)
                bytes.append(contentsOf: [._space, ._colon, ._space])
                // value
                writeValuePretty(value, into: &bytes, depth: depth + 1)
            }
            bytes.append(._newline)
            addInset(to: &bytes, depth: depth)
            bytes.append(._closebrace)
        }

        private func encodeString(_ string: String, to bytes: inout [UInt8]) {
            bytes.append(UInt8(ascii: "\""))
            let stringBytes = string.utf8
            var startCopyIndex = stringBytes.startIndex
            var nextIndex = startCopyIndex

            while nextIndex != stringBytes.endIndex {
                switch stringBytes[nextIndex] {
                case 0..<32, UInt8(ascii: "\""), UInt8(ascii: "\\"):
                    // All Unicode characters may be placed within the
                    // quotation marks, except for the characters that MUST be escaped:
                    // quotation mark, reverse solidus, and the control characters (U+0000
                    // through U+001F).
                    // https://tools.ietf.org/html/rfc8259#section-7

                    // copy the current range over
                    bytes.append(contentsOf: stringBytes[startCopyIndex..<nextIndex])
                    switch stringBytes[nextIndex] {
                    case UInt8(ascii: "\""): // quotation mark
                        bytes.append(contentsOf: [._backslash, ._quote])
                    case UInt8(ascii: "\\"): // reverse solidus
                        bytes.append(contentsOf: [._backslash, ._backslash])
                    case 0x08: // backspace
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "b")])
                    case 0x0C: // form feed
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "f")])
                    case 0x0A: // line feed
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "n")])
                    case 0x0D: // carriage return
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "r")])
                    case 0x09: // tab
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "t")])
                    default:
                        func valueToAscii(_ value: UInt8) -> UInt8 {
                            switch value {
                            case 0...9:
                                return value + UInt8(ascii: "0")
                            case 10...15:
                                return value - 10 + UInt8(ascii: "a")
                            default:
                                preconditionFailure()
                            }
                        }
                        bytes.append(UInt8(ascii: "\\"))
                        bytes.append(UInt8(ascii: "u"))
                        bytes.append(UInt8(ascii: "0"))
                        bytes.append(UInt8(ascii: "0"))
                        let first = stringBytes[nextIndex] / 16
                        let remaining = stringBytes[nextIndex] % 16
                        bytes.append(valueToAscii(first))
                        bytes.append(valueToAscii(remaining))
                    }

                    nextIndex = stringBytes.index(after: nextIndex)
                    startCopyIndex = nextIndex

                case UInt8(ascii: "/"):
                    if options.contains(.withoutEscapingSlashes) == false {
                        bytes.append(contentsOf: stringBytes[startCopyIndex..<nextIndex])
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "/")])
                        nextIndex = stringBytes.index(after: nextIndex)
                        startCopyIndex = nextIndex
                    } else {
                        bytes.append(contentsOf: stringBytes[startCopyIndex..<nextIndex])
                        bytes.append(contentsOf: [._backslash, UInt8(ascii: "/")])
                        nextIndex = stringBytes.index(after: nextIndex)
                        startCopyIndex = nextIndex
                    }

                default:
                    nextIndex = stringBytes.index(after: nextIndex)
                }
            }

            // copy everything, that hasn't been copied yet
            bytes.append(contentsOf: stringBytes[startCopyIndex..<nextIndex])
            bytes.append(UInt8(ascii: "\""))
        }
    }
}

extension JSONValue {
    var object: [String: JSONValue]? {
        switch self {
        case let .object(v):
            return v
        default:
            return nil
        }
    }

    var array: [JSONValue]? {
        switch self {
        case let .array(v):
            return v
        default:
            return nil
        }
    }

    var peel: Any {
        switch self {
        case let .array(v):
            return v.peel
        case let .bool(v):
            return v
        case let .number(v):
            return v
        case let .string(v):
            return v
        case let .object(v):
            return v.peel
        case .null:
            return NSNull()
        }
    }
}

extension Dictionary<String, JSONValue> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [String: Any] {
        mapValues { $0.peel }
    }
}

extension Array<JSONValue> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [Any] {
        map { $0.peel }
    }
}

extension Array<[String: JSONValue]> {
    /// The parsed value will be wrapped by SmartAny. Use this property to unwrap it.
    var peel: [Any] {
        map { $0.peel }
    }
}

struct JSONParser {
    var reader: DocumentReader
    var depth: Int = 0

    init(bytes: [UInt8]) {
        self.reader = DocumentReader(array: bytes)
    }

    mutating func parse() throws -> JSONValue {
        try reader.consumeWhitespace()
        let value = try parseValue()
        #if DEBUG
        defer {
            guard self.depth == 0 else {
                preconditionFailure("Expected to end parsing with a depth of 0")
            }
        }
        #endif

        // ensure only white space is remaining
        var whitespace = 0
        while let next = reader.peek(offset: whitespace) {
            switch next {
            case ._space, ._tab, ._return, ._newline:
                whitespace += 1
                continue
            default:
                throw JSONParserError.unexpectedCharacter(ascii: next, characterIndex: reader.readerIndex + whitespace)
            }
        }

        return value
    }

    // MARK: Generic Value Parsing

    mutating func parseValue() throws -> JSONValue {
        var whitespace = 0
        while let byte = reader.peek(offset: whitespace) {
            switch byte {
            case UInt8(ascii: "\""):
                reader.moveReaderIndex(forwardBy: whitespace)
                return try .string(reader.readString())
            case ._openbrace:
                reader.moveReaderIndex(forwardBy: whitespace)
                let object = try parseObject()
                return .object(object)
            case ._openbracket:
                reader.moveReaderIndex(forwardBy: whitespace)
                let array = try parseArray()
                return .array(array)
            case UInt8(ascii: "f"), UInt8(ascii: "t"):
                reader.moveReaderIndex(forwardBy: whitespace)
                let bool = try reader.readBool()
                return .bool(bool)
            case UInt8(ascii: "n"):
                reader.moveReaderIndex(forwardBy: whitespace)
                try reader.readNull()
                return .null
            case UInt8(ascii: "-"), UInt8(ascii: "0")...UInt8(ascii: "9"):
                reader.moveReaderIndex(forwardBy: whitespace)
                let number = try reader.readNumber()
                return .number(number)
            case ._space, ._return, ._newline, ._tab:
                whitespace += 1
                continue
            default:
                throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: reader.readerIndex)
            }
        }

        throw JSONParserError.unexpectedEndOfFile
    }

    // MARK: - Parse Array -

    mutating func parseArray() throws -> [JSONValue] {
        precondition(reader.read() == ._openbracket)
        guard depth < 512 else {
            throw JSONParserError.tooManyNestedArraysOrDictionaries(characterIndex: reader.readerIndex - 1)
        }
        depth += 1
        defer { depth -= 1 }

        // parse first value or end immediatly
        switch try reader.consumeWhitespace() {
        case ._space, ._return, ._newline, ._tab:
            preconditionFailure("Expected that all white space is consumed")
        case ._closebracket:
            // if the first char after whitespace is a closing bracket, we found an empty array
            reader.moveReaderIndex(forwardBy: 1)
            return []
        default:
            break
        }

        var array = [JSONValue]()
        array.reserveCapacity(10)

        // parse values
        while true {
            let value = try parseValue()
            array.append(value)

            // consume the whitespace after the value before the comma
            let ascii = try reader.consumeWhitespace()
            switch ascii {
            case ._space, ._return, ._newline, ._tab:
                preconditionFailure("Expected that all white space is consumed")
            case ._closebracket:
                reader.moveReaderIndex(forwardBy: 1)
                return array
            case ._comma:
                // consume the comma
                reader.moveReaderIndex(forwardBy: 1)
                // consume the whitespace before the next value
                if try reader.consumeWhitespace() == ._closebracket {
                    // the foundation json implementation does support trailing commas
                    reader.moveReaderIndex(forwardBy: 1)
                    return array
                }
                continue
            default:
                throw JSONParserError.unexpectedCharacter(ascii: ascii, characterIndex: reader.readerIndex)
            }
        }
    }

    // MARK: - Object parsing -

    mutating func parseObject() throws -> [String: JSONValue] {
        precondition(reader.read() == ._openbrace)
        guard depth < 512 else {
            throw JSONParserError.tooManyNestedArraysOrDictionaries(characterIndex: reader.readerIndex - 1)
        }
        depth += 1
        defer { depth -= 1 }

        // parse first value or end immediatly
        switch try reader.consumeWhitespace() {
        case ._space, ._return, ._newline, ._tab:
            preconditionFailure("Expected that all white space is consumed")
        case ._closebrace:
            // if the first char after whitespace is a closing bracket, we found an empty array
            reader.moveReaderIndex(forwardBy: 1)
            return [:]
        default:
            break
        }

        var object = [String: JSONValue]()
        object.reserveCapacity(20)

        while true {
            let key = try reader.readString()
            let colon = try reader.consumeWhitespace()
            guard colon == ._colon else {
                throw JSONParserError.unexpectedCharacter(ascii: colon, characterIndex: reader.readerIndex)
            }
            reader.moveReaderIndex(forwardBy: 1)
            try reader.consumeWhitespace()
            object[key] = try parseValue()

            let commaOrBrace = try reader.consumeWhitespace()
            switch commaOrBrace {
            case ._closebrace:
                reader.moveReaderIndex(forwardBy: 1)
                return object
            case ._comma:
                reader.moveReaderIndex(forwardBy: 1)
                if try reader.consumeWhitespace() == ._closebrace {
                    // the foundation json implementation does support trailing commas
                    reader.moveReaderIndex(forwardBy: 1)
                    return object
                }
                continue
            default:
                throw JSONParserError.unexpectedCharacter(ascii: commaOrBrace, characterIndex: reader.readerIndex)
            }
        }
    }
}

extension JSONParser {
    struct DocumentReader {
        let array: [UInt8]

        private(set) var readerIndex: Int = 0

        private var readableBytes: Int {
            array.endIndex - readerIndex
        }

        var isEOF: Bool {
            readerIndex >= array.endIndex
        }

        init(array: [UInt8]) {
            self.array = array
        }

        subscript<R: RangeExpression<Int>>(bounds: R) -> ArraySlice<UInt8> {
            array[bounds]
        }

        mutating func read() -> UInt8? {
            guard readerIndex < array.endIndex else {
                readerIndex = array.endIndex
                return nil
            }

            defer { self.readerIndex += 1 }

            return array[readerIndex]
        }

        func peek(offset: Int = 0) -> UInt8? {
            guard readerIndex + offset < array.endIndex else {
                return nil
            }

            return array[readerIndex + offset]
        }

        mutating func moveReaderIndex(forwardBy offset: Int) {
            readerIndex += offset
        }

        @discardableResult
        mutating func consumeWhitespace() throws -> UInt8 {
            var whitespace = 0
            while let ascii = peek(offset: whitespace) {
                switch ascii {
                case ._space, ._return, ._newline, ._tab:
                    whitespace += 1
                    continue
                default:
                    moveReaderIndex(forwardBy: whitespace)
                    return ascii
                }
            }

            throw JSONParserError.unexpectedEndOfFile
        }

        mutating func readString() throws -> String {
            try readUTF8StringTillNextUnescapedQuote()
        }

        mutating func readNumber() throws -> String {
            try parseNumber()
        }

        mutating func readBool() throws -> Bool {
            switch read() {
            case UInt8(ascii: "t"):
                guard read() == UInt8(ascii: "r"),
                      read() == UInt8(ascii: "u"),
                      read() == UInt8(ascii: "e")
                else {
                    guard !isEOF else {
                        throw JSONParserError.unexpectedEndOfFile
                    }

                    throw JSONParserError.unexpectedCharacter(ascii: peek(offset: -1)!, characterIndex: readerIndex - 1)
                }

                return true
            case UInt8(ascii: "f"):
                guard read() == UInt8(ascii: "a"),
                      read() == UInt8(ascii: "l"),
                      read() == UInt8(ascii: "s"),
                      read() == UInt8(ascii: "e")
                else {
                    guard !isEOF else {
                        throw JSONParserError.unexpectedEndOfFile
                    }

                    throw JSONParserError.unexpectedCharacter(ascii: peek(offset: -1)!, characterIndex: readerIndex - 1)
                }

                return false
            default:
                preconditionFailure("Expected to have `t` or `f` as first character")
            }
        }

        mutating func readNull() throws {
            guard read() == UInt8(ascii: "n"),
                  read() == UInt8(ascii: "u"),
                  read() == UInt8(ascii: "l"),
                  read() == UInt8(ascii: "l")
            else {
                guard !isEOF else {
                    throw JSONParserError.unexpectedEndOfFile
                }

                throw JSONParserError.unexpectedCharacter(ascii: peek(offset: -1)!, characterIndex: readerIndex - 1)
            }
        }

        // MARK: - Private Methods -

        // MARK: String

        enum EscapedSequenceError: Swift.Error {
            case expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: Int)
            case unexpectedEscapedCharacter(ascii: UInt8, index: Int)
            case couldNotCreateUnicodeScalarFromUInt32(index: Int, unicodeScalarValue: UInt32)
        }

        private mutating func readUTF8StringTillNextUnescapedQuote() throws -> String {
            guard read() == ._quote else {
                throw JSONParserError.unexpectedCharacter(ascii: peek(offset: -1)!, characterIndex: readerIndex - 1)
            }
            var stringStartIndex = readerIndex
            var copy = 0
            var output: String?

            while let byte = peek(offset: copy) {
                switch byte {
                case UInt8(ascii: "\""):
                    moveReaderIndex(forwardBy: copy + 1)
                    guard var result = output else {
                        // if we don't have an output string we create a new string
                        return try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    }
                    // if we have an output string we append
                    result += try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    return result

                case 0...31:
                    // All Unicode characters may be placed within the
                    // quotation marks, except for the characters that must be escaped:
                    // quotation mark, reverse solidus, and the control characters (U+0000
                    // through U+001F).
                    var string = output ?? ""
                    let errorIndex = readerIndex + copy
                    string += try makeString(at: stringStartIndex...errorIndex)
                    throw JSONParserError.unescapedControlCharacterInString(ascii: byte, in: string, index: errorIndex)

                case UInt8(ascii: "\\"):
                    moveReaderIndex(forwardBy: copy)
                    if output != nil {
                        output! += try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    } else {
                        output = try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    }

                    let escapedStartIndex = readerIndex

                    do {
                        let escaped = try parseEscapeSequence()
                        output! += escaped
                        stringStartIndex = readerIndex
                        copy = 0
                    } catch let EscapedSequenceError.unexpectedEscapedCharacter(ascii, failureIndex) {
                        output! += try makeString(at: escapedStartIndex..<self.readerIndex)
                        throw JSONParserError.unexpectedEscapedCharacter(ascii: ascii, in: output!, index: failureIndex)
                    } catch let EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(failureIndex) {
                        output! += try makeString(at: escapedStartIndex..<self.readerIndex)
                        throw JSONParserError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(in: output!, index: failureIndex)
                    } catch let EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(failureIndex, unicodeScalarValue) {
                        output! += try makeString(at: escapedStartIndex..<self.readerIndex)
                        throw JSONParserError.couldNotCreateUnicodeScalarFromUInt32(
                            in: output!, index: failureIndex, unicodeScalarValue: unicodeScalarValue
                        )
                    }

                default:
                    copy += 1
                    continue
                }
            }

            throw JSONParserError.unexpectedEndOfFile
        }

        private func makeString<R: RangeExpression<Int>>(at range: R) throws -> String {
            let raw = array[range]
            guard let str = String(bytes: raw, encoding: .utf8) else {
                throw JSONParserError.invalidUTF8Sequence(Data(raw), characterIndex: range.relative(to: array).lowerBound)
            }
            return str
        }

        private mutating func parseEscapeSequence() throws -> String {
            precondition(read() == ._backslash, "Expected to have an backslash first")
            guard let ascii = read() else {
                throw JSONParserError.unexpectedEndOfFile
            }

            switch ascii {
            case 0x22: return "\""
            case 0x5C: return "\\"
            case 0x2F: return "/"
            case 0x62: return "\u{08}" // \b
            case 0x66: return "\u{0C}" // \f
            case 0x6E: return "\u{0A}" // \n
            case 0x72: return "\u{0D}" // \r
            case 0x74: return "\u{09}" // \t
            case 0x75:
                let character = try parseUnicodeSequence()
                return String(character)
            default:
                throw EscapedSequenceError.unexpectedEscapedCharacter(ascii: ascii, index: readerIndex - 1)
            }
        }

        private mutating func parseUnicodeSequence() throws -> Unicode.Scalar {
            // we build this for utf8 only for now.
            let bitPattern = try parseUnicodeHexSequence()

            // check if high surrogate
            let isFirstByteHighSurrogate = bitPattern & 0xFC00 // nil everything except first six bits
            if isFirstByteHighSurrogate == 0xD800 {
                // if we have a high surrogate we expect a low surrogate next
                let highSurrogateBitPattern = bitPattern
                guard let escapeChar = read(),
                      let uChar = read()
                else {
                    throw JSONParserError.unexpectedEndOfFile
                }

                guard escapeChar == UInt8(ascii: #"\"#), uChar == UInt8(ascii: "u") else {
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: readerIndex - 1)
                }

                let lowSurrogateBitBattern = try parseUnicodeHexSequence()
                let isSecondByteLowSurrogate = lowSurrogateBitBattern & 0xFC00 // nil everything except first six bits
                guard isSecondByteLowSurrogate == 0xDC00 else {
                    // we are in an escaped sequence. for this reason an output string must have
                    // been initialized
                    throw EscapedSequenceError.expectedLowSurrogateUTF8SequenceAfterHighSurrogate(index: readerIndex - 1)
                }

                let highValue = UInt32(highSurrogateBitPattern - 0xD800) * 0x400
                let lowValue = UInt32(lowSurrogateBitBattern - 0xDC00)
                let unicodeValue = highValue + lowValue + 0x10000
                guard let unicode = Unicode.Scalar(unicodeValue) else {
                    throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                        index: readerIndex, unicodeScalarValue: unicodeValue
                    )
                }
                return unicode
            }

            guard let unicode = Unicode.Scalar(bitPattern) else {
                throw EscapedSequenceError.couldNotCreateUnicodeScalarFromUInt32(
                    index: readerIndex, unicodeScalarValue: UInt32(bitPattern)
                )
            }
            return unicode
        }

        private mutating func parseUnicodeHexSequence() throws -> UInt16 {
            // As stated in RFC-8259 an escaped unicode character is 4 HEXDIGITs long
            // https://tools.ietf.org/html/rfc8259#section-7
            let startIndex = readerIndex
            guard let firstHex = read(),
                  let secondHex = read(),
                  let thirdHex = read(),
                  let forthHex = read()
            else {
                throw JSONParserError.unexpectedEndOfFile
            }

            guard let first = DocumentReader.hexAsciiTo4Bits(firstHex),
                  let second = DocumentReader.hexAsciiTo4Bits(secondHex),
                  let third = DocumentReader.hexAsciiTo4Bits(thirdHex),
                  let forth = DocumentReader.hexAsciiTo4Bits(forthHex)
            else {
                let hexString = String(decoding: [firstHex, secondHex, thirdHex, forthHex], as: Unicode.UTF8.self)
                throw JSONParserError.invalidHexDigitSequence(hexString, index: startIndex)
            }
            let firstByte = UInt16(first) << 4 | UInt16(second)
            let secondByte = UInt16(third) << 4 | UInt16(forth)

            let bitPattern = UInt16(firstByte) << 8 | UInt16(secondByte)

            return bitPattern
        }

        private static func hexAsciiTo4Bits(_ ascii: UInt8) -> UInt8? {
            switch ascii {
            case 48...57:
                return ascii - 48
            case 65...70:
                // uppercase letters
                return ascii - 55
            case 97...102:
                // lowercase letters
                return ascii - 87
            default:
                return nil
            }
        }

        // MARK: Numbers

        private enum ControlCharacter {
            case operand
            case decimalPoint
            case exp
            case expOperator
        }

        private mutating func parseNumber() throws -> String {
            var pastControlChar: ControlCharacter = .operand
            var numbersSinceControlChar: UInt = 0
            var hasLeadingZero = false

            // parse first character

            guard let ascii = peek() else {
                preconditionFailure("Why was this function called, if there is no 0...9 or -")
            }
            switch ascii {
            case UInt8(ascii: "0"):
                numbersSinceControlChar = 1
                pastControlChar = .operand
                hasLeadingZero = true
            case UInt8(ascii: "1")...UInt8(ascii: "9"):
                numbersSinceControlChar = 1
                pastControlChar = .operand
            case UInt8(ascii: "-"):
                numbersSinceControlChar = 0
                pastControlChar = .operand
            default:
                preconditionFailure("Why was this function called, if there is no 0...9 or -")
            }

            var numberchars = 1

            // parse everything else
            while let byte = peek(offset: numberchars) {
                switch byte {
                case UInt8(ascii: "0"):
                    if hasLeadingZero {
                        throw JSONParserError.numberWithLeadingZero(index: readerIndex + numberchars)
                    }
                    if numbersSinceControlChar == 0, pastControlChar == .operand {
                        // the number started with a minus. this is the leading zero.
                        hasLeadingZero = true
                    }
                    numberchars += 1
                    numbersSinceControlChar += 1
                case UInt8(ascii: "1")...UInt8(ascii: "9"):
                    if hasLeadingZero {
                        throw JSONParserError.numberWithLeadingZero(index: readerIndex + numberchars)
                    }
                    numberchars += 1
                    numbersSinceControlChar += 1
                case UInt8(ascii: "."):
                    guard numbersSinceControlChar > 0, pastControlChar == .operand else {
                        throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: readerIndex + numberchars)
                    }

                    numberchars += 1
                    hasLeadingZero = false
                    pastControlChar = .decimalPoint
                    numbersSinceControlChar = 0
                case UInt8(ascii: "e"), UInt8(ascii: "E"):
                    guard numbersSinceControlChar > 0,
                          pastControlChar == .operand || pastControlChar == .decimalPoint
                    else {
                        throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: readerIndex + numberchars)
                    }

                    numberchars += 1
                    hasLeadingZero = false
                    pastControlChar = .exp
                    numbersSinceControlChar = 0
                case UInt8(ascii: "+"), UInt8(ascii: "-"):
                    guard numbersSinceControlChar == 0, pastControlChar == .exp else {
                        throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: readerIndex + numberchars)
                    }

                    numberchars += 1
                    pastControlChar = .expOperator
                    numbersSinceControlChar = 0
                case ._space, ._return, ._newline, ._tab, ._comma, ._closebracket, ._closebrace:
                    guard numbersSinceControlChar > 0 else {
                        throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: readerIndex + numberchars)
                    }
                    let numberStartIndex = readerIndex
                    moveReaderIndex(forwardBy: numberchars)

                    return String(decoding: self[numberStartIndex..<readerIndex], as: Unicode.UTF8.self)
                default:
                    throw JSONParserError.unexpectedCharacter(ascii: byte, characterIndex: readerIndex + numberchars)
                }
            }

            guard numbersSinceControlChar > 0 else {
                throw JSONParserError.unexpectedEndOfFile
            }

            defer { self.readerIndex = self.array.endIndex }
            return String(decoding: array.suffix(from: readerIndex), as: Unicode.UTF8.self)
        }
    }
}

extension UInt8 {
    static let _space = UInt8(ascii: " ")
    static let _return = UInt8(ascii: "\r")
    static let _newline = UInt8(ascii: "\n")
    static let _tab = UInt8(ascii: "\t")

    static let _colon = UInt8(ascii: ":")
    static let _comma = UInt8(ascii: ",")

    static let _openbrace = UInt8(ascii: "{")
    static let _closebrace = UInt8(ascii: "}")

    static let _openbracket = UInt8(ascii: "[")
    static let _closebracket = UInt8(ascii: "]")

    static let _quote = UInt8(ascii: "\"")
    static let _backslash = UInt8(ascii: "\\")
}

extension Array<UInt8> {
    static let _true = [UInt8(ascii: "t"), UInt8(ascii: "r"), UInt8(ascii: "u"), UInt8(ascii: "e")]
    static let _false = [UInt8(ascii: "f"), UInt8(ascii: "a"), UInt8(ascii: "l"), UInt8(ascii: "s"), UInt8(ascii: "e")]
    static let _null = [UInt8(ascii: "n"), UInt8(ascii: "u"), UInt8(ascii: "l"), UInt8(ascii: "l")]
}

// MARK: - JSONDecoder
open class SmartJSONDecoder: JSONDecoder, @unchecked Sendable {
    open var smartDataDecodingStrategy: SmartDataDecodingStrategy = .base64

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy?
        let dataDecodingStrategy: SmartDataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: SmartKeyDecodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level decoder.
    var options: _Options {
        _Options(
            dateDecodingStrategy: smartDateDecodingStrategy,
            dataDecodingStrategy: smartDataDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
            keyDecodingStrategy: smartKeyDecodingStrategy,
            userInfo: userInfo
        )
    }

    open var smartDateDecodingStrategy: DateDecodingStrategy?

    open var smartKeyDecodingStrategy: SmartKeyDecodingStrategy = .useDefaultKeys

    // MARK: - Decoding Values

    /// Decodes a top-level value of the given type from the given JSON representation.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter data: The data to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    override open func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let mark = SmartSentinel.parsingMark()
        if let parsingMark = CodingUserInfoKey.parsingMark {
            userInfo.updateValue(mark, forKey: parsingMark)
        }

        do {
            var parser = JSONParser(bytes: Array(data))
            let json = try parser.parse()
            let impl = JSONDecoderImpl(userInfo: userInfo, from: json, codingPath: [], options: options)
            let value = try impl.unwrap(as: type)
            SmartSentinel.monitorLogs(in: "\(type)", parsingMark: mark, impl: impl)
            return value
        } catch {
            SmartSentinel.monitorAndPrint(debugDescription: "The given data was not valid JSON.", error: error, in: type)
            throw error
        }
    }
}

extension CodingUserInfoKey {
    /// This parsing tag is used to summarize logs.
    static let parsingMark = CodingUserInfoKey(rawValue: "Stamrt.parsingMark")

    static let logContextHeader = CodingUserInfoKey(rawValue: "Stamrt.logContext.header")
    static let logContextFooter = CodingUserInfoKey(rawValue: "Stamrt.logContext.footer")
}

extension JSONDecoder {
    public enum SmartDataDecodingStrategy: Sendable {
        /// Decode the `Data` from a Base64-encoded string. This is the default strategy.
        case base64
    }
}

extension JSONDecoder {
    public enum SmartKeyDecodingStrategy: Sendable {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
        ///
        /// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from snake case to camel case:
        /// 1. Capitalizes the word starting after each `_`
        /// 2. Removes all `_`
        /// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
        /// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
        ///
        /// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
        case fromSnakeCase

        /// Convert the first letter of the key to lower case before attempting to match a key with the one specified by each type.
        /// For example, `OneTwoThree` becomes `oneTwoThree`.
        ///
        /// - Note: This strategy should be used with caution, especially if the key's first letter is intended to be uppercase for distinguishing purposes. It also incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterLower

        /// Convert the first letter of the key to upper case before attempting to match a key with the one specified by each type.
        /// For example, `oneTwoThree` becomes `OneTwoThree`.
        ///
        /// - Note: This strategy should be used when the keys are expected to start with a lowercase letter and need to be converted to start with an uppercase letter. It incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterUpper
    }
}

extension JSONDecoder.SmartKeyDecodingStrategy {
    static func _convertFirstLetterToLowercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).lowercased() + stringKey.dropFirst()
    }

    static func _convertFirstLetterToUppercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).uppercased() + stringKey.dropFirst()
    }

    static func _convertFromSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        // Find the first non-underscore character
        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return stringKey
        }

        // Find the last non-underscore character
        var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
        while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
            stringKey.formIndex(before: &lastNonUnderscore)
        }

        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

        let components = stringKey[keyRange].split(separator: "_")
        let joinedString: String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result: String
        if leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty {
            result = joinedString
        } else if !leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty {
            // Both leading and trailing underscores
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if !leadingUnderscoreRange.isEmpty {
            // Just leading
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }
        return result
    }
}

/// Handles key mapping and conversion for JSON values during decoding
enum KeysMapper {
    /// Converts JSON values according to the target type's key mapping rules
    /// - Parameters:
    ///   - jsonValue: The original JSON value to convert
    ///   - type: The target type for decoding
    /// - Returns: Converted JSON value or nil if conversion fails
    static func convertFrom(_ jsonValue: JSONValue, type: Any.Type) -> JSONValue? {
        // Type is not Model, no key renaming needed
        guard let type = type as? SmartDecodable.Type else { return jsonValue }

        switch jsonValue {
        case let .string(stringValue):
            // Handle string values that might contain JSON
            if let value = parseJSON(from: stringValue, as: type) {
                return JSONValue.make(value)
            }

        case let .object(dictValue):
            // Convert dictionary keys according to mapping rules
            if let dict = mapDictionary(dict: dictValue, using: type) as? [String: JSONValue] {
                return JSONValue.object(dict)
            }

        default:
            break
        }
        return nil
    }

    /// Parses a string into JSON object and applies key mapping
    private static func parseJSON(from string: String, as type: SmartDecodable.Type) -> Any? {
        guard let jsonObject = string.toJSONObject() else { return string }
        if let dict = jsonObject as? [String: Any] {
            // Apply key mapping to dictionary
            return mapDictionary(dict: dict, using: type)
        } else {
            return jsonObject
        }
    }

    /// Applies key mapping rules to a dictionary
    private static func mapDictionary(dict: [String: Any], using type: SmartDecodable.Type) -> [String: Any]? {
        guard let mappings = type.mappingForKey(), !mappings.isEmpty else { return nil }

        var newDict = dict
        for mapping in mappings {
            let newKey = mapping.to.stringValue

            /**
             * Check if the original field is an interference field (exists in mapping relationship)
             * Interference field scenario: Note cases like CodingKeys.name <--- ["newName"]
             * Valid field scenario: Note cases like CodingKeys.name <--- ["name", "newName"]
             */
            if !(mapping.from.contains(newKey)) {
                newDict.removeValue(forKey: newKey)
            }

            // break effect: Prefer the first non-null field
            for oldKey in mapping.from {
                // Mapping exists at current level
                if let value = dict[oldKey] as? JSONValue, value != .null {
                    newDict[newKey] = value
                    break
                }

                // Mapping requires cross-level path handling
                if let pathValue = dict.getValue(forKeyPath: oldKey) {
                    newDict.updateValue(pathValue, forKey: newKey)
                    break
                }
            }
        }
        return newDict
    }
}

extension Dictionary {
    /// Retrieves the value corresponding to the path in the dictionary.
    ///  let dict = [
    ///      "inDict": [
    ///         "name": "Mccc"
    ///      ]
    ///  ]
    ///
    ///  keyPath is “inDict.name”
    ///
    ///  result： Mccc
    ///
    fileprivate func getValue(forKeyPath keyPath: String) -> Any? {
        guard keyPath.contains(".") else { return nil }
        let keys = keyPath.components(separatedBy: ".")
        var currentAny: Any = self
        for key in keys {
            if let currentDict = currentAny as? [String: Any] {
                if let value = currentDict[key] {
                    currentAny = value
                } else {
                    return nil
                }
            } else if case let JSONValue.object(object) = currentAny, let temp = object[key] {
                currentAny = temp
            } else {
                return nil
            }
        }
        return currentAny
    }
}

extension String {
    func toJSONObject() -> Any? {
        guard starts(with: "{") || starts(with: "[") else { return nil }
        return data(using: .utf8).flatMap { try? JSONSerialization.jsonObject(with: $0) }
    }
}

/// Caches default values during decoding operations
/// Used to provide fallback values when decoding fails
class DecodingCache: Cachable {
    typealias SomeSnapshot = DecodingSnapshot

    /// Stack of decoding snapshots
    var snapshots: [DecodingSnapshot] = []

    /// Creates and stores a snapshot of initial values for a Decodable type
    /// - Parameter type: The Decodable type to cache
    func cacheSnapshot<T>(for type: T.Type) {
        // 减少动态派发开销，is 检查是编译时静态行为，比 as? 动态转换更高效。
        guard type is SmartDecodable.Type else { return }

        if let object = type as? SmartDecodable.Type {
            let snapshot = DecodingSnapshot()
            // [initialValues] Lazy initialization:
            // Generate initial values via reflection only when first accessed,
            // using the recorded objectType to optimize parsing performance.
            snapshot.objectType = object
            snapshots.append(snapshot)
        }
    }

    /// Removes the most recent snapshot for the given type
    /// - Parameter type: The type to remove from cache
    func removeSnapshot<T>(for type: T.Type) {
        guard T.self is SmartDecodable.Type else { return }
        if !snapshots.isEmpty {
            snapshots.removeLast()
        }
    }
}

extension DecodingCache {
    /// Retrieves a cached value for the given coding key
    /// - Parameter key: The coding key to look up
    /// - Returns: The cached value if available, nil otherwise
    func initialValueIfPresent<T>(forKey key: CodingKey?) -> T? {
        guard let key else { return nil }

        // Lazy initialization: Generate initial values via reflection only when first accessed,
        // using the recorded objectType to optimize parsing performance
        if topSnapshot?.initialValues.isEmpty ?? true {
            populateInitialValues()
        }

        guard let cacheValue = topSnapshot?.initialValues[key.stringValue] else {
            // Handle @propertyWrapper cases (prefixed with underscore)
            return handlePropertyWrapperCases(for: key)
        }

        // When the CGFloat type is resolved,
        // it is resolved as Double. So we need to do a type conversion.
        if T.self == CGFloat.self, let temp = cacheValue as? CGFloat {
            return Double(temp) as? T
        }

        if let value = cacheValue as? T {
            return value
        } else if let caseValue = cacheValue as? any SmartCaseDefaultable {
            return caseValue.rawValue as? T
        }

        return nil
    }

    func initialValue<T>(forKey key: CodingKey?) throws -> T {
        guard let value: T = initialValueIfPresent(forKey: key) else {
            return try Patcher<T>.defaultForType()
        }
        return value
    }

    /// 获取转换器
    func valueTransformer(for key: CodingKey?) -> SmartValueTransformer? {
        guard let lastKey = key else { return nil }

        // Initialize transformers only once
        if topSnapshot?.transformers?.isEmpty ?? true {
            return nil
        }

        let transformer = topSnapshot?.transformers?.first(where: {
            $0.location.stringValue == lastKey.stringValue
        })
        return transformer
    }

    /// Handles property wrapper cases (properties prefixed with underscore)
    private func handlePropertyWrapperCases<T>(for key: CodingKey) -> T? {
        if let cached = topSnapshot?.initialValues["_" + key.stringValue] {
            return extractWrappedValue(from: cached)
        }

        return snapshots.reversed().lazy.compactMap {
            $0.initialValues["_" + key.stringValue]
        }.first.flatMap(extractWrappedValue)
    }

    /// Extracts wrapped value from potential property wrapper types
    private func extractWrappedValue<T>(from value: Any) -> T? {
        if let wrapper = value as? IgnoredKey<T> {
            return wrapper.wrappedValue
        } else if let wrapper = value as? SmartAny<T> {
            return wrapper.wrappedValue
        } else if let value = value as? T {
            return value
        }
        return nil
    }

    private func populateInitialValues() {
        guard let type = topSnapshot?.objectType else { return }

        // Recursively captures initial values from a type and its superclasses
        func captureInitialValues(from mirror: Mirror) {
            for child in mirror.children {
                if let key = child.label {
                    snapshots.last?.initialValues[key] = child.value
                }
            }
            if let superclassMirror = mirror.superclassMirror {
                captureInitialValues(from: superclassMirror)
            }
        }

        let mirror = Mirror(reflecting: type.init())
        captureInitialValues(from: mirror)
    }
}

/// Snapshot of decoding state for a particular model
class DecodingSnapshot: Snapshot {
    typealias ObjectType = SmartDecodable.Type

    var objectType: (any SmartDecodable.Type)?

    lazy var transformers: [SmartValueTransformer]? = objectType?.mappingForValue()

    /// Dictionary storing initial values of properties
    /// Key: Property name, Value: Initial value
    var initialValues: [String: Any] = [:]
}

extension DecodingError {
    static func _keyNotFound(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key)."))
    }

    static func _valueNotFound(key: CodingKey, expectation: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.valueNotFound(expectation, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode '\(expectation)' but found 'null' instead."))
    }

    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter desc: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, desc: String) -> DecodingError {
        let description = "Expected to decode '\(expectation)' but found \(desc) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    private static func _typeDescription(of value: Any?) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber /* FIXME: If swift-corelibs-foundation isn't updated to use NSNumber, this check will be necessary: || value is Int || value is Double */ {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String: Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}

struct JSONDecoderImpl {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    let json: JSONValue
    let options: SmartJSONDecoder._Options

    /// Records the initialization values of the properties in the keyed container.
    var cache: DecodingCache

    init(userInfo: [CodingUserInfoKey: Any], from json: JSONValue, codingPath: [CodingKey], options: SmartJSONDecoder._Options) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.json = json
        self.options = options
        self.cache = DecodingCache()
    }
}

// Regarding the generation of containers, there is no need for compatibility,
// when the type is wrong, an exception is thrown,
// and when the exception is handled, the initial value can be obtained.
extension JSONDecoderImpl: Decoder {
    func container<Key>(keyedBy key: Key.Type) throws ->
        KeyedDecodingContainer<Key> where Key: CodingKey {
        switch json {
        case let .object(dictionary):
            let container = KeyedContainer<Key>(
                impl: self,
                codingPath: codingPath,
                dictionary: dictionary
            )
            return KeyedDecodingContainer(container)
        case let .string(string): // json string modeling compatibility
            if let dict = string.toJSONObject() as? [String: Any],
               let dictionary = JSONValue.make(dict)?.object {
                let container = KeyedContainer<Key>(
                    impl: self,
                    codingPath: codingPath,
                    dictionary: dictionary
                )
                return KeyedDecodingContainer(container)
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get keyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError._typeMismatch(at: codingPath, expectation: [String: JSONValue].self, desc: json.debugDataTypeDescription)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch json {
        case let .array(array):
            return UnkeyedContainer(
                impl: self,
                codingPath: codingPath,
                array: array
            )
        case let .string(string): // json字符串的模型化兼容
            if let arr = string.toJSONObject() as? [Any],
               let array = JSONValue.make(arr)?.array {
                return UnkeyedContainer(
                    impl: self,
                    codingPath: codingPath,
                    array: array
                )
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get unkeyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError.typeMismatch([JSONValue].self, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected to decode \([JSONValue].self) but found \(json.debugDataTypeDescription) instead."
        ))
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SingleValueContainer(
            impl: self,
            codingPath: codingPath,
            json: json
        )
    }
}

struct _JSONKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    static let `super` = _JSONKey(stringValue: "super")!
}

extension JSONDecoderImpl {
    /// A container that provides a view into a JSON dictionary and decodes values from it
    struct KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K

        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let dictionary: [String: JSONValue]

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], dictionary: [String: JSONValue]) {
            self.codingPath = codingPath

            self.dictionary = _convertDictionary(dictionary, impl: impl)
            // The transformation of the dictionary does not affect the structure,
            // but only adds a new field to the data corresponding to the current container.
            // No impl changes are required
            self.impl = impl
        }

        var allKeys: [K] {
            dictionary.keys.compactMap { K(stringValue: $0) }
        }

        func contains(_ key: K) -> Bool {
            if let _ = dictionary[key.stringValue] {
                return true
            }
            return false
        }

        func decodeNil(forKey key: K) throws -> Bool {
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: codingPath)
            }
            return value == .null
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            try decoderForKey(key).container(keyedBy: type)
        }

        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            try decoderForKey(key).unkeyedContainer()
        }

        func superDecoder() throws -> Decoder {
            decoderForKeyNoThrow(_JSONKey.super)
        }

        func superDecoder(forKey key: K) throws -> Decoder {
            decoderForKeyNoThrow(key)
        }

        private func decoderForKey<LocalKey: CodingKey>(_ key: LocalKey) throws -> JSONDecoderImpl {
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: codingPath)
            }

            var newPath = codingPath
            newPath.append(key)

            return JSONDecoderImpl(userInfo: impl.userInfo, from: value, codingPath: newPath, options: impl.options)
        }

        private func decoderForKeyCompatibleForJson<LocalKey: CodingKey, T>(_ key: LocalKey, type: T.Type) throws -> JSONDecoderImpl {
            guard let value = getValue(forKey: key) else {
                throw DecodingError._keyNotFound(key: key, codingPath: codingPath)
            }
            var newPath = codingPath
            newPath.append(key)

            var newImpl = JSONDecoderImpl(userInfo: impl.userInfo, from: value, codingPath: newPath, options: impl.options)

            // If the new parser is not a parse Model,
            // it inherits the cache from the previous one.
            if !(type is SmartDecodable.Type) {
                newImpl.cache = impl.cache
            }

            return newImpl
        }

        private func decoderForKeyNoThrow<LocalKey: CodingKey>(_ key: LocalKey) -> JSONDecoderImpl {
            let value: JSONValue = getValue(forKey: key) ?? .null
            var newPath = codingPath
            newPath.append(key)

            return JSONDecoderImpl(
                userInfo: impl.userInfo,
                from: value,
                codingPath: newPath,
                options: impl.options
            )
        }

        @inline(__always) private func getValue<LocalKey: CodingKey>(forKey key: LocalKey) -> JSONValue? {
            guard let value = dictionary[key.stringValue] else { return nil }
            return value
        }
    }
}

extension JSONDecoderImpl.KeyedContainer {
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        try _decodeBoolValue(key: key)
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        try _decodeStringValue(key: key)
    }

    func decode(_: Double.Type, forKey key: K) throws -> Double {
        try _decodeFloatingPoint(key: key)
    }

    func decode(_: CGFloat.Type, forKey key: K) throws -> CGFloat {
        let value = try decode(Double.self, forKey: key)
        return CGFloat(value)
    }

    func decode(_: Float.Type, forKey key: K) throws -> Float {
        try _decodeFloatingPoint(key: key)
    }

    func decode(_: Int.Type, forKey key: K) throws -> Int {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int8.Type, forKey key: K) throws -> Int8 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int16.Type, forKey key: K) throws -> Int16 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int32.Type, forKey key: K) throws -> Int32 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: Int64.Type, forKey key: K) throws -> Int64 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt.Type, forKey key: K) throws -> UInt {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt8.Type, forKey key: K) throws -> UInt8 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt16.Type, forKey key: K) throws -> UInt16 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt32.Type, forKey key: K) throws -> UInt32 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode(_: UInt64.Type, forKey key: K) throws -> UInt64 {
        try _decodeFixedWidthInteger(key: key)
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        try _decodeDecodable(type, forKey: key)
    }
}

extension JSONDecoderImpl.KeyedContainer {
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        _decodeBoolValueIfPresent(key: key)
    }

    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        _decodeStringValueIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? {
        _decodeFloatingPointIfPresent(key: key)
    }

    func decodeIfPresent(_ type: CGFloat.Type, forKey key: K) throws -> CGFloat? {
        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return CGFloat(value)
        }
        return nil
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        _decodeFloatingPointIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? {
        _decodeFixedWidthIntegerIfPresent(key: key)
    }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable {
        _decodeDecodableIfPresent(type, forKey: key)
    }
}

extension JSONDecoderImpl.KeyedContainer {
    fileprivate func _compatibleDecode<T>(forKey key: Key, needConvert: Bool = true) -> T? {
        guard let value = getValue(forKey: key) else {
            SmartSentinel.monitorLog(impl: impl, forKey: key, value: nil, type: T.self)
            return impl.cache.initialValueIfPresent(forKey: key)
        }

        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)

        if needConvert {
            if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
                return decoded
            }
        }
        return impl.cache.initialValueIfPresent(forKey: key)
    }

    /// Performs post-mapping cleanup and notifications
    fileprivate func didFinishMapping<T>(_ decodeValue: T) -> T {
        // Properties wrapped by property wrappers don't conform to SmartDecodable protocol.
        // Here we use PostDecodingHookable as an intermediary layer for processing.
        if var value = decodeValue as? SmartDecodable {
            value.didFinishMapping()
            if let temp = value as? T { return temp }
        } else if let value = decodeValue as? PostDecodingHookable {
            if let temp = value.wrappedValueDidFinishMapping() as? T {
                return temp
            }
        }
        return decodeValue
    }

    private func decodeWithTransformer<T>(_ transformer: SmartValueTransformer,
                                          type: T.Type,
                                          key: K) -> T? where T: Decodable {
        // 处理属性包装类型
        if let propertyWrapperType = T.self as? any PropertyWrapperInitializable.Type {
            if type is FlatType.Type, let decoded = transformer.tranform(value: impl.json),
               let wrapperValue = propertyWrapperType.createInstance(with: decoded) as? T {
                return didFinishMapping(wrapperValue)
            }

            if let value = getValue(forKey: key),
               let decoded = transformer.tranform(value: value),
               let wrapperValue = propertyWrapperType.createInstance(with: decoded) as? T {
                return didFinishMapping(wrapperValue)
            }
        }

        // 处理普通类型转换
        if let value = getValue(forKey: key),
           let decoded = transformer.tranform(value: value) as? T {
            return didFinishMapping(decoded)
        }
        return nil
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeFixedWidthIntegerIfPresent<T: FixedWidthInteger>(key: Self.Key) -> T? {
        guard let value = getValue(forKey: key) else { return _compatibleDecode(forKey: key) }
        guard let decoded = impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
            return _compatibleDecode(forKey: key)
        }
        return decoded
    }

    @inline(__always) private func _decodeFixedWidthInteger<T: FixedWidthInteger>(key: Self.Key) throws -> T {
        if let decoded: T = _decodeFixedWidthIntegerIfPresent(key: key) { return decoded }
        return try Patcher<T>.defaultForType()
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeFloatingPointIfPresent<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) -> T? {
        guard let value = getValue(forKey: key) else { return _compatibleDecode(forKey: key) }
        guard let decoded = impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return _compatibleDecode(forKey: key)
        }
        return decoded
    }

    @inline(__always) private func _decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) throws -> T {
        if let decoded: T = _decodeFloatingPointIfPresent(key: key) { return decoded }
        return try Patcher<T>.defaultForType()
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeBoolValueIfPresent(key: K) -> Bool? {
        guard let value = getValue(forKey: key) else { return _compatibleDecode(forKey: key) }
        guard let decoded = impl.unwrapBoolValue(from: value, for: key) else {
            return _compatibleDecode(forKey: key)
        }
        return decoded
    }

    @inline(__always) private func _decodeBoolValue(key: K) throws -> Bool {
        if let decoded = _decodeBoolValueIfPresent(key: key) { return decoded }
        return try Patcher<Bool>.defaultForType()
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeStringValueIfPresent(key: K) -> String? {
        guard let value = getValue(forKey: key) else { return _compatibleDecode(forKey: key) }
        guard let decoded = impl.unwrapStringValue(from: value, for: key) else {
            return _compatibleDecode(forKey: key)
        }
        return decoded
    }

    @inline(__always) private func _decodeStringValue(key: K) throws -> String {
        if let decoded = _decodeStringValueIfPresent(key: key) { return decoded }
        return try Patcher<String>.defaultForType()
    }
}

extension JSONDecoderImpl.KeyedContainer {
    @inline(__always) private func _decodeDecodableIfPresent<T: Decodable>(_ type: T.Type, forKey key: K) -> T? {
        // 检查是否有值转换器
        if let transformer = impl.cache.valueTransformer(for: key) {
            if let decoded = decodeWithTransformer(transformer, type: type, key: key) {
                return didFinishMapping(decoded)
            }
            if let decoded: T = _compatibleDecode(forKey: key, needConvert: false) {
                return didFinishMapping(decoded)
            }
            return nil
        }

        /// @SmartFlat的处理
        if let type = type as? FlatType.Type {
            if type.isArray {
                return try? T(from: superDecoder(forKey: key))
            } else {
                return try? T(from: impl)
            }
        }

        guard let newDecoder = try? decoderForKeyCompatibleForJson(key, type: type) else {
            return _compatibleDecode(forKey: key)
        }

        if let decoded = try? newDecoder.unwrap(as: type) {
            return didFinishMapping(decoded)
        }

        if let decoded: T = _compatibleDecode(forKey: key) {
            return didFinishMapping(decoded)
        } else {
            return nil
        }
    }

    @inline(__always) private func _decodeDecodable<T: Decodable>(_ type: T.Type, forKey key: K) throws -> T {
        if let decoded: T = _decodeDecodableIfPresent(type, forKey: key) { return decoded }
        return try Patcher<T>.defaultForType()
    }
}

/// Handles correspondence between field names that need to be parsed.
private func _convertDictionary(_ dictionary: [String: JSONValue], impl: JSONDecoderImpl) -> [String: JSONValue] {
    var dictionary = dictionary

    switch impl.options.keyDecodingStrategy {
    case .useDefaultKeys:
        break
    case .fromSnakeCase:
        // Convert the snake case keys in the container to camel case.
        // If we hit a duplicate key after conversion, then we'll use the first one we saw. Effectively an undefined behavior with JSON dictionaries.
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFromSnakeCase(dict.key), dict.value)
        }, uniquingKeysWith: { first, _ in first })
    case .firstLetterLower:
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFirstLetterToLowercase(dict.key), dict.value)
        }, uniquingKeysWith: { first, _ in first })
    case .firstLetterUpper:
        dictionary = Dictionary(dictionary.map {
            dict in (JSONDecoder.SmartKeyDecodingStrategy._convertFirstLetterToUppercase(dict.key), dict.value)
        }, uniquingKeysWith: { first, _ in first })
    }

    guard let type = impl.cache.topSnapshot?.objectType else { return dictionary }

    if let tempValue = KeysMapper.convertFrom(JSONValue.object(dictionary), type: type), let dict = tempValue.object {
        return dict
    }
    return dictionary
}

extension JSONDecoderImpl {
    struct SingleValueContainer: SingleValueDecodingContainer {
        let impl: JSONDecoderImpl
        let value: JSONValue
        let codingPath: [CodingKey]

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], json: JSONValue) {
            self.impl = impl
            self.codingPath = codingPath
            self.value = json
        }

        func decodeNil() -> Bool {
            value == .null
        }
    }
}

extension JSONDecoderImpl.SingleValueContainer {
    func decode(_: Bool.Type) throws -> Bool {
        guard case let .bool(bool) = value else {
            if let trans = Patcher<Bool>.convertToType(from: value, impl: impl) {
                return trans
            }
            throw impl.createTypeMismatchError(type: Bool.self, value: value)
        }

        return bool
    }

    func decode(_: String.Type) throws -> String {
        guard case let .string(string) = value else {
            if let trans = Patcher<String>.convertToType(from: value, impl: impl) {
                return trans
            }
            throw impl.createTypeMismatchError(type: String.self, value: value)
        }
        return string
    }

    func decode(_: Double.Type) throws -> Double {
        try decodeFloatingPoint()
    }

    func decode(_: Float.Type) throws -> Float {
        try decodeFloatingPoint()
    }

    func decode(_: Int.Type) throws -> Int {
        try decodeFixedWidthInteger()
    }

    func decode(_: Int8.Type) throws -> Int8 {
        try decodeFixedWidthInteger()
    }

    func decode(_: Int16.Type) throws -> Int16 {
        try decodeFixedWidthInteger()
    }

    func decode(_: Int32.Type) throws -> Int32 {
        try decodeFixedWidthInteger()
    }

    func decode(_: Int64.Type) throws -> Int64 {
        try decodeFixedWidthInteger()
    }

    func decode(_: UInt.Type) throws -> UInt {
        try decodeFixedWidthInteger()
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        try decodeFixedWidthInteger()
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        try decodeFixedWidthInteger()
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        try decodeFixedWidthInteger()
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        try decodeFixedWidthInteger()
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try impl.unwrap(as: type)
    }

    @inline(__always) private func decodeFixedWidthInteger<T: FixedWidthInteger>() throws -> T {
        if let decoded = impl.unwrapFixedWidthInteger(from: value, as: T.self) {
            return decoded
        }
        if let trnas = Patcher<T>.convertToType(from: value, impl: impl) {
            return trnas
        } else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath,
                debugDescription: "Parsed JSON number does not fit in \(T.self)."
            ))
        }
    }

    @inline(__always) private func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
        if let decoded = impl.unwrapFloatingPoint(from: value, as: T.self) {
            return decoded
        }
        if let trnas = Patcher<T>.convertToType(from: value, impl: impl) {
            return trnas
        } else {
            throw DecodingError.typeMismatch(T.self, .init(
                codingPath: codingPath,
                debugDescription: "Expected to decode \(T.self) but found \(value.debugDataTypeDescription) instead."
            ))
        }
    }
}

extension JSONDecoderImpl {
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let array: [JSONValue]

        var count: Int? { array.count }
        var isAtEnd: Bool { currentIndex >= (count ?? 0) }
        var currentIndex = 0

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], array: [JSONValue]) {
            self.impl = impl
            self.codingPath = codingPath
            self.array = array
        }

        mutating func decodeNil() throws -> Bool {
            if try getNextValue(ofType: Never.self) == .null {
                currentIndex += 1
                return true
            }

            // The protocol states:
            //   If the value is not null, does not increment currentIndex.
            return false
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            let decoder = decoderForNextElement(ofType: KeyedDecodingContainer<NestedKey>.self)
            let container = try decoder.container(keyedBy: type)

            currentIndex += 1
            return container
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let decoder = decoderForNextElement(ofType: UnkeyedDecodingContainer.self)
            let container = try decoder.unkeyedContainer()

            currentIndex += 1
            return container
        }

        mutating func superDecoder() throws -> Decoder {
            let decoder = decoderForNextElement(ofType: Decoder.self)
            currentIndex += 1
            return decoder
        }

        private mutating func decoderForNextElement<T>(ofType: T.Type) -> JSONDecoderImpl {
            var value: JSONValue
            do {
                value = try getNextValue(ofType: T.self)
            } catch {
                value = JSONValue.array([])
            }

            let newPath = codingPath + [_JSONKey(index: currentIndex)]

            return JSONDecoderImpl(
                userInfo: impl.userInfo,
                from: value,
                codingPath: newPath,
                options: impl.options
            )
        }
    }
}

// Because UnkeyedDecodingContainer itself is not directly associated with a particular model property,
// but is used to parse unlabeled sequences,
// it does not automatically select a decoding method for a particular type.
// Instead, it tries to use generic decoding methods so that it can handle values of various types.
// Specific types of decode methods, the use of scenarios are relatively few,
// `let first = try unkeyedContainer.decode(Int.self) '.
extension JSONDecoderImpl.UnkeyedContainer {
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = try? getNextValue(ofType: Bool.self) else {
            return try forceDecode()
        }
        guard case let .bool(bool) = value else {
            return try forceDecode()
        }
        currentIndex += 1
        return bool
    }

    mutating func decode(_ type: String.Type) throws -> String {
        guard let value = try? getNextValue(ofType: Bool.self) else {
            return try forceDecode()
        }
        guard case let .string(string) = value else {
            return try forceDecode()
        }
        currentIndex += 1
        return string
    }

    mutating func decode(_: Double.Type) throws -> Double {
        try decodeFloatingPoint()
    }

    mutating func decode(_: Float.Type) throws -> Float {
        try decodeFloatingPoint()
    }

    mutating func decode(_: Int.Type) throws -> Int {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int8.Type) throws -> Int8 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int16.Type) throws -> Int16 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int32.Type) throws -> Int32 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: Int64.Type) throws -> Int64 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt.Type) throws -> UInt {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt8.Type) throws -> UInt8 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt16.Type) throws -> UInt16 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt32.Type) throws -> UInt32 {
        try decodeFixedWidthInteger()
    }

    mutating func decode(_: UInt64.Type) throws -> UInt64 {
        try decodeFixedWidthInteger()
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        // If it is a basic data type,
        // a new decoder is still created for parsing.
        // If type is of type Int, then SingleContainer is created.
        let newDecoder = decoderForNextElement(ofType: type)

        // Because of the requirement that the index not be incremented unless
        // decoding the desired result type succeeds, it can not be a tail call.
        // Hopefully the compiler still optimizes well enough that the result
        // doesn't get copied around.
        if codingPath.isEmpty {
            guard let result = try? newDecoder.unwrap(as: type) else {
                let decoded: T = try forceDecode()
                return didFinishMapping(decoded)
            }
            currentIndex += 1
            return didFinishMapping(result)
        } else {
            // If it is not the first level of array model parsing, it is not compatible.
            // Throw an exception to make keyedController compatible.
            let result = try newDecoder.unwrap(as: type)
            currentIndex += 1
            return didFinishMapping(result)
        }
    }

    @inline(__always) private mutating func decodeFixedWidthInteger<T: FixedWidthInteger>() throws -> T {
        guard let value = try? getNextValue(ofType: T.self) else {
            return try forceDecode()
        }

        let key = _JSONKey(index: currentIndex)
        guard let result = impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
            return try forceDecode()
        }
        currentIndex += 1
        return result
    }

    @inline(__always) private mutating func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
        guard let value = try? getNextValue(ofType: T.self) else {
            return try forceDecode()
        }

        let key = _JSONKey(index: currentIndex)
        guard let result = impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return try forceDecode()
        }
        currentIndex += 1
        return result
    }

    fileprivate mutating func forceDecode<T>() throws -> T {
        let key = _JSONKey(index: currentIndex)

        guard let value = try? getNextValue(ofType: T.self) else {
            let decoded: T = try impl.cache.initialValue(forKey: key)
            SmartSentinel.monitorLog(impl: impl, forKey: key, value: nil, type: T.self)
            currentIndex += 1
            return decoded
        }

        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)

        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            currentIndex += 1
            return decoded
        } else {
            let decoded: T = try impl.cache.initialValue(forKey: key)
            currentIndex += 1
            return decoded
        }
    }
}

extension JSONDecoderImpl.UnkeyedContainer {
    mutating func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        guard let value = try? getNextValue(ofType: Bool.self) else {
            return optionalDecode()
        }
        guard case let .bool(bool) = value else {
            return optionalDecode()
        }
        currentIndex += 1
        return bool
    }

    mutating func decodeIfPresent(_ type: String.Type) throws -> String? {
        currentIndex += 1
        guard let value = try? getNextValue(ofType: String.self) else {
            return optionalDecode()
        }
        guard case let .string(string) = value else {
            return optionalDecode()
        }
        currentIndex += 1
        return string
    }

    mutating func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        decodeIfPresentFloatingPoint()
    }

    mutating func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        decodeIfPresentFloatingPoint()
    }

    mutating func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        decodeIfPresentFixedWidthInteger()
    }

    mutating func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        decodeIfPresentFixedWidthInteger()
    }

    ///   is not convertible to the requested type.
    mutating func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T: Decodable {
        let newDecoder = decoderForNextElement(ofType: type)
        if let decoded = try? newDecoder.unwrap(as: type) {
            currentIndex += 1
            return didFinishMapping(decoded)
        } else if let decoded: T = optionalDecode() {
            currentIndex += 1
            return didFinishMapping(decoded)
        } else {
            currentIndex += 1
            return nil
        }
    }

    @inline(__always) private mutating func decodeIfPresentFixedWidthInteger<T: FixedWidthInteger>() -> T? {
        guard let value = try? getNextValue(ofType: T.self) else {
            return optionalDecode()
        }

        let key = _JSONKey(index: currentIndex)
        guard let result = impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
            return optionalDecode()
        }
        currentIndex += 1
        return result
    }

    @inline(__always) private mutating func decodeIfPresentFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() -> T? {
        guard let value = try? getNextValue(ofType: T.self) else {
            return optionalDecode()
        }

        let key = _JSONKey(index: currentIndex)
        guard let result = impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return optionalDecode()
        }
        currentIndex += 1
        return result
    }

    fileprivate mutating func optionalDecode<T>() -> T? {
        guard let value = try? getNextValue(ofType: T.self) else {
            currentIndex += 1
            return nil
        }
        let key = _JSONKey(index: currentIndex)
        SmartSentinel.monitorLog(impl: impl, forKey: key, value: value, type: T.self)
        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            currentIndex += 1
            return decoded
        } else {
            currentIndex += 1
            return nil
        }
    }
}

extension JSONDecoderImpl.UnkeyedContainer {
    // 被属性包装器包裹的，不会调用该方法。Swift的类型系统在运行时无法直接识别出wrappedValue的实际类型.
    fileprivate func didFinishMapping<T>(_ decodeValue: T) -> T {
        // 减少动态派发开销，is 检查是编译时静态行为，比 as? 动态转换更高效。
        guard T.self is SmartDecodable.Type else { return decodeValue }

        if var value = decodeValue as? SmartDecodable {
            value.didFinishMapping()
            if let temp = value as? T { return temp }
        } else if let value = decodeValue as? PostDecodingHookable {
            if let temp = value.wrappedValueDidFinishMapping() as? T {
                return temp
            }
        }
        return decodeValue
    }
}

extension JSONDecoderImpl.UnkeyedContainer {
    @inline(__always)
    private func getNextValue<T>(ofType: T.Type) throws -> JSONValue {
        guard !isAtEnd else {
            var message = "Unkeyed container is at end."

            if T.self == JSONDecoderImpl.UnkeyedContainer.self {
                message = "Cannot get nested unkeyed container -- unkeyed container is at end."
            }
            if T.self == Decoder.self {
                message = "Cannot get superDecoder() -- unkeyed container is at end."
            }

            var path = codingPath
            path.append(_JSONKey(index: currentIndex))

            throw DecodingError.valueNotFound(
                T.self,
                .init(codingPath: path,
                      debugDescription: message,
                      underlyingError: nil)
            )
        }
        return array[currentIndex]
    }
}

private protocol _JSONStringDictionaryDecodableMarker {
    static var elementType: Decodable.Type { get }
}

extension Dictionary: _JSONStringDictionaryDecodableMarker where Key == String, Value: Decodable {
    static var elementType: Decodable.Type { Value.self }
}

extension JSONDecoderImpl {
    // MARK: Special case handling

    func unwrap<T: Decodable>(as type: T.Type) throws -> T {
        if type == Date.self {
            return try unwrapDate() as! T
        }
        if type == Data.self {
            return try unwrapData() as! T
        }
        if type == URL.self {
            return try unwrapURL() as! T
        }
        if type == Decimal.self {
            return try unwrapDecimal() as! T
        }
        if type == CGFloat.self {
            return try unwrapCGFloat() as! T
        }

        if type is _JSONStringDictionaryDecodableMarker.Type {
            return try unwrapDictionary(as: type)
        }

        cache.cacheSnapshot(for: type)
        let decoded = try type.init(from: self)
        cache.removeSnapshot(for: type)
        return decoded
    }

    func unwrapFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(
        from value: JSONValue, for additionalKey: CodingKey? = nil, as type: T.Type
    ) -> T? {
        if let tranformer = cache.valueTransformer(for: additionalKey) {
            guard let decoded = tranformer.tranform(value: value) as? T else { return nil }
            return decoded
        }

        if case let .number(number) = value {
            guard let floatingPoint = T(number), floatingPoint.isFinite else { return nil }
            return floatingPoint
        }

        if case let .string(string) = value,
           case let .convertFromString(posInfString, negInfString, nanString) = options.nonConformingFloatDecodingStrategy {
            if string == posInfString {
                return T.infinity
            } else if string == negInfString {
                return -T.infinity
            } else if string == nanString {
                return T.nan
            }
        }

        return nil
    }

    func unwrapFixedWidthInteger<T: FixedWidthInteger>(
        from value: JSONValue, for additionalKey: CodingKey? = nil, as type: T.Type
    ) -> T? {
        if let tranformer = cache.valueTransformer(for: additionalKey) {
            return tranformer.tranform(value: value) as? T
        }

        guard case let .number(number) = value else { return nil }

        // this is the fast pass. Number directly convertible to Integer
        if let integer = T(number) {
            return integer
        }

        // this is the really slow path... If the fast path has failed. For example for "34.0" as
        // an integer, we try to go through NSNumber
        if let nsNumber = NSNumber.fromJSONNumber(number) {
            if type == UInt8.self, NSNumber(value: nsNumber.uint8Value) == nsNumber {
                return nsNumber.uint8Value as? T
            }
            if type == Int8.self, NSNumber(value: nsNumber.int8Value) == nsNumber {
                return nsNumber.int8Value as? T
            }
            if type == UInt16.self, NSNumber(value: nsNumber.uint16Value) == nsNumber {
                return nsNumber.uint16Value as? T
            }
            if type == Int16.self, NSNumber(value: nsNumber.int16Value) == nsNumber {
                return nsNumber.int16Value as? T
            }
            if type == UInt32.self, NSNumber(value: nsNumber.uint32Value) == nsNumber {
                return nsNumber.uint32Value as? T
            }
            if type == Int32.self, NSNumber(value: nsNumber.int32Value) == nsNumber {
                return nsNumber.int32Value as? T
            }
            if type == UInt64.self, NSNumber(value: nsNumber.uint64Value) == nsNumber {
                return nsNumber.uint64Value as? T
            }
            if type == Int64.self, NSNumber(value: nsNumber.int64Value) == nsNumber {
                return nsNumber.int64Value as? T
            }
            if type == UInt.self, NSNumber(value: nsNumber.uintValue) == nsNumber {
                return nsNumber.uintValue as? T
            }
            if type == Int.self, NSNumber(value: nsNumber.intValue) == nsNumber {
                return nsNumber.intValue as? T
            }
        }
        return nil
    }

    func unwrapBoolValue(from value: JSONValue, for additionalKey: CodingKey? = nil) -> Bool? {
        if let tranformer = cache.valueTransformer(for: additionalKey) {
            return tranformer.tranform(value: value) as? Bool
        }

        guard case let .bool(bool) = value else { return nil }
        return bool
    }

    func unwrapStringValue(from value: JSONValue, for additionalKey: CodingKey? = nil) -> String? {
        if let tranformer = cache.valueTransformer(for: additionalKey) {
            return tranformer.tranform(value: value) as? String
        }

        guard case let .string(string) = value else { return nil }
        return string
    }
}

extension JSONDecoderImpl {
    private func unwrapDate() throws -> Date {
        if let tranformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = tranformer.tranform(value: json) as? Date {
                return decoded
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Date is not valid , unknown anomaly"))
            }
        }

        let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)

        if let dateDecodingStrategy = options.dateDecodingStrategy {
            switch dateDecodingStrategy {
            case .deferredToDate:
                return try Date(from: self)

            case .secondsSince1970:
                let double = try container.decode(Double.self)
                return Date(timeIntervalSince1970: double)

            case .millisecondsSince1970:
                let double = try container.decode(Double.self)
                return Date(timeIntervalSince1970: double / 1000.0)

            case .iso8601:
                let string = try container.decode(String.self)
                guard let date = FrameworkConfiguration.smartModelFormatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }
                return date

            case let .formatted(formatter):
                let string = try container.decode(String.self)
                guard let date = formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Date string does not match format expected by formatter."))
                }
                return date

            case let .custom(closure):
                return try closure(self)

            @unknown default:
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Date is not valid , unknown anomaly"))
            }
        }

        // 如果没有设置策略，使用 DateParser 做兜底解析
        if let (date, _) = DateParser.parse(json.peel) {
            return date
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unsupported date format: \(json)"))
        }
    }

    private func unwrapData() throws -> Data {
        if let tranformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = tranformer.tranform(value: json) as? Data {
                return decoded
            }
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Data is not valid Base64."))
        }

        switch options.dataDecodingStrategy {
        case .base64:
            let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
            let string = try container.decode(String.self)

            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }

            return data
        }
    }

    private func unwrapURL() throws -> URL {
        if let tranformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = tranformer.tranform(value: json) as? URL {
                return decoded
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Invalid URL string."))
        }

        let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
        let string = try container.decode(String.self)

        guard let url = URL(string: string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Invalid URL string."))
        }
        return url
    }

    private func unwrapDecimal() throws -> Decimal {
        if let tranformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = tranformer.tranform(value: json) as? Decimal {
                return decoded
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath,
                debugDescription: "Parsed JSON number does not fit in \(Decimal.self)."
            ))
        }

        guard case let .number(numberString) = json else {
            throw DecodingError.typeMismatch(Decimal.self, DecodingError.Context(codingPath: codingPath, debugDescription: ""))
        }

        guard let decimal = Decimal(string: numberString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath,
                debugDescription: "Parsed JSON number <\(numberString)> does not fit in \(Decimal.self)."
            ))
        }

        return decimal
    }

    private func unwrapCGFloat() throws -> CGFloat {
        if let transformer = cache.valueTransformer(for: codingPath.last) {
            if let decoded = transformer.tranform(value: json) as? CGFloat {
                return decoded
            }
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath,
                debugDescription: "Parsed JSON value cannot be transformed to \(CGFloat.self)."
            ))
        }

        guard case let .number(numberString) = json else {
            throw DecodingError.typeMismatch(CGFloat.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected a JSON number for \(CGFloat.self), but found."
            ))
        }

        guard let doubleValue = Double(numberString) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: codingPath,
                debugDescription: "Parsed JSON number <\(numberString)> is not a valid Double for conversion to \(CGFloat.self)."
            ))
        }

        return CGFloat(doubleValue)
    }

    private func unwrapDictionary<T: Decodable>(as: T.Type) throws -> T {
        guard let dictType = T.self as? (_JSONStringDictionaryDecodableMarker & Decodable).Type else {
            preconditionFailure("Must only be called of T implements _JSONStringDictionaryDecodableMarker")
        }

        guard case let .object(object) = json else {
            throw DecodingError.typeMismatch([String: JSONValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode \([String: JSONValue].self) but found \(json.debugDataTypeDescription) instead."
            ))
        }

        var result = [String: Any]()

        for (key, value) in object {
            var newPath = codingPath
            newPath.append(_JSONKey(stringValue: key)!)
            let newDecoder = JSONDecoderImpl(
                userInfo: userInfo,
                from: value,
                codingPath: newPath,
                options: options
            )
            result[key] = try dictType.elementType.createByDirectlyUnwrapping(from: newDecoder)
        }
        return result as! T
    }

    func createTypeMismatchError(type: Any.Type, for additionalKey: CodingKey? = nil, value: JSONValue) -> DecodingError {
        var path = codingPath
        if let additionalKey {
            path.append(additionalKey)
        }

        return DecodingError.typeMismatch(type, .init(
            codingPath: path,
            debugDescription: "Expected to decode \(type) but found \(value.debugDataTypeDescription) instead."
        ))
    }
}

extension Decodable {
    fileprivate static func createByDirectlyUnwrapping(from decoder: JSONDecoderImpl) throws -> Self {
        if Self.self == URL.self
            || Self.self == Date.self
            || Self.self == Data.self
            || Self.self == Decimal.self
            || Self.self == SmartAnyImpl.self
            || Self.self is _JSONStringDictionaryDecodableMarker.Type {
            return try decoder.unwrap(as: Self.self)
        }
        return try Self(from: decoder)
    }
}

enum Patcher<T> {
    static func defaultForType() throws -> T {
        try Provider.defaultValue()
    }

    static func convertToType(from value: JSONValue?, impl: JSONDecoderImpl) -> T? {
        guard let value else { return nil }
        return Transformer.typeTransform(from: value, impl: impl)
    }
}

extension Patcher {
    enum Provider {
        static func defaultValue() throws -> T {
            if let value = T.self as? BasicType.Type {
                return value.init() as! T
            }

            // 处理 SmartDecodable 类型的对象
            if let decodable = T.self as? SmartDecodable.Type {
                return decodable.init() as! T
            }

            // 处理 SmartCaseDefaultable 类型的对象
            if let caseDefaultable = T.self as? any SmartCaseDefaultable.Type {
                if let first = caseDefaultable.allCases.first, let firstCase = first as? T {
                    return firstCase
                }
            }

            // ***处理 DefaultCaseCodable 类型的对象***
            if let caseCodable = T.self as? any DefaultCaseCodable.Type {
                return caseCodable.defaultCase as! T
            }

            // 处理 SmartAssociatedEnumerable 类型的对象
            if let associatedEnumerable = T.self as? any SmartAssociatedEnumerable.Type {
                return associatedEnumerable.defaultCase as! T
            }

            // 如果都没有匹配的类型，抛出错误
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: [], debugDescription: "Expected \(T.self) value，but an exception occurred！Please report this issue（请上报该问题）"))
        }
    }
}

extension Patcher {
    enum Transformer {
        static func typeTransform(from jsonValue: JSONValue, impl: JSONDecoderImpl) -> T? {
            (T.self as? TypeTransformable.Type)?.transformValue(from: jsonValue, impl: impl) as? T
        }
    }
}

private protocol TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Self?
}

extension Bool: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Bool? {
        switch value {
        case let .bool(bool):
            return bool
        case let .string(string):
            if ["1", "YES", "Yes", "yes", "TRUE", "True", "true"].contains(string) { return true }
            if ["0", "NO", "No", "no", "FALSE", "False", "false"].contains(string) { return false }
        case .number:
            if let int = impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
                if int == 1 {
                    return true
                } else if int == 0 {
                    return false
                }
            }
        default:
            break
        }
        return nil
    }
}

extension String: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> String? {
        switch value {
        case let .string(string):
            return string
        case let .number(number):
            if let int = impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
                return "\(int)"
            } else if let double = impl.unwrapFloatingPoint(from: value, as: Double.self) {
                return "\(double)"
            }
            return number
        default:
            break
        }
        return nil
    }
}

extension Int: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int? {
        _fixedWidthInteger(from: value)
    }
}

extension Int8: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int8? {
        _fixedWidthInteger(from: value)
    }
}

extension Int16: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int16? {
        _fixedWidthInteger(from: value)
    }
}

extension Int32: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int32? {
        _fixedWidthInteger(from: value)
    }
}

extension Int64: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Int64? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt8: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt8? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt16: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt16? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt32: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt32? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt64: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> UInt64? {
        _fixedWidthInteger(from: value)
    }
}

extension Float: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Float? {
        _floatingPoint(from: value)
    }
}

extension Double: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> Double? {
        _floatingPoint(from: value)
    }
}

extension CGFloat: TypeTransformable {
    static func transformValue(from value: JSONValue, impl: JSONDecoderImpl) -> CGFloat? {
        if let temp: Double = _floatingPoint(from: value) {
            return CGFloat(temp)
        }
        return nil
    }
}

private func _floatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(from value: JSONValue) -> T? {
    switch value {
    case let .string(string):
        return T(string)
    case let .number(number):
        return T(number)
    default:
        break
    }
    return nil
}

private func _fixedWidthInteger<T: FixedWidthInteger>(from value: JSONValue) -> T? {
    switch value {
    case let .string(string):
        if let integer = T(string) {
            return integer
        } else if let float = Double(string) {
            return _convertFloatToInteger(float)
        }
    case let .number(number):
        if let integer = T(number) {
            return integer
        } else if let float = Double(number) {
            return _convertFloatToInteger(float)
        }
    default:
        break
    }
    return nil
}

/// 统一的浮点数转整数方法（包含范围检查和转换策略）
private func _convertFloatToInteger<T: FixedWidthInteger>(_ float: Double) -> T? {
    // 前置检查
    guard float.isFinite,
          float >= Double(T.min),
          float <= Double(T.max) else {
        return nil
    }

    // 应用转换策略
    switch SmartCoding.numberConversionStrategy {
    case .strict: return T(exactly: float)
    case .truncate: return T(float)
    case .rounded: return T(float.rounded())
    }
}

// MARK: - JSONEncoder
open class SmartJSONEncoder: JSONEncoder, @unchecked Sendable {
    open var smartKeyEncodingStrategy: SmartKeyEncodingStrategy = .useDefaultKeys
    open var smartDataEncodingStrategy: SmartDataEncodingStrategy = .base64

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: SmartDataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: SmartKeyEncodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        _Options(dateEncodingStrategy: .secondsSince1970,
                 dataEncodingStrategy: smartDataEncodingStrategy,
                 nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                 keyEncodingStrategy: smartKeyEncodingStrategy,
                 userInfo: userInfo)
    }

    // MARK: - Encoding Values

    /// Encodes the given top-level value and returns its JSON representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded JSON data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    override open func encode<T: Encodable>(_ value: T) throws -> Data {
        let value: JSONValue = try encodeAsJSONValue(value)
        let writer = JSONValue.Writer(options: outputFormatting)
        let bytes = writer.writeValue(value)

        return Data(bytes)
    }

    func encodeAsJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        let encoder = JSONEncoderImpl(options: options, codingPath: [])
        guard let topLevel = try encoder.wrapEncodable(value, for: nil) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }

        return topLevel
    }
}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//

extension EncodingError {
    /// Returns a `.invalidValue` error describing the given invalid floating-point value.
    ///
    ///
    /// - parameter value: The value that was invalid to encode.
    /// - parameter path: The path of `CodingKey`s taken to encode this value.
    /// - returns: An `EncodingError` with the appropriate path and debug description.
    fileprivate static func _invalidFloatingPointValue<T: FloatingPoint>(_ value: T, at codingPath: [CodingKey]) -> EncodingError {
        let valueDescription: String
        if value == T.infinity {
            valueDescription = "\(T.self).infinity"
        } else if value == -T.infinity {
            valueDescription = "-\(T.self).infinity"
        } else {
            valueDescription = "\(T.self).nan"
        }

        let debugDescription = "Unable to encode \(valueDescription) directly in JSON. Use SmartJSONEncoder.NonConformingFloatEncodingStrategy.convertToString to specify how the value should be encoded."
        return .invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: debugDescription))
    }
}

extension JSONEncoder {
    /// Data的解析策略
    /// 由于是JSONEncoder解析器只能解析JSON数据，所以Data类型只能用base64.
    public enum SmartDataEncodingStrategy: Sendable {
        case base64
    }
}

extension JSONEncoder {
    public enum SmartKeyEncodingStrategy: Sendable {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to JSON payload.
        ///
        /// Capital characters are determined by testing membership in Unicode General Categories Lu and Lt.
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case toSnakeCase

        /// Convert the first letter of the key to lower case before attempting to match a key with the one specified by each type.
        /// For example, `OneTwoThree` becomes `oneTwoThree`.
        ///
        /// - Note: This strategy should be used with caution, especially if the key's first letter is intended to be uppercase for distinguishing purposes. It also incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterLower

        /// Convert the first letter of the key to upper case before attempting to match a key with the one specified by each type.
        /// For example, `oneTwoThree` becomes `OneTwoThree`.
        ///
        /// - Note: This strategy should be used when the keys are expected to start with a lowercase letter and need to be converted to start with an uppercase letter. It incurs a nominal performance cost, as the first character of each key needs to be inspected and possibly modified.
        case firstLetterUpper
    }
}

extension JSONEncoder.SmartKeyEncodingStrategy {
    static func _convertFirstLetterToLowercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).lowercased() + stringKey.dropFirst()
    }

    static func _convertFirstLetterToUppercase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        return stringKey.prefix(1).uppercased() + stringKey.dropFirst()
    }

    static func _convertToSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        var words: [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        // Find next uppercase character
        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }

            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map { range in
            stringKey[range].lowercased()
        }.joined(separator: "_")
        return result
    }
}

class EncodingCache: Cachable {
    typealias SomeSnapshot = EncodingSnapshot

    var snapshots: [EncodingSnapshot] = []

    /// Caches a snapshot for an Encodable type
    func cacheSnapshot<T>(for type: T.Type) {
        if let object = type as? SmartEncodable.Type {
            var snapshot = EncodingSnapshot()
            snapshot.objectType = object
            snapshot.transformers = object.mappingForValue()
            snapshots.append(snapshot)
        }
    }

    /// Removes the most recent snapshot for the given type
    func removeSnapshot<T>(for type: T.Type) {
        if let _ = T.self as? SmartEncodable.Type {
            if snapshots.count > 0 {
                snapshots.removeLast()
            }
        }
    }
}

extension EncodingCache {
    /// Transforms a value to JSON using the appropriate transformer
    /// - Parameters:
    ///   - value: The value to transform
    ///   - key: The associated coding key
    /// - Returns: The transformed JSON value or nil if no transformer applies
    func tranform(from value: Any, with key: CodingKey?) -> JSONValue? {
        guard let top = topSnapshot, let key else { return nil }

        let wantKey = key.stringValue
        let targetTran = top.transformers?.first(where: { transformer in
            if wantKey == transformer.location.stringValue {
                return true
            } else {
                if let keyTransformers = top.objectType?.mappingForKey() {
                    for keyTransformer in keyTransformers {
                        if keyTransformer.from.contains(wantKey) {
                            return true
                        }
                    }
                }
                return false
            }
        })

        if let tran = targetTran, let decoded = transform(decodedValue: value, performer: tran.performer) {
            return JSONValue.make(decoded)
        }

        return nil
    }

    /// Performs the actual value transformation
    private func transform<Transform: ValueTransformable>(decodedValue: Any, performer: Transform) -> Any? {
        // 首先检查是否是属性包装器
        if let propertyWrapper = decodedValue as? any PropertyWrapperInitializable {
            let wrappedValue = propertyWrapper.wrappedValue
            guard let value = wrappedValue as? Transform.Object else { return nil }
            return performer.transformToJSON(value)
        } else {
            guard let value = decodedValue as? Transform.Object else { return nil }
            return performer.transformToJSON(value)
        }
    }
}

/// Snapshot of encoding state for a particular model
struct EncodingSnapshot: Snapshot {
    var objectType: (any SmartEncodable.Type)?

    typealias ObjectType = SmartEncodable.Type

    var transformers: [SmartValueTransformer]?
}

enum JSONFuture {
    case value(JSONValue)
    case encoder(JSONEncoderImpl)
    case nestedArray(RefArray)
    case nestedObject(RefObject)

    class RefArray {
        private(set) var array: [JSONFuture] = []

        init() {
            array.reserveCapacity(10)
        }

        @inline(__always) func append(_ element: JSONValue) {
            array.append(.value(element))
        }

        @inline(__always) func append(_ encoder: JSONEncoderImpl) {
            array.append(.encoder(encoder))
        }

        @inline(__always) func appendArray() -> RefArray {
            let array = RefArray()
            self.array.append(.nestedArray(array))
            return array
        }

        @inline(__always) func appendObject() -> RefObject {
            let object = RefObject()
            array.append(.nestedObject(object))
            return object
        }

        var values: [JSONValue] {
            array.map { future -> JSONValue in
                switch future {
                case let .value(value):
                    return value
                case let .nestedArray(array):
                    return .array(array.values)
                case let .nestedObject(object):
                    return .object(object.values)
                case let .encoder(encoder):
                    return encoder.value ?? .object([:])
                }
            }
        }
    }

    class RefObject {
        private(set) var dict: [String: JSONFuture] = [:]

        init() {
            dict.reserveCapacity(20)
        }

        @inline(__always) func set(_ value: JSONValue, for key: String) {
            dict[key] = .value(value)
        }

        @inline(__always) func setArray(for key: String) -> RefArray {
            switch dict[key] {
            case .encoder:
                preconditionFailure("For key \"\(key)\" an encoder has already been created.")
            case .nestedObject:
                preconditionFailure("For key \"\(key)\" a keyed container has already been created.")
            case let .nestedArray(array):
                return array
            case .none, .value:
                let array = RefArray()
                dict[key] = .nestedArray(array)
                return array
            }
        }

        @inline(__always) func setObject(for key: String) -> RefObject {
            switch dict[key] {
            case .encoder:
                preconditionFailure("For key \"\(key)\" an encoder has already been created.")
            case let .nestedObject(object):
                return object
            case .nestedArray:
                preconditionFailure("For key \"\(key)\" a unkeyed container has already been created.")
            case .none, .value:
                let object = RefObject()
                dict[key] = .nestedObject(object)
                return object
            }
        }

        @inline(__always) func set(_ encoder: JSONEncoderImpl, for key: String) {
            switch dict[key] {
            case .encoder:
                preconditionFailure("For key \"\(key)\" an encoder has already been created.")
            case .nestedObject:
                preconditionFailure("For key \"\(key)\" a keyed container has already been created.")
            case .nestedArray:
                preconditionFailure("For key \"\(key)\" a unkeyed container has already been created.")
            case .none, .value:
                dict[key] = .encoder(encoder)
            }
        }

        var values: [String: JSONValue] {
            dict.mapValues { future -> JSONValue in
                switch future {
                case let .value(value):
                    return value
                case let .nestedArray(array):
                    return .array(array.values)
                case let .nestedObject(object):
                    return .object(object.values)
                case let .encoder(encoder):
                    return encoder.value ?? .object([:])
                }
            }
        }
    }
}

struct JSONKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol, _SpecialTreatmentEncoder {
    typealias Key = K

    let impl: JSONEncoderImpl
    let object: JSONFuture.RefObject
    let codingPath: [CodingKey]

    private var firstValueWritten: Bool = false
    var options: SmartJSONEncoder._Options {
        impl.options
    }

    init(impl: JSONEncoderImpl, codingPath: [CodingKey]) {
        self.impl = impl
        self.object = impl.object!
        self.codingPath = codingPath
    }

    // used for nested containers
    init(impl: JSONEncoderImpl, object: JSONFuture.RefObject, codingPath: [CodingKey]) {
        self.impl = impl
        self.object = object
        self.codingPath = codingPath
    }

    mutating func encodeNil(forKey key: Self.Key) throws {
        object.set(.null, for: _converted(key).stringValue)
    }

    mutating func encode(_ value: Bool, forKey key: Self.Key) throws {
        let convertedKey = _converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey) {
            object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            object.set(.bool(value), for: _converted(key).stringValue)
        }
    }

    mutating func encode(_ value: String, forKey key: Self.Key) throws {
        let convertedKey = _converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey) {
            object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            object.set(.string(value), for: convertedKey.stringValue)
        }
    }

    mutating func encode(_ value: Double, forKey key: Self.Key) throws {
        try encodeFloatingPoint(value, key: _converted(key))
    }

    mutating func encode(_ value: Float, forKey key: Self.Key) throws {
        try encodeFloatingPoint(value, key: _converted(key))
    }

    mutating func encode(_ value: Int, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: Int8, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: Int16, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: Int32, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: Int64, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: UInt, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: UInt8, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: UInt16, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: UInt32, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode(_ value: UInt64, forKey key: Self.Key) throws {
        try encodeFixedWidthInteger(value, key: _converted(key))
    }

    mutating func encode<T>(_ value: T, forKey key: Self.Key) throws where T: Encodable {
        let convertedKey = _converted(key)
        if let jsonValue = impl.cache.tranform(from: value, with: convertedKey) {
            object.set(jsonValue, for: convertedKey.stringValue)
        } else {
            if let encoded = try wrapEncodable(value, for: convertedKey) {
                object.set(encoded, for: convertedKey.stringValue)
            }
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Self.Key) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let convertedKey = _converted(key)
        let newPath = codingPath + [convertedKey]
        let object = object.setObject(for: convertedKey.stringValue)
        let nestedContainer = JSONKeyedEncodingContainer<NestedKey>(impl: impl, object: object, codingPath: newPath)
        return KeyedEncodingContainer(nestedContainer)
    }

    mutating func nestedUnkeyedContainer(forKey key: Self.Key) -> UnkeyedEncodingContainer {
        let convertedKey = _converted(key)
        let newPath = codingPath + [convertedKey]
        let array = object.setArray(for: convertedKey.stringValue)
        let nestedContainer = JSONUnkeyedEncodingContainer(impl: impl, array: array, codingPath: newPath)
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        let newEncoder = getEncoder(for: _JSONKey.super)
        object.set(newEncoder, for: _JSONKey.super.stringValue)
        return newEncoder
    }

    mutating func superEncoder(forKey key: Self.Key) -> Encoder {
        let convertedKey = _converted(key)
        let newEncoder = getEncoder(for: convertedKey)
        object.set(newEncoder, for: convertedKey.stringValue)
        return newEncoder
    }
}

extension JSONKeyedEncodingContainer {
    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F, key: CodingKey) throws {
        if let jsonValue = impl.cache.tranform(from: float, with: key) {
            object.set(jsonValue, for: key.stringValue)
        } else {
            let value = try wrapFloat(float, for: key)
            object.set(value, for: key.stringValue)
        }
    }

    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N, key: CodingKey) throws {
        if let jsonValue = impl.cache.tranform(from: value, with: key) {
            object.set(jsonValue, for: key.stringValue)
        } else {
            object.set(.number(value.description), for: key.stringValue)
        }
    }
}

struct JSONSingleValueEncodingContainer: SingleValueEncodingContainer, _SpecialTreatmentEncoder {
    let impl: JSONEncoderImpl
    let codingPath: [CodingKey]

    private var firstValueWritten: Bool = false
    var options: SmartJSONEncoder._Options {
        impl.options
    }

    init(impl: JSONEncoderImpl, codingPath: [CodingKey]) {
        self.impl = impl
        self.codingPath = codingPath
    }

    mutating func encodeNil() throws {
        preconditionCanEncodeNewValue()
        impl.singleValue = .null
    }

    mutating func encode(_ value: Bool) throws {
        preconditionCanEncodeNewValue()
        impl.singleValue = .bool(value)
    }

    mutating func encode(_ value: Int) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int8) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int16) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int32) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int64) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt8) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt16) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt32) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt64) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Float) throws {
        try encodeFloatingPoint(value)
    }

    mutating func encode(_ value: Double) throws {
        try encodeFloatingPoint(value)
    }

    mutating func encode(_ value: String) throws {
        preconditionCanEncodeNewValue()
        impl.singleValue = .string(value)
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        preconditionCanEncodeNewValue()
        impl.singleValue = try wrapEncodable(value, for: nil)
    }

    func preconditionCanEncodeNewValue() {
        precondition(impl.singleValue == nil, "Attempt to encode value through single value container when previously value already encoded.")
    }
}

extension JSONSingleValueEncodingContainer {
    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N) throws {
        preconditionCanEncodeNewValue()
        impl.singleValue = .number(value.description)
    }

    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F) throws {
        preconditionCanEncodeNewValue()
        let value = try wrapFloat(float, for: nil)
        impl.singleValue = value
    }
}

struct JSONUnkeyedEncodingContainer: UnkeyedEncodingContainer, _SpecialTreatmentEncoder {
    let impl: JSONEncoderImpl
    let array: JSONFuture.RefArray
    let codingPath: [CodingKey]

    var count: Int {
        array.array.count
    }

    private var firstValueWritten: Bool = false
    var options: SmartJSONEncoder._Options {
        impl.options
    }

    init(impl: JSONEncoderImpl, codingPath: [CodingKey]) {
        self.impl = impl
        self.array = impl.array!
        self.codingPath = codingPath
    }

    // used for nested containers
    init(impl: JSONEncoderImpl, array: JSONFuture.RefArray, codingPath: [CodingKey]) {
        self.impl = impl
        self.array = array
        self.codingPath = codingPath
    }

    mutating func encodeNil() throws {
        array.append(.null)
    }

    mutating func encode(_ value: Bool) throws {
        array.append(.bool(value))
    }

    mutating func encode(_ value: String) throws {
        array.append(.string(value))
    }

    mutating func encode(_ value: Double) throws {
        try encodeFloatingPoint(value)
    }

    mutating func encode(_ value: Float) throws {
        try encodeFloatingPoint(value)
    }

    mutating func encode(_ value: Int) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int8) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int16) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int32) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: Int64) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt8) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt16) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt32) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode(_ value: UInt64) throws {
        try encodeFixedWidthInteger(value)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        let key = _JSONKey(stringValue: "Index \(count)", intValue: count)
        let encoded = try wrapEncodable(value, for: key)
        array.append(encoded ?? .object([:]))
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let newPath = codingPath + [_JSONKey(index: count)]
        let object = array.appendObject()
        let nestedContainer = JSONKeyedEncodingContainer<NestedKey>(impl: impl, object: object, codingPath: newPath)
        return KeyedEncodingContainer(nestedContainer)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let newPath = codingPath + [_JSONKey(index: count)]
        let array = array.appendArray()
        let nestedContainer = JSONUnkeyedEncodingContainer(impl: impl, array: array, codingPath: newPath)
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        let encoder = getEncoder(for: _JSONKey(index: count))
        array.append(encoder)
        return encoder
    }
}

extension JSONUnkeyedEncodingContainer {
    @inline(__always) private mutating func encodeFixedWidthInteger<N: FixedWidthInteger>(_ value: N) throws {
        array.append(.number(value.description))
    }

    @inline(__always) private mutating func encodeFloatingPoint<F: FloatingPoint & CustomStringConvertible>(_ float: F) throws {
        let value = try wrapFloat(float, for: _JSONKey(index: count))
        array.append(value)
    }
}

class JSONEncoderImpl {
    let options: SmartJSONEncoder._Options
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] {
        options.userInfo
    }

    /// Records the initialization values of each attribute of the current keyed container.
    /// Records of Unkey containers are not supported.    var cache: EncodingCache
    var cache: EncodingCache

    var singleValue: JSONValue?
    var array: JSONFuture.RefArray?
    var object: JSONFuture.RefObject?

    var value: JSONValue? {
        if let object {
            return .object(object.values)
        }
        if let array {
            return .array(array.values)
        }
        return singleValue
    }

    init(options: SmartJSONEncoder._Options, codingPath: [CodingKey], cache: EncodingCache? = nil) {
        self.options = options
        self.codingPath = codingPath
        self.cache = cache ?? EncodingCache()
    }
}

extension JSONEncoderImpl: Encoder {
    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        if let _ = object {
            let container = JSONKeyedEncodingContainer<Key>(impl: self, codingPath: codingPath)
            return KeyedEncodingContainer(container)
        }

        guard singleValue == nil, array == nil else {
            preconditionFailure()
        }

        object = JSONFuture.RefObject()
        let container = JSONKeyedEncodingContainer<Key>(impl: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        if let _ = array {
            return JSONUnkeyedEncodingContainer(impl: self, codingPath: codingPath)
        }

        guard singleValue == nil, object == nil else {
            preconditionFailure()
        }

        array = JSONFuture.RefArray()
        return JSONUnkeyedEncodingContainer(impl: self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        guard object == nil, array == nil else {
            preconditionFailure()
        }

        return JSONSingleValueEncodingContainer(impl: self, codingPath: codingPath)
    }
}

// this is a private protocol to implement convenience methods directly on the EncodingContainers
extension JSONEncoderImpl: _SpecialTreatmentEncoder {
    var impl: JSONEncoderImpl {
        self
    }

    // untyped escape hatch. needed for `wrapObject`
    func wrapUntyped(_ encodable: Encodable) throws -> JSONValue {
        switch encodable {
        case let date as Date:
            return try wrapDate(date, for: nil)
        case let data as Data:
            return try wrapData(data, for: nil)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            return .number(decimal.description)
        case let object as [String: Encodable]: // this emits a warning, but it works perfectly
            return try wrapObject(object, for: nil)
        default:
            try encodable.encode(to: self)
            return value ?? .object([:])
        }
    }
}

protocol _JSONStringDictionaryEncodableMarker {}

extension Dictionary: _JSONStringDictionaryEncodableMarker where Key == String, Value: Encodable {}

protocol _SpecialTreatmentEncoder {
    var codingPath: [CodingKey] { get }
    var options: SmartJSONEncoder._Options { get }
    var impl: JSONEncoderImpl { get }
}

extension _SpecialTreatmentEncoder {
    @inline(__always)
    func wrapFloat<F: FloatingPoint & CustomStringConvertible>(_ float: F, for additionalKey: CodingKey?) throws -> JSONValue {
        guard !float.isNaN, !float.isInfinite else {
            if case let .convertToString(posInfString, negInfString, nanString) = options.nonConformingFloatEncodingStrategy {
                switch float {
                case F.infinity:
                    return .string(posInfString)
                case -F.infinity:
                    return .string(negInfString)
                default:
                    // must be nan in this case
                    return .string(nanString)
                }
            }

            var path = codingPath
            if let additionalKey {
                path.append(additionalKey)
            }

            throw EncodingError.invalidValue(float, .init(
                codingPath: path,
                debugDescription: "Unable to encode \(F.self).\(float) directly in JSON."
            ))
        }

        var string = float.description
        if string.hasSuffix(".0") {
            string.removeLast(2)
        }
        return .number(string)
    }

    func wrapEncodable<E: Encodable>(_ encodable: E, for additionalKey: CodingKey?) throws -> JSONValue? {
        switch encodable {
        case let date as Date:
            return try wrapDate(date, for: additionalKey)
        case let data as Data:
            return try wrapData(data, for: additionalKey)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            return .number(decimal.description)
        case let object as _JSONStringDictionaryEncodableMarker:
            return try wrapObject(object as! [String: Encodable], for: additionalKey)
        default:

            impl.cache.cacheSnapshot(for: E.self)

            let encoder = getEncoder(for: additionalKey)
            try encodable.encode(to: encoder)
            impl.cache.removeSnapshot(for: E.self)

            // If it is modified by SmartFlat, you need to encode to the upper layer to restore the data.
            if encodable is FlatType {
                if let object = encoder.value?.object {
                    for (key, value) in object {
                        impl.object?.set(value, for: key)
                    }
                    return nil
                }
            }

            return encoder.value
        }
    }

    func wrapDate(_ date: Date, for additionalKey: CodingKey?) throws -> JSONValue {
        if let value = impl.cache.tranform(from: date, with: additionalKey) {
            return value
        }

        switch options.dateEncodingStrategy {
        case .deferredToDate:
            let encoder = getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null

        case .secondsSince1970:
            return .number(date.timeIntervalSince1970.description)

        case .millisecondsSince1970:
            return .number((date.timeIntervalSince1970 * 1000).description)

        case .iso8601:
            return .string(FrameworkConfiguration.smartModelFormatter.string(from: date))

        case let .formatted(formatter):
            return .string(formatter.string(from: date))

        case let .custom(closure):
            let encoder = getEncoder(for: additionalKey)
            try closure(date, encoder)
            // The closure didn't encode anything. Return the default keyed container.
            return encoder.value ?? .object([:])

        @unknown default:
            let encoder = getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null
        }
    }

    func wrapData(_ data: Data, for additionalKey: CodingKey?) throws -> JSONValue {
        switch options.dataEncodingStrategy {
        case .base64:
            let base64 = data.base64EncodedString()
            return .string(base64)
        }
    }

    func wrapObject(_ object: [String: Encodable], for additionalKey: CodingKey?) throws -> JSONValue {
        var baseCodingPath = codingPath
        if let additionalKey {
            baseCodingPath.append(additionalKey)
        }
        var result = [String: JSONValue]()
        result.reserveCapacity(object.count)

        try object.forEach { key, value in
            var elemCodingPath = baseCodingPath
            elemCodingPath.append(_JSONKey(stringValue: key, intValue: nil))
            let encoder = JSONEncoderImpl(options: self.options, codingPath: elemCodingPath)

            result[key] = try encoder.wrapUntyped(value)
        }

        return .object(result)
    }

    func getEncoder(for additionalKey: CodingKey?) -> JSONEncoderImpl {
        if let additionalKey {
            var newCodingPath = codingPath
            newCodingPath.append(additionalKey)
            return JSONEncoderImpl(options: options, codingPath: newCodingPath, cache: impl.cache)
        }
        return impl
    }
}

extension _SpecialTreatmentEncoder {
    func _converted(_ key: CodingKey) -> CodingKey {
        var newKey = key

        if let objectType = impl.cache.topSnapshot?.objectType {
            if let mappings = objectType.mappingForKey() {
                for mapping in mappings {
                    if mapping.to.stringValue == newKey.stringValue {
                        if let first = mapping.from.first {
                            newKey = _JSONKey(stringValue: first, intValue: nil)
                        } else {
                            newKey = mapping.to
                        }
                    }
                }
            }
        }

        switch options.keyEncodingStrategy {
        case .toSnakeCase:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertToSnakeCase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .firstLetterLower:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertFirstLetterToLowercase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .firstLetterUpper:
            let newKeyString = SmartJSONEncoder.SmartKeyEncodingStrategy._convertFirstLetterToUppercase(newKey.stringValue)
            return _JSONKey(stringValue: newKeyString, intValue: newKey.intValue)
        case .useDefaultKeys:
            return newKey
        }
    }
}

// MARK: - FrameworkConfiguration+SmartModel
extension FrameworkConfiguration {
    fileprivate static var smartModelMode = SmartSentinel.Level.none
    fileprivate static var smartModelCache = LogCache()
    fileprivate static var smartModelHandler: ((String) -> Void)?
    fileprivate static var smartModelStrategy = SmartCoding.NumberConversionStrategy.strict
    fileprivate static let smartModelFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}
