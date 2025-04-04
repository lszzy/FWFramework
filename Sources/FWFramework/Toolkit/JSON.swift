//
//  JSON.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Wrapper
extension Wrapper {
    public var safeJSON: JSON { JSON(base) }
}

// MARK: - JSONError
public enum JSONError: Int, Swift.Error {
    case unsupportedType = 999
    case indexOutOfBounds = 900
    case elementTooDeep = 902
    case wrongType = 901
    case notExist = 500
    case invalidJSON = 490
}

extension JSONError: CustomNSError {
    public static var errorDomain: String { "site.wuyong.error.json" }

    public var errorCode: Int { rawValue }

    public var errorUserInfo: [String: Any] {
        switch self {
        case .unsupportedType:
            return [NSLocalizedDescriptionKey: "It is an unsupported type."]
        case .indexOutOfBounds:
            return [NSLocalizedDescriptionKey: "Array Index is out of bounds."]
        case .wrongType:
            return [NSLocalizedDescriptionKey: "Couldn't merge, because the JSONs differ in type on top level."]
        case .notExist:
            return [NSLocalizedDescriptionKey: "Dictionary key does not exist."]
        case .invalidJSON:
            return [NSLocalizedDescriptionKey: "JSON is invalid."]
        case .elementTooDeep:
            return [NSLocalizedDescriptionKey: "Element too deep. Increase maxObjectDepth and make sure there is no reference loop."]
        }
    }
}

// MARK: - JSONType
public enum JSONType: Int, Sendable {
    case number
    case string
    case bool
    case array
    case dictionary
    case null
    case unknown
}

// MARK: - JSON
/**
 JSON

 - see: [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
 */
@dynamicMemberLookup
public struct JSON: @unchecked Sendable {
    public init() {
        self.init(jsonObject: NSNull())
    }

    public init(data: Data, options opt: JSONSerialization.ReadingOptions = []) throws {
        let object: Any = try JSONSerialization.jsonObject(with: data, options: opt)
        self.init(jsonObject: object)
    }

    public init(_ object: Any?) {
        guard let object else {
            self.init(jsonObject: NSNull())
            return
        }
        switch object {
        case let object as Data:
            do {
                try self.init(data: object)
            } catch {
                self.init(jsonObject: NSNull())
            }
        default:
            self.init(jsonObject: object)
        }
    }

    public init(parseJSON jsonString: String) {
        if let data = jsonString.data(using: .utf8) {
            self.init(data)
        } else {
            self.init(NSNull())
        }
    }

    fileprivate init(jsonObject: Any) {
        self.object = jsonObject
    }

    public mutating func merge(with other: JSON) throws {
        try self.merge(with: other, typecheck: true)
    }

    public func merged(with other: JSON) throws -> JSON {
        var merged = self
        try merged.merge(with: other, typecheck: true)
        return merged
    }

    fileprivate mutating func merge(with other: JSON, typecheck: Bool) throws {
        if type == other.type {
            switch type {
            case .dictionary:
                for (key, _) in other {
                    try self[key].merge(with: other[key], typecheck: false)
                }
            case .array:
                self = JSON(arrayValue + other.arrayValue)
            default:
                self = other
            }
        } else {
            if typecheck {
                throw JSONError.wrongType
            } else {
                self = other
            }
        }
    }

    fileprivate var rawArray: [Any] = []
    fileprivate var rawDictionary: [String: Any] = [:]
    fileprivate var rawString: String = ""
    fileprivate var rawNumber: NSNumber = 0
    fileprivate var rawNull: NSNull = .init()
    fileprivate var rawBool: Bool = false

    public fileprivate(set) var type: JSONType = .null

    public fileprivate(set) var error: JSONError?

    public var object: Any {
        get {
            switch type {
            case .array: return rawArray
            case .dictionary: return rawDictionary
            case .string: return rawString
            case .number: return rawNumber
            case .bool: return rawBool
            default: return rawNull
            }
        }
        set {
            error = nil
            switch jsonUnwrap(newValue) {
            case let number as NSNumber:
                if number.isBool {
                    type = .bool
                    rawBool = number.boolValue
                } else {
                    type = .number
                    rawNumber = number
                }
            case let string as String:
                type = .string
                rawString = string
            case _ as NSNull:
                type = .null
            case Optional<Any>.none:
                type = .null
            case let array as [Any]:
                type = .array
                rawArray = array
            case let dictionary as [String: Any]:
                type = .dictionary
                rawDictionary = dictionary
            default:
                type = .unknown
                error = JSONError.unsupportedType
            }
        }
    }

    public static var null: JSON { JSON(NSNull()) }
}

private func jsonUnwrap(_ object: Any) -> Any {
    switch object {
    case let json as JSON:
        return jsonUnwrap(json.object)
    case let array as [Any]:
        return array.map(jsonUnwrap)
    case let dictionary as [String: Any]:
        var d = dictionary
        for pair in dictionary {
            d[pair.key] = jsonUnwrap(pair.value)
        }
        return d
    default:
        return object
    }
}

// MARK: - Index
public enum Index<T: Any>: Comparable {
    case array(Int)
    case dictionary(DictionaryIndex<String, T>)
    case null

    public static func ==(lhs: Index, rhs: Index) -> Bool {
        switch (lhs, rhs) {
        case let (.array(left), .array(right)): return left == right
        case let (.dictionary(left), .dictionary(right)): return left == right
        case (.null, .null): return true
        default: return false
        }
    }

    public static func <(lhs: Index, rhs: Index) -> Bool {
        switch (lhs, rhs) {
        case let (.array(left), .array(right)): return left < right
        case let (.dictionary(left), .dictionary(right)): return left < right
        default: return false
        }
    }
}

public typealias JSONIndex = Index<JSON>
public typealias JSONRawIndex = Index<Any>

extension JSON: Swift.Collection {
    public typealias Index = JSONRawIndex

    public var startIndex: Index {
        switch type {
        case .array: return .array(rawArray.startIndex)
        case .dictionary: return .dictionary(rawDictionary.startIndex)
        default: return .null
        }
    }

    public var endIndex: Index {
        switch type {
        case .array: return .array(rawArray.endIndex)
        case .dictionary: return .dictionary(rawDictionary.endIndex)
        default: return .null
        }
    }

    public func index(after i: Index) -> Index {
        switch i {
        case let .array(idx): return .array(rawArray.index(after: idx))
        case let .dictionary(idx): return .dictionary(rawDictionary.index(after: idx))
        default: return .null
        }
    }

    public subscript(position: Index) -> (String, JSON) {
        switch position {
        case let .array(idx): return (String(idx), JSON(rawArray[idx]))
        case let .dictionary(idx): return (rawDictionary[idx].key, JSON(rawDictionary[idx].value))
        default: return ("", JSON.null)
        }
    }
}

// MARK: - Subscript
public enum JSONKey {
    case index(Int)
    case key(String)
}

public protocol JSONSubscriptType {
    var jsonKey: JSONKey { get }
}

extension Int: JSONSubscriptType {
    public var jsonKey: JSONKey {
        JSONKey.index(self)
    }
}

extension String: JSONSubscriptType {
    public var jsonKey: JSONKey {
        JSONKey.key(self)
    }
}

extension JSON {
    fileprivate subscript(index index: Int) -> JSON {
        get {
            if type != .array {
                var r = JSON.null
                r.error = self.error ?? JSONError.wrongType
                return r
            } else if rawArray.indices.contains(index) {
                return JSON(rawArray[index])
            } else {
                var r = JSON.null
                r.error = JSONError.indexOutOfBounds
                return r
            }
        }
        set {
            if type == .array &&
                rawArray.indices.contains(index) &&
                newValue.error == nil {
                rawArray[index] = newValue.object
            }
        }
    }

    fileprivate subscript(key key: String) -> JSON {
        get {
            var r = JSON.null
            if type == .dictionary {
                if let o = rawDictionary[key] {
                    r = JSON(o)
                } else {
                    r.error = JSONError.notExist
                }
            } else {
                r.error = self.error ?? JSONError.wrongType
            }
            return r
        }
        set {
            if type == .dictionary && newValue.error == nil {
                rawDictionary[key] = newValue.object
            }
        }
    }

    fileprivate subscript(sub sub: JSONSubscriptType) -> JSON {
        get {
            switch sub.jsonKey {
            case let .index(index): return self[index: index]
            case let .key(key): return self[key: key]
            }
        }
        set {
            switch sub.jsonKey {
            case let .index(index): self[index: index] = newValue
            case let .key(key): self[key: key] = newValue
            }
        }
    }

    public subscript(path: [JSONSubscriptType]) -> JSON {
        get {
            path.reduce(self) { $0[sub: $1] }
        }
        set {
            switch path.count {
            case 0: return
            case 1: self[sub: path[0]].object = newValue.object
            default:
                var aPath = path
                aPath.remove(at: 0)
                var nextJSON = self[sub: path[0]]
                nextJSON[aPath] = newValue
                self[sub: path[0]] = nextJSON
            }
        }
    }

    public subscript(path: JSONSubscriptType...) -> JSON {
        get {
            self[path]
        }
        set {
            self[path] = newValue
        }
    }
}

// MARK: - Dynamic
extension JSON {
    public subscript(dynamicMember key: String) -> JSON {
        get {
            let sub: JSONSubscriptType = Int(key) ?? key
            return self[sub]
        }
        set {
            let sub: JSONSubscriptType = Int(key) ?? key
            self[sub] = newValue
        }
    }
}

// MARK: - LiteralConvertible
extension JSON: Swift.ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension JSON: Swift.ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        let dictionary = elements.reduce(into: [String: Any]()) { $0[$1.0] = $1.1 }
        self.init(dictionary)
    }
}

extension JSON: Swift.ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

// MARK: - Raw
extension JSON: Swift.RawRepresentable {
    public init?(rawValue: Any) {
        if JSON(rawValue).type == .unknown {
            return nil
        } else {
            self.init(rawValue)
        }
    }

    public var rawValue: Any {
        object
    }

    public func rawData(options opt: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(rawValue: 0)) throws -> Data {
        guard JSONSerialization.isValidJSONObject(object) else {
            throw JSONError.invalidJSON
        }

        return try JSONSerialization.data(withJSONObject: object, options: opt)
    }

    public func rawString(_ encoding: String.Encoding = .utf8, options opt: JSONSerialization.WritingOptions = .prettyPrinted) -> String? {
        do {
            return try _rawString(encoding, options: [.jsonSerialization: opt])
        } catch {
            print("Could not serialize object to JSON because:", error.localizedDescription)
            return nil
        }
    }

    public func rawString(_ options: [JSONWritingOptionsKeys: Any]) -> String? {
        let encoding = options[.encoding] as? String.Encoding ?? String.Encoding.utf8
        let maxObjectDepth = options[.maxObjextDepth] as? Int ?? 10
        do {
            return try _rawString(encoding, options: options, maxObjectDepth: maxObjectDepth)
        } catch {
            print("Could not serialize object to JSON because:", error.localizedDescription)
            return nil
        }
    }

    fileprivate func _rawString(_ encoding: String.Encoding = .utf8, options: [JSONWritingOptionsKeys: Any], maxObjectDepth: Int = 10) throws -> String? {
        guard maxObjectDepth > 0 else { throw JSONError.invalidJSON }
        switch type {
        case .dictionary:
            do {
                if !(options[.castNilToNSNull] as? Bool ?? false) {
                    let jsonOption = options[.jsonSerialization] as? JSONSerialization.WritingOptions ?? JSONSerialization.WritingOptions.prettyPrinted
                    let data = try rawData(options: jsonOption)
                    return String(data: data, encoding: encoding)
                }

                guard let dict = object as? [String: Any?] else {
                    return nil
                }
                let body = try dict.keys.map { key throws -> String in
                    guard let value = dict[key] else {
                        return "\"\(key)\": null"
                    }
                    guard let unwrappedValue = value else {
                        return "\"\(key)\": null"
                    }

                    let nestedValue = JSON(unwrappedValue)
                    guard let nestedString = try nestedValue._rawString(encoding, options: options, maxObjectDepth: maxObjectDepth - 1) else {
                        throw JSONError.elementTooDeep
                    }
                    if nestedValue.type == .string {
                        return "\"\(key)\": \"\(nestedString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
                    } else {
                        return "\"\(key)\": \(nestedString)"
                    }
                }

                return "{\(body.joined(separator: ","))}"
            } catch _ {
                return nil
            }
        case .array:
            do {
                if !(options[.castNilToNSNull] as? Bool ?? false) {
                    let jsonOption = options[.jsonSerialization] as? JSONSerialization.WritingOptions ?? JSONSerialization.WritingOptions.prettyPrinted
                    let data = try rawData(options: jsonOption)
                    return String(data: data, encoding: encoding)
                }

                guard let array = object as? [Any?] else {
                    return nil
                }
                let body = try array.map { value throws -> String in
                    guard let unwrappedValue = value else {
                        return "null"
                    }

                    let nestedValue = JSON(unwrappedValue)
                    guard let nestedString = try nestedValue._rawString(encoding, options: options, maxObjectDepth: maxObjectDepth - 1) else {
                        throw JSONError.invalidJSON
                    }
                    if nestedValue.type == .string {
                        return "\"\(nestedString.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
                    } else {
                        return nestedString
                    }
                }

                return "[\(body.joined(separator: ","))]"
            } catch _ {
                return nil
            }
        case .string: return rawString
        case .number: return rawNumber.stringValue
        case .bool: return rawBool.description
        case .null: return "null"
        default: return nil
        }
    }
}

// MARK: - Printable
extension JSON: Swift.CustomStringConvertible, Swift.CustomDebugStringConvertible {
    public var description: String {
        rawString(options: .prettyPrinted) ?? "unknown"
    }

    public var debugDescription: String {
        description
    }
}

// MARK: - Array
extension JSON {
    public var array: [JSON]? {
        type == .array ? rawArray.map { JSON($0) } : nil
    }

    public var arrayValue: [JSON] {
        self.array ?? []
    }

    public var arrayObject: [Any]? {
        get {
            switch type {
            case .array: return rawArray
            default: return nil
            }
        }
        set {
            self.object = newValue ?? NSNull()
        }
    }
}

// MARK: - Dictionary
extension JSON {
    public var dictionary: [String: JSON]? {
        if type == .dictionary {
            var d = [String: JSON](minimumCapacity: rawDictionary.count)
            for pair in rawDictionary {
                d[pair.key] = JSON(pair.value)
            }
            return d
        } else {
            return nil
        }
    }

    public var dictionaryValue: [String: JSON] {
        dictionary ?? [:]
    }

    public var dictionaryObject: [String: Any]? {
        get {
            switch type {
            case .dictionary: return rawDictionary
            default: return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }
}

// MARK: - Bool
extension JSON {
    public var bool: Bool? {
        get {
            switch type {
            case .bool: return rawBool
            default: return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    public var boolValue: Bool {
        get {
            switch type {
            case .bool: return rawBool
            case .number: return rawNumber.boolValue
            case .string: return ["true", "y", "t", "yes", "1"].contains { rawString.caseInsensitiveCompare($0) == .orderedSame }
            default: return false
            }
        }
        set {
            object = newValue
        }
    }
}

// MARK: - String
extension JSON {
    public var string: String? {
        get {
            switch type {
            case .string: return object as? String
            default: return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    public var stringValue: String {
        get {
            switch type {
            case .string: return object as? String ?? ""
            case .number: return rawNumber.stringValue
            case .bool: return (object as? Bool).map { String($0) } ?? ""
            default: return ""
            }
        }
        set {
            object = newValue
        }
    }
}

// MARK: - Number
extension JSON {
    public var number: NSNumber? {
        get {
            switch type {
            case .number: return rawNumber
            case .bool: return NSNumber(value: rawBool ? 1 : 0)
            default: return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    public var numberValue: NSNumber {
        get {
            switch type {
            case .string:
                let decimal = NSDecimalNumber(string: object as? String)
                return decimal == .notANumber ? .zero : decimal
            case .number: return object as? NSNumber ?? NSNumber(value: 0)
            case .bool: return NSNumber(value: rawBool ? 1 : 0)
            default: return NSNumber(value: 0.0)
            }
        }
        set {
            object = newValue
        }
    }
}

// MARK: - Null
extension JSON {
    public var null: NSNull? {
        set {
            object = NSNull()
        }
        get {
            switch type {
            case .null: return rawNull
            default: return nil
            }
        }
    }

    public func exists() -> Bool {
        if let errorValue = error, (400...1000).contains(errorValue.errorCode) {
            return false
        }
        return true
    }
}

// MARK: - URL
extension JSON {
    public var url: URL? {
        get {
            switch type {
            case .string:
                if rawString.range(of: "%[0-9A-Fa-f]{2}", options: .regularExpression, range: nil, locale: nil) != nil {
                    return Foundation.URL(string: rawString)
                } else if let encodedString_ = rawString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    return Foundation.URL(string: encodedString_)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
        set {
            object = newValue?.absoluteString ?? NSNull()
        }
    }
}

// MARK: - Digital
extension JSON {
    public var double: Double? {
        get {
            number?.doubleValue
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var doubleValue: Double {
        get {
            numberValue.doubleValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var float: Float? {
        get {
            number?.floatValue
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var floatValue: Float {
        get {
            numberValue.floatValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int: Int? {
        get {
            number?.intValue
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var intValue: Int {
        get {
            numberValue.intValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt: UInt? {
        get {
            number?.uintValue
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uIntValue: UInt {
        get {
            numberValue.uintValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int8: Int8? {
        get {
            number?.int8Value
        }
        set {
            if let newValue {
                object = NSNumber(value: Int(newValue))
            } else {
                object = NSNull()
            }
        }
    }

    public var int8Value: Int8 {
        get {
            numberValue.int8Value
        }
        set {
            object = NSNumber(value: Int(newValue))
        }
    }

    public var uInt8: UInt8? {
        get {
            number?.uint8Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uInt8Value: UInt8 {
        get {
            numberValue.uint8Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int16: Int16? {
        get {
            number?.int16Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var int16Value: Int16 {
        get {
            numberValue.int16Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt16: UInt16? {
        get {
            number?.uint16Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uInt16Value: UInt16 {
        get {
            numberValue.uint16Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int32: Int32? {
        get {
            number?.int32Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var int32Value: Int32 {
        get {
            numberValue.int32Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt32: UInt32? {
        get {
            number?.uint32Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uInt32Value: UInt32 {
        get {
            numberValue.uint32Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int64: Int64? {
        get {
            number?.int64Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var int64Value: Int64 {
        get {
            numberValue.int64Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt64: UInt64? {
        get {
            number?.uint64Value
        }
        set {
            if let newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uInt64Value: UInt64 {
        get {
            numberValue.uint64Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }
}

// MARK: - Comparable
extension JSON: Swift.Comparable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber == rhs.rawNumber
    case (.string, .string): return lhs.rawString == rhs.rawString
    case (.bool, .bool): return lhs.rawBool == rhs.rawBool
    case (.array, .array): return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null): return true
    default: return false
    }
}

public func <=(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber <= rhs.rawNumber
    case (.string, .string): return lhs.rawString <= rhs.rawString
    case (.bool, .bool): return lhs.rawBool == rhs.rawBool
    case (.array, .array): return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null): return true
    default: return false
    }
}

public func >=(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber >= rhs.rawNumber
    case (.string, .string): return lhs.rawString >= rhs.rawString
    case (.bool, .bool): return lhs.rawBool == rhs.rawBool
    case (.array, .array): return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null): return true
    default: return false
    }
}

public func >(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber > rhs.rawNumber
    case (.string, .string): return lhs.rawString > rhs.rawString
    default: return false
    }
}

public func <(lhs: JSON, rhs: JSON) -> Bool {
    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber < rhs.rawNumber
    case (.string, .string): return lhs.rawString < rhs.rawString
    default: return false
    }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

// MARK: - NSNumber: Comparable
extension NSNumber {
    fileprivate var isBool: Bool {
        let objCType = String(cString: objCType)
        if (compare(trueNumber) == .orderedSame && objCType == trueObjCType) || (compare(falseNumber) == .orderedSame && objCType == falseObjCType) {
            return true
        } else {
            return false
        }
    }
}

func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default: return lhs.compare(rhs) == .orderedSame
    }
}

func !=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    !(lhs == rhs)
}

func <(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default: return lhs.compare(rhs) == .orderedAscending
    }
}

func >(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default: return lhs.compare(rhs) == ComparisonResult.orderedDescending
    }
}

func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default: return lhs.compare(rhs) != .orderedDescending
    }
}

func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default: return lhs.compare(rhs) != .orderedAscending
    }
}

public enum JSONWritingOptionsKeys: Sendable {
    case jsonSerialization
    case castNilToNSNull
    case maxObjextDepth
    case encoding
}

// MARK: - JSON: Codable
extension JSON: Codable {
    private static var codableTypes: [Codable.Type] {
        [
            Bool.self,
            Int.self,
            Int8.self,
            Int16.self,
            Int32.self,
            Int64.self,
            UInt.self,
            UInt8.self,
            UInt16.self,
            UInt32.self,
            UInt64.self,
            Double.self,
            String.self,
            [JSON].self,
            [String: JSON].self
        ]
    }

    public init(from decoder: Decoder) throws {
        var object: Any?

        if let container = try? decoder.singleValueContainer(), !container.decodeNil() {
            for type in JSON.codableTypes {
                if object != nil {
                    break
                }

                switch type {
                case let boolType as Bool.Type:
                    object = try? container.decode(boolType)
                case let intType as Int.Type:
                    object = try? container.decode(intType)
                case let int8Type as Int8.Type:
                    object = try? container.decode(int8Type)
                case let int32Type as Int32.Type:
                    object = try? container.decode(int32Type)
                case let int64Type as Int64.Type:
                    object = try? container.decode(int64Type)
                case let uintType as UInt.Type:
                    object = try? container.decode(uintType)
                case let uint8Type as UInt8.Type:
                    object = try? container.decode(uint8Type)
                case let uint16Type as UInt16.Type:
                    object = try? container.decode(uint16Type)
                case let uint32Type as UInt32.Type:
                    object = try? container.decode(uint32Type)
                case let uint64Type as UInt64.Type:
                    object = try? container.decode(uint64Type)
                case let doubleType as Double.Type:
                    object = try? container.decode(doubleType)
                case let stringType as String.Type:
                    object = try? container.decode(stringType)
                case let jsonValueArrayType as [JSON].Type:
                    object = try? container.decode(jsonValueArrayType)
                case let jsonValueDictType as [String: JSON].Type:
                    object = try? container.decode(jsonValueDictType)
                default:
                    break
                }
            }
        }
        self.init(object ?? NSNull())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if object is NSNull {
            try container.encodeNil()
            return
        }
        switch object {
        case let intValue as Int:
            try container.encode(intValue)
        case let int8Value as Int8:
            try container.encode(int8Value)
        case let int32Value as Int32:
            try container.encode(int32Value)
        case let int64Value as Int64:
            try container.encode(int64Value)
        case let uintValue as UInt:
            try container.encode(uintValue)
        case let uint8Value as UInt8:
            try container.encode(uint8Value)
        case let uint16Value as UInt16:
            try container.encode(uint16Value)
        case let uint32Value as UInt32:
            try container.encode(uint32Value)
        case let uint64Value as UInt64:
            try container.encode(uint64Value)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case is [Any]:
            let jsonValueArray = array ?? []
            try container.encode(jsonValueArray)
        case is [String: Any]:
            let jsonValueDictValue = dictionary ?? [:]
            try container.encode(jsonValueDictValue)
        default:
            break
        }
    }
}
