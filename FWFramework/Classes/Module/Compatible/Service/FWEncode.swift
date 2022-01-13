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
extension Data {
    public static func fwJsonEncode(_ object: Any) -> Data? { return NSData.fwJsonEncode(object) }
    public var fwJsonDecode: Any? { return fwNSData.fwJsonDecode }
    public var fwBase64Encode: Data { return fwNSData.fwBase64Encode() }
    public var fwBase64Decode: Data? { return fwNSData.fwBase64Decode() }
    public var fwNSData: NSData { return self as NSData }
    public var fwUTF8String: String? { return String(data: self, encoding: .utf8) }
}
extension Date {
    public var fwNSDate: NSDate { return self as NSDate }
}
extension Dictionary {
    public var fwNSDictionary: NSDictionary { return self as NSDictionary }
}
extension String {
    public static func fwJsonEncode(_ object: Any) -> String? { return NSString.fwJsonEncode(object) }
    public var fwJsonDecode: Any? { return fwNSString.fwJsonDecode }
    public var fwBase64Encode: String? { return fwNSString.fwBase64Encode() }
    public var fwBase64Decode: String? { return fwNSString.fwBase64Decode() }
    public var fwUnicodeLength: UInt { return fwNSString.fwUnicodeLength() }
    public func fwUnicodeSubstring(_ length: UInt) -> String { return fwNSString.fwUnicodeSubstring(length) }
    public var fwUnicodeEncode: String { return fwNSString.fwUnicodeEncode() }
    public var fwUnicodeDecode: String { return fwNSString.fwUnicodeDecode() }
    public var fwUrlEncodeComponent: String? { return fwNSString.fwUrlEncodeComponent() }
    public var fwUrlDecodeComponent: String? { return fwNSString.fwUrlDecodeComponent() }
    public var fwUrlEncode: String? { return fwNSString.fwUrlEncode() }
    public var fwUrlDecode: String? { return fwNSString.fwUrlDecode() }
    public static func fwQueryEncode(_ dict: [String: Any]) -> String { return NSString.fwQueryEncode(dict) }
    public var fwQueryDecode: [String: String] { return fwNSString.fwQueryDecode() }
    public var fwMd5Encode: String { return fwNSString.fwMd5Encode() }
    public var fwMd5EncodeFile: String? { return fwNSString.fwMd5EncodeFile() }
    public var fwTrimString: String { return trimmingCharacters(in: .whitespacesAndNewlines) }
    public var fwEscapeJson: String { return fwNSString.fwEscapeJson }
    public var fwNSString: NSString { return self as NSString }
    public var fwUTF8Data: Data? { return self.data(using: .utf8) }
    public var fwURL: URL? { return fwNSString.fwURL }
    public var fwNumber: NSNumber? { return fwNSString.fwNumber }
    public func fwSubstring(from index: Int) -> String { return fwNSString.fwSubstring(from: index) ?? "" }
    public func fwSubstring(to index: Int) -> String { return fwNSString.fwSubstring(to: index) ?? "" }
    public func fwSubstring(with range: NSRange) -> String { return fwNSString.fwSubstring(with: range) ?? "" }
    public func fwSubstring(with range: Range<Int>) -> String { return fwSubstring(with: NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)) }
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
