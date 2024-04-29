//
//  Parameter.swift
//  FWFramework
//
//  Created by wuyong on 2024/4/15.
//

import Foundation

// MARK: - AnyParameter
public protocol AnyParameter {}

public protocol DataParameter: AnyParameter {
    var dataValue: Data { get }
}

public protocol StringParameter: AnyParameter {
    var stringValue: String { get }
}

public protocol AttributedStringParameter: AnyParameter {
    var attributedStringValue: NSAttributedString { get }
}

public protocol URLParameter: AnyParameter {
    var urlValue: URL { get }
}

public protocol ArrayParameter<E>: AnyParameter {
    associatedtype E
    var arrayValue: Array<E> { get }
}

public protocol DictionaryParameter<K, V>: AnyParameter where K: Hashable {
    associatedtype K
    associatedtype V
    var dictionaryValue: Dictionary<K, V> { get }
}

public protocol ObjectParameter: DictionaryParameter, ObjectType {
    init(dictionaryValue: [AnyHashable: Any])
}

// MARK: - AnyParameter+Extension
extension Data: DataParameter, StringParameter {
    public var dataValue: Data { self }
    public var stringValue: String { String(data: self, encoding: .utf8) ?? .init() }
}

extension String: StringParameter, AttributedStringParameter, DataParameter, URLParameter {
    public var stringValue: String { self }
    public var attributedStringValue: NSAttributedString { NSAttributedString(string: self) }
    public var dataValue: Data { data(using: .utf8) ?? .init() }
    public var urlValue: URL { URL.fw_url(string: self) ?? URL() }
}

extension NSAttributedString: AttributedStringParameter, StringParameter {
    public var attributedStringValue: NSAttributedString { self }
    public var stringValue: String { string }
}

extension URL: URLParameter, StringParameter {
    public var urlValue: URL { self }
    public var stringValue: String { absoluteString }
}

extension URLRequest: URLParameter, StringParameter {
    public var urlValue: URL { url ?? URL() }
    public var stringValue: String { url?.absoluteString ?? .init() }
}

extension Array: ArrayParameter {
    public var arrayValue: Array<Element> { self }
}

extension Dictionary: DictionaryParameter {
    public var dictionaryValue: Dictionary<Key, Value> { self }
}

extension ObjectParameter {
    public var dictionaryValue: [AnyHashable: Any] {
        NSObject.fw_mirrorDictionary(self)
    }
}

extension ObjectParameter where Self: JSONModel {
    public init(dictionaryValue: [AnyHashable: Any]) {
        self.init()
        merge(from: dictionaryValue)
    }
    
    public var dictionaryValue: [AnyHashable: Any] {
        let mirror = NSObject.fw_mirrorDictionary(self)
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
