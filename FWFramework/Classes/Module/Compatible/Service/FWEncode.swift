//
//  FWEncode.swift
//  FWFramework
//
//  Created by wuyong on 2019/10/30.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - FWSafeBridge

extension Array {
    public var fwNSArray: NSArray { return self as NSArray }
}
extension Set {
    public var fwNSSet: NSSet { return self as NSSet }
}

extension FWWrapper where T == Data {
    public var jsonDecode: Any? { return nsdata.fw.jsonDecode }
    public var base64Encode: Data { return nsdata.fw.base64Encode() }
    public var base64Decode: Data? { return nsdata.fw.base64Decode() }
    public var nsdata: NSData { return self.base as NSData }
    public var utf8String: String? { return String(data: self.base, encoding: .utf8) }
}

extension FWWrapper where T == Data.Type {
    public func jsonEncode(_ object: Any) -> Data? { return NSData.fw.jsonEncode(object) }
}

extension Date {
    public var fwNSDate: NSDate { return self as NSDate }
}
extension Dictionary {
    public var fwNSDictionary: NSDictionary { return self as NSDictionary }
}

extension FWWrapper where T == String {
    public var jsonDecode: Any? { return nsstring.fw.jsonDecode }
    public var base64Encode: String? { return nsstring.fw.base64Encode() }
    public var base64Decode: String? { return nsstring.fw.base64Decode() }
    public var unicodeLength: UInt { return nsstring.fw.unicodeLength() }
    public func unicodeSubstring(_ length: UInt) -> String { return nsstring.fw.unicodeSubstring(length) }
    public var unicodeEncode: String { return nsstring.fw.unicodeEncode() }
    public var unicodeDecode: String { return nsstring.fw.unicodeDecode() }
    public var urlEncodeComponent: String? { return nsstring.fw.urlEncodeComponent() }
    public var urlDecodeComponent: String? { return nsstring.fw.urlDecodeComponent() }
    public var urlEncode: String? { return nsstring.fw.urlEncode() }
    public var urlDecode: String? { return nsstring.fw.urlDecode() }
    public var queryDecode: [String: String] { return nsstring.fw.queryDecode() }
    public var md5Encode: String { return nsstring.fw.md5Encode() }
    public var md5EncodeFile: String? { return nsstring.fw.md5EncodeFile() }
    public var trimString: String { return base.trimmingCharacters(in: .whitespacesAndNewlines) }
    public var escapeJson: String { return nsstring.fwEscapeJson }
    public var nsstring: NSString { return self.base as NSString }
    public var utf8Data: Data? { return self.base.data(using: .utf8) }
    public var url: URL? { return nsstring.fwURL }
    public var number: NSNumber? { return nsstring.fwNumber }
    public func substring(from index: Int) -> String { return nsstring.fwSubstring(from: index) ?? "" }
    public func substring(to index: Int) -> String { return nsstring.fwSubstring(to: index) ?? "" }
    public func substring(with range: NSRange) -> String { return nsstring.fwSubstring(with: range) ?? "" }
    public func substring(with range: Range<Int>) -> String { return substring(with: NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)) }
}

extension FWWrapper where T == String.Type {
    public func jsonEncode(_ object: Any) -> String? { return NSString.fw.jsonEncode(object) }
    public func queryEncode(_ dict: [String: Any]) -> String { return NSString.fw.queryEncode(dict) }
}

extension URL {
    public static func fwURL(string: String?) -> URL? { return NSURL.fwURL(with: string) }
    public static func fwURL(string: String?, relativeTo baseURL: URL?) -> URL? { return NSURL.fwURL(with: string, relativeTo: baseURL) }
    public var fwQueryDictionary: [String: String] { return fwNSURL.fwQueryDictionary }
    public var fwPathURI: String? { return fwNSURL.fwPathURI }
    public var fwNSURL: NSURL { return self as NSURL }
}

// MARK: - FWSafeUnwrappable

public func FWSafeValue<T: FWSafeUnwrappable>(_ value: T?) -> T {
    return value.fwSafeValue
}

public func FWIsEmpty<T: FWSafeUnwrappable>(_ value: T?) -> Bool {
    return value.fwIsEmpty
}

public func FWIsNil(_ value: Any?) -> Bool {
    return value.fwIsNil
}

public protocol FWSafeUnwrappable {
    static var fwSafeValue: Self { get }
    var fwIsEmpty: Bool { get }
    
    var fwAsInt: Int { get }
    var fwAsBool: Bool { get }
    var fwAsFloat: Float { get }
    var fwAsDouble: Double { get }
    var fwAsString: String { get }
    var fwAsNumber: NSNumber { get }
    var fwAsArray: [Any] { get }
    var fwAsDicationary: [AnyHashable: Any] { get }
}

extension FWSafeUnwrappable {
    public var fwAsInt: Int { return fwAsNumber.intValue }
    public var fwAsBool: Bool { return fwAsNumber.boolValue }
    public var fwAsFloat: Float { return fwAsNumber.floatValue }
    public var fwAsDouble: Double { return fwAsNumber.doubleValue }
    public var fwAsString: String { return FWSafeString(self) }
    public var fwAsNumber: NSNumber { return FWSafeNumber(self) }
    public var fwAsArray: [Any] { return (self as? [Any]) ?? .fwSafeValue }
    public var fwAsDicationary: [AnyHashable: Any] { return (self as? [AnyHashable: Any]) ?? .fwSafeValue }
}

extension Optional where Wrapped: FWSafeUnwrappable {
    public var fwSafeValue: Wrapped { if let value = self { return value } else { return .fwSafeValue } }
    public var fwIsEmpty: Bool { if let value = self { return value.fwIsEmpty } else { return true } }
}
extension Optional {
    public var fwIsNil: Bool { return self == nil }
    
    public var fwAsInt: Int { return fwAsNumber.intValue }
    public var fwAsBool: Bool { return fwAsNumber.boolValue }
    public var fwAsFloat: Float { return fwAsNumber.floatValue }
    public var fwAsDouble: Double { return fwAsNumber.doubleValue }
    public var fwAsString: String { return FWSafeString(self) }
    public var fwAsNumber: NSNumber { return FWSafeNumber(self) }
    public var fwAsArray: [Any] { return (self as? [Any]) ?? .fwSafeValue }
    public var fwAsDicationary: [AnyHashable: Any] { return (self as? [AnyHashable: Any]) ?? .fwSafeValue }
}
extension Int: FWSafeUnwrappable {
    public static var fwSafeValue: Int = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Int8: FWSafeUnwrappable {
    public static var fwSafeValue: Int8 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Int16: FWSafeUnwrappable {
    public static var fwSafeValue: Int16 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Int32: FWSafeUnwrappable {
    public static var fwSafeValue: Int32 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Int64: FWSafeUnwrappable {
    public static var fwSafeValue: Int64 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension UInt: FWSafeUnwrappable {
    public static var fwSafeValue: UInt = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension UInt8: FWSafeUnwrappable {
    public static var fwSafeValue: UInt8 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension UInt16: FWSafeUnwrappable {
    public static var fwSafeValue: UInt16 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension UInt32: FWSafeUnwrappable {
    public static var fwSafeValue: UInt32 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension UInt64: FWSafeUnwrappable {
    public static var fwSafeValue: UInt64 = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Float: FWSafeUnwrappable {
    public static var fwSafeValue: Float = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Double: FWSafeUnwrappable {
    public static var fwSafeValue: Double = .zero
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension Bool: FWSafeUnwrappable {
    public static var fwSafeValue: Bool = false
    public var fwIsEmpty: Bool { return self == .fwSafeValue }
}
extension String: FWSafeUnwrappable {
    public static var fwSafeValue: String = ""
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Array: FWSafeUnwrappable {
    public static var fwSafeValue: Array<Element> { return [] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Set: FWSafeUnwrappable {
    public static var fwSafeValue: Set<Element> { return [] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}
extension Dictionary: FWSafeUnwrappable {
    public static var fwSafeValue: Dictionary<Key, Value> { return [:] }
    public var fwIsEmpty: Bool { return self.isEmpty }
}
