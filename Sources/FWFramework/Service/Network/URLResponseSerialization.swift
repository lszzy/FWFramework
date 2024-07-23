//
//  URLResponseSerialization.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation
import UIKit

public protocol URLResponseSerialization: AnyObject {
    func responseObject(for response: URLResponse?, data: Data) throws -> Any
}

open class HTTPResponseSerializer: NSObject, URLResponseSerialization {
    open var acceptableStatusCodes: IndexSet? = IndexSet(integersIn: 200..<300)
    open var acceptableContentTypes: Set<String>?
    
    public override init() {
        super.init()
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for response: URLResponse?) {
        response?.fw.setPropertyCopy(userInfo, forName: "userInfo")
    }
    
    open func userInfo(for response: URLResponse?) -> [AnyHashable: Any]? {
        return response?.fw.property(forName: "userInfo") as? [AnyHashable: Any]
    }
    
    open func validateResponse(_ response: URLResponse?, data: Data) throws {
        guard let response = response as? HTTPURLResponse else { return }
        
        if let contentTypes = acceptableContentTypes,
           !contentTypes.contains(response.mimeType ?? ""),
           !(response.mimeType == nil && data.count == 0) {
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: String(format: "Request failed: unacceptable content-type: %@", response.mimeType ?? ""),
                Self.NetworkingOperationFailingURLResponseErrorKey: response,
                Self.NetworkingOperationFailingURLResponseDataErrorKey: data,
            ]
            if let url = response.url {
                userInfo[NSURLErrorFailingURLErrorKey] = url
            }
            
            throw NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
        }

        if let statusCodes = acceptableStatusCodes,
           !statusCodes.contains(response.statusCode) {
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: String(format: "Request failed: %@ (%ld)", HTTPURLResponse.localizedString(forStatusCode: response.statusCode), response.statusCode),
                Self.NetworkingOperationFailingURLResponseErrorKey: response,
                Self.NetworkingOperationFailingURLResponseDataErrorKey: data,
            ]
            if let url = response.url {
                userInfo[NSURLErrorFailingURLErrorKey] = url
            }

            throw NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorBadServerResponse, userInfo: userInfo)
        }
    }
    
    open func responseObject(for response: URLResponse?, data: Data) throws -> Any {
        try validateResponse(response, data: data)
        
        return data
    }
}

extension HTTPResponseSerializer {
    public static let URLResponseSerializationErrorDomain = "site.wuyong.error.serialization.response"
    public static let NetworkingOperationFailingURLResponseErrorKey = "site.wuyong.serialization.response.error.response"
    public static let NetworkingOperationFailingURLResponseDataErrorKey = "site.wuyong.serialization.response.error.data"
    
    public static func removingKeysWithNullValues(_ jsonObject: Any) -> Any {
        if let array = jsonObject as? [Any] {
            var mutableArray: [Any] = []
            for value in array {
                if !(value is NSNull) {
                    mutableArray.append(removingKeysWithNullValues(value))
                }
            }
            
            return mutableArray
        } else if let dictionary = jsonObject as? [AnyHashable: Any] {
            var mutableDictionary = dictionary
            for (key, value) in dictionary {
                if value is NSNull {
                    mutableDictionary.removeValue(forKey: key)
                } else if value is [Any] || value is [AnyHashable: Any] {
                    mutableDictionary[key] = removingKeysWithNullValues(value)
                }
            }
            
            return mutableDictionary
        }
        
        return jsonObject
    }
}

open class JSONResponseSerializer: HTTPResponseSerializer {
    open var readingOptions: JSONSerialization.ReadingOptions = []
    open var removesKeysWithNullValues = false
    
    public override init() {
        super.init()
        acceptableContentTypes = ["application/json", "text/json", "text/javascript"]
    }
    
    public convenience init(readingOptions: JSONSerialization.ReadingOptions) {
        self.init()
        self.readingOptions = readingOptions
    }
    
    open override func responseObject(for response: URLResponse?, data: Data) throws -> Any {
        try validateResponse(response, data: data)
        
        let isSpace = data == Data([UInt8](" ".utf8))
        guard data.count > 0, !isSpace else {
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: "Request failed: response data is empty",
                Self.NetworkingOperationFailingURLResponseDataErrorKey: data,
            ]
            if let response = response {
                userInfo[Self.NetworkingOperationFailingURLResponseErrorKey] = response
            }
            if let url = (response as? HTTPURLResponse)?.url {
                userInfo[NSURLErrorFailingURLErrorKey] = url
            }
            
            throw NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
        }
        
        var responseObject = try Data.fw.jsonDecode(data, options: readingOptions)
        if removesKeysWithNullValues {
            responseObject = Self.removingKeysWithNullValues(responseObject)
        }
        return responseObject
    }
}

open class PropertyListResponseSerializer: HTTPResponseSerializer {
    open var format: PropertyListSerialization.PropertyListFormat = .xml
    open var readOptions: PropertyListSerialization.ReadOptions = []
    
    public override init() {
        super.init()
        acceptableContentTypes = ["application/x-plist"]
    }
    
    public convenience init(format: PropertyListSerialization.PropertyListFormat, readOptions: PropertyListSerialization.ReadOptions) {
        self.init()
        self.format = format
        self.readOptions = readOptions
    }
    
    open override func responseObject(for response: URLResponse?, data: Data) throws -> Any {
        try validateResponse(response, data: data)
        
        let responseObject = try PropertyListSerialization.propertyList(from: data, options: readOptions, format: nil)
        return responseObject
    }
}

open class ImageResponseSerializer: HTTPResponseSerializer {
    open var imageScale: CGFloat = UIScreen.main.scale
    open var automaticallyInflatesResponseImage = true
    open var shouldCacheResponseData = false
    
    nonisolated(unsafe) static var imageDecodeBlock: ((_ data: Data, _ scale: CGFloat, _ options: [ImageCoderOptions : Any]?) -> UIImage?)?
    nonisolated(unsafe) private static var imageLock = NSLock()
    
    public override init() {
        super.init()
        acceptableContentTypes = ["application/octet-stream", "application/pdf", "image/tiff", "image/jpeg", "image/gif", "image/png", "image/ico", "image/x-icon", "image/bmp", "image/x-bmp", "image/x-xbitmap", "image/x-ms-bmp", "image/x-win-bitmap", "image/heic", "image/heif", "image/webp", "image/svg+xml"]
    }
    
    public static func cachedResponseData(for image: UIImage) -> Data? {
        return image.fw.property(forName: "cachedResponseData") as? Data
    }
    
    public static func clearCachedResponseData(for image: UIImage) {
        setCachedResponseData(nil, for: image)
    }
    
    private static func setCachedResponseData(_ data: Data?, for image: UIImage) {
        image.fw.setProperty(data, forName: "cachedResponseData")
    }
    
    private static func image(data: Data?, scale: CGFloat, options: [ImageCoderOptions : Any]?) -> UIImage? {
        guard let data = data, data.count > 0 else {
            return nil
        }
        
        var image: UIImage?
        imageLock.lock()
        if imageDecodeBlock != nil {
            image = imageDecodeBlock?(data, scale, options)
        } else {
            image = UIImage(data: data)
            if image?.images == nil, let cgImage = image?.cgImage {
                image = UIImage(cgImage: cgImage, scale: scale, orientation: image?.imageOrientation ?? .up)
            }
        }
        imageLock.unlock()
        return image
    }
    
    private static func inflatedImage(response: HTTPURLResponse?, data: Data?, scale: CGFloat, options: [ImageCoderOptions : Any]?) -> UIImage? {
        guard let data = data, data.count > 0 else {
            return nil
        }
        
        let image = image(data: data, scale: scale, options: options)
        guard let image = image, image.images == nil else {
            return image
        }
        
        var imageRef: CGImage?
        let dataProvider = CGDataProvider(data: data as CFData)
        
        if response?.mimeType == "image/png", let dataProvider = dataProvider {
            imageRef = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        } else if response?.mimeType == "image/jpeg", let dataProvider = dataProvider {
            imageRef = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)

            if imageRef != nil {
                let imageColorSpaceModel = imageRef?.colorSpace?.model
                if imageColorSpaceModel == .cmyk {
                    imageRef = nil
                }
            }
        }

        if imageRef == nil {
            imageRef = image.cgImage?.copy()
        }
        guard let imageRef = imageRef else {
            return image
        }

        let width = imageRef.width
        let height = imageRef.height
        let bitsPerComponent = imageRef.bitsPerComponent
        
        if width * height > 1024 * 1024 || bitsPerComponent > 8 {
            return image
        }

        let bytesPerRow: size_t = 0
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorSpaceModel = colorSpace.model
        var bitmapInfo = imageRef.bitmapInfo.rawValue

        if colorSpaceModel == .rgb {
            let alpha = bitmapInfo & CGBitmapInfo.alphaInfoMask.rawValue
            if alpha == CGImageAlphaInfo.none.rawValue {
                bitmapInfo &= ~CGBitmapInfo.alphaInfoMask.rawValue
                bitmapInfo |= CGImageAlphaInfo.noneSkipFirst.rawValue
            } else if !(alpha == CGImageAlphaInfo.noneSkipFirst.rawValue || alpha == CGImageAlphaInfo.noneSkipLast.rawValue) {
                bitmapInfo &= ~CGBitmapInfo.alphaInfoMask.rawValue
                bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
            }
        }

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return image
        }

        context.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
        guard let inflatedImageRef = context.makeImage() else {
            return image
        }

        let inflatedImage = UIImage(cgImage: inflatedImageRef, scale: scale, orientation: image.imageOrientation)
        return inflatedImage
    }
    
    open override func responseObject(for response: URLResponse?, data: Data) throws -> Any {
        try validateResponse(response, data: data)
        
        var image: UIImage?
        let options = userInfo(for: response) as? [ImageCoderOptions : Any]
        if automaticallyInflatesResponseImage {
            image = Self.inflatedImage(response: response as? HTTPURLResponse, data: data, scale: imageScale, options: options)
        } else {
            image = Self.image(data: data, scale: imageScale, options: options)
        }
        guard let image = image else {
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: data.count > 0 ? "Request failed: response image decode error" : "Request failed: response data is empty",
                Self.NetworkingOperationFailingURLResponseDataErrorKey: data,
            ]
            if let response = response {
                userInfo[Self.NetworkingOperationFailingURLResponseErrorKey] = response
            }
            if let url = (response as? HTTPURLResponse)?.url {
                userInfo[NSURLErrorFailingURLErrorKey] = url
            }
            
            throw NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo)
        }
        
        if shouldCacheResponseData {
            Self.setCachedResponseData(data, for: image)
        }
        return image
    }
}

open class CompoundResponseSerializer: HTTPResponseSerializer {
    open private(set) var responseSerializers: [URLResponseSerialization] = []
    
    public override init() {
        super.init()
    }
    
    public convenience init(responseSerializers: [URLResponseSerialization]) {
        self.init()
        self.responseSerializers = responseSerializers
    }
    
    open override func responseObject(for response: URLResponse?, data: Data) throws -> Any {
        for responseSerializer in responseSerializers {
            let responseObject = try? responseSerializer.responseObject(for: response, data: data)
            if let responseObject = responseObject {
                return responseObject
            }
        }
        
        return try super.responseObject(for: response, data: data)
    }
}
