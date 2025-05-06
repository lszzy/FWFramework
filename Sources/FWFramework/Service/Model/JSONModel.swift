//
//  JSONModel.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import UIKit

// MARK: - JSONModel
/// 通用JSON模型协议，已移除内存读写方式，使用时可实现KeyMappable，并选择以下模式使用，推荐方式
///
/// KeyMappable模式一：MappedValue模式
/// 1. 支持JSONModel类型字段，使用方式：@MappedValue
/// 2. 支持多字段映射，使用方式：@MappedValue("name1", "name2")
/// 3. 支持Any类型字段，使用方式：@MappedValue
/// 4. 未标记MappedValue的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
///
/// KeyMappable模式二：MappedValueMacro模式(需引入FWPluginMacros子模块)
/// 1. 标记class或struct为自动映射存储属性宏，使用方式：@MappedValueMacro
/// 2. 可自定义字段映射规则，使用方式：@MappedValue("name1", "name2")
/// 3. 以下划线开头或结尾的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
///
/// KeyMappable模式三：自定义模式
/// 1. 需完整实现JSONModel协议的mappingValue(_:forKey:)协议方法
///
/// [HandyJSON](https://github.com/alibaba/HandyJSON)
public protocol JSONModel: _ExtendCustomModelType, AnyModel {}

public protocol JSONModelCustomTransformable: _ExtendCustomBasicType {}

public protocol JSONModelEnum: _RawEnumProtocol {}

// MARK: - Measuable
public protocol _Measurable {}

extension _Measurable {
    func isNSObjectType() -> Bool {
        (type(of: self) as? NSObject.Type) != nil
    }

    func getBridgedPropertyList() -> Set<String> {
        if let anyClass = type(of: self) as? AnyClass {
            return _getBridgedPropertyList(anyClass: anyClass)
        }
        return []
    }

    func _getBridgedPropertyList(anyClass: AnyClass) -> Set<String> {
        if !(anyClass is JSONModel.Type) {
            return []
        }
        var propertyList = Set<String>()
        if let superClass = class_getSuperclass(anyClass), superClass != NSObject.self {
            propertyList = propertyList.union(_getBridgedPropertyList(anyClass: superClass))
        }
        let count = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        if let props = class_copyPropertyList(anyClass, count) {
            for i in 0..<count.pointee {
                let name = String(cString: property_getName(props.advanced(by: Int(i)).pointee))
                propertyList.insert(name)
            }
            free(props)
        }
        count.deallocate()
        return propertyList
    }
}

// MARK: - Transformable
public protocol _Transformable: _Measurable {}

extension _Transformable {
    static func transform(from object: Any) -> Self? {
        if let typedObject = object as? Self {
            return typedObject
        }
        switch self {
        case let type as _ExtendCustomBasicType.Type:
            return type._transform(from: object) as? Self
        case let type as _BuiltInBridgeType.Type:
            return type._transform(from: object) as? Self
        case let type as _BuiltInBasicType.Type:
            return type._transform(from: object) as? Self
        case let type as _RawEnumProtocol.Type:
            return type._transform(from: object) as? Self
        case let type as _ExtendCustomModelType.Type:
            return type._transform(from: object) as? Self
        default:
            return nil
        }
    }

    func plainValue() -> Any? {
        switch self {
        case let rawValue as _ExtendCustomBasicType:
            return rawValue._plainValue()
        case let rawValue as _BuiltInBridgeType:
            return rawValue._plainValue()
        case let rawValue as _BuiltInBasicType:
            return rawValue._plainValue()
        case let rawValue as _RawEnumProtocol:
            return rawValue._plainValue()
        case let rawValue as _ExtendCustomModelType:
            return rawValue._plainValue()
        default:
            return nil
        }
    }
}

// MARK: - BuiltInBasicType
protocol _BuiltInBasicType: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

// Suppport integer type

protocol IntegerPropertyProtocol: FixedWidthInteger, _BuiltInBasicType {
    init?(_ text: String, radix: Int)
    init(_ number: NSNumber)
}

extension IntegerPropertyProtocol {
    static func _transform(from object: Any) -> Self? {
        switch object {
        case let str as String:
            return Self(str, radix: 10)
        case let num as NSNumber:
            return Self(num)
        default:
            return nil
        }
    }

    func _plainValue() -> Any? {
        self
    }
}

extension Int: IntegerPropertyProtocol {}
extension UInt: IntegerPropertyProtocol {}
extension Int8: IntegerPropertyProtocol {}
extension Int16: IntegerPropertyProtocol {}
extension Int32: IntegerPropertyProtocol {}
extension Int64: IntegerPropertyProtocol {}
extension UInt8: IntegerPropertyProtocol {}
extension UInt16: IntegerPropertyProtocol {}
extension UInt32: IntegerPropertyProtocol {}
extension UInt64: IntegerPropertyProtocol {}

extension Bool: _BuiltInBasicType {
    static func _transform(from object: Any) -> Bool? {
        switch object {
        case let str as NSString:
            let lowerCase = str.lowercased
            if ["0", "false"].contains(lowerCase) {
                return false
            }
            if ["1", "true"].contains(lowerCase) {
                return true
            }
            return nil
        case let num as NSNumber:
            return num.boolValue
        default:
            return nil
        }
    }

    func _plainValue() -> Any? {
        self
    }
}

// Support float type

protocol FloatPropertyProtocol: _BuiltInBasicType, LosslessStringConvertible {
    init(_ number: NSNumber)
}

extension FloatPropertyProtocol {
    static func _transform(from object: Any) -> Self? {
        switch object {
        case let str as String:
            return Self(str)
        case let num as NSNumber:
            return Self(num)
        default:
            return nil
        }
    }

    func _plainValue() -> Any? {
        self
    }
}

extension Float: FloatPropertyProtocol {}
extension Double: FloatPropertyProtocol {}

extension String: _BuiltInBasicType {
    static func _transform(from object: Any) -> String? {
        switch object {
        case let str as String:
            return str
        case let num as NSNumber:
            // Boolean Type Inside
            if NSStringFromClass(type(of: num)) == String(format: "%@%@%@", "__N", "SCFBo", "olean") {
                if num.boolValue {
                    return "true"
                } else {
                    return "false"
                }
            }
            return num.stringValue
        case _ as NSNull:
            return nil
        default:
            return "\(object)"
        }
    }

    func _plainValue() -> Any? {
        self
    }
}

// MARK: Optional Support

extension Optional: _BuiltInBasicType {
    static func _transform(from object: Any) -> Optional? {
        if let value = (Wrapped.self as? _Transformable.Type)?.transform(from: object) as? Wrapped {
            return Optional(value)
        } else if let value = object as? Wrapped {
            return Optional(value)
        }
        return nil
    }

    func _getWrappedValue() -> Any? {
        map { wrapped -> Any in
            return wrapped as Any
        }
    }

    func _plainValue() -> Any? {
        if let value = _getWrappedValue() {
            if let transformable = value as? _Transformable {
                return transformable.plainValue()
            } else {
                return value
            }
        }
        return nil
    }
}

// MARK: Collection Support : Array & Set

extension Collection {
    static func _collectionTransform(from object: Any) -> [Iterator.Element]? {
        guard let arr = object as? [Any] else {
            InternalLogger.logDebug("Expect object to be an array but it's not")
            return nil
        }
        typealias Element = Iterator.Element
        var result = [Element]()
        for each in arr {
            if let element = (Element.self as? _Transformable.Type)?.transform(from: each) as? Element {
                result.append(element)
            } else if let element = each as? Element {
                result.append(element)
            }
        }
        return result
    }

    func _collectionPlainValue() -> Any? {
        typealias Element = Iterator.Element
        var result = [Any]()
        for each in self {
            if let transformable = each as? _Transformable, let transValue = transformable.plainValue() {
                result.append(transValue)
            } else {
                InternalLogger.logError("value: \(each) isn't transformable type!")
            }
        }
        return result
    }
}

extension Array: _BuiltInBasicType {
    static func _transform(from object: Any) -> [Element]? {
        _collectionTransform(from: object)
    }

    func _plainValue() -> Any? {
        _collectionPlainValue()
    }
}

extension Set: _BuiltInBasicType {
    static func _transform(from object: Any) -> Set<Element>? {
        if let arr = _collectionTransform(from: object) {
            return Set(arr)
        }
        return nil
    }

    func _plainValue() -> Any? {
        _collectionPlainValue()
    }
}

// MARK: Dictionary Support

extension Dictionary: _BuiltInBasicType {
    static func _transform(from object: Any) -> [Key: Value]? {
        guard let dict = object as? [String: Any] else {
            InternalLogger.logDebug("Expect object to be an NSDictionary but it's not")
            return nil
        }
        var result = [Key: Value]()
        for (key, value) in dict {
            if let sKey = key as? Key {
                if let nValue = (Value.self as? _Transformable.Type)?.transform(from: value) as? Value {
                    result[sKey] = nValue
                } else if let nValue = value as? Value {
                    result[sKey] = nValue
                }
            }
        }
        return result
    }

    func _plainValue() -> Any? {
        var result = [String: Any]()
        for (key, value) in self {
            if let key = key as? String {
                if let transformable = value as? _Transformable {
                    if let transValue = transformable.plainValue() {
                        result[key] = transValue
                    }
                }
            }
        }
        return result
    }
}

// MARK: - BuiltInBridgeType
protocol _BuiltInBridgeType: _Transformable {
    static func _transform(from object: Any) -> _BuiltInBridgeType?
    func _plainValue() -> Any?
}

extension NSString: _BuiltInBridgeType {
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        if let str = String.transform(from: object) {
            return NSString(string: str)
        }
        return nil
    }

    func _plainValue() -> Any? {
        self
    }
}

extension NSNumber: _BuiltInBridgeType {
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        switch object {
        case let num as NSNumber:
            return num
        case let str as NSString:
            let lowercase = str.lowercased
            if lowercase == "true" {
                return NSNumber(booleanLiteral: true)
            } else if lowercase == "false" {
                return NSNumber(booleanLiteral: false)
            } else {
                // normal number
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                return formatter.number(from: str as String)
            }
        default:
            return nil
        }
    }

    func _plainValue() -> Any? {
        self
    }
}

extension NSArray: _BuiltInBridgeType {
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        object as? NSArray
    }

    func _plainValue() -> Any? {
        (self as? [Any])?.plainValue()
    }
}

extension NSDictionary: _BuiltInBridgeType {
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        object as? NSDictionary
    }

    func _plainValue() -> Any? {
        (self as? [String: Any])?.plainValue()
    }
}

// MARK: - EnumType
public protocol _RawEnumProtocol: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

extension RawRepresentable where Self: _RawEnumProtocol {
    public static func _transform(from object: Any) -> Self? {
        if let transformableType = RawValue.self as? _Transformable.Type {
            if let typedValue = transformableType.transform(from: object) {
                return Self(rawValue: typedValue as! RawValue)
            }
        }
        return nil
    }

    public func _plainValue() -> Any? {
        rawValue
    }
}

// MARK: - ExtendCustomModelType
public protocol _ExtendCustomModelType: _Transformable {
    init()
    mutating func willStartMapping()
    mutating func mapping(mapper: HelpingMapper)
    mutating func didFinishMapping()
    mutating func mappingValue(_ value: Any, forKey key: String)
}

extension _ExtendCustomModelType {
    public mutating func willStartMapping() {}
    public mutating func mapping(mapper: HelpingMapper) {}
    public mutating func didFinishMapping() {}
    public mutating func mappingValue(_ value: Any, forKey key: String) {}
}

extension NSObject {
    /// Finds the internal object in `object` as the `designatedPath` specified
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
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

    // this's a workaround before https://bugs.swift.org/browse/SR-5223 fixed
    static func createInstance() -> NSObject {
        self.init()
    }
}

extension _ExtendCustomModelType {
    static func _transform(from object: Any) -> Self? {
        if let dict = object as? [String: Any] {
            // nested object, transform recursively
            return _transform(dict: dict) as? Self
        }
        return nil
    }

    static func _transform(dict: [String: Any]) -> _ExtendCustomModelType? {
        var instance: Self
        if let _nsType = Self.self as? NSObject.Type {
            instance = _nsType.createInstance() as! Self
        } else {
            instance = Self()
        }
        instance.willStartMapping()
        _transform(dict: dict, to: &instance)
        instance.didFinishMapping()
        return instance
    }

    static func _transform(dict: [String: Any], to instance: inout Self) {
        // do user-specified mapping first
        let mapper = HelpingMapper()
        guard let properties = getProperties(for: instance, mapper: mapper) else {
            InternalLogger.logDebug("Failed when try to get properties from type: \(type(of: Self.self))")
            return
        }

        instance.mapping(mapper: mapper)

        let _dict = convertKeyIfNeeded(dict: dict)
        let instanceIsNsObject = instance.isNSObjectType()
        let bridgedPropertyList = instance.getBridgedPropertyList()

        for property in properties {
            let isBridgedProperty = instanceIsNsObject && bridgedPropertyList.contains(property.key)

            let propertyDetail = PropertyInfo(key: property.key, type: property.type, bridged: isBridgedProperty)
            if mapper.propertyExcluded(property: propertyDetail) {
                InternalLogger.logDebug("Exclude property: \(property.key)")
                continue
            }

            if let rawValue = getRawValueFrom(dict: _dict, property: propertyDetail, mapper: mapper) {
                if let convertedValue = convertValue(rawValue: rawValue, property: propertyDetail, mapper: mapper) {
                    assignProperty(convertedValue: convertedValue, instance: &instance, property: propertyDetail)
                    continue
                }
            }
            InternalLogger.logDebug("Property: \(property.key) hasn't been written in")
        }
    }

    static func convertKeyIfNeeded(dict: [String: Any]) -> [String: Any] {
        if !JSONModelConfiguration.shared.deserializeOptions.isEmpty {
            var newDict = [String: Any]()
            for kvPair in dict {
                var newKey = kvPair.key
                if JSONModelConfiguration.shared.deserializeOptions.contains(.snakeToCamel) {
                    newKey = newKey.fw.camelString
                } else if JSONModelConfiguration.shared.deserializeOptions.contains(.camelToSnake) {
                    newKey = newKey.fw.underlineString
                }
                if JSONModelConfiguration.shared.deserializeOptions.contains(.caseInsensitive) {
                    newKey = newKey.lowercased()
                }
                newDict[newKey] = kvPair.value
            }
            return newDict
        }
        return dict
    }

    static func getRawValueFrom(dict: [String: Any], property: PropertyInfo, mapper: HelpingMapper) -> Any? {
        if let mappingHandler = mapper.getMappingHandler(property: property) {
            if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
                for mappingPath in mappingPaths {
                    if let _value = dict.findValueBy(path: mappingPath) {
                        return _value
                    }
                }
                return nil
            }
        }
        if JSONModelConfiguration.shared.deserializeOptions.contains(.caseInsensitive) {
            return dict[property.key.lowercased()]
        }
        return dict[property.key]
    }

    static func convertValue(rawValue: Any, property: PropertyInfo, mapper: HelpingMapper) -> Any? {
        if rawValue is NSNull { return nil }
        if let mappingHandler = mapper.getMappingHandler(property: property),
           let transformer = mappingHandler.assignmentClosure {
            return transformer(rawValue)
        }
        if let transformableType = property.type as? _Transformable.Type {
            return transformableType.transform(from: rawValue)
        } else {
            return extensions(of: property.type).takeValue(from: rawValue)
        }
    }

    static func readAllChildrenFrom(mirror: Mirror) -> [(String, Any)] {
        var children = [(label: String?, value: Any)]()
        children += mirror.children

        var currentMirror = mirror
        while let superclassChildren = currentMirror.superclassMirror?.children {
            children += superclassChildren
            currentMirror = currentMirror.superclassMirror!
        }
        var result = [(String, Any)]()
        for child in children {
            if let _label = child.label {
                if child.value is JSONMappedValue {
                    result.append((String(_label.dropFirst()), child.value))
                } else {
                    result.append((_label, child.value))
                }
            }
        }
        return result
    }

    static func merge(children: [(String, Any)], propertyInfos: [PropertyInfo]) -> [String: (Any, PropertyInfo?)] {
        var infoDict = [String: PropertyInfo]()
        for info in propertyInfos {
            infoDict[info.key] = info
        }

        var result = [String: (Any, PropertyInfo?)]()
        if JSONModelConfiguration.shared.deserializeOptions.contains(.serializeReverse) {
            for child in children {
                var key = child.0
                if JSONModelConfiguration.shared.deserializeOptions.contains(.snakeToCamel) {
                    key = key.fw.underlineString
                } else if JSONModelConfiguration.shared.deserializeOptions.contains(.camelToSnake) {
                    key = key.fw.camelString
                }
                if let value = child.1 as? JSONMappedValue {
                    result[key] = (value.mappingValue(), infoDict[child.0])
                } else {
                    result[key] = (child.1, infoDict[child.0])
                }
            }
        } else {
            for child in children {
                if let value = child.1 as? JSONMappedValue {
                    result[child.0] = (value.mappingValue(), infoDict[child.0])
                } else {
                    result[child.0] = (child.1, infoDict[child.0])
                }
            }
        }
        return result
    }

    static func getProperties<T: _ExtendCustomModelType>(for instance: T, mapper: HelpingMapper, children: [(String, Any)]? = nil) -> [Property.Description]? {
        if instance is KeyMappable {
            let children = children ?? readAllChildrenFrom(mirror: Mirror(reflecting: instance))
            return children.map { child in
                if let value = child.1 as? JSONMappedValue {
                    if let mappingKeys = value.mappingKeys(), !mappingKeys.isEmpty {
                        mapper.specify(key: child.0, names: mappingKeys)
                    }
                    return Property.Description(key: child.0, type: type(of: value.mappingValue()))
                } else {
                    return Property.Description(key: child.0, type: type(of: child.1))
                }
            }
        } else {
            return nil
        }
    }

    static func assignProperty(convertedValue: Any, instance: inout Self, property: PropertyInfo) {
        if property.bridged {
            (instance as! NSObject).setValue(convertedValue, forKey: property.key)
        } else {
            if instance is KeyMappable {
                instance.mappingValue(convertedValue, forKey: property.key)
            }
        }
    }
}

extension _ExtendCustomModelType {
    func _plainValue() -> Any? {
        Self._serializeAny(object: self)
    }

    static func _serializeAny(object: _Transformable) -> Any? {
        let mirror = Mirror(reflecting: object)

        guard let displayStyle = mirror.displayStyle else {
            return object.plainValue()
        }

        // after filtered by protocols above, now we expect the type is pure struct/class
        switch displayStyle {
        case .class, .struct:
            let mapper = HelpingMapper()
            // do user-specified mapping first
            if !(object is _ExtendCustomModelType) {
                InternalLogger.logDebug("This model of type: \(type(of: object)) is not mappable but is class/struct type")
                return object
            }

            let children = readAllChildrenFrom(mirror: mirror)
            var instance = object as! _ExtendCustomModelType
            guard let properties = getProperties(for: instance, mapper: mapper, children: children) else {
                InternalLogger.logError("Can not get properties info for type: \(type(of: object))")
                return nil
            }

            let instanceIsNsObject = instance.isNSObjectType()
            let bridgedProperty = instance.getBridgedPropertyList()
            let propertyInfos = properties.map { desc -> PropertyInfo in
                return PropertyInfo(key: desc.key, type: desc.type, bridged: instanceIsNsObject && bridgedProperty.contains(desc.key))
            }

            instance.mapping(mapper: mapper)

            let requiredInfo = merge(children: children, propertyInfos: propertyInfos)

            return _serializeModelObject(instance: instance, properties: requiredInfo, mapper: mapper) as Any
        default:
            return object.plainValue()
        }
    }

    static func _serializeModelObject(instance: _ExtendCustomModelType, properties: [String: (Any, PropertyInfo?)], mapper: HelpingMapper) -> [String: Any] {
        var dict = [String: Any]()
        for (key, property) in properties {
            var realKey = key
            var realValue = property.0

            if let info = property.1 {
                if info.bridged, let _value = (instance as! NSObject).value(forKey: key) {
                    realValue = _value
                }

                if mapper.propertyExcluded(property: info) {
                    continue
                }

                if let mappingHandler = mapper.getMappingHandler(property: info) {
                    // if specific key is set, replace the label
                    if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
                        // take the first path, last segment if more than one
                        realKey = mappingPaths[0].segments.last!
                    }

                    if let transformer = mappingHandler.takeValueClosure {
                        if let _transformedValue = transformer(realValue) {
                            dict[realKey] = _transformedValue
                        }
                        continue
                    }
                }
            }

            if let typedValue = realValue as? _Transformable {
                if let result = _serializeAny(object: typedValue) {
                    dict[realKey] = result
                    continue
                }
            }

            InternalLogger.logDebug("The value for key: \(key) is not transformable type")
        }
        return dict
    }
}

// MARK: - ExtendCustomBasicType
public protocol _ExtendCustomBasicType: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

// MARK: - Deserializer
extension JSONModel {
    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserialize(from dict: [AnyHashable: Any]?, designatedPath: String? = nil) -> Self? {
        JSONDeserializer<Self>.deserializeFrom(dict: dict as? [String: Any], designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserialize(from json: String?, designatedPath: String? = nil) -> Self? {
        JSONDeserializer<Self>.deserializeFrom(json: json, designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `array` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserialize(from array: [Any]?, designatedPath: String? = nil) -> Self? {
        JSONDeserializer<Self>.deserializeFrom(array: array, designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in  `object` as the `designatedPath` specified, and converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil) -> Self? {
        if let dict = object as? [AnyHashable: Any] {
            return deserialize(from: dict, designatedPath: designatedPath)
        } else if let array = object as? [Any] {
            return deserialize(from: array, designatedPath: designatedPath)
        } else {
            var string = object as? String
            if string == nil, let data = object as? Data {
                string = String(data: data, encoding: .utf8)
            }
            return deserialize(from: string, designatedPath: designatedPath)
        }
    }

    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and safe converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func safeDeserialize(from dict: [AnyHashable: Any]?, designatedPath: String? = nil) -> Self {
        deserialize(from: dict, designatedPath: designatedPath) ?? Self()
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and safe converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func safeDeserialize(from string: String?, designatedPath: String? = nil) -> Self {
        deserialize(from: string, designatedPath: designatedPath) ?? Self()
    }

    /// Finds the internal JSON field in `array` as the `designatedPath` specified, and safe converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func safeDeserialize(from array: [Any]?, designatedPath: String? = nil) -> Self {
        deserialize(from: array, designatedPath: designatedPath) ?? Self()
    }

    /// Finds the internal JSON field in `object` as the `designatedPath` specified, and safe converts it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer
    public static func safeDeserializeAny(from object: Any?, designatedPath: String? = nil) -> Self {
        if let dict = object as? [AnyHashable: Any] {
            return deserialize(from: dict, designatedPath: designatedPath) ?? Self()
        } else if let array = object as? [Any] {
            return deserialize(from: array, designatedPath: designatedPath) ?? Self()
        } else {
            var string = object as? String
            if string == nil, let data = object as? Data {
                string = String(data: data, encoding: .utf8)
            }
            return deserialize(from: string, designatedPath: designatedPath) ?? Self()
        }
    }

    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public mutating func merge(from dict: [AnyHashable: Any]?, designatedPath: String? = nil) {
        JSONDeserializer.update(object: &self, from: dict as? [String: Any], designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public mutating func merge(from string: String?, designatedPath: String? = nil) {
        JSONDeserializer.update(object: &self, from: string, designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `array` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public mutating func merge(from array: [Any]?, designatedPath: String? = nil) {
        JSONDeserializer.update(object: &self, from: array, designatedPath: designatedPath)
    }

    /// Finds the internal JSON field in `object` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public mutating func mergeAny(from object: Any?, designatedPath: String? = nil) {
        if let dict = object as? [AnyHashable: Any] {
            merge(from: dict, designatedPath: designatedPath)
        } else if let array = object as? [Any] {
            merge(from: array, designatedPath: designatedPath)
        } else {
            var string = object as? String
            if string == nil, let data = object as? Data {
                string = String(data: data, encoding: .utf8)
            }
            merge(from: string, designatedPath: designatedPath)
        }
    }
}

extension Array where Element: JSONModel {
    /// if the JSON field finded by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserialize(from json: String?, designatedPath: String? = nil) -> [Element?]? {
        JSONDeserializer<Element>.deserializeModelArrayFrom(json: json, designatedPath: designatedPath)
    }

    /// deserialize model array from dictionary
    public static func deserialize(from dict: [AnyHashable: Any]?, designatedPath: String? = nil) -> [Element?]? {
        JSONDeserializer<Element>.deserializeModelArrayFrom(dict: dict, designatedPath: designatedPath)
    }

    /// deserialize model array from array
    public static func deserialize(from array: [Any]?, designatedPath: String? = nil) -> [Element?]? {
        JSONDeserializer<Element>.deserializeModelArrayFrom(array: array, designatedPath: designatedPath)
    }

    /// deserialize model array from object
    public static func deserializeAny(from object: Any?, designatedPath: String? = nil) -> [Element]? {
        if let array = object as? [Any] {
            let elements = deserialize(from: array, designatedPath: designatedPath)
            return elements?.compactMap { $0 }
        } else if let dict = object as? [AnyHashable: Any] {
            let elements = deserialize(from: dict, designatedPath: designatedPath)
            return elements?.compactMap { $0 }
        } else {
            var string = object as? String
            if string == nil, let data = object as? Data {
                string = String(data: data, encoding: .utf8)
            }
            let elements = deserialize(from: string, designatedPath: designatedPath)
            return elements?.compactMap { $0 }
        }
    }

    /// safe deserialize model array from array
    public static func safeDeserialize(from array: [Any]?, designatedPath: String? = nil) -> [Element] {
        let elements = deserialize(from: array, designatedPath: designatedPath) ?? []
        return elements.compactMap { $0 }
    }

    /// if the JSON field finded by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method safe converts it to a Models array
    public static func safeDeserialize(from string: String?, designatedPath: String? = nil) -> [Element] {
        let elements = deserialize(from: string, designatedPath: designatedPath) ?? []
        return elements.compactMap { $0 }
    }

    /// safe deserialize model array from dictionary
    public static func safeDeserialize(from dict: [AnyHashable: Any]?, designatedPath: String? = nil) -> [Element] {
        let elements = JSONDeserializer<Element>.deserializeModelArrayFrom(dict: dict, designatedPath: designatedPath) ?? []
        return elements.compactMap { $0 }
    }

    /// safe deserialize model array from object
    public static func safeDeserializeAny(from object: Any?, designatedPath: String? = nil) -> [Element] {
        if let array = object as? [Any] {
            return safeDeserialize(from: array, designatedPath: designatedPath)
        } else if let dict = object as? [AnyHashable: Any] {
            return safeDeserialize(from: dict, designatedPath: designatedPath)
        } else {
            var string = object as? String
            if string == nil, let data = object as? Data {
                string = String(data: data, encoding: .utf8)
            }
            return safeDeserialize(from: string, designatedPath: designatedPath)
        }
    }
}

public class JSONDeserializer<T: JSONModel> {
    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and map it to a Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func deserializeFrom(dict: [String: Any]?, designatedPath: String? = nil) -> T? {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = NSObject.getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let _dict = targetDict {
            return T._transform(dict: _dict) as? T
        }
        return nil
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and converts it to Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func deserializeFrom(json: String?, designatedPath: String? = nil) -> T? {
        guard let _json = json else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonDict = NSObject.getInnerObject(inside: jsonObject, by: designatedPath) as? [String: Any] {
                return deserializeFrom(dict: jsonDict)
            }
        } catch {
            InternalLogger.logError(error)
        }
        return nil
    }

    /// Finds the internal JSON field in `array` as the `designatedPath` specified, and converts it to Model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func deserializeFrom(array: [Any]?, designatedPath: String? = nil) -> T? {
        guard let jsonObject = array else {
            return nil
        }
        if let jsonDict = NSObject.getInnerObject(inside: jsonObject, by: designatedPath) as? [String: Any] {
            return deserializeFrom(dict: jsonDict)
        }
        return nil
    }

    /// Finds the internal dictionary in `dict` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func update(object: inout T, from dict: [String: Any]?, designatedPath: String? = nil) {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = NSObject.getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let _dict = targetDict {
            T._transform(dict: _dict, to: &object)
        }
    }

    /// Finds the internal JSON field in `json` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func update(object: inout T, from json: String?, designatedPath: String? = nil) {
        guard let _json = json else {
            return
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonDict = jsonObject as? [String: Any] {
                update(object: &object, from: jsonDict, designatedPath: designatedPath)
            }
        } catch {
            InternalLogger.logError(error)
        }
    }

    /// Finds the internal JSON field in `array` as the `designatedPath` specified, and use it to reassign an exist model
    /// `designatedPath` is a string like `result.data.orderInfo`, which each element split by `.` represents key of each layer, or nil
    public static func update(object: inout T, from array: [Any]?, designatedPath: String? = nil) {
        guard let jsonObject = array else {
            return
        }
        if let jsonDict = NSObject.getInnerObject(inside: jsonObject, by: designatedPath) as? [String: Any] {
            update(object: &object, from: jsonDict)
        }
    }

    /// if the JSON field found by `designatedPath` in `json` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserializeModelArrayFrom(json: String?, designatedPath: String? = nil) -> [T?]? {
        guard let _json = json else {
            return nil
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: String.Encoding.utf8)!, options: .allowFragments)
            if let jsonArray = NSObject.getInnerObject(inside: jsonObject, by: designatedPath) as? [Any] {
                return jsonArray.map { item -> T? in
                    return self.deserializeFrom(dict: item as? [String: Any])
                }
            }
        } catch {
            InternalLogger.logError(error)
        }
        return nil
    }

    /// if the JSON field found by `designatedPath` in `object` is representing a array, such as `[{...}, {...}, {...}]`,
    /// this method converts it to a Models array
    public static func deserializeModelArrayFrom(dict: [AnyHashable: Any]?, designatedPath: String? = nil) -> [T?]? {
        guard let jsonObject = dict else {
            return nil
        }
        if let jsonArray = NSObject.getInnerObject(inside: jsonObject, by: designatedPath) as? [Any] {
            return jsonArray.map { item -> T? in
                return self.deserializeFrom(dict: item as? [String: Any])
            }
        }
        return nil
    }

    /// mapping raw array to Models array
    public static func deserializeModelArrayFrom(array: [Any]?, designatedPath: String? = nil) -> [T?]? {
        guard let _arr = array else {
            return nil
        }
        if let jsonArray = NSObject.getInnerObject(inside: _arr, by: designatedPath) as? [Any] {
            return jsonArray.map { item -> T? in
                return self.deserializeFrom(dict: item as? [String: Any])
            }
        }
        return nil
    }
}

// MARK: - Serializer
extension JSONModel {
    public func toJSON() -> [String: Any]? {
        if let dict = Self._serializeAny(object: self) as? [String: Any] {
            return dict
        }
        return nil
    }

    public func toJSONString(prettyPrint: Bool = false) -> String? {
        if let anyObject = toJSON() {
            if JSONSerialization.isValidJSONObject(anyObject) {
                do {
                    let jsonData: Data
                    if prettyPrint {
                        jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: [.prettyPrinted])
                    } else {
                        jsonData = try JSONSerialization.data(withJSONObject: anyObject, options: [])
                    }
                    return String(data: jsonData, encoding: .utf8)
                } catch {
                    InternalLogger.logError(error)
                }
            } else {
                InternalLogger.logDebug("\(anyObject)) is not a valid JSON Object")
            }
        }
        return nil
    }
}

extension Collection where Iterator.Element: JSONModel {
    public func toJSON() -> [[String: Any]?] {
        map { $0.toJSON() }
    }

    public func toJSONString(prettyPrint: Bool = false) -> String? {
        let anyArray = toJSON()
        if JSONSerialization.isValidJSONObject(anyArray) {
            do {
                let jsonData: Data
                if prettyPrint {
                    jsonData = try JSONSerialization.data(withJSONObject: anyArray, options: [.prettyPrinted])
                } else {
                    jsonData = try JSONSerialization.data(withJSONObject: anyArray, options: [])
                }
                return String(data: jsonData, encoding: .utf8)
            } catch {
                InternalLogger.logError(error)
            }
        } else {
            InternalLogger.logDebug("\(toJSON()) is not a valid JSON Object")
        }
        return nil
    }
}

// MARK: - HashString
extension JSONModel where Self: AnyObject {
    public var hashString: String {
        let opaquePointer = Unmanaged.passUnretained(self).toOpaque()
        return String(describing: opaquePointer)
    }
}

// MARK: - HelpingMapper
public typealias CustomMappingKeyValueTuple = (String, MappingPropertyHandler)

struct MappingPath {
    var segments: [String]

    static func buildFrom(rawPath: String) -> MappingPath {
        let regex = try! NSRegularExpression(pattern: "(?<![\\\\])\\.")
        let nsString = rawPath as NSString
        let results = regex.matches(in: rawPath, range: NSRange(location: 0, length: nsString.length))
        var splitPoints = results.map(\.range.location)

        var curPos = 0
        var pathArr = [String]()
        splitPoints.append(nsString.length)
        for point in splitPoints {
            let start = rawPath.index(rawPath.startIndex, offsetBy: curPos)
            let end = rawPath.index(rawPath.startIndex, offsetBy: point)
            let subPath = String(rawPath[start..<end]).replacingOccurrences(of: "\\.", with: ".")
            if !subPath.isEmpty {
                pathArr.append(subPath)
            }
            curPos = point + 1
        }
        return MappingPath(segments: pathArr)
    }
}

extension Dictionary where Key == String, Value: Any {
    func findValueBy(path: MappingPath) -> Any? {
        var currentDict: [String: Any]? = self
        var lastValue: Any?
        for segment in path.segments {
            lastValue = currentDict?[segment]
            currentDict = currentDict?[segment] as? [String: Any]
        }
        return lastValue
    }
}

public class MappingPropertyHandler {
    var mappingPaths: [MappingPath]?
    var assignmentClosure: ((Any?) -> (Any?))?
    var takeValueClosure: ((Any?) -> (Any?))?

    public init(rawPaths: [String]?, assignmentClosure: ((Any?) -> (Any?))?, takeValueClosure: ((Any?) -> (Any?))?) {
        let mappingPaths = rawPaths?.map { rawPath -> MappingPath in
            if JSONModelConfiguration.shared.deserializeOptions.contains(.caseInsensitive) {
                return MappingPath.buildFrom(rawPath: rawPath.lowercased())
            }
            return MappingPath.buildFrom(rawPath: rawPath)
        }.filter { mappingPath -> Bool in
            return mappingPath.segments.count > 0
        }
        if let count = mappingPaths?.count, count > 0 {
            self.mappingPaths = mappingPaths
        }
        self.assignmentClosure = assignmentClosure
        self.takeValueClosure = takeValueClosure
    }
}

public class HelpingMapper {
    private var mappingHandlers = [String: MappingPropertyHandler]()
    private var excludeProperties = [String]()

    public func specify(key: String, names: String...) {
        specify(key: key, names: names)
    }

    public func specify(key: String, names: [String]) {
        mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil)
    }

    public func specify<T>(property: inout T, key: String, name: String? = nil, converter: ((String) -> T)?) {
        let names = (name == nil ? nil : [name!])

        if let _converter = converter {
            let assignmentClosure = { (jsonValue: Any?) -> Any? in
                if let _value = jsonValue {
                    if let object = _value as? NSObject {
                        if let str = String.transform(from: object) {
                            return _converter(str)
                        }
                    }
                }
                return nil
            }
            mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: assignmentClosure, takeValueClosure: nil)
        } else {
            mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil)
        }
    }

    public func addCustomMapping(key: String, mappingInfo: MappingPropertyHandler) {
        mappingHandlers[key] = mappingInfo
    }

    public func exclude(key: String) {
        excludeProperties.append(key)
    }

    func getMappingHandler(property: PropertyInfo) -> MappingPropertyHandler? {
        if let handler = mappingHandlers[property.key] {
            return handler
        }
        return nil
    }

    func propertyExcluded(property: PropertyInfo) -> Bool {
        if excludeProperties.contains(property.key) {
            return true
        }
        return false
    }
}

// MARK: - Logger
enum InternalLogger {
    static func logError(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if JSONModelConfiguration.shared.debugMode.rawValue <= JSONModelConfiguration.DebugMode.error.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }

    static func logDebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if JSONModelConfiguration.shared.debugMode.rawValue <= JSONModelConfiguration.DebugMode.debug.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }

    static func logVerbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if JSONModelConfiguration.shared.debugMode.rawValue <= JSONModelConfiguration.DebugMode.verbose.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }
}

// MARK: - Configuration
public struct DeserializeOptions: OptionSet, Sendable {
    public let rawValue: Int

    public static let caseInsensitive = DeserializeOptions(rawValue: 1 << 0)

    public static let snakeToCamel = DeserializeOptions(rawValue: 1 << 1)

    public static let camelToSnake = DeserializeOptions(rawValue: 1 << 2)

    public static let serializeReverse = DeserializeOptions(rawValue: 1 << 3)

    public static let defaultOptions: DeserializeOptions = []

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public class JSONModelConfiguration: @unchecked Sendable {
    public enum DebugMode: Int {
        case verbose = 0
        case debug = 1
        case error = 2
        case none = 3
    }

    public static let shared = JSONModelConfiguration()

    public var debugMode: DebugMode = .error
    public var deserializeOptions: DeserializeOptions = .defaultOptions
}

// MARK: - AnyExtensions
protocol AnyExtensions {}

extension AnyExtensions {
    static func takeValue(from anyValue: Any) -> Self? {
        anyValue as? Self
    }
}

func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions: AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}

// MARK: - PropertyInfo
struct PropertyInfo {
    let key: String
    let type: Any.Type
    let bridged: Bool
}

// MARK: - Properties
/// An instance property
struct Property {
    let key: String
    let value: Any

    /// An instance property description
    struct Description {
        let key: String
        let type: Any.Type
    }
}

// MARK: - TransformOf
open class TransformOf<ObjectType, JSONType>: TransformType {
    public typealias Object = ObjectType
    public typealias JSON = JSONType

    private let fromJSON: (JSONType?) -> ObjectType?
    private let toJSON: (ObjectType?) -> JSONType?

    public init(fromJSON: @escaping (JSONType?) -> ObjectType?, toJSON: @escaping (ObjectType?) -> JSONType?) {
        self.fromJSON = fromJSON
        self.toJSON = toJSON
    }

    open func transformFromJSON(_ value: Any?) -> ObjectType? {
        fromJSON(value as? JSONType)
    }

    open func transformToJSON(_ value: ObjectType?) -> JSONType? {
        toJSON(value)
    }
}

// MARK: - TransformType
public protocol TransformType {
    associatedtype Object
    associatedtype JSON

    func transformFromJSON(_ value: Any?) -> Object?
    func transformToJSON(_ value: Object?) -> JSON?
}

// MARK: - URLTransform
open class URLTransform: TransformType {
    public typealias Object = URL
    public typealias JSON = String
    private let shouldEncodeURLString: Bool

    /**
     Initializes the URLTransform with an option to encode URL strings before converting them to an NSURL
     - parameter shouldEncodeUrlString: when true (the default) the string is encoded before passing
     to `NSURL(string:)`
     - returns: an initialized transformer
     */
    public init(shouldEncodeURLString: Bool = true) {
        self.shouldEncodeURLString = shouldEncodeURLString
    }

    open func transformFromJSON(_ value: Any?) -> URL? {
        guard let URLString = value as? String else { return nil }

        if !shouldEncodeURLString {
            return URL(string: URLString)
        }

        guard let escapedURLString = URLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        return URL(string: escapedURLString)
    }

    open func transformToJSON(_ value: URL?) -> String? {
        if let URL = value {
            return URL.absoluteString
        }
        return nil
    }
}

// MARK: - EnumTransform
open class EnumTransform<T: RawRepresentable>: TransformType {
    public typealias Object = T
    public typealias JSON = T.RawValue

    public init() {}

    open func transformFromJSON(_ value: Any?) -> T? {
        if let raw = value as? T.RawValue {
            return T(rawValue: raw)
        }
        return nil
    }

    open func transformToJSON(_ value: T?) -> T.RawValue? {
        if let obj = value {
            return obj.rawValue
        }
        return nil
    }
}

// MARK: - NSDecimalNumberTransform
open class NSDecimalNumberTransform: TransformType {
    public typealias Object = NSDecimalNumber
    public typealias JSON = String

    public init() {}

    open func transformFromJSON(_ value: Any?) -> NSDecimalNumber? {
        if let string = value as? String {
            return NSDecimalNumber(string: string)
        }
        if let double = value as? Double {
            return NSDecimalNumber(value: double)
        }
        return nil
    }

    open func transformToJSON(_ value: NSDecimalNumber?) -> String? {
        guard let value else { return nil }
        return value.description
    }
}

// MARK: - DataTransform
open class DataTransform: TransformType {
    public typealias Object = Data
    public typealias JSON = String

    public init() {}

    open func transformFromJSON(_ value: Any?) -> Data? {
        guard let string = value as? String else {
            return nil
        }
        return Data(base64Encoded: string)
    }

    open func transformToJSON(_ value: Data?) -> String? {
        guard let data = value else {
            return nil
        }
        return data.base64EncodedString()
    }
}

// MARK: - HexColorTransform
open class HexColorTransform: TransformType {
    public typealias Object = UIColor

    public typealias JSON = String

    var prefix: Bool = false

    var alpha: Bool = false

    public init(prefixToJSON: Bool = false, alphaToJSON: Bool = false) {
        self.alpha = alphaToJSON
        self.prefix = prefixToJSON
    }

    open func transformFromJSON(_ value: Any?) -> Object? {
        if let rgba = value as? String {
            if rgba.hasPrefix("#") {
                let index = rgba.index(rgba.startIndex, offsetBy: 1)
                let hex = String(rgba[index...])
                return getColor(hex: hex)
            } else {
                return getColor(hex: rgba)
            }
        }
        return nil
    }

    open func transformToJSON(_ value: Object?) -> JSON? {
        if let value {
            return hexString(color: value)
        }
        return nil
    }

    fileprivate func hexString(color: Object) -> String {
        let comps = color.cgColor.components!
        let r = Int(comps[0] * 255)
        let g = Int(comps[1] * 255)
        let b = Int(comps[2] * 255)
        let a = Int(comps[3] * 255)
        var hexString = ""
        if prefix {
            hexString = "#"
        }
        hexString += String(format: "%02X%02X%02X", r, g, b)

        if alpha {
            hexString += String(format: "%02X", a)
        }
        return hexString
    }

    fileprivate func getColor(hex: String) -> Object? {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 1.0

        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch hex.count {
            case 3:
                red = CGFloat((hexValue & 0xF00) >> 8) / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
                blue = CGFloat(hexValue & 0x00F) / 15.0
            case 4:
                red = CGFloat((hexValue & 0xF000) >> 12) / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8) / 15.0
                blue = CGFloat((hexValue & 0x00F0) >> 4) / 15.0
                alpha = CGFloat(hexValue & 0x000F) / 15.0
            case 6:
                red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
                blue = CGFloat(hexValue & 0x0000FF) / 255.0
            case 8:
                red = CGFloat((hexValue & 0xFF00_0000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF_0000) >> 16) / 255.0
                blue = CGFloat((hexValue & 0x0000_FF00) >> 8) / 255.0
                alpha = CGFloat(hexValue & 0x0000_00FF) / 255.0
            default:
                // Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8
                return nil
            }
        } else {
            // "Scan hex error
            return nil
        }
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - DateTransform
open class DateTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = Double

    public init() {}

    open func transformFromJSON(_ value: Any?) -> Date? {
        if let timeInt = value as? Double {
            return Date(timeIntervalSince1970: TimeInterval(timeInt))
        }

        if let timeStr = value as? String {
            return Date(timeIntervalSince1970: TimeInterval(atof(timeStr)))
        }

        return nil
    }

    open func transformToJSON(_ value: Date?) -> Double? {
        if let date = value {
            return Double(date.timeIntervalSince1970)
        }
        return nil
    }
}

// MARK: - DateFormatterTransform
open class DateFormatterTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String

    public let dateFormatter: DateFormatter

    public init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }

    open func transformFromJSON(_ value: Any?) -> Date? {
        if let dateString = value as? String {
            return dateFormatter.date(from: dateString)
        }
        return nil
    }

    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return dateFormatter.string(from: date)
        }
        return nil
    }
}

// MARK: - ISO8601DateTransform
open class ISO8601DateTransform: DateFormatterTransform {
    public init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        super.init(dateFormatter: formatter)
    }
}

// MARK: - CustomDateFormatTransform
open class CustomDateFormatTransform: DateFormatterTransform {
    public init(formatString: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = formatString

        super.init(dateFormatter: formatter)
    }
}

// MARK: - KeyMappable
extension KeyMappable where Self: _ExtendCustomModelType {
    public mutating func mappingValue(_ value: Any, forKey key: String) {
        mappingMirror(value, forKey: key)
    }

    @discardableResult
    public func mappingMirror(_ value: Any, forKey key: String) -> Bool {
        var mirror: Mirror! = Mirror(reflecting: self)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                if let wrapper = child.value as? JSONMappedValue,
                   key == child.label!.dropFirst() {
                    wrapper.mappingValue(value)
                    return true
                }
            }
            mirror = mirror.superclassMirror
        }
        return false
    }
}

// MARK: - MappedValue
public protocol JSONMappedValue {
    func mappingKeys() -> [String]?
    func mappingValue() -> Any
    func mappingValue(_ value: Any)
}

extension MappedValue: JSONMappedValue {
    public func mappingKeys() -> [String]? {
        stringKeys
    }

    public func mappingValue() -> Any {
        if let wrapped = wrappedValue as? JSONMappedValue {
            return wrapped.mappingValue()
        } else {
            return wrappedValue
        }
    }

    public func mappingValue(_ value: Any) {
        guard !ignored else { return }

        if let wrapped = wrappedValue as? JSONMappedValue {
            wrapped.mappingValue(value)
        } else {
            wrappedValue = value as! Value
        }
    }
}

extension ValidatedValue: JSONMappedValue {
    public func mappingKeys() -> [String]? {
        nil
    }

    public func mappingValue() -> Any {
        if let wrapped = wrappedValue as? JSONMappedValue {
            return wrapped.mappingValue()
        } else {
            return wrappedValue
        }
    }

    public func mappingValue(_ value: Any) {
        if let wrapped = wrappedValue as? JSONMappedValue {
            wrapped.mappingValue(value)
        } else {
            wrappedValue = value as! Value
        }
    }
}

// MARK: - JSONModel+ObjectParameter
extension ObjectParameter where Self: JSONModel {
    public init(dictionaryValue: [AnyHashable: Any]) {
        self.init()
        merge(from: dictionaryValue)
    }

    public var dictionaryValue: [AnyHashable: Any] {
        let mirror = NSObject.fw.mirrorDictionary(self)
        var result: [AnyHashable: Any] = [:]
        for (key, value) in mirror {
            if let wrapper = value as? JSONMappedValue {
                result[String(key.dropFirst())] = wrapper.mappingValue()
            } else {
                result[key] = value
            }
        }
        return result
    }
}

// MARK: - JSONModel+AnyArchivable
extension AnyArchivable where Self: JSONModel {
    public static func archiveDecode(_ data: Data?) -> Self? {
        guard let data else { return nil }
        return deserialize(from: String(data: data, encoding: .utf8))
    }

    public func archiveEncode() -> Data? {
        toJSONString()?.data(using: .utf8)
    }
}
