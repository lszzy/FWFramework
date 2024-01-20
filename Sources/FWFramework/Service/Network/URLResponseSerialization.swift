//
// URLResponseSerialization.swift
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

/*
public protocol URLResponseSerialization: AnyObject {
    func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any?
}

open class HTTPResponseSerializer: NSObject, NSCopying, URLResponseSerialization {
    open var acceptableStatusCodes: IndexSet?
    open var acceptableContentTypes: Set<String>?
    
    public required override init() {
        super.init()
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for response: URLResponse?) {
        
    }
    
    open func userInfo(for response: URLResponse?) -> [AnyHashable: Any]? {
        return nil
    }
    
    open func validateResponse(_ response: HTTPURLResponse?, data: Data?, error: inout Error?) -> Bool {
        return false
    }
    
    open func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        return nil
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let serializer = Self.init()
        serializer.acceptableStatusCodes = acceptableStatusCodes
        serializer.acceptableContentTypes = acceptableContentTypes
        return serializer
    }
}

extension HTTPResponseSerializer {
    public static let URLResponseSerializationErrorDomain = "site.wuyong.error.serialization.response"
    public static let NetworkingOperationFailingURLResponseErrorKey = "site.wuyong.serialization.response.error.response"
    public static let NetworkingOperationFailingURLResponseDataErrorKey = "site.wuyong.serialization.response.error.data"
    
    public static func jsonObjectByRemovingKeysWithNullValues(_ jsonObject: Any) -> Any {
        if let array = jsonObject as? [Any] {
            var mutableArray: [Any] = []
            for value in array {
                if !(value is NSNull) {
                    mutableArray.append(jsonObjectByRemovingKeysWithNullValues(value))
                }
            }
            
            return mutableArray
        } else if let dictionary = jsonObject as? [AnyHashable: Any] {
            var mutableDictionary = dictionary
            for (key, value) in dictionary {
                if value is NSNull {
                    mutableDictionary.removeValue(forKey: key)
                } else if value is [Any] || value is [AnyHashable: Any] {
                    mutableDictionary[key] = jsonObjectByRemovingKeysWithNullValues(value)
                }
            }
            
            return mutableDictionary
        }
        
        return jsonObject
    }
    
    private static func errorWithUnderlyingError(_ error: Error?, underlyingError: Error?) -> Error? {
        guard let nserror = error as? NSError else {
            return underlyingError
        }
        
        if underlyingError == nil || nserror.userInfo[NSUnderlyingErrorKey] != nil {
            return error
        }
        
        var mutableUserInfo = nserror.userInfo
        mutableUserInfo[NSUnderlyingErrorKey] = underlyingError
        
        return NSError(domain: nserror.domain, code: nserror.code, userInfo: mutableUserInfo)
    }

    private static func errorOrUnderlyingErrorHasCodeInDomain(_ error: Error?, code: Int, domain: String) -> Bool {
        guard let nserror = error as? NSError else { return false }
        
        if nserror.domain == domain && nserror.code == code {
            return true
        } else if let underlyingError = nserror.userInfo[NSUnderlyingErrorKey] as? Error {
            return errorOrUnderlyingErrorHasCodeInDomain(underlyingError, code: code, domain: domain)
        }
        
        return false
    }
}

open class JSONResponseSerializer: HTTPResponseSerializer {
    open var readingOptions: JSONSerialization.ReadingOptions = []
    open var removesKeysWithNullValues = false
    
    public required init() {
        super.init()
    }
    
    public convenience init(readingOptions: JSONSerialization.ReadingOptions) {
        self.init()
        self.readingOptions = readingOptions
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let serializer = super.copy(with: zone) as! JSONResponseSerializer
        serializer.readingOptions = readingOptions
        serializer.removesKeysWithNullValues = removesKeysWithNullValues
        return serializer
    }
}

open class PropertyListResponseSerializer: HTTPResponseSerializer {
    open var format: PropertyListSerialization.PropertyListFormat = .xml
    open var readOptions: PropertyListSerialization.ReadOptions = []
    
    public required init() {
        super.init()
    }
    
    public convenience init(format: PropertyListSerialization.PropertyListFormat, readOptions: PropertyListSerialization.ReadOptions) {
        self.init()
        self.format = format
        self.readOptions = readOptions
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let serializer = super.copy(with: zone) as! PropertyListResponseSerializer
        serializer.format = format
        serializer.readOptions = readOptions
        return serializer
    }
}

open class ImageResponseSerializer: HTTPResponseSerializer {
    open var imageScale: CGFloat = UIScreen.main.scale
    open var automaticallyInflatesResponseImage = true
    open var shouldCacheResponseData = false
    
    public required init() {
        super.init()
    }
    
    open func cachedResponseData(for image: UIImage?) -> Data? {
        return nil
    }
    
    open func clearCachedResponseData(for image: UIImage?) {
        
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let serializer = super.copy(with: zone) as! ImageResponseSerializer
        serializer.imageScale = imageScale
        serializer.automaticallyInflatesResponseImage = automaticallyInflatesResponseImage
        serializer.shouldCacheResponseData = shouldCacheResponseData
        return serializer
    }
}

open class CompoundResponseSerializer: HTTPResponseSerializer {
    open private(set) var responseSerializers: [URLResponseSerialization] = []
    
    public required init() {
        super.init()
    }
    
    public convenience init(responseSerializers: [URLResponseSerialization]) {
        self.init()
        self.responseSerializers = responseSerializers
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let serializer = super.copy(with: zone) as! CompoundResponseSerializer
        serializer.responseSerializers = responseSerializers
        return serializer
    }
}*/
