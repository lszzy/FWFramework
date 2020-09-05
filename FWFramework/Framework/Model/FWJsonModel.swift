//
//  FWJsonModel.swift
//  FWFramework
//
//  Created by wuyong on 2020/5/15.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - JSON Error
// swiftlint:disable line_length
public enum FWJSONError: Int, Swift.Error {
    case unsupportedType = 999
    case indexOutOfBounds = 900
    case elementTooDeep = 902
    case wrongType = 901
    case notExist = 500
    case invalidJSON = 490
}

extension FWJSONError: CustomNSError {

    /// return the error domain of FWJSONError
    public static var errorDomain: String { return "site.wuyong.FWJSON" }

    /// return the error code of FWJSONError
    public var errorCode: Int { return self.rawValue }

    /// return the userInfo of FWJSONError
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

// MARK: - JSON Type

/**
JSON's type definitions.

See http://www.json.org
*/
public enum FWJSONType: Int {
    case number
    case string
    case bool
    case array
    case dictionary
    case null
    case unknown
}

// MARK: - JSON Base

/**
 FWJSON
 
 - see: [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
 */
public struct FWJSON {

    /**
     Creates a JSON using the data.
    
     - parameter data: The NSData used to convert to json.Top level object in data is an NSArray or NSDictionary
     - parameter opt: The JSON serialization reading options. `[]` by default.
    
     - returns: The created JSON
     */
    public init(data: Data, options opt: JSONSerialization.ReadingOptions = []) throws {
        let object: Any = try JSONSerialization.jsonObject(with: data, options: opt)
        self.init(jsonObject: object)
    }

    /**
     Creates a JSON object
     - note: this does not parse a `String` into JSON, instead use `init(parseJSON: String)`
    
     - parameter object: the object

     - returns: the created JSON object
     */
    public init(_ object: Any) {
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

    /**
     Parses the JSON string into a JSON object
    
     - parameter json: the JSON string
    
     - returns: the created JSON object
    */
    public init(parseJSON jsonString: String) {
        if let data = jsonString.data(using: .utf8) {
            self.init(data)
        } else {
            self.init(NSNull())
        }
    }

    /**
     Creates a JSON using the object.
    
     - parameter jsonObject:  The object must have the following properties: All objects are NSString/String, NSNumber/Int/Float/Double/Bool, NSArray/Array, NSDictionary/Dictionary, or NSNull; All dictionary keys are NSStrings/String; NSNumbers are not NaN or infinity.
    
     - returns: The created JSON
     */
    fileprivate init(jsonObject: Any) {
        object = jsonObject
    }

    /**
     Merges another JSON into this JSON, whereas primitive values which are not present in this JSON are getting added,
     present values getting overwritten, array values getting appended and nested JSONs getting merged the same way.
 
     - parameter other: The JSON which gets merged into this JSON
    
     - throws `ErrorWrongType` if the other JSONs differs in type on the top level.
     */
    public mutating func merge(with other: FWJSON) throws {
        try self.merge(with: other, typecheck: true)
    }

    /**
     Merges another JSON into this JSON and returns a new JSON, whereas primitive values which are not present in this JSON are getting added,
     present values getting overwritten, array values getting appended and nested JSONS getting merged the same way.
    
     - parameter other: The JSON which gets merged into this JSON
    
     - throws `ErrorWrongType` if the other JSONs differs in type on the top level.
    
     - returns: New merged JSON
     */
    public func merged(with other: FWJSON) throws -> FWJSON {
        var merged = self
        try merged.merge(with: other, typecheck: true)
        return merged
    }

    /**
     Private woker function which does the actual merging
     Typecheck is set to true for the first recursion level to prevent total override of the source JSON
     */
     fileprivate mutating func merge(with other: FWJSON, typecheck: Bool) throws {
        if type == other.type {
            switch type {
            case .dictionary:
                for (key, _) in other {
                    try self[key].merge(with: other[key], typecheck: false)
                }
            case .array:
                self = FWJSON(arrayValue + other.arrayValue)
            default:
                self = other
            }
        } else {
            if typecheck {
                throw FWJSONError.wrongType
            } else {
                self = other
            }
        }
    }

    /// Private object
    fileprivate var rawArray: [Any] = []
    fileprivate var rawDictionary: [String: Any] = [:]
    fileprivate var rawString: String = ""
    fileprivate var rawNumber: NSNumber = 0
    fileprivate var rawNull: NSNull = NSNull()
    fileprivate var rawBool: Bool = false

    /// JSON type, fileprivate setter
    public fileprivate(set) var type: FWJSONType = .null

    /// Error in JSON, fileprivate setter
    public fileprivate(set) var error: FWJSONError?

    /// Object in JSON
    public var object: Any {
        get {
            switch type {
            case .array:      return rawArray
            case .dictionary: return rawDictionary
            case .string:     return rawString
            case .number:     return rawNumber
            case .bool:       return rawBool
            default:          return rawNull
            }
        }
        set {
            error = nil
            switch fwjson_unwrap(newValue) {
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
            case nil:
                type = .null
            case let array as [Any]:
                type = .array
                rawArray = array
            case let dictionary as [String: Any]:
                type = .dictionary
                rawDictionary = dictionary
            default:
                type = .unknown
                error = FWJSONError.unsupportedType
            }
        }
    }

    /// The static null JSON
    @available(*, unavailable, renamed:"null")
    public static var nullJSON: FWJSON { return null }
    public static var null: FWJSON { return FWJSON(NSNull()) }
}

/// Private method to unwarp an object recursively
private func fwjson_unwrap(_ object: Any) -> Any {
    switch object {
    case let json as FWJSON:
        return fwjson_unwrap(json.object)
    case let array as [Any]:
        return array.map(fwjson_unwrap)
    case let dictionary as [String: Any]:
        var d = dictionary
        dictionary.forEach { pair in
            d[pair.key] = fwjson_unwrap(pair.value)
        }
        return d
    default:
        return object
    }
}

public enum FWIndex<T: Any>: Comparable {
    case array(Int)
    case dictionary(DictionaryIndex<String, T>)
    case null

    static public func == (lhs: FWIndex, rhs: FWIndex) -> Bool {
        switch (lhs, rhs) {
        case (.array(let left), .array(let right)):           return left == right
        case (.dictionary(let left), .dictionary(let right)): return left == right
        case (.null, .null):                                  return true
        default:                                              return false
        }
    }

    static public func < (lhs: FWIndex, rhs: FWIndex) -> Bool {
        switch (lhs, rhs) {
        case (.array(let left), .array(let right)):           return left < right
        case (.dictionary(let left), .dictionary(let right)): return left < right
        default:                                              return false
        }
    }
}

public typealias FWJSONIndex = FWIndex<FWJSON>
public typealias FWJSONRawIndex = FWIndex<Any>

extension FWJSON: Swift.Collection {

    public typealias Index = FWJSONRawIndex

    public var startIndex: Index {
        switch type {
        case .array:      return .array(rawArray.startIndex)
        case .dictionary: return .dictionary(rawDictionary.startIndex)
        default:          return .null
        }
    }

    public var endIndex: Index {
        switch type {
        case .array:      return .array(rawArray.endIndex)
        case .dictionary: return .dictionary(rawDictionary.endIndex)
        default:          return .null
        }
    }

    public func index(after i: Index) -> Index {
        switch i {
        case .array(let idx):      return .array(rawArray.index(after: idx))
        case .dictionary(let idx): return .dictionary(rawDictionary.index(after: idx))
        default:                   return .null
        }
    }

    public subscript (position: Index) -> (String, FWJSON) {
        switch position {
        case .array(let idx):      return (String(idx), FWJSON(rawArray[idx]))
        case .dictionary(let idx): return (rawDictionary[idx].key, FWJSON(rawDictionary[idx].value))
        default:                   return ("", FWJSON.null)
        }
    }
}

// MARK: - Subscript

/**
 *  To mark both String and Int can be used in subscript.
 */
public enum FWJSONKey {
    case index(Int)
    case key(String)
}

public protocol FWJSONSubscriptType {
    var jsonKey: FWJSONKey { get }
}

extension Int: FWJSONSubscriptType {
    public var jsonKey: FWJSONKey {
        return FWJSONKey.index(self)
    }
}

extension String: FWJSONSubscriptType {
    public var jsonKey: FWJSONKey {
        return FWJSONKey.key(self)
    }
}

extension FWJSON {

    /// If `type` is `.array`, return json whose object is `array[index]`, otherwise return null json with error.
    fileprivate subscript(index index: Int) -> FWJSON {
        get {
            if type != .array {
                var r = FWJSON.null
                r.error = self.error ?? FWJSONError.wrongType
                return r
            } else if rawArray.indices.contains(index) {
                return FWJSON(rawArray[index])
            } else {
                var r = FWJSON.null
                r.error = FWJSONError.indexOutOfBounds
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

    /// If `type` is `.dictionary`, return json whose object is `dictionary[key]` , otherwise return null json with error.
    fileprivate subscript(key key: String) -> FWJSON {
        get {
            var r = FWJSON.null
            if type == .dictionary {
                if let o = rawDictionary[key] {
                    r = FWJSON(o)
                } else {
                    r.error = FWJSONError.notExist
                }
            } else {
                r.error = self.error ?? FWJSONError.wrongType
            }
            return r
        }
        set {
            if type == .dictionary && newValue.error == nil {
                rawDictionary[key] = newValue.object
            }
        }
    }

    /// If `sub` is `Int`, return `subscript(index:)`; If `sub` is `String`,  return `subscript(key:)`.
    fileprivate subscript(sub sub: FWJSONSubscriptType) -> FWJSON {
        get {
            switch sub.jsonKey {
            case .index(let index): return self[index: index]
            case .key(let key):     return self[key: key]
            }
        }
        set {
            switch sub.jsonKey {
            case .index(let index): self[index: index] = newValue
            case .key(let key):     self[key: key] = newValue
            }
        }
    }

    /**
     Find a json in the complex data structures by using array of Int and/or String as path.
    
     Example:
    
     ```
     let json = JSON[data]
     let path = [9,"list","person","name"]
     let name = json[path]
     ```
    
     The same as: let name = json[9]["list"]["person"]["name"]
    
     - parameter path: The target json's path.
    
     - returns: Return a json found by the path or a null json with error
     */
    public subscript(path: [FWJSONSubscriptType]) -> FWJSON {
        get {
            return path.reduce(self) { $0[sub: $1] }
        }
        set {
            switch path.count {
            case 0: return
            case 1: self[sub:path[0]].object = newValue.object
            default:
                var aPath = path
                aPath.remove(at: 0)
                var nextJSON = self[sub: path[0]]
                nextJSON[aPath] = newValue
                self[sub: path[0]] = nextJSON
            }
        }
    }

    /**
     Find a json in the complex data structures by using array of Int and/or String as path.

     - parameter path: The target json's path. Example:

     let name = json[9,"list","person","name"]

     The same as: let name = json[9]["list"]["person"]["name"]

     - returns: Return a json found by the path or a null json with error
     */
    public subscript(path: FWJSONSubscriptType...) -> FWJSON {
        get {
            return self[path]
        }
        set {
            self[path] = newValue
        }
    }
}

// MARK: - LiteralConvertible

extension FWJSON: Swift.ExpressibleByStringLiteral {

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

extension FWJSON: Swift.ExpressibleByIntegerLiteral {

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension FWJSON: Swift.ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension FWJSON: Swift.ExpressibleByFloatLiteral {

    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension FWJSON: Swift.ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        let dictionary = elements.reduce(into: [String: Any](), { $0[$1.0] = $1.1})
        self.init(dictionary)
    }
}

extension FWJSON: Swift.ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

// MARK: - Raw

extension FWJSON: Swift.RawRepresentable {

    public init?(rawValue: Any) {
        if FWJSON(rawValue).type == .unknown {
            return nil
        } else {
            self.init(rawValue)
        }
    }

    public var rawValue: Any {
        return object
    }

    public func rawData(options opt: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(rawValue: 0)) throws -> Data {
        guard JSONSerialization.isValidJSONObject(object) else {
            throw FWJSONError.invalidJSON
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

    public func rawString(_ options: [FWJSONWritingOptionsKeys: Any]) -> String? {
        let encoding = options[.encoding] as? String.Encoding ?? String.Encoding.utf8
        let maxObjectDepth = options[.maxObjextDepth] as? Int ?? 10
        do {
            return try _rawString(encoding, options: options, maxObjectDepth: maxObjectDepth)
        } catch {
            print("Could not serialize object to JSON because:", error.localizedDescription)
            return nil
        }
    }

    fileprivate func _rawString(_ encoding: String.Encoding = .utf8, options: [FWJSONWritingOptionsKeys: Any], maxObjectDepth: Int = 10) throws -> String? {
        guard maxObjectDepth > 0 else { throw FWJSONError.invalidJSON }
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

                    let nestedValue = FWJSON(unwrappedValue)
                    guard let nestedString = try nestedValue._rawString(encoding, options: options, maxObjectDepth: maxObjectDepth - 1) else {
                        throw FWJSONError.elementTooDeep
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

                    let nestedValue = FWJSON(unwrappedValue)
                    guard let nestedString = try nestedValue._rawString(encoding, options: options, maxObjectDepth: maxObjectDepth - 1) else {
                        throw FWJSONError.invalidJSON
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
        case .bool:   return rawBool.description
        case .null:   return "null"
        default:      return nil
        }
    }
}

// MARK: - Printable, DebugPrintable

extension FWJSON: Swift.CustomStringConvertible, Swift.CustomDebugStringConvertible {

    public var description: String {
        return rawString(options: .prettyPrinted) ?? "unknown"
    }

    public var debugDescription: String {
        return description
    }
}

// MARK: - Array

extension FWJSON {

    //Optional [JSON]
    public var array: [FWJSON]? {
        return type == .array ? rawArray.map { FWJSON($0) } : nil
    }

    //Non-optional [JSON]
    public var arrayValue: [FWJSON] {
        return self.array ?? []
    }

    //Optional [Any]
    public var arrayObject: [Any]? {
        get {
            switch type {
            case .array: return rawArray
            default:     return nil
            }
        }
        set {
            self.object = newValue ?? NSNull()
        }
    }
}

// MARK: - Dictionary

extension FWJSON {

    //Optional [String : JSON]
    public var dictionary: [String: FWJSON]? {
        if type == .dictionary {
            var d = [String: FWJSON](minimumCapacity: rawDictionary.count)
            rawDictionary.forEach { pair in
                d[pair.key] = FWJSON(pair.value)
            }
            return d
        } else {
            return nil
        }
    }

    //Non-optional [String : JSON]
    public var dictionaryValue: [String: FWJSON] {
        return dictionary ?? [:]
    }

    //Optional [String : Any]

    public var dictionaryObject: [String: Any]? {
        get {
            switch type {
            case .dictionary: return rawDictionary
            default:          return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }
}

// MARK: - Bool

extension FWJSON { // : Swift.Bool

    //Optional bool
    public var bool: Bool? {
        get {
            switch type {
            case .bool: return rawBool
            default:    return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    //Non-optional bool
    public var boolValue: Bool {
        get {
            switch type {
            case .bool:   return rawBool
            case .number: return rawNumber.boolValue
            case .string: return ["true", "y", "t", "yes", "1"].contains { rawString.caseInsensitiveCompare($0) == .orderedSame }
            default:      return false
            }
        }
        set {
            object = newValue
        }
    }
}

// MARK: - String

extension FWJSON {

    //Optional string
    public var string: String? {
        get {
            switch type {
            case .string: return object as? String
            default:      return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    //Non-optional string
    public var stringValue: String {
        get {
            switch type {
            case .string: return object as? String ?? ""
            case .number: return rawNumber.stringValue
            case .bool:   return (object as? Bool).map { String($0) } ?? ""
            default:      return ""
            }
        }
        set {
            object = newValue
        }
    }
}

// MARK: - Number

extension FWJSON {

    //Optional number
    public var number: NSNumber? {
        get {
            switch type {
            case .number: return rawNumber
            case .bool:   return NSNumber(value: rawBool ? 1 : 0)
            default:      return nil
            }
        }
        set {
            object = newValue ?? NSNull()
        }
    }

    //Non-optional number
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

extension FWJSON {

    public var null: NSNull? {
        set {
            object = NSNull()
        }
        get {
            switch type {
            case .null: return rawNull
            default:    return nil
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

extension FWJSON {

    //Optional URL
    public var url: URL? {
        get {
            switch type {
            case .string:
                // Check for existing percent escapes first to prevent double-escaping of % character
                if rawString.range(of: "%[0-9A-Fa-f]{2}", options: .regularExpression, range: nil, locale: nil) != nil {
                    return Foundation.URL(string: rawString)
                } else if let encodedString_ = rawString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    // We have to use `Foundation.URL` otherwise it conflicts with the variable name.
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

// MARK: - Int, Double, Float, Int8, Int16, Int32, Int64

extension FWJSON {

    public var double: Double? {
        get {
            return number?.doubleValue
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var doubleValue: Double {
        get {
            return numberValue.doubleValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var float: Float? {
        get {
            return number?.floatValue
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var floatValue: Float {
        get {
            return numberValue.floatValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int: Int? {
        get {
            return number?.intValue
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var intValue: Int {
        get {
            return numberValue.intValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt: UInt? {
        get {
            return number?.uintValue
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object = NSNull()
            }
        }
    }

    public var uIntValue: UInt {
        get {
            return numberValue.uintValue
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int8: Int8? {
        get {
            return number?.int8Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: Int(newValue))
            } else {
                object =  NSNull()
            }
        }
    }

    public var int8Value: Int8 {
        get {
            return numberValue.int8Value
        }
        set {
            object = NSNumber(value: Int(newValue))
        }
    }

    public var uInt8: UInt8? {
        get {
            return number?.uint8Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var uInt8Value: UInt8 {
        get {
            return numberValue.uint8Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int16: Int16? {
        get {
            return number?.int16Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var int16Value: Int16 {
        get {
            return numberValue.int16Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt16: UInt16? {
        get {
            return number?.uint16Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var uInt16Value: UInt16 {
        get {
            return numberValue.uint16Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int32: Int32? {
        get {
            return number?.int32Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var int32Value: Int32 {
        get {
            return numberValue.int32Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt32: UInt32? {
        get {
            return number?.uint32Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var uInt32Value: UInt32 {
        get {
            return numberValue.uint32Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var int64: Int64? {
        get {
            return number?.int64Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var int64Value: Int64 {
        get {
            return numberValue.int64Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }

    public var uInt64: UInt64? {
        get {
            return number?.uint64Value
        }
        set {
            if let newValue = newValue {
                object = NSNumber(value: newValue)
            } else {
                object =  NSNull()
            }
        }
    }

    public var uInt64Value: UInt64 {
        get {
            return numberValue.uint64Value
        }
        set {
            object = NSNumber(value: newValue)
        }
    }
}

// MARK: - Comparable

extension FWJSON: Swift.Comparable {}

public func == (lhs: FWJSON, rhs: FWJSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber == rhs.rawNumber
    case (.string, .string): return lhs.rawString == rhs.rawString
    case (.bool, .bool):     return lhs.rawBool == rhs.rawBool
    case (.array, .array):   return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null):     return true
    default:                 return false
    }
}

public func <= (lhs: FWJSON, rhs: FWJSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber <= rhs.rawNumber
    case (.string, .string): return lhs.rawString <= rhs.rawString
    case (.bool, .bool):     return lhs.rawBool == rhs.rawBool
    case (.array, .array):   return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null):     return true
    default:                 return false
    }
}

public func >= (lhs: FWJSON, rhs: FWJSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber >= rhs.rawNumber
    case (.string, .string): return lhs.rawString >= rhs.rawString
    case (.bool, .bool):     return lhs.rawBool == rhs.rawBool
    case (.array, .array):   return lhs.rawArray as NSArray == rhs.rawArray as NSArray
    case (.dictionary, .dictionary): return lhs.rawDictionary as NSDictionary == rhs.rawDictionary as NSDictionary
    case (.null, .null):     return true
    default:                 return false
    }
}

public func > (lhs: FWJSON, rhs: FWJSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber > rhs.rawNumber
    case (.string, .string): return lhs.rawString > rhs.rawString
    default:                 return false
    }
}

public func < (lhs: FWJSON, rhs: FWJSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case (.number, .number): return lhs.rawNumber < rhs.rawNumber
    case (.string, .string): return lhs.rawString < rhs.rawString
    default:                 return false
    }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

// MARK: - NSNumber: Comparable

extension NSNumber {
    fileprivate var isBool: Bool {
        let objCType = String(cString: self.objCType)
        if (self.compare(trueNumber) == .orderedSame && objCType == trueObjCType) || (self.compare(falseNumber) == .orderedSame && objCType == falseObjCType) {
            return true
        } else {
            return false
        }
    }
}

func == (lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default:            return lhs.compare(rhs) == .orderedSame
    }
}

func != (lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs == rhs)
}

func < (lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default:            return lhs.compare(rhs) == .orderedAscending
    }
}

func > (lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default:            return lhs.compare(rhs) == ComparisonResult.orderedDescending
    }
}

func <= (lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default:            return lhs.compare(rhs) != .orderedDescending
    }
}

func >= (lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true): return false
    case (true, false): return false
    default:            return lhs.compare(rhs) != .orderedAscending
    }
}

public enum FWJSONWritingOptionsKeys {
    case jsonSerialization
    case castNilToNSNull
    case maxObjextDepth
    case encoding
}

// MARK: - JSON: Codable
extension FWJSON: Codable {
    private static var codableTypes: [Codable.Type] {
        return [
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
            [FWJSON].self,
            [String: FWJSON].self
        ]
    }
    public init(from decoder: Decoder) throws {
        var object: Any?

        if let container = try? decoder.singleValueContainer(), !container.decodeNil() {
            for type in FWJSON.codableTypes {
                if object != nil {
                    break
                }
                // try to decode value
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
                case let jsonValueArrayType as [FWJSON].Type:
                    object = try? container.decode(jsonValueArrayType)
                case let jsonValueDictType as [String: FWJSON].Type:
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
