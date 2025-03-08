//
//  SmartModel.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/2.
//

import Foundation

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

// MARK: - SmartCodable
/// [SmartCodable](https://github.com/intsig171/SmartCodable)
public typealias SmartCodable = SmartDecodable & SmartEncodable

public protocol SmartDecodable: Decodable {
    /// The callback for when mapping is complete
    mutating func didFinishMapping()

    /// The mapping relationship of decoding keys, the first mapping relationship that is not null is preferred
    static func mappingForKey() -> [SmartKeyTransformer]?

    /// The strategy for decoding values
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
    /// date的默认策略是ReferenceDate（参考日期是指2001年1月1日 00:00:00 UTC），以秒为单位。
    case date(JSONDecoder.DateDecodingStrategy)

    case data(JSONDecoder.SmartDataDecodingStrategy)

    case float(JSONDecoder.NonConformingFloatDecodingStrategy)

    /// The mapping strategy for keys during parsing
    case key(JSONDecoder.SmartKeyDecodingStrategy)

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
        default:
            return false
        }
    }
}

extension SmartDecodable {
    /// Deserializes any into a model
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        if let dict = object as? [String: Any] {
            return deserialize(from: dict, designatedPath: designatedPath, options: options)
        } else if let data = object as? Data {
            return deserialize(from: data, designatedPath: designatedPath, options: options)
        } else {
            return deserialize(from: object as? String, designatedPath: designatedPath, options: options)
        }
    }
    
    /// Deserializes into a model
    public static func deserialize(from dict: [String: Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let _dict = dict else {
            return nil
        }

        guard let _data = getInnerData(inside: _dict, by: designatedPath) else {
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into a model
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let _json = json else {
            return nil
        }

        guard let _data = getInnerData(inside: _json, by: designatedPath) else {
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into a model
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let data else {
            return nil
        }

        guard let _data = getInnerData(inside: data, by: designatedPath) else {
            return nil
        }

        return try? _data._deserializeDict(type: Self.self, options: options)
    }

    /// Deserializes into a model
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> Self? {
        guard let data else {
            return nil
        }

        guard let _tranData = data.tranformToJSONData(type: Self.self) else {
            return nil
        }

        guard let _data = getInnerData(inside: _tranData, by: designatedPath) else {
            return nil
        }

        return try? _data._deserializeDict(type: Self.self, options: options)
    }
}

extension Array where Element: SmartDecodable {
    /// Deserializes any into an array of models
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        if let array = object as? [Any] {
            return deserialize(from: array, designatedPath: designatedPath, options: options)
        } else if let data = object as? Data {
            return deserialize(from: data, designatedPath: designatedPath, options: options)
        } else {
            return deserialize(from: object as? String, designatedPath: designatedPath, options: options)
        }
    }
    
    /// Deserializes into an array of models
    public static func deserialize(from array: [Any]?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let _arr = array else {
            return nil
        }

        guard let _data = getInnerData(inside: _arr, by: nil) else {
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into an array of models
    public static func deserialize(from json: String?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let _json = json else {
            return nil
        }

        guard let _data = getInnerData(inside: _json, by: designatedPath) else {
            return nil
        }

        return deserialize(from: _data, options: options)
    }

    /// Deserializes into an array of models
    public static func deserialize(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let data else {
            return nil
        }

        guard let _data = getInnerData(inside: data, by: designatedPath) else {
            return nil
        }

        return try? _data._deserializeArray(type: Self.self, options: options)
    }

    /// Deserializes into an array of models
    public static func deserializePlist(from data: Data?, designatedPath: String? = nil, options: Set<SmartDecodingOption>? = nil) -> [Element]? {
        guard let data else {
            return nil
        }

        guard let _tranData = data.tranformToJSONData(type: Self.self) else {
            return nil
        }

        guard let _data = getInnerData(inside: _tranData, by: designatedPath) else {
            return nil
        }

        return try? _data._deserializeArray(type: Self.self, options: options)
    }
}

extension Data {
    private func createDecoder<T>(type: T.Type, options: Set<SmartDecodingOption>? = nil) -> JSONDecoder {
        let _decoder = SmartJSONDecoder()

        if let _options = options {
            for _option in _options {
                switch _option {
                case let .data(strategy):
                    _decoder.smartDataDecodingStrategy = strategy

                case let .date(strategy):
                    _decoder.dateDecodingStrategy = strategy

                case let .float(strategy):
                    _decoder.nonConformingFloatDecodingStrategy = strategy

                case let .key(strategy):
                    _decoder.smartKeyDecodingStrategy = strategy
                }
            }
        }

        return _decoder
    }

    fileprivate func _deserializeDict<T>(type: T.Type, options: Set<SmartDecodingOption>? = nil) throws -> T? where T: SmartDecodable {
        do {
            let _decoder = createDecoder(type: type, options: options)
            var obj = try _decoder.decode(type, from: self)
            obj.didFinishMapping()
            return obj
        } catch {
            return nil
        }
    }

    fileprivate func _deserializeArray<T>(type: [T].Type, options: Set<SmartDecodingOption>? = nil) throws -> [T]? where T: SmartDecodable {
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
            return nil
        }

        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            return nil
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            return jsonData
        } catch {
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

public protocol SmartEncodable: Encodable {
    /// The callback for when mapping is complete
    mutating func didFinishMapping()

    /// The mapping relationship of decoding keys
    static func mappingForKey() -> [SmartKeyTransformer]?

    /// The strategy for decoding values
    static func mappingForValue() -> [SmartValueTransformer]?

    init()
}

public enum SmartEncodingOption: Hashable {
    /// date的默认策略是ReferenceDate（参考日期是指2001年1月1日 00:00:00 UTC），以秒为单位。
    case date(JSONEncoder.DateEncodingStrategy)

    case data(JSONEncoder.SmartDataEncodingStrategy)

    case float(JSONEncoder.NonConformingFloatEncodingStrategy)

    case key(JSONEncoder.SmartKeyEncodingStrategy)

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
    public func toDictionary(options: Set<SmartEncodingOption>? = nil) -> [String: Any]? {
        _transformToJson(self, type: Self.self, options: options)
    }

    /// Serializes into a JSON string
    public func toJSONString(options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toDictionary(options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Self.self)
        }
        return nil
    }
}

extension Array where Element: SmartEncodable {
    /// Serializes into a array
    public func toArray(options: Set<SmartEncodingOption>? = nil) -> [Any]? {
        _transformToJson(self, type: Element.self, options: options)
    }

    /// Serializes into a JSON string
    public func toJSONString(options: Set<SmartEncodingOption>? = nil, prettyPrint: Bool = false) -> String? {
        if let anyObject = toArray(options: options) {
            return _transformToJsonString(object: anyObject, prettyPrint: prettyPrint, type: Element.self)
        }
        return nil
    }
}

private func _transformToJson<T>(_ some: Encodable, type: Any.Type, options: Set<SmartEncodingOption>? = nil) -> T? {
    let jsonEncoder = SmartJSONEncoder()

    if let _options = options {
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
            }
        } catch {}
    }
    return nil
}

private func _transformToJsonString(object: Any, prettyPrint: Bool = false, type: Any.Type) -> String? {
    if JSONSerialization.isValidJSONObject(object) {
        do {
            let options: JSONSerialization.WritingOptions = prettyPrint ? [.prettyPrinted] : []
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: options)
            return String(data: jsonData, encoding: .utf8)

        } catch {}
    }
    return nil
}

extension SmartDecodable where Self: SmartEncodable {
    /// Merge any info a model
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

public struct SmartUpdater<T: SmartCodable> {
    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    public static func update(_ dest: inout T, from src: Data?) {
        guard let src else { return }

        guard let dict = try? JSONSerialization.jsonObject(with: src, options: .mutableContainers) as? [String: Any] else {
            return
        }
        update(&dest, from: dict)
    }

    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
    public static func update(_ dest: inout T, from src: String?) {
        guard let src else { return }

        guard let data = src.data(using: .utf8) else { return }

        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }

        update(&dest, from: dict)
    }

    /// This method is used to parse JSON data from a Data object and use the resulting dictionary to update a target object.
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
public enum SmartColor {
    case color(UIColor)

    public init(from value: UIColor) {
        self = .color(value)
    }

    public var peel: UIColor {
        switch self {
        case let .color(c):
            return c
        }
    }
}

extension SmartColor: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hexString = try container.decode(String.self)
        guard let color = UIColor.hex(hexString) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode SmartColor from provided hex string.")
        }
        self = .color(color)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .color(color):
            try container.encode(color.hexString)
        }
    }
}

public protocol SmartCaseDefaultable: RawRepresentable, Codable, CaseIterable { }
public extension SmartCaseDefaultable where Self: Decodable, Self.RawValue: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(RawValue.self)
        if let v = Self.init(rawValue: decoded) {
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

        let value = _decoder.json

        if let tranform = _decoder.cache.tranform(value: value, for: _decoder.codingPath.last) as? Self {
            self = tranform
        } else {
            throw DecodingError.valueNotFound(Self.self, DecodingError.Context(codingPath: _decoder.codingPath, debugDescription: "未对关联值枚举实现自定义解析策略"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = encodeValue() {
            try container.encode(value)
        }
    }
}

// MARK: - Cachable
protocol Cachable {
    associatedtype CacheType

    var cacheType: CacheType? { get set }

    var snapshots: [Snapshot] { set get }

    var topSnapshot: Snapshot? { get }

    func cacheSnapshot<T>(for type: T.Type)

    mutating func removeSnapshot<T>(for type: T.Type)
}

extension Cachable {
    var topSnapshot: Snapshot? {
        snapshots.last
    }

    mutating func removeSnapshot<T>(for type: T.Type) {
        if let _ = T.self as? CacheType {
            if snapshots.count > 0 {
                snapshots.removeLast()
            }
        }
    }
}

struct Snapshot {
    var typeName: String = ""

    var initialValues: [String: Any] = [:]

    var transformers: [SmartValueTransformer] = []
}

// MARK: - PropertyWrapper
/** IgnoredKey 使用注意
 * 1. 并不是真正的忽略被修饰属性的解析，而是解析的时候忽略使用数据。
 * 2. 是否有对应数据，不同的处理：
 *  - 有数据时候，会走进IgnoredKey的 `encode(to:)` 方法，抛出异常，让外部处理。
 *  - 没有数据时，不会进来，会被当前一个普通数据解析处理，走无数据时的兜底逻辑。
 */

@propertyWrapper
public struct IgnoredKey<T>: Codable {
    public var wrappedValue: T

    var isEncodable: Bool = true

    /// isEncodable表示该属性是否支持编码, 默认不支持，即：不会加入json中。
    public init(wrappedValue: T, isEncodable: Bool = false) {
        self.wrappedValue = wrappedValue
        self.isEncodable = isEncodable
    }

    public init(from decoder: Decoder) throws {
        guard let impl = decoder as? JSONDecoderImpl else {
            self.wrappedValue = try Patcher<T>.defaultForType()
            return
        }

        // 属性被IgnoredKey修饰的时，如果自定义了该属性的解析策略，在此支持
        if let key = impl.codingPath.last {
            if let decoded = impl.cache.tranform(value: impl.json, for: key) as? T {
                self.wrappedValue = decoded
                return
            }
        }

        /// The resolution triggered by the other three parties may be resolved here.
        self.wrappedValue = try impl.smartDecode(type: T.self)
    }

    public func encode(to encoder: Encoder) throws {
        guard isEncodable else { return }

        /// 自定义编码策略
        if let impl = encoder as? JSONEncoderImpl,
           let key = impl.codingPath.last,
           let jsonValue = impl.cache.tranform(from: wrappedValue, with: key),
           let value = jsonValue.peel as? Encodable {
            try value.encode(to: encoder)
            return
        }

        // 如果 wrappedValue 符合 Encodable 协议，则手动进行编码，否则使用nil替代。
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
        if let key = codingPath.last, let value: T = cache.getValue(forKey: key) {
            return value
        } else {
            return try Patcher<T>.defaultForType()
        }
    }
}

/// 被属性包装器包裹的，不会调用didFinishMapping方法。
/// Swift的类型系统在运行时无法直接识别出wrappedValue的实际类型，需要各个属性包装器自行处理。

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

extension SmartFlat: WrapperLifecycle {
    func wrappedValueDidFinishMapping() -> SmartFlat<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartFlat(wrappedValue: temp as! T)
        }
        return nil
    }
}

protocol FlatType {
    static var isArray: Bool { get }
}

extension SmartFlat: FlatType {
    static var isArray: Bool { T.self is _ArrayMark.Type }
}

// 当 T 是一个数组并且其元素类型符合 Decodable 协议时，
// T.self 会被 _Array 扩展所覆盖，这样 T.self is _Array.Type 就会返回 true。
protocol _ArrayMark {}
// 这里将 Array 类型扩展，使得它在元素类型 (Element) 符合 Decodable 协议时，满足 _Array 协议。也就是说，只有当数组中的元素符合 Decodable 协议时，这个数组类型才会被标记为 _Array。
extension Array: _ArrayMark where Element: Decodable {}

/// 协议SmartPublishedProtocol，目标是为任何遵循该协议的类型提供统一的接口。
/// WrappedValue定义泛型类型，必须要求符合 Codable 协议。
/// createInstance方法，尝试给定义的值创建实例。
public protocol SmartPublishedProtocol {
    associatedtype WrappedValue: Codable
    init(wrappedValue: WrappedValue)

    static func createInstance(with value: Any) -> Self?
}

import Combine
import Foundation
import SwiftUI

/// 这段代码实现了一个自定义的属性包装器 SmartPublished，
/// 将Combine 的发布功能与 Codable 的数据序列化能力结合。通过属性包装器简化属性的声明，同时支持相应式编程。
/// 用于结合 Combine 的功能和编码解码支持。以下是对整个代码的说明。
/// projectedValue提供一个发布者，可供订阅。
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
        // willSet 观察器在 wrappedValue 被修改前调用，会将新的值通过 publisher 发送出去，从而通知所有的订阅者。这实现了数据更新的响应式特性。
        willSet {
            publisher.subject.send(newValue)
        }
    }

    public var projectedValue: Publisher {
        publisher
    }

    private var publisher: Publisher

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

    /// 这个下标实现了对属性包装器的自定义访问逻辑，用于在包装器内自定义 wrappedValue 的访问和修改行为。
    /// 参数解析：
    /// observed：观察者，即外部的 ObservableObject 实例。
    /// wrappedKeyPath：指向被包装值的引用键路径。
    /// storageKeyPath：指向属性包装器自身的引用键路径。
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            // 在设置新值之前，如果 observed 的 objectWillChange 属性是 ObservableObjectPublisher 类型，则它会发送通知，确保在属性值更新之前，订阅者能收到通知。
            if let subject = observed.objectWillChange as? ObservableObjectPublisher {
                subject.send() // 修改 wrappedValue 之前
                observed[keyPath: storageKeyPath].wrappedValue = newValue
            }
        }
    }
}

extension SmartPublished: WrapperLifecycle {
    func wrappedValueDidFinishMapping() -> SmartPublished<Value>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartPublished(wrappedValue: temp as! Value)
        }
        return nil
    }
}

/// 协议扩展
/// 使 SmartPublished 符合 SmartPublishedProtocol。
/// 利用泛型和类型检查，从任意值创建 SmartPublished 实例。
extension SmartPublished: SmartPublishedProtocol {
    public static func createInstance(with value: Any) -> SmartPublished? {
        if let value = value as? Value {
            return SmartPublished(wrappedValue: value)
        }
        return nil
    }
}

/// 作用于属性包装器的标识
protocol WrapperLifecycle {
    ///  被包裹的属性解码完成的回调，一般是遵循SmartDecode协议的model
    func wrappedValueDidFinishMapping() -> Self?
}

@propertyWrapper
public struct SmartAny<T>: Codable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        guard let decoder = decoder as? JSONDecoderImpl else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）"
            ))
        }
        let value = decoder.json
        if let key = decoder.codingPath.last {
            if let cached = decoder.cache.tranform(value: value, for: key),
               let decoded = cached as? T {
                self = .init(wrappedValue: decoded)
                return
            }
        }

        if let decoded = try? decoder.unwrap(as: SmartAnyImpl.self), let peel = decoded.peel as? T {
            self = .init(wrappedValue: peel)
        } else {
            // 类型检查
            if let _type = T.self as? Decodable.Type {
                if let decoded = try? _type.init(from: decoder) as? T {
                    self = .init(wrappedValue: decoded)
                    return
                }
            }

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

extension SmartAny: WrapperLifecycle {
    func wrappedValueDidFinishMapping() -> SmartAny<T>? {
        if var temp = wrappedValue as? SmartDecodable {
            temp.didFinishMapping()
            return SmartAny(wrappedValue: temp as! T)
        }
        return nil
    }
}

enum SmartAnyImpl {
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
    var cover: [String: SmartAnyImpl] {
        mapValues { SmartAnyImpl(from: $0) }
    }

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
    var peel: [String: Any] {
        mapValues { $0.peel }
    }
}

extension Array<SmartAnyImpl> {
    var peel: [Any] {
        map { $0.peel }
    }
}

extension Array<[String: SmartAnyImpl]> {
    public var peel: [Any] {
        map { $0.peel }
    }
}

extension SmartAnyImpl {
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
        guard let decoder = decoder as? JSONDecoderImpl,
              let container = try? decoder.singleValueContainer() as? JSONDecoderImpl.SingleValueContainer else {
            throw DecodingError.typeMismatch(SmartAnyImpl.self, DecodingError.Context(
                codingPath: decoder.codingPath, debugDescription: "Expected \(Self.self) value，but an exception occurred！Please report this issue（请上报该问题）"
            ))
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
        case let v as [Any]: return .array(v.map { convertToSmartAny($0) })
        case is NSNull: return .null(NSNull())
        default: return .null(NSNull())
        }
    }
}

extension JSONDecoderImpl {
    fileprivate func unwrapSmartAny() throws -> SmartAnyImpl {
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? SmartAnyImpl {
            return decoded
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
        guard let decoded = try? impl.unwrapFixedWidthInteger(from: value, as: T.self) else {
            return nil
        }
        return decoded
    }

    @inline(__always) private func decodeIfPresentFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() -> T? {
        guard let decoded = try? impl.unwrapFloatingPoint(from: value, as: T.self) else {
            return nil
        }
        return decoded
    }
}

// MARK: - JSONParserValue
enum JSONParserValue: Equatable {
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    case array([JSONParserValue])
    case object([String: JSONParserValue])

    static func make(_ value: Any) -> Self? {
        if let jsonValue = value as? JSONParserValue {
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

extension JSONParserValue {
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

extension JSONParserValue {
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

extension JSONParserValue {
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

        if digitCount > 17, exp >= -128, exp <= 127, let decimal = Decimal(string: string), decimal.isFinite {
            return NSDecimalNumber(decimal: decimal)
        }

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
extension JSONParserValue {
    struct Writer {
        let options: SmartJSONEncoder.OutputFormatting

        init(options: SmartJSONEncoder.OutputFormatting) {
            self.options = options
        }

        func writeValue(_ value: JSONParserValue) -> [UInt8] {
            var bytes = [UInt8]()
            if options.contains(.prettyPrinted) {
                writeValuePretty(value, into: &bytes)
            } else {
                writeValue(value, into: &bytes)
            }
            return bytes
        }

        private func writeValue(_ value: JSONParserValue, into bytes: inout [UInt8]) {
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
                if #available(macOS 10.13, *), options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    self.writeObject(sorted, into: &bytes)
                } else {
                    writeObject(dict, into: &bytes)
                }
            }
        }

        private func writeObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONParserValue) {
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

        private func writeValuePretty(_ value: JSONParserValue, into bytes: inout [UInt8], depth: Int = 0) {
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
                if #available(macOS 10.13, *), options.contains(.sortedKeys) {
                    let sorted = dict.sorted { $0.key.compare($1.key, options: [.caseInsensitive, .diacriticInsensitive, .forcedOrdering, .numeric, .widthInsensitive]) == .orderedAscending }
                    self.writePrettyObject(sorted, into: &bytes, depth: depth)
                } else {
                    writePrettyObject(dict, into: &bytes, depth: depth)
                }
            }
        }

        private func writePrettyObject<Object: Sequence>(_ object: Object, into bytes: inout [UInt8], depth: Int = 0)
            where Object.Element == (key: String, value: JSONParserValue) {
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

            bytes.append(contentsOf: stringBytes[startCopyIndex..<nextIndex])
            bytes.append(UInt8(ascii: "\""))
        }
    }
}

extension JSONParserValue {
    var object: [String: JSONParserValue]? {
        switch self {
        case let .object(v):
            return v
        default:
            return nil
        }
    }

    var array: [JSONParserValue]? {
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

extension Dictionary<String, JSONParserValue> {
    var peel: [String: Any] {
        mapValues { $0.peel }
    }
}

extension Array<JSONParserValue> {
    var peel: [Any] {
        map { $0.peel }
    }
}

extension Array<[String: JSONParserValue]> {
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

    mutating func parse() throws -> JSONParserValue {
        try reader.consumeWhitespace()
        let value = try parseValue()
        #if DEBUG
        defer {
            guard self.depth == 0 else {
                preconditionFailure("Expected to end parsing with a depth of 0")
            }
        }
        #endif

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

    mutating func parseValue() throws -> JSONParserValue {
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

    mutating func parseArray() throws -> [JSONParserValue] {
        precondition(reader.read() == ._openbracket)
        guard depth < 512 else {
            throw JSONParserError.tooManyNestedArraysOrDictionaries(characterIndex: reader.readerIndex - 1)
        }
        depth += 1
        defer { depth -= 1 }

        switch try reader.consumeWhitespace() {
        case ._space, ._return, ._newline, ._tab:
            preconditionFailure("Expected that all white space is consumed")
        case ._closebracket:
            reader.moveReaderIndex(forwardBy: 1)
            return []
        default:
            break
        }

        var array = [JSONParserValue]()
        array.reserveCapacity(10)

        while true {
            let value = try parseValue()
            array.append(value)

            let ascii = try reader.consumeWhitespace()
            switch ascii {
            case ._space, ._return, ._newline, ._tab:
                preconditionFailure("Expected that all white space is consumed")
            case ._closebracket:
                reader.moveReaderIndex(forwardBy: 1)
                return array
            case ._comma:
                reader.moveReaderIndex(forwardBy: 1)
                if try reader.consumeWhitespace() == ._closebracket {
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

    mutating func parseObject() throws -> [String: JSONParserValue] {
        precondition(reader.read() == ._openbrace)
        guard depth < 512 else {
            throw JSONParserError.tooManyNestedArraysOrDictionaries(characterIndex: reader.readerIndex - 1)
        }
        depth += 1
        defer { depth -= 1 }

        switch try reader.consumeWhitespace() {
        case ._space, ._return, ._newline, ._tab:
            preconditionFailure("Expected that all white space is consumed")
        case ._closebrace:
            reader.moveReaderIndex(forwardBy: 1)
            return [:]
        default:
            break
        }

        var object = [String: JSONParserValue]()
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
                        return try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    }
                    result += try makeString(at: stringStartIndex..<stringStartIndex + copy)
                    return result

                case 0...31:
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
            let bitPattern = try parseUnicodeHexSequence()

            let isFirstByteHighSurrogate = bitPattern & 0xFC00
            if isFirstByteHighSurrogate == 0xD800 {
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
                let isSecondByteLowSurrogate = lowSurrogateBitBattern & 0xFC00
                guard isSecondByteLowSurrogate == 0xDC00 else {
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
                return ascii - 55
            case 97...102:
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

            while let byte = peek(offset: numberchars) {
                switch byte {
                case UInt8(ascii: "0"):
                    if hasLeadingZero {
                        throw JSONParserError.numberWithLeadingZero(index: readerIndex + numberchars)
                    }
                    if numbersSinceControlChar == 0, pastControlChar == .operand {
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

// MARK: - JSONEncoder
class EncodingCache: Cachable {
    typealias CacheType = SmartEncodable.Type

    var cacheType: CacheType?
    var snapshots: [Snapshot] = []

    func cacheSnapshot<T>(for type: T.Type) {
        if let object = type as? SmartEncodable.Type {
            cacheType = object

            var snapshot = Snapshot()
            let instance = object.init()
            let mirror = Mirror(reflecting: instance)
            for child in mirror.children {
                if let key = child.label {
                    snapshot.initialValues[key] = child.value
                }
            }
            snapshot.typeName = "\(type)"
            snapshot.transformers = object.mappingForValue() ?? []
            snapshots.append(snapshot)
        }
    }
}

extension EncodingCache {
    func tranform(from value: Any, with key: CodingKey?) -> JSONParserValue? {
        if let trans = topSnapshot?.transformers, let key {
            let wantKey = key.stringValue
            let tran = trans.first(where: { transformer in
                if wantKey == transformer.location.stringValue {
                    return true
                } else {
                    if let keyTransformers = cacheType?.mappingForKey() {
                        for keyTransformer in keyTransformers {
                            if keyTransformer.from.contains(wantKey) {
                                return true
                            }
                        }
                    }
                    return false
                }
            })

            if let tran, let decoded = tranform(decodedValue: value, transformer: tran.tranformer) {
                return JSONParserValue.make(decoded)
            }
        }
        return nil
    }

    private func tranform<Transform: ValueTransformable>(decodedValue: Any, transformer: Transform) -> Any? {
        if let value = decodedValue as? Transform.Object {
            return transformer.transformToJSON(value)
        }
        return nil
    }
}

enum JSONFuture {
    case value(JSONParserValue)
    case encoder(JSONEncoderImpl)
    case nestedArray(RefArray)
    case nestedObject(RefObject)

    class RefArray {
        private(set) var array: [JSONFuture] = []

        init() {
            array.reserveCapacity(10)
        }

        @inline(__always) func append(_ element: JSONParserValue) {
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

        var values: [JSONParserValue] {
            array.map { future -> JSONParserValue in
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

        @inline(__always) func set(_ value: JSONParserValue, for key: String) {
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

        var values: [String: JSONParserValue] {
            dict.mapValues { future -> JSONParserValue in
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

open class SmartJSONEncoder: JSONEncoder, @unchecked Sendable {
    open var smartKeyEncodingStrategy: SmartKeyEncodingStrategy = .useDefaultKeys
    open var smartDataEncodingStrategy: SmartDataEncodingStrategy = .base64

    struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let dataEncodingStrategy: SmartDataEncodingStrategy
        let nonConformingFloatEncodingStrategy: NonConformingFloatEncodingStrategy
        let keyEncodingStrategy: SmartKeyEncodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    fileprivate var options: _Options {
        _Options(dateEncodingStrategy: dateEncodingStrategy,
                 dataEncodingStrategy: smartDataEncodingStrategy,
                 nonConformingFloatEncodingStrategy: nonConformingFloatEncodingStrategy,
                 keyEncodingStrategy: smartKeyEncodingStrategy,
                 userInfo: userInfo)
    }

    // MARK: - Encoding Values
    override open func encode<T: Encodable>(_ value: T) throws -> Data {
        let value: JSONParserValue = try encodeAsJSONParserValue(value)
        let writer = JSONParserValue.Writer(options: outputFormatting)
        let bytes = writer.writeValue(value)

        return Data(bytes)
    }

    func encodeAsJSONParserValue<T: Encodable>(_ value: T) throws -> JSONParserValue {
        let encoder = JSONEncoderImpl(options: options, codingPath: [])
        guard let topLevel = try encoder.wrapEncodable(value, for: nil) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }

        return topLevel
    }
}

extension EncodingError {
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
    public enum SmartDataEncodingStrategy: Sendable {
        case base64
    }
}

extension JSONEncoder {
    public enum SmartKeyEncodingStrategy: Sendable {
        case useDefaultKeys

        case toSnakeCase

        case firstLetterLower

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
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                wordStart = searchRange.lowerBound
                break
            }

            let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                wordStart = upperCaseRange.lowerBound
            } else {
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

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
            if let encoded = try? wrapEncodable(value, for: convertedKey) {
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

protocol _JSONStringDictionaryEncodableMarker {}

extension Dictionary: _JSONStringDictionaryEncodableMarker where Key == String, Value: Encodable {}

protocol _SpecialTreatmentEncoder {
    var codingPath: [CodingKey] { get }
    var options: SmartJSONEncoder._Options { get }
    var impl: JSONEncoderImpl { get }
}

extension _SpecialTreatmentEncoder {
    @inline(__always)
    func wrapFloat<F: FloatingPoint & CustomStringConvertible>(_ float: F, for additionalKey: CodingKey?) throws -> JSONParserValue {
        guard !float.isNaN, !float.isInfinite else {
            if case let .convertToString(posInfString, negInfString, nanString) = options.nonConformingFloatEncodingStrategy {
                switch float {
                case F.infinity:
                    return .string(posInfString)
                case -F.infinity:
                    return .string(negInfString)
                default:
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

    func wrapEncodable<E: Encodable>(_ encodable: E, for additionalKey: CodingKey?) throws -> JSONParserValue? {
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

            return encoder.value
        }
    }

    func wrapDate(_ date: Date, for additionalKey: CodingKey?) throws -> JSONParserValue {
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
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            return .string(formatter.string(from: date))
        case let .formatted(formatter):
            return .string(formatter.string(from: date))

        case let .custom(closure):
            let encoder = getEncoder(for: additionalKey)
            try closure(date, encoder)
            return encoder.value ?? .object([:])

        @unknown default:
            let encoder = getEncoder(for: additionalKey)
            try date.encode(to: encoder)
            return encoder.value ?? .null
        }
    }

    func wrapData(_ data: Data, for additionalKey: CodingKey?) throws -> JSONParserValue {
        switch options.dataEncodingStrategy {
        case .base64:
            let base64 = data.base64EncodedString()
            return .string(base64)
        }
    }

    func wrapObject(_ object: [String: Encodable], for additionalKey: CodingKey?) throws -> JSONParserValue {
        var baseCodingPath = codingPath
        if let additionalKey {
            baseCodingPath.append(additionalKey)
        }
        var result = [String: JSONParserValue]()
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

        if let objectType = impl.cache.cacheType {
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

class JSONEncoderImpl {
    let options: SmartJSONEncoder._Options
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] {
        options.userInfo
    }

    /// 记录当前keyed容器的各个属性的初始化值， 不支持Unkey容器的记录。
    var cache: EncodingCache

    var singleValue: JSONParserValue?
    var array: JSONFuture.RefArray?
    var object: JSONFuture.RefObject?

    var value: JSONParserValue? {
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

extension JSONEncoderImpl: _SpecialTreatmentEncoder {
    var impl: JSONEncoderImpl {
        self
    }

    func wrapUntyped(_ encodable: Encodable) throws -> JSONParserValue {
        switch encodable {
        case let date as Date:
            return try wrapDate(date, for: nil)
        case let data as Data:
            return try wrapData(data, for: nil)
        case let url as URL:
            return .string(url.absoluteString)
        case let decimal as Decimal:
            return .number(decimal.description)
        case let object as [String: Encodable]:
            return try wrapObject(object, for: nil)
        default:
            try encodable.encode(to: self)
            return value ?? .object([:])
        }
    }
}

// MARK: - JSONDecoder
class DecodingCache {
    private(set) var snapshots: [Snapshot] = []

    var decodedType: SmartDecodable.Type?

    var topSnapshot: Snapshot? {
        snapshots.last
    }

    func cacheInitialState<T: Decodable>(for type: T.Type) {
        if let object = type as? SmartDecodable.Type {
            decodedType = object
            var snapshot = Snapshot()

            let instance = object.init()
            // 递归处理所有的 superclassMirror
            func captureInitialValues(from mirror: Mirror) {
                for child in mirror.children {
                    if let key = child.label {
                        snapshot.initialValues[key] = child.value
                    }
                }
                if let superclassMirror = mirror.superclassMirror {
                    captureInitialValues(from: superclassMirror)
                }
            }
            // 获取当前类和所有父类的属性值
            let mirror = Mirror(reflecting: instance)
            captureInitialValues(from: mirror)

            snapshot.typeName = "\(type)"
            snapshot.transformers = object.mappingForValue() ?? []
            snapshots.append(snapshot)
        }
    }

    func clearLastState<T: Decodable>(for type: T.Type) {
        if let _ = T.self as? SmartDecodable.Type {
            if snapshots.count > 0 {
                snapshots.removeLast()
            }
        }
    }

    func getValue<T>(forKey key: CodingKey) -> T? {
        if var cacheValue = snapshots.last?.initialValues[key.stringValue] {
            if let temp = cacheValue as? CGFloat {
                cacheValue = Double(temp)
            }

            if let value = cacheValue as? T {
                return value
            } else if let caseValue = cacheValue as? (any SmartCaseDefaultable) {
                return caseValue.rawValue as? T
            } else if let caseValue = cacheValue as? (any DefaultCaseCodable) {
                return caseValue.rawValue as? T
            }
        } else {
            if let cached = snapshots.last?.initialValues["_" + key.stringValue] {
                if let value = cached as? IgnoredKey<T> {
                    return value.wrappedValue
                } else if let value = cached as? SmartAny<T> {
                    return value.wrappedValue
                } else if let value = cached as? T { // 当key缺失的时候，会进入
                    return value
                }
            } else {
                for item in snapshots.reversed() {
                    if let cached = item.initialValues["_" + key.stringValue] {
                        if let value = cached as? IgnoredKey<T> {
                            return value.wrappedValue
                        } else if let value = cached as? SmartAny<T> {
                            return value.wrappedValue
                        } else if let value = cached as? T {
                            return value
                        }
                    }
                }
            }
        }
        return nil
    }

    func tranform(value: JSONParserValue, for key: CodingKey?) -> Any? {
        if let lastKey = key {
            let container = topSnapshot?.transformers.first(where: {
                $0.location.stringValue == lastKey.stringValue
            })
            if let tranformValue = container?.tranformer.transformFromJSON(value.peel) {
                return tranformValue
            }
        }
        return nil
    }
}

extension DecodingCache {
    struct Snapshot {
        var typeName: String = ""

        var initialValues: [String: Any] = [:]

        var transformers: [SmartValueTransformer] = []
    }
}

extension DecodingError {
    static func _keyNotFound(key: CodingKey, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No value associated with key \(key)."))
    }

    static func _valueNotFound(key: CodingKey, expectation: Any.Type, codingPath: [CodingKey]) -> DecodingError {
        DecodingError.valueNotFound(expectation, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode '\(expectation)' but found 'null' instead."))
    }

    static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, desc: String) -> DecodingError {
        let description = "Expected to decode '\(expectation)' but found \(desc) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

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

enum KeysMapper {
    static func convertFrom(_ jsonValue: JSONParserValue, type: Any.Type) -> JSONParserValue? {
        guard let type = type as? SmartDecodable.Type else { return jsonValue }

        switch jsonValue {
        case let .string(stringValue):
            let value = parseJSON(from: stringValue, as: type)
            return JSONParserValue.make(value)

        case let .object(dictValue):
            if let dict = mapDictionary(dict: dictValue, using: type) as? [String: JSONParserValue] {
                return JSONParserValue.object(dict)
            }

        default:
            break
        }
        return nil
    }

    private static func parseJSON(from string: String, as type: SmartDecodable.Type) -> Any {
        guard let jsonObject = string.toJSONObject() else { return string }
        if let dict = jsonObject as? [String: Any] {
            return mapDictionary(dict: dict, using: type)
        } else {
            return jsonObject
        }
    }

    private static func mapDictionary(dict: [String: Any], using type: SmartDecodable.Type) -> [String: Any] {
        var newDict = dict
        type.mappingForKey()?.forEach { mapping in
            let newKey = mapping.to.stringValue

            /** 判断原字段是否为干扰字段（映射关系中是否存在该字段）。
             * 干扰字段场景：注意这种情况 CodingKeys.name <--- ["newName"]
             * 有效字段场景：注意这种情况 CodingKeys.name <--- ["name", "newName"]
             */
            if !(mapping.from.contains(newKey)) {
                newDict.removeValue(forKey: newKey)
            }

            // break的作用： 优先使用第一个不为null的字段。
            for oldKey in mapping.from {
                // 映射关系在当前层
                if let value = newDict[oldKey] as? JSONParserValue, value != .null {
                    newDict[newKey] = newDict[oldKey]
                    break
                }

                // 映射关系需要根据路径跨层处理
                if let pathValue = newDict.getValue(forKeyPath: oldKey) {
                    newDict.updateValue(pathValue, forKey: newKey)
                    break
                }
            }
        }
        return newDict
    }
}

extension Dictionary {
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
            } else if case let JSONParserValue.object(object) = currentAny, let temp = object[key] {
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

open class SmartJSONDecoder: JSONDecoder, @unchecked Sendable {
    open var smartDataDecodingStrategy: SmartDataDecodingStrategy = .base64

    struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: SmartDataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: SmartKeyDecodingStrategy
        let userInfo: [CodingUserInfoKey: Any]
    }

    var options: _Options {
        _Options(
            dateDecodingStrategy: dateDecodingStrategy,
            dataDecodingStrategy: smartDataDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
            keyDecodingStrategy: smartKeyDecodingStrategy,
            userInfo: userInfo
        )
    }

    open var smartKeyDecodingStrategy: SmartKeyDecodingStrategy = .useDefaultKeys

    // MARK: - Decoding Values
    override open func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            var parser = JSONParser(bytes: Array(data))
            let json = try parser.parse()
            let impl = JSONDecoderImpl(userInfo: userInfo, from: json, codingPath: [], options: options)
            let value = try impl.unwrap(as: type)
            return value
        } catch {
            throw error
        }
    }
}

extension JSONDecoder {
    public enum SmartDataDecodingStrategy: Sendable {
        case base64
    }
}

extension JSONDecoder {
    public enum SmartKeyDecodingStrategy: Sendable {
        case useDefaultKeys

        case fromSnakeCase

        case firstLetterLower

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

        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            return stringKey
        }

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
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        let result: String
        if leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty {
            result = joinedString
        } else if !leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty {
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if !leadingUnderscoreRange.isEmpty {
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }
        return result
    }
}

struct JSONDecoderImpl {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    let json: JSONParserValue
    let options: SmartJSONDecoder._Options

    var cache: DecodingCache

    init(userInfo: [CodingUserInfoKey: Any], from json: JSONParserValue, codingPath: [CodingKey], options: SmartJSONDecoder._Options) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        self.json = json
        self.options = options
        self.cache = DecodingCache()
    }
}

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
               let dictionary = JSONParserValue.make(dict)?.object {
                let container = KeyedContainer<Key>(
                    impl: self,
                    codingPath: codingPath,
                    dictionary: dictionary
                )
                return KeyedDecodingContainer(container)
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONParserValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get keyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError._typeMismatch(at: codingPath, expectation: [String: JSONParserValue].self, desc: json.debugDataTypeDescription)
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
               let array = JSONParserValue.make(arr)?.array {
                return UnkeyedContainer(
                    impl: self,
                    codingPath: codingPath,
                    array: array
                )
            }
        case .null:
            throw DecodingError.valueNotFound([String: JSONParserValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get unkeyed decoding container -- found null value instead"
            ))
        default:
            break
        }
        throw DecodingError.typeMismatch([JSONParserValue].self, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected to decode \([JSONParserValue].self) but found \(json.debugDataTypeDescription) instead."
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
    struct KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K

        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let dictionary: [String: JSONParserValue]

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], dictionary: [String: JSONParserValue]) {
            self.codingPath = codingPath

            self.dictionary = _convertDictionary(dictionary, impl: impl)
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
            let value = try getValue(forKey: key)
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
            let value = try getValue(forKey: key)
            var newPath = codingPath
            newPath.append(key)

            return JSONDecoderImpl(
                userInfo: impl.userInfo,
                from: value,
                codingPath: newPath,
                options: impl.options
            )
        }

        private func decoderForKeyCompatibleForJson<LocalKey: CodingKey, T>(_ key: LocalKey, type: T.Type) throws -> JSONDecoderImpl {
            let value = try getValue(forKey: key)
            var newPath = codingPath
            newPath.append(key)

            var newImpl = JSONDecoderImpl(
                userInfo: impl.userInfo,
                from: value,
                codingPath: newPath,
                options: impl.options
            )

            if !(type is SmartDecodable.Type) {
                newImpl.cache = impl.cache
            }

            return newImpl
        }

        private func decoderForKeyNoThrow<LocalKey: CodingKey>(_ key: LocalKey) -> JSONDecoderImpl {
            let value: JSONParserValue
            do {
                value = try getValue(forKey: key)
            } catch {
                value = .null
            }
            var newPath = codingPath
            newPath.append(key)

            return JSONDecoderImpl(
                userInfo: impl.userInfo,
                from: value,
                codingPath: newPath,
                options: impl.options
            )
        }

        @inline(__always) private func getValue<LocalKey: CodingKey>(forKey key: LocalKey) throws -> JSONParserValue {
            guard let value = dictionary[key.stringValue] else {
                throw DecodingError._keyNotFound(key: key, codingPath: codingPath)
            }

            return value
        }

        @inline(__always) private func createTypeMismatchError(type: Any.Type, forKey key: K, value: JSONParserValue) -> DecodingError {
            let codingPath = codingPath + [key]
            return DecodingError.typeMismatch(type, .init(
                codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(value.debugDataTypeDescription) instead."
            ))
        }

        @inline(__always) private func decodeFixedWidthInteger<T: FixedWidthInteger>(key: Self.Key) -> T? {
            guard let value = try? getValue(forKey: key) else { return nil }

            if let decoded = impl.cache.tranform(value: value, for: key) as? T {
                return decoded
            }

            guard let decoded = try? impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
                return nil
            }
            return decoded
        }

        @inline(__always) private func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(key: K) -> T? {
            guard let value = try? getValue(forKey: key) else { return nil }

            if let decoded = impl.cache.tranform(value: value, for: key) as? T {
                return decoded
            }
            guard let decoded = try? impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
                return nil
            }
            return decoded
        }
    }
}

extension JSONDecoderImpl.KeyedContainer {
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        guard let value = try? getValue(forKey: key) else {
            return try forceDecode(forKey: key)
        }

        if let decoded = impl.cache.tranform(value: value, for: key) as? Bool {
            return decoded
        }

        guard case let .bool(bool) = value else {
            return try forceDecode(forKey: key)
        }
        return bool
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let value = try? getValue(forKey: key) else {
            return try forceDecode(forKey: key)
        }

        if let decoded = impl.cache.tranform(value: value, for: key) as? String {
            return decoded
        }

        guard case let .string(string) = value else {
            return try forceDecode(forKey: key)
        }
        return string
    }

    func decode(_: Double.Type, forKey key: K) throws -> Double {
        if let decoded: Double = decodeFloatingPoint(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: CGFloat.Type, forKey key: K) throws -> CGFloat {
        let value = try decode(Double.self, forKey: key)
        return CGFloat(value)
    }

    func decode(_: Float.Type, forKey key: K) throws -> Float {
        if let decoded: Float = decodeFloatingPoint(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: Int.Type, forKey key: K) throws -> Int {
        if let decoded: Int = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: Int8.Type, forKey key: K) throws -> Int8 {
        if let decoded: Int8 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: Int16.Type, forKey key: K) throws -> Int16 {
        if let decoded: Int16 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: Int32.Type, forKey key: K) throws -> Int32 {
        if let decoded: Int32 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: Int64.Type, forKey key: K) throws -> Int64 {
        if let decoded: Int64 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: UInt.Type, forKey key: K) throws -> UInt {
        if let decoded: UInt = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: UInt8.Type, forKey key: K) throws -> UInt8 {
        if let decoded: UInt8 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: UInt16.Type, forKey key: K) throws -> UInt16 {
        if let decoded: UInt16 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: UInt32.Type, forKey key: K) throws -> UInt32 {
        if let decoded: UInt32 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode(_: UInt64.Type, forKey key: K) throws -> UInt64 {
        if let decoded: UInt64 = decodeFixedWidthInteger(key: key) {
            return decoded
        }
        return try forceDecode(forKey: key)
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if type == CGFloat.self {
            return try decode(CGFloat.self, forKey: key) as! T
        }

        // 如果值可以被成功获取
        if let value = try? getValue(forKey: key) {
            if let decoded = impl.cache.tranform(value: value, for: key) {
                if let tTypeValue = decoded as? T {
                    return tTypeValue
                } else if let publishedType = T.self as? any SmartPublishedProtocol.Type,
                          let publishedValue = publishedType.createInstance(with: decoded) as? T {
                    // // 检查 SmartPublished 包装器类型
                    return publishedValue
                }
            }
        }

        if let type = type as? FlatType.Type {
            if type.isArray {
                let decoded = try T(from: superDecoder(forKey: key))
                return didFinishMapping(decoded)
            } else {
                let decoded = try T(from: impl)
                return didFinishMapping(decoded)
            }
        } else {
            do {
                let newDecoder = try decoderForKeyCompatibleForJson(key, type: type)
                let decoded = try newDecoder.unwrap(as: type)
                return didFinishMapping(decoded)
            } catch {
                let decoded: T = try forceDecode(forKey: key)
                return didFinishMapping(decoded)
            }
        }
    }
}

extension JSONDecoderImpl.KeyedContainer {
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        guard let value = try? getValue(forKey: key) else {
            return optionalDecode(forKey: key)
        }

        if let decoded = impl.cache.tranform(value: value, for: key) as? Bool {
            return decoded
        }

        guard case let .bool(bool) = value else {
            return optionalDecode(forKey: key)
        }
        return bool
    }

    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        guard let value = try? getValue(forKey: key) else {
            return optionalDecode(forKey: key)
        }

        if let decoded = impl.cache.tranform(value: value, for: key) as? String {
            return decoded
        }

        guard case let .string(string) = value else {
            return optionalDecode(forKey: key)
        }
        return string
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? {
        guard let decoded: Float = decodeFloatingPoint(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: CGFloat.Type, forKey key: K) throws -> CGFloat? {
        guard let decoded: Double = decodeFloatingPoint(key: key) else {
            return optionalDecode(forKey: key)
        }
        return CGFloat(decoded)
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        guard let decoded: Double = decodeFloatingPoint(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        guard let decoded: Int = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? {
        guard let decoded: Int8 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? {
        guard let decoded: Int16 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? {
        guard let decoded: Int32 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? {
        guard let decoded: Int64 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
        guard let decoded: UInt = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? {
        guard let decoded: UInt8 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? {
        guard let decoded: UInt16 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? {
        guard let decoded: UInt32 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? {
        guard let decoded: UInt64 = decodeFixedWidthInteger(key: key) else {
            return optionalDecode(forKey: key)
        }
        return decoded
    }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable {
        guard let value = try? getValue(forKey: key) else {
            return optionalDecode(forKey: key)
        }

        if type == CGFloat.self {
            return try decodeIfPresent(CGFloat.self, forKey: key) as? T
        }

        if let decoded = impl.cache.tranform(value: value, for: key) as? T {
            return decoded
        }

        guard let newDecoder = try? decoderForKeyCompatibleForJson(key, type: type) else {
            return nil
        }

        if let decoded = try? newDecoder.unwrap(as: type) {
            return didFinishMapping(decoded)
        }

        if let decoded: T = optionalDecode(forKey: key) {
            return didFinishMapping(decoded)
        } else {
            return nil
        }
    }
}

extension JSONDecoderImpl.KeyedContainer {
    fileprivate func optionalDecode<T>(forKey key: Key) -> T? {
        guard let value = try? getValue(forKey: key) else {
            if let initializer: T = impl.cache.getValue(forKey: key) {
                return initializer
            }
            return nil
        }

        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            return decoded
        } else if let initializer: T = impl.cache.getValue(forKey: key) {
            return initializer
        } else {
            return nil
        }
    }

    fileprivate func forceDecode<T>(forKey key: Key) throws -> T {
        func fillDefault() throws -> T {
            if let value: T = impl.cache.getValue(forKey: key) {
                return value
            } else {
                return try Patcher<T>.defaultForType()
            }
        }

        guard let value = try? getValue(forKey: key) else {
            return try fillDefault()
        }

        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            return decoded
        } else {
            return try fillDefault()
        }
    }

    fileprivate func didFinishMapping<T>(_ decodeValue: T) -> T {
        // 被属性包装器包裹的属性，是没遵循SmartDecodable协议的。
        // 这里使用WrapperLifecycle做一层中转处理
        if var value = decodeValue as? SmartDecodable {
            value.didFinishMapping()
            if let temp = value as? T { return temp }
        } else if let value = decodeValue as? WrapperLifecycle {
            if let temp = value.wrappedValueDidFinishMapping() as? T {
                return temp
            }
        }
        return decodeValue
    }
}

private func _toData(_ value: Any) -> Data? {
    guard JSONSerialization.isValidJSONObject(value) else { return nil }
    return try? JSONSerialization.data(withJSONObject: value)
}

private func _convertDictionary(_ dictionary: [String: JSONParserValue], impl: JSONDecoderImpl) -> [String: JSONParserValue] {
    var dictionary = dictionary

    switch impl.options.keyDecodingStrategy {
    case .useDefaultKeys:
        break
    case .fromSnakeCase:
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

    guard let type = impl.cache.decodedType else { return dictionary }

    if let tempValue = KeysMapper.convertFrom(JSONParserValue.object(dictionary), type: type), let dict = tempValue.object {
        return dict
    }
    return dictionary
}

extension JSONDecoderImpl {
    struct SingleValueContainer: SingleValueDecodingContainer {
        let impl: JSONDecoderImpl
        let value: JSONParserValue
        let codingPath: [CodingKey]

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], json: JSONParserValue) {
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
        do {
            return try impl.unwrapFixedWidthInteger(from: value, as: T.self)
        } catch {
            if let trnas = Patcher<T>.convertToType(from: value, impl: impl) {
                return trnas
            } else {
                throw error
            }
        }
    }

    @inline(__always) private func decodeFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>() throws -> T {
        do {
            return try impl.unwrapFloatingPoint(from: value, as: T.self)
        } catch {
            if let trnas = Patcher<T>.convertToType(from: value, impl: impl) {
                return trnas
            } else {
                throw error
            }
        }
    }
}

extension JSONDecoderImpl {
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        let impl: JSONDecoderImpl
        let codingPath: [CodingKey]
        let array: [JSONParserValue]

        var count: Int? { array.count }
        var isAtEnd: Bool { currentIndex >= (count ?? 0) }
        var currentIndex = 0

        init(impl: JSONDecoderImpl, codingPath: [CodingKey], array: [JSONParserValue]) {
            self.impl = impl
            self.codingPath = codingPath
            self.array = array
        }

        mutating func decodeNil() throws -> Bool {
            if try getNextValue(ofType: Never.self) == .null {
                currentIndex += 1
                return true
            }

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
            var value: JSONParserValue
            do {
                value = try getNextValue(ofType: T.self)
            } catch {
                value = JSONParserValue.array([])
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
        let newDecoder = decoderForNextElement(ofType: type)

        if codingPath.isEmpty {
            guard let result = try? newDecoder.unwrap(as: type) else {
                let decoded: T = try forceDecode()
                return didFinishMapping(decoded)
            }
            currentIndex += 1
            return didFinishMapping(result)
        } else {
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
        guard let result = try? impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
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
        guard let result = try? impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
            return try forceDecode()
        }
        currentIndex += 1
        return result
    }

    fileprivate mutating func forceDecode<T>() throws -> T {
        guard let value = try? getNextValue(ofType: T.self) else {
            let decoded: T = try Patcher<T>.defaultForType()
            currentIndex += 1
            return decoded
        }

        if let decoded = Patcher<T>.convertToType(from: value, impl: impl) {
            currentIndex += 1
            return decoded
        } else {
            let decoded: T = try Patcher<T>.defaultForType()
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
        guard let result = try? impl.unwrapFixedWidthInteger(from: value, for: key, as: T.self) else {
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
        guard let result = try? impl.unwrapFloatingPoint(from: value, for: key, as: T.self) else {
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
        if var value = decodeValue as? SmartDecodable {
            value.didFinishMapping()
            if let temp = value as? T { return temp }
        } else if let value = decodeValue as? WrapperLifecycle {
            if let temp = value.wrappedValueDidFinishMapping() as? T {
                return temp
            }
        }
        return decodeValue
    }
}

extension JSONDecoderImpl.UnkeyedContainer {
    @inline(__always)
    private func getNextValue<T>(ofType: T.Type) throws -> JSONParserValue {
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

        if type == SmartColor.self {
            return try unwrapSmartColor() as! T
        }

        if type is _JSONStringDictionaryDecodableMarker.Type {
            return try unwrapDictionary(as: type)
        }

        cache.cacheInitialState(for: type)
        let decoded = try type.init(from: self)
        cache.clearLastState(for: type)
        return decoded
    }

    func unwrapFloatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(
        from value: JSONParserValue,
        for additionalKey: CodingKey? = nil,
        as type: T.Type
    ) throws -> T {
        if case let .number(number) = value {
            guard let floatingPoint = T(number), floatingPoint.isFinite else {
                var path = codingPath
                if let additionalKey {
                    path.append(additionalKey)
                }
                throw DecodingError.dataCorrupted(.init(
                    codingPath: path,
                    debugDescription: "Parsed JSON number <\(number)> does not fit in \(T.self)."
                ))
            }

            return floatingPoint
        }

        if case let .string(string) = value,
           case let .convertFromString(posInfString, negInfString, nanString) =
           options.nonConformingFloatDecodingStrategy {
            if string == posInfString {
                return T.infinity
            } else if string == negInfString {
                return -T.infinity
            } else if string == nanString {
                return T.nan
            }
        }

        throw createTypeMismatchError(type: T.self, for: additionalKey, value: value)
    }

    func unwrapFixedWidthInteger<T: FixedWidthInteger>(
        from value: JSONParserValue,
        for additionalKey: CodingKey? = nil,
        as type: T.Type
    ) throws -> T {
        guard case let .number(number) = value else {
            throw createTypeMismatchError(type: T.self, for: additionalKey, value: value)
        }

        if let integer = T(number) {
            return integer
        }

        if let nsNumber = NSNumber.fromJSONNumber(number) {
            if type == UInt8.self, NSNumber(value: nsNumber.uint8Value) == nsNumber {
                return nsNumber.uint8Value as! T
            }
            if type == Int8.self, NSNumber(value: nsNumber.int8Value) == nsNumber {
                return nsNumber.int8Value as! T
            }
            if type == UInt16.self, NSNumber(value: nsNumber.uint16Value) == nsNumber {
                return nsNumber.uint16Value as! T
            }
            if type == Int16.self, NSNumber(value: nsNumber.int16Value) == nsNumber {
                return nsNumber.int16Value as! T
            }
            if type == UInt32.self, NSNumber(value: nsNumber.uint32Value) == nsNumber {
                return nsNumber.uint32Value as! T
            }
            if type == Int32.self, NSNumber(value: nsNumber.int32Value) == nsNumber {
                return nsNumber.int32Value as! T
            }
            if type == UInt64.self, NSNumber(value: nsNumber.uint64Value) == nsNumber {
                return nsNumber.uint64Value as! T
            }
            if type == Int64.self, NSNumber(value: nsNumber.int64Value) == nsNumber {
                return nsNumber.int64Value as! T
            }
            if type == UInt.self, NSNumber(value: nsNumber.uintValue) == nsNumber {
                return nsNumber.uintValue as! T
            }
            if type == Int.self, NSNumber(value: nsNumber.intValue) == nsNumber {
                return nsNumber.intValue as! T
            }
        }

        var path = codingPath
        if let additionalKey {
            path.append(additionalKey)
        }
        throw DecodingError.dataCorrupted(.init(
            codingPath: path,
            debugDescription: "Parsed JSON number <\(number)> does not fit in \(T.self)."
        ))
    }
}

extension JSONDecoderImpl {
    private func unwrapDate() throws -> Date {
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? Date {
            return decoded
        }

        switch options.dateDecodingStrategy {
        case .deferredToDate:
            return try Date(from: self)

        case .secondsSince1970:
            let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
            let double = try container.decode(Double.self)
            return Date(timeIntervalSince1970: double)

        case .millisecondsSince1970:
            let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
            let double = try container.decode(Double.self)
            return Date(timeIntervalSince1970: double / 1000.0)

        case .iso8601:
            let container = SingleValueContainer(impl: self, codingPath: self.codingPath, json: self.json)
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
            }
            return date

        case let .formatted(formatter):
            let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
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

    private func unwrapData() throws -> Data {
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? Data {
            return decoded
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
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? URL {
            return decoded
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

    private func unwrapSmartColor() throws -> SmartColor {
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? SmartColor {
            return decoded
        }

        let container = SingleValueContainer(impl: self, codingPath: codingPath, json: json)
        let string = try container.decode(String.self)

        guard let color = UIColor.hex(string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Invalid Color string."))
        }
        return SmartColor(from: color)
    }

    private func unwrapDecimal() throws -> Decimal {
        if let decoded = cache.tranform(value: json, for: codingPath.last) as? Decimal {
            return decoded
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

    private func unwrapDictionary<T: Decodable>(as: T.Type) throws -> T {
        guard let dictType = T.self as? (_JSONStringDictionaryDecodableMarker & Decodable).Type else {
            preconditionFailure("Must only be called of T implements _JSONStringDictionaryDecodableMarker")
        }

        guard case let .object(object) = json else {
            throw DecodingError.typeMismatch([String: JSONParserValue].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode \([String: JSONParserValue].self) but found \(json.debugDataTypeDescription) instead."
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

    func createTypeMismatchError(type: Any.Type, for additionalKey: CodingKey? = nil, value: JSONParserValue) -> DecodingError {
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
            || Self.self == SmartColor.self
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

    static func convertToType(from value: JSONParserValue?, impl: JSONDecoderImpl) -> T? {
        Transformer.typeTransform(from: value, impl: impl)
    }
}

extension Patcher {
    enum Provider {
        static func defaultValue() throws -> T {
            if let value = T.self as? BasicType.Type {
                return value.init() as! T
            } else if let object = T.self as? SmartDecodable.Type {
                return object.init() as! T
            } else if let object = T.self as? any SmartCaseDefaultable.Type {
                if let first = object.allCases.first as? T { return first }
            } else if let object = T.self as? any DefaultCaseCodable.Type {
                return object.defaultCase as! T
            } else if let object = T.self as? any SmartAssociatedEnumerable.Type {
                return object.defaultCase as! T
            }

            throw DecodingError.valueNotFound(T.self, DecodingError.Context(
                codingPath: [], debugDescription: "Expected \(T.self) value，but an exception occurred！Please report this issue（请上报该问题）"
            ))
        }
    }
}

extension Patcher {
    enum Transformer {
        static func typeTransform(from jsonValue: JSONParserValue?, impl: JSONDecoderImpl) -> T? {
            guard let value = jsonValue else { return nil }
            return (T.self as? TypeTransformable.Type)?.transformValue(from: value, impl: impl) as? T
        }
    }
}

private protocol TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Self?
}

extension Bool: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Bool? {
        switch value {
        case let .bool(bool):
            return bool
        case let .string(string):
            if ["1", "YES", "Yes", "yes", "TRUE", "True", "true"].contains(string) { return true }
            if ["0", "NO", "No", "no", "FALSE", "False", "false"].contains(string) { return false }
        case .number:
            if let int = try? impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
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
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> String? {
        switch value {
        case let .string(string):
            return string
        case let .number(number):
            if let int = try? impl.unwrapFixedWidthInteger(from: value, as: Int.self) {
                return "\(int)"
            } else if let double = try? impl.unwrapFloatingPoint(from: value, as: Double.self) {
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
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Int? {
        _fixedWidthInteger(from: value)
    }
}

extension Int8: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Int8? {
        _fixedWidthInteger(from: value)
    }
}

extension Int16: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Int16? {
        _fixedWidthInteger(from: value)
    }
}

extension Int32: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Int32? {
        _fixedWidthInteger(from: value)
    }
}

extension Int64: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Int64? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> UInt? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt8: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> UInt8? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt16: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> UInt16? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt32: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> UInt32? {
        _fixedWidthInteger(from: value)
    }
}

extension UInt64: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> UInt64? {
        _fixedWidthInteger(from: value)
    }
}

extension Float: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Float? {
        _floatingPoint(from: value)
    }
}

extension Double: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> Double? {
        _floatingPoint(from: value)
    }
}

extension CGFloat: TypeTransformable {
    static func transformValue(from value: JSONParserValue, impl: JSONDecoderImpl) -> CGFloat? {
        if let temp: Double = _floatingPoint(from: value) {
            return CGFloat(temp)
        }
        return nil
    }
}

private func _floatingPoint<T: LosslessStringConvertible & BinaryFloatingPoint>(from value: JSONParserValue) -> T? {
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

private func _fixedWidthInteger<T: FixedWidthInteger>(from value: JSONParserValue) -> T? {
    switch value {
    case let .string(string):
        if let integer = T(string) {
            return integer
        } else if let float = Double(string), float.isFinite, float >= Double(T.min) && float <= Double(T.max), let integer = T(exactly: float) {
            return integer
        }
    case let .number(number):
        if let integer = T(number) {
            return integer
        } else if let float = Double(number), float.isFinite, float >= Double(T.min) && float <= Double(T.max), let integer = T(exactly: float) {
            return integer
        }
    default:
        break
    }
    return nil
}

public struct SmartHexColorTransformer: ValueTransformable {
    public typealias Object = UIColor

    public typealias JSON = String

    public init() {}

    public func transformFromJSON(_ value: Any) -> Object? {
        if let rgba = value as? String {
            return UIColor.hex(rgba)
        }
        return nil
    }

    public func transformToJSON(_ value: Object) -> JSON? {
        value.hexString
    }
}

extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int(red * 255) << 16) | (Int(green * 255) << 8) | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }

    static func hex(_ hex: String) -> UIColor? {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0

        var useAlpha: CGFloat = 1

        var hex: String = hex

        /** 开头是用0x开始的 */
        if hex.hasPrefix("0X") {
            let index = hex.index(hex.startIndex, offsetBy: 2)
            hex = String(hex[index...])
        }

        /** 开头是以＃＃开始的 */
        if hex.hasPrefix("##") {
            let index = hex.index(hex.startIndex, offsetBy: 2)
            hex = String(hex[index...])
        }

        /** 开头是以＃开头的 */
        if hex.hasPrefix("#") {
            let index = hex.index(hex.startIndex, offsetBy: 1)
            hex = String(hex[index...])
        }

        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch hex.count {
            case 3:
                red = CGFloat((hexValue & 0xF00) >> 8) / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
                blue = CGFloat(hexValue & 0x00F) / 15.0
            case 4:
                let index = hex.index(hex.startIndex, offsetBy: 1)

                /// 处理透明度
                let alphaStr = String(hex[hex.startIndex..<index])
                if let doubleValue = Double(alphaStr) {
                    useAlpha = CGFloat(doubleValue) / 15
                }

                hex = String(hex[index...])
                red = CGFloat((hexValue & 0xF00) >> 8) / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
                blue = CGFloat(hexValue & 0x00F) / 15.0
            case 6:
                red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                blue = CGFloat(hexValue & 0x0000FF) / 255.0
            case 8:
                let index = hex.index(hex.startIndex, offsetBy: 2)
                /// 处理透明度
                let alphaStr = String(hex[hex.startIndex..<index])
                if let doubleValue = Double(alphaStr) {
                    useAlpha = CGFloat(doubleValue) / 255
                }

                hex = String(hex[index...])
                red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                blue = CGFloat(hexValue & 0x0000FF) / 255.0
            default:
                print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
                return nil
            }
        } else {
            return nil
        }

        return UIColor(red: red, green: green, blue: blue, alpha: useAlpha)
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
    public typealias JSON = Double
    public typealias Object = Date

    public init() {}

    public func transformFromJSON(_ value: Any) -> Date? {
        if let timeInt = value as? Double {
            return Date(timeIntervalSinceReferenceDate: timeInt)
        }

        if let timeStr = value as? String {
            return Date(timeIntervalSince1970: TimeInterval(atof(timeStr)))
        }

        return nil
    }

    public func transformToJSON(_ value: Date) -> Double? {
        Double(value.timeIntervalSince1970)
    }
}

public struct SmartDateFormatTransformer: ValueTransformable {
    public typealias JSON = String
    public typealias Object = Date

    let dateFormatter: DateFormatter

    public init(_ dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }

    public func transformFromJSON(_ value: Any) -> Date? {
        if let dateString = value as? String {
            return dateFormatter.date(from: dateString)
        }
        return nil
    }

    public func transformToJSON(_ value: Date) -> String? {
        dateFormatter.string(from: value)
    }
}

public struct SmartKeyTransformer {
    var from: [String]
    var to: CodingKey
}

infix operator <---

public func <---(to: CodingKey, from: String) -> SmartKeyTransformer {
    to <--- [from]
}

public func <---(to: CodingKey, from: [String]) -> SmartKeyTransformer {
    SmartKeyTransformer(from: from, to: to)
}

public struct SmartValueTransformer {
    var location: CodingKey
    var tranformer: any ValueTransformable
    public init(location: CodingKey, tranformer: any ValueTransformable) {
        self.location = location
        self.tranformer = tranformer
    }
}

public protocol ValueTransformable {
    associatedtype Object
    associatedtype JSON

    func transformFromJSON(_ value: Any) -> Object?

    func transformToJSON(_ value: Object) -> JSON?
}

public func <---(location: CodingKey, tranformer: any ValueTransformable) -> SmartValueTransformer {
    SmartValueTransformer(location: location, tranformer: tranformer)
}

public struct FastTransformer<Object, JSON>: ValueTransformable {
    private let fromJSON: (JSON?) -> Object?
    private let toJSON: ((Object?) -> JSON?)?

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

public struct SmartURLTransformer: ValueTransformable {
    public typealias JSON = String
    public typealias Object = URL
    private let shouldEncodeURLString: Bool
    private let prefix: String?

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

// MARK: - AnyArchivable
extension AnyArchivable where Self: SmartModel {
    public static func archiveDecode(_ data: Data?) -> Self? {
        return deserialize(from: data)
    }

    public func archiveEncode() -> Data? {
        toJSONString()?.data(using: .utf8)
    }
}
