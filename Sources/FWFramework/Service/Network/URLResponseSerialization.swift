//
//  URLResponseSerialization.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/17.
//

import Foundation

public protocol URLResponseSerialization: AnyObject {
    func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any?
}

open class HTTPResponseSerializer: NSObject, NSCopying, URLResponseSerialization {
    open var acceptableStatusCodes: IndexSet? = IndexSet(integersIn: 200..<300)
    open var acceptableContentTypes: Set<String>?
    
    public required override init() {
        super.init()
    }
    
    open func setUserInfo(_ userInfo: [AnyHashable: Any]?, for response: URLResponse?) {
        guard let response = response else { return }
        response.fw_setPropertyCopy(userInfo, forName: "userInfo")
    }
    
    open func userInfo(for response: URLResponse?) -> [AnyHashable: Any]? {
        guard let response = response else { return nil }
        return response.fw_property(forName: "userInfo") as? [AnyHashable: Any]
    }
    
    @discardableResult
    open func validateResponse(_ response: HTTPURLResponse?, data: Data?, error: inout Error?) -> Bool {
        var responseIsValid = true
        var validationError: Error?

        if let response = response {
            if let contentTypes = acceptableContentTypes,
               !contentTypes.contains(response.mimeType ?? ""),
               !(response.mimeType == nil && (data?.count ?? 0) == 0) {

                if let data = data, data.count > 0, let url = response.url {
                    var userInfo: [String: Any] = [:]
                    userInfo[NSLocalizedDescriptionKey] = String(format: NSLocalizedString("Request failed: unacceptable content-type: %@", comment: ""), response.mimeType ?? "")
                    userInfo[NSURLErrorFailingURLErrorKey] = url
                    userInfo[Self.NetworkingOperationFailingURLResponseErrorKey] = response
                    userInfo[Self.NetworkingOperationFailingURLResponseDataErrorKey] = data

                    validationError = Self.errorWithUnderlyingError(NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorCannotDecodeContentData, userInfo: userInfo), underlyingError: validationError)
                }

                responseIsValid = false
            }

            if let statusCodes = acceptableStatusCodes,
               !statusCodes.contains(response.statusCode),
               let url = response.url {
                var userInfo: [String: Any] = [:]
                userInfo[NSLocalizedDescriptionKey] = String(format: NSLocalizedString("Request failed: %@ (%ld)", comment: ""), HTTPURLResponse.localizedString(forStatusCode: response.statusCode), response.statusCode)
                userInfo[NSURLErrorFailingURLErrorKey] = url
                userInfo[Self.NetworkingOperationFailingURLResponseErrorKey] = response
                if let data = data {
                    userInfo[Self.NetworkingOperationFailingURLResponseDataErrorKey] = data
                }

                validationError = Self.errorWithUnderlyingError(NSError(domain: Self.URLResponseSerializationErrorDomain, code: NSURLErrorBadServerResponse, userInfo: userInfo), underlyingError: validationError)

                responseIsValid = false
            }
        }

        if !responseIsValid {
            error = validationError
        }

        return responseIsValid
    }
    
    open func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        validateResponse(response as? HTTPURLResponse, data: data, error: &error)
        
        return data
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
    
    fileprivate static func errorWithUnderlyingError(_ error: Error?, underlyingError: Error?) -> Error? {
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

    fileprivate static func errorOrUnderlyingErrorHasCodeInDomain(_ error: Error?, code: Int, domain: String) -> Bool {
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
        acceptableContentTypes = ["application/json", "text/json", "text/javascript"]
    }
    
    public convenience init(readingOptions: JSONSerialization.ReadingOptions) {
        self.init()
        self.readingOptions = readingOptions
    }
    
    open override func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        if !validateResponse(response as? HTTPURLResponse, data: data, error: &error) {
            if Self.errorOrUnderlyingErrorHasCodeInDomain(error, code: NSURLErrorCannotDecodeContentData, domain: Self.URLResponseSerializationErrorDomain) {
                return nil
            }
        }
        
        let isSpace = data == Data([UInt8](" ".utf8))
        guard let data = data, data.count > 0, !isSpace else {
            return nil
        }
        
        var responseObject: Any?
        var serializationError: Error?
        do {
            responseObject = try Data.fw_jsonDecode(data, options: readingOptions)
        } catch let decodeError {
            serializationError = decodeError
        }
        
        guard let responseObject = responseObject else {
            error = Self.errorWithUnderlyingError(serializationError, underlyingError: error)
            return nil
        }
        
        if removesKeysWithNullValues {
            return Self.jsonObjectByRemovingKeysWithNullValues(responseObject)
        }
        
        return responseObject
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
        acceptableContentTypes = ["application/x-plist"]
    }
    
    public convenience init(format: PropertyListSerialization.PropertyListFormat, readOptions: PropertyListSerialization.ReadOptions) {
        self.init()
        self.format = format
        self.readOptions = readOptions
    }
    
    open override func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        if !validateResponse(response as? HTTPURLResponse, data: data, error: &error) {
            if Self.errorOrUnderlyingErrorHasCodeInDomain(error, code: NSURLErrorCannotDecodeContentData, domain: Self.URLResponseSerializationErrorDomain) {
                return nil
            }
        }
        
        guard let data = data else {
            return nil
        }
        
        var responseObject: Any?
        var serializationError: Error?
        do {
            responseObject = try PropertyListSerialization.propertyList(from: data, options: readOptions, format: nil)
        } catch let decodeError {
            serializationError = decodeError
        }
        
        guard let responseObject = responseObject else {
            error = Self.errorWithUnderlyingError(serializationError, underlyingError: error)
            return nil
        }
        
        return responseObject
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
        acceptableContentTypes = ["application/octet-stream", "application/pdf", "image/tiff", "image/jpeg", "image/gif", "image/png", "image/ico", "image/x-icon", "image/bmp", "image/x-bmp", "image/x-xbitmap", "image/x-ms-bmp", "image/x-win-bitmap", "image/heic", "image/heif", "image/webp", "image/svg+xml"]
    }
    
    public static func cachedResponseData(for image: UIImage?) -> Data? {
        guard let image = image else { return nil }
        return image.fw_property(forName: "cachedResponseData") as? Data
    }
    
    public static func clearCachedResponseData(for image: UIImage?) {
        setCachedResponseData(nil, for: image)
    }
    
    private static func setCachedResponseData(_ data: Data?, for image: UIImage?) {
        guard let image = image else { return }
        image.fw_setProperty(data, forName: "cachedResponseData")
    }
    
    private static var imageLock = NSLock()
    
    private static func image(data: Data?, scale: CGFloat, options: [ImageCoderOptions : Any]?) -> UIImage? {
        guard let data = data, data.count > 0 else {
            return nil
        }
        
        var image: UIImage?
        imageLock.lock()
        image = UIImage.fw_image(data: data, scale: scale, options: options)
        imageLock.unlock()
        
        /*
        image = UIImage(data: data)
        if image?.images == nil, let cgImage = image?.cgImage {
            image = UIImage(cgImage: cgImage, scale: scale, orientation: image?.imageOrientation ?? .up)
        }*/
        
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
    
    open override func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        if !validateResponse(response as? HTTPURLResponse, data: data, error: &error) {
            if Self.errorOrUnderlyingErrorHasCodeInDomain(error, code: NSURLErrorCannotDecodeContentData, domain: Self.URLResponseSerializationErrorDomain) {
                return nil
            }
        }
        
        var image: UIImage?
        let options = userInfo(for: response) as? [ImageCoderOptions : Any]
        if automaticallyInflatesResponseImage {
            image = Self.inflatedImage(response: response as? HTTPURLResponse, data: data, scale: imageScale, options: options)
        } else {
            image = Self.image(data: data, scale: imageScale, options: options)
        }
        
        if shouldCacheResponseData && image != nil {
            Self.setCachedResponseData(data, for: image)
        }
        
        return image
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
    
    open override func responseObject(for response: URLResponse?, data: Data?, error: inout Error?) -> Any? {
        for serializer in responseSerializers {
            var serializerError: Error?
            let responseObject = serializer.responseObject(for: response, data: data, error: &error)
            if let responseObject = responseObject {
                error = Self.errorWithUnderlyingError(serializerError, underlyingError: error)
                
                return responseObject
            }
        }
        
        return super.responseObject(for: response, data: data, error: &error)
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let serializer = super.copy(with: zone) as! CompoundResponseSerializer
        serializer.responseSerializers = responseSerializers
        return serializer
    }
}
