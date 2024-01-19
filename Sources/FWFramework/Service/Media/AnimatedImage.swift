//
//  AnimatedImage.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import MobileCoreServices
import ImageIO
#if FWMacroSPM
import FWObjC
#endif

// MARK: - ImageFormat
/// 图片格式可扩展枚举
public struct ImageFormat: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    public static let undefined: ImageFormat = .init(-1)
    public static let jpeg: ImageFormat = .init(0)
    public static let png: ImageFormat = .init(1)
    public static let gif: ImageFormat = .init(2)
    public static let tiff: ImageFormat = .init(3)
    public static let webp: ImageFormat = .init(4) // iOS14+
    public static let heic: ImageFormat = .init(5) // iOS13+
    public static let heif: ImageFormat = .init(6) // iOS13+
    public static let pdf: ImageFormat = .init(7)
    public static let svg: ImageFormat = .init(8) // iOS13+
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

// MARK: - ImageFrame
/// 动图单帧对象
public class ImageFrame {
    
    /// 单帧图片
    public let image: UIImage
    /// 单帧时长
    public let duration: TimeInterval

    /// 创建单帧对象
    public init(image: UIImage, duration: TimeInterval) {
        self.image = image
        self.duration = duration
    }

    /// 根据单帧对象创建动图Image
    public class func animatedImage(frames: [ImageFrame]?) -> UIImage? {
        guard let frameCount = frames?.count,
              let frames = frames,
              frameCount > 0 else {
            return nil
        }

        var durations = [Int](repeating: 0, count: frameCount)
        for i in 0 ..< frameCount {
            durations[i] = Int(frames[i].duration * 1000)
        }
        let gcd = gcdArray(durations)
        var totalDuration = 0
        var animatedImages = [UIImage]()
        for frame in frames {
            let image = frame.image
            let duration = Int(frame.duration * 1000)
            totalDuration += duration
            var repeatCount = 1
            if gcd != 0 {
                repeatCount = duration / gcd
            }
            for _ in 0 ..< repeatCount {
                animatedImages.append(image)
            }
        }
        
        return UIImage.animatedImage(with: animatedImages, duration: TimeInterval(totalDuration) / 1000)
    }

    /// 从动图Image创建单帧对象数组
    public class func frames(animatedImage: UIImage?) -> [ImageFrame]? {
        guard let animatedImage = animatedImage,
              let animatedImages = animatedImage.images,
              animatedImages.count > 0 else {
            return nil
        }

        var frames = [ImageFrame]()
        let frameCount = animatedImages.count
        var avgDuration = animatedImage.duration / Double(frameCount)
        if avgDuration <= 0 {
            avgDuration = 0.1
        }

        var index = 0
        var repeatCount = 1
        var previousImage = animatedImages[0]
        for (idx, image) in animatedImages.enumerated() {
            if idx == 0 {
                continue
            }

            if image.isEqual(previousImage) {
                repeatCount += 1
            } else {
                let frame = ImageFrame(image: previousImage, duration: avgDuration * Double(repeatCount))
                frames.append(frame)
                repeatCount = 1
                index += 1
            }
            previousImage = image

            if idx == frameCount - 1 {
                let frame = ImageFrame(image: previousImage, duration: avgDuration * Double(repeatCount))
                frames.append(frame)
            }
        }
        return frames
    }
    
    private class func gcd(_ a: Int, with b: Int) -> Int {
        var c = 0
        var a = a
        var b = b
        while a != 0 {
            c = a
            a = b % a
            b = c
        }
        return b
    }
    
    private class func gcdArray(_ values: [Int]) -> Int {
        if values.count == 0 {
            return 0
        }
        var result = values[0]
        for i in 1 ..< values.count {
            result = gcd(values[i], with: result)
        }
        return result
    }
    
}

// MARK: - ImageCoder
/// 图片解码器，支持动图
///
/// [SDWebImage](https://github.com/SDWebImage/SDWebImage)
open class ImageCoder: NSObject {
    
    /// 单例模式
    public static let shared = ImageCoder()
    
    /// 扩展系统UTType
    public static let kUTTypeHEIC = "public.heic" as CFString
    public static let kUTTypeHEIF = "public.heif" as CFString
    public static let kUTTypeHEICS = "public.heics" as CFString
    public static let kUTTypeWEBP = "org.webmproject.webp" as CFString

    /// 是否启用HEIC动图，因系统解码性能原因，默认为NO，禁用HEIC动图
    open var heicsEnabled: Bool = false
    
    private lazy var decodeUTTypes: Set<String> = {
        let result = CGImageSourceCopyTypeIdentifiers() as? [String]
        return Set(result ?? [])
    }()
    
    private lazy var encodeUTTypes: Set<String> = {
        let result = CGImageDestinationCopyTypeIdentifiers() as? [String]
        return Set(result ?? [])
    }()

    /// 解析图片数据到Image，可指定scale
    open func decodedImage(data: Data?, scale: CGFloat, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        guard let data = data, data.count > 0,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        var scale = max(scale, 1)
        if let scaleFactor = options?[.scaleFactor] as? NSNumber {
            scale = max(scaleFactor.doubleValue, 1)
        }
        var thumbnailSize = CGSize.zero
        if let thumbnailSizeValue = options?[.thumbnailPixelSize] as? NSValue {
            thumbnailSize = thumbnailSizeValue.cgSizeValue
        }

        var animatedImage: UIImage?
        let count = CGImageSourceGetCount(source)
        let format = ImageCoder.imageFormat(for: data)
        if format == .svg {
            animatedImage = ObjCBridge.svgDecode(data, thumbnailSize: thumbnailSize)
        } else if format == .pdf {
            animatedImage = createBitmapPDF(data: data, thumbnailSize: thumbnailSize)
        } else if !isAnimated(format, forDecode: true) || count <= 1 {
            animatedImage = createFrame(at: 0, source: source, scale: scale, thumbnailSize: thumbnailSize)
        } else {
            var frames = [ImageFrame]()
            for i in 0 ..< count {
                guard let image = createFrame(at: i, source: source, scale: scale, thumbnailSize: thumbnailSize) else { continue }
                
                let duration = frameDuration(at: i, source: source, format: format)
                let frame = ImageFrame(image: image, duration: duration)
                frames.append(frame)
            }

            let loopCount = imageLoopCount(source: source, format: format)
            animatedImage = ImageFrame.animatedImage(frames: frames)
            animatedImage?.fw_imageLoopCount = loopCount
        }
        
        animatedImage?.fw_imageFormat = format
        return animatedImage
    }

    /// 编码UIImage到图片数据，可指定格式
    open func encodedData(image: UIImage?, format: ImageFormat, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        guard let image = image else {
            return nil
        }
        
        var format = format
        if format == .undefined {
            format = image.fw_hasAlpha ? .png : .jpeg
        }
        if format == .svg {
            return ObjCBridge.svgEncode(image)
        }
        
        guard let imageRef = image.cgImage else {
            return nil
        }

        let imageData = NSMutableData()
        let imageUTType = ImageCoder.utType(from: format)
        let isAnimated = isAnimated(format, forDecode: false)
        let frames = isAnimated ? ImageFrame.frames(animatedImage: image) : nil
        let count = max(1, frames?.count ?? 0)
        guard let imageDestination = CGImageDestinationCreateWithData(imageData, imageUTType, count, nil) else {
            return nil
        }

        var properties: [String: Any] = [:]
        properties[kCGImageDestinationLossyCompressionQuality as String] = 1
        properties[kCGImageDestinationEmbedThumbnail as String] = false

        if !isAnimated || count <= 1 {
            properties[kCGImagePropertyOrientation as String] = Self.exifOrientation(from: image.imageOrientation)
            CGImageDestinationAddImage(imageDestination, imageRef, properties as CFDictionary)
        } else {
            var dictionaryProperties: [String: Any] = [:]
            if let loopCountProperty = loopCountProperty(format) {
                dictionaryProperties[loopCountProperty] = image.fw_imageLoopCount
            }
            var containerProperties: [String: Any] = [:]
            if let dictionaryProperty = dictionaryProperty(format) {
                containerProperties[dictionaryProperty] = dictionaryProperties
            }
            CGImageDestinationSetProperties(imageDestination, containerProperties as CFDictionary)

            for i in 0..<count {
                guard let frame = frames?[i], let frameImageRef = frame.image.cgImage else { continue }
                
                var frameProperties: [String: Any] = [:]
                if let delayTimeProperty = delayTimeProperty(format) {
                    frameProperties[delayTimeProperty] = frame.duration
                }
                if let dictionaryProperty = dictionaryProperty(format) {
                    properties[dictionaryProperty] = frameProperties
                }
                CGImageDestinationAddImage(imageDestination, frameImageRef, properties as CFDictionary)
            }
        }

        if !CGImageDestinationFinalize(imageDestination) {
            return nil
        }
        return imageData.copy() as? Data
    }

    /// 获取图片数据的格式，未知格式返回undefined
    open class func imageFormat(for imageData: Data?) -> ImageFormat {
        guard let data = imageData, data.count > 0 else {
            return .undefined
        }

        // File signatures table: http://www.garykessler.net/library/file_sigs.html
        let c = data[0]
        switch c {
        case 0xFF:
            return .jpeg
        case 0x89:
            return .png
        case 0x47:
            return .gif
        case 0x49, 0x4D:
            return .tiff
        case 0x52:
            if data.count >= 12 {
                if let testString = String(data: data[0..<12], encoding: .ascii),
                   testString.hasPrefix("RIFF"),
                   testString.hasSuffix("WEBP") {
                    return .webp
                }
            }
        case 0x00:
            if data.count >= 12 {
                let testString = String(data: data[4..<12], encoding: .ascii)
                if testString == "ftypheic" || testString == "ftypheix" || testString == "ftyphevc" || testString == "ftyphevx" {
                    return .heic
                }
                if testString == "ftypmif1" || testString == "ftypmsf1" {
                    return .heif
                }
            }
        case 0x25:
            if data.count >= 4 {
                let testString = String(data: data[1..<4], encoding: .ascii)
                if testString == "PDF" {
                    return .pdf
                }
            }
        case 0x3C:
            let range = (data.count - min(100, data.count))..<data.count
            if let svgTagEndData = "</svg>".data(using: .utf8),
               data.range(of: svgTagEndData, options: .backwards, in: range) != nil {
                return .svg
            }
        default:
            break
        }
        
        return .undefined
    }

    /// 图片格式转化为UTType，未知格式返回kUTTypeImage
    open class func utType(from imageFormat: ImageFormat) -> CFString {
        var utType: CFString
        switch imageFormat {
        case .jpeg:
            utType = kUTTypeJPEG
        case .png:
            utType = kUTTypePNG
        case .gif:
            utType = kUTTypeGIF
        case .tiff:
            utType = kUTTypeTIFF
        case .webp:
            utType = ImageCoder.kUTTypeWEBP
        case .heic:
            utType = ImageCoder.kUTTypeHEIC
        case .heif:
            utType = ImageCoder.kUTTypeHEIF
        case .pdf:
            utType = kUTTypePDF
        case .svg:
            utType = kUTTypeScalableVectorGraphics
        default:
            utType = kUTTypeImage
        }
        return utType
    }

    /// UTType转化为图片格式，未知格式返回ImageFormat.undefined
    open class func imageFormat(from utType: CFString?) -> ImageFormat {
        guard let utType = utType else {
            return .undefined
        }
        var imageFormat: ImageFormat
        if CFStringCompare(utType, kUTTypeJPEG, []) == .compareEqualTo {
            imageFormat = .jpeg
        } else if CFStringCompare(utType, kUTTypePNG, []) == .compareEqualTo {
            imageFormat = .png
        } else if CFStringCompare(utType, kUTTypeGIF, []) == .compareEqualTo {
            imageFormat = .gif
        } else if CFStringCompare(utType, kUTTypeTIFF, []) == .compareEqualTo {
            imageFormat = .tiff
        } else if CFStringCompare(utType, ImageCoder.kUTTypeWEBP, []) == .compareEqualTo {
            imageFormat = .webp
        } else if CFStringCompare(utType, ImageCoder.kUTTypeHEIC, []) == .compareEqualTo {
            imageFormat = .heic
        } else if CFStringCompare(utType, ImageCoder.kUTTypeHEIF, []) == .compareEqualTo {
            imageFormat = .heif
        } else if CFStringCompare(utType, kUTTypePDF, []) == .compareEqualTo {
            imageFormat = .pdf
        } else if CFStringCompare(utType, kUTTypeScalableVectorGraphics, []) == .compareEqualTo {
            imageFormat = .svg
        } else {
            imageFormat = .undefined
        }
        return imageFormat
    }

    /// 图片格式转化为mimeType，未知格式返回application/octet-stream
    open class func mimeType(from imageFormat: ImageFormat) -> String {
        var mimeType: String
        switch imageFormat {
        case .jpeg:
            mimeType = "image/jpeg"
        case .png:
            mimeType = "image/png"
        case .gif:
            mimeType = "image/gif"
        case .tiff:
            mimeType = "image/tiff"
        case .webp:
            mimeType = "image/webp"
        case .heic:
            mimeType = "image/heic"
        case .heif:
            mimeType = "image/heif"
        case .pdf:
            mimeType = "application/pdf"
        case .svg:
            mimeType = "image/svg+xml"
        default:
            mimeType = "application/octet-stream"
        }
        return mimeType
    }

    /// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
    open class func mimeType(from fileExtension: String) -> String {
        if let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeUnretainedValue(),
           let mimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeUnretainedValue() as String? {
            return mimeType
        }
        return "application/octet-stream"
    }
    
    /// 图片方向转为EXIF方向
    open class func exifOrientation(from imageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        var exifOrientation: CGImagePropertyOrientation = .up
        switch imageOrientation {
        case .up:
            exifOrientation = .up
        case .down:
            exifOrientation = .down
        case .left:
            exifOrientation = .left
        case .right:
            exifOrientation = .right
        case .upMirrored:
            exifOrientation = .upMirrored
        case .downMirrored:
            exifOrientation = .downMirrored
        case .leftMirrored:
            exifOrientation = .leftMirrored
        case .rightMirrored:
            exifOrientation = .rightMirrored
        @unknown default:
            break
        }
        return exifOrientation
    }
    
    /// EXIF方向转为图片方向
    open class func imageOrientation(from exifOrientation: CGImagePropertyOrientation) -> UIImage.Orientation {
        var imageOrientation: UIImage.Orientation = .up
        switch exifOrientation {
        case .up:
            imageOrientation = .up
        case .down:
            imageOrientation = .down
        case .left:
            imageOrientation = .left
        case .right:
            imageOrientation = .right
        case .upMirrored:
            imageOrientation = .upMirrored
        case .downMirrored:
            imageOrientation = .downMirrored
        case .leftMirrored:
            imageOrientation = .leftMirrored
        case .rightMirrored:
            imageOrientation = .rightMirrored
        }
        return imageOrientation
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式
    open class func base64String(for imageData: Data?) -> String? {
        guard let data = imageData, data.count > 0 else {
            return nil
        }
        let base64String = data.base64EncodedString(options: .lineLength64Characters)
        let mimeType = ImageCoder.mimeType(from: ImageCoder.imageFormat(for: data))
        let base64Prefix = "data:\(mimeType);base64,"
        return base64Prefix + base64String
    }
    
    /// 图片base64字符串解码为数据，兼容格式：data:image/png;base64,数据
    open class func imageData(for base64String: String?) -> Data? {
        guard var string = base64String, string.count > 0 else {
            return nil
        }
        string = string.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
        if string.hasPrefix("data:"), let range = string.range(of: ";base64,") {
            string = String(string.suffix(from: range.upperBound))
        }
        return Data(base64Encoded: string, options: .ignoreUnknownCharacters)
    }

    /// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
    open class func isVectorImage(_ image: UIImage?) -> Bool {
        guard let image = image else {
            return false
        }
        if image.isSymbolImage {
            return true
        }
        let svgSelector = NSSelectorFromString(String(format: "_%@", "CGSVGDocument"))
        if image.responds(to: svgSelector) && image.perform(svgSelector)?.takeUnretainedValue() != nil {
            return true
        }
        let pdfSelector = NSSelectorFromString(String(format: "_%@", "CGPDFPage"))
        if image.responds(to: pdfSelector) && image.perform(pdfSelector)?.takeUnretainedValue() != nil {
            return true
        }
        return false
    }
    
    private func isAnimated(_ format: ImageFormat, forDecode: Bool) -> Bool {
        var isAnimated = false
        switch format {
        case .png, .gif:
            isAnimated = true
        case .heic, .heif:
            isAnimated = heicsEnabled
        case .webp:
            if #available(iOS 14.0, *) {
                isAnimated = true
            }
        default:
            break
        }
        if !isAnimated {
            return false
        }

        let imageUTType = ImageCoder.utType(from: format)
        let imageUTTypes = forDecode ? decodeUTTypes : encodeUTTypes
        return imageUTTypes.contains(imageUTType as String)
    }
    
    private func dictionaryProperty(_ format: ImageFormat) -> String? {
        switch format {
        case .gif:
            return kCGImagePropertyGIFDictionary as String
        case .png:
            return kCGImagePropertyPNGDictionary as String
        case .heic, .heif:
            return kCGImagePropertyHEICSDictionary as String
        case .webp:
            if #available(iOS 14.0, *) {
                return kCGImagePropertyWebPDictionary as String
            }
            return "{WebP}"
        default:
            return nil
        }
    }

    private func unclampedDelayTimeProperty(_ format: ImageFormat) -> String? {
        switch format {
        case .gif:
            return kCGImagePropertyGIFUnclampedDelayTime as String
        case .png:
            return kCGImagePropertyAPNGUnclampedDelayTime as String
        case .heic, .heif:
            return kCGImagePropertyHEICSUnclampedDelayTime as String
        case .webp:
            if #available(iOS 14.0, *) {
                return kCGImagePropertyWebPUnclampedDelayTime as String
            }
            return "UnclampedDelayTime"
        default:
            return nil
        }
    }
    
    private func delayTimeProperty(_ format: ImageFormat) -> String? {
        switch format {
        case .gif:
            return kCGImagePropertyGIFDelayTime as String
        case .png:
            return kCGImagePropertyAPNGDelayTime as String
        case .heic, .heif:
            return kCGImagePropertyHEICSDelayTime as String
        case .webp:
            if #available(iOS 14.0, *) {
                return kCGImagePropertyWebPDelayTime as String
            }
            return "DelayTime"
        default:
            return nil
        }
    }
    
    private func loopCountProperty(_ format: ImageFormat) -> String? {
        switch format {
            case .gif:
                return kCGImagePropertyGIFLoopCount as String
            case .png:
                return kCGImagePropertyAPNGLoopCount as String
            case .heic, .heif:
                return kCGImagePropertyHEICSLoopCount as String
            case .webp:
                if #available(iOS 14.0, *) {
                    return kCGImagePropertyWebPLoopCount as String
                }
                return "LoopCount"
            default:
                return nil
        }
    }

    private func defaultLoopCount(_ format: ImageFormat) -> UInt {
        switch format {
            case .gif:
                return 1
            default:
                return 0
        }
    }
    
    private func imageLoopCount(source: CGImageSource, format: ImageFormat) -> UInt {
        var loopCount = defaultLoopCount(format)
        if let dictionaryProperty = dictionaryProperty(format),
           let loopCountProperty = loopCountProperty(format),
           let imageProperties = CGImageSourceCopyProperties(source, nil) as NSDictionary?,
           let containerProperties = imageProperties[dictionaryProperty] as? NSDictionary,
           let containerLoopCount = containerProperties[loopCountProperty] as? NSNumber {
            loopCount = containerLoopCount.uintValue
        }
        return loopCount
    }
    
    private func frameDuration(at index: Int, source: CGImageSource, format: ImageFormat) -> TimeInterval {
        var options: [String: Any] = [:]
        options[kCGImageSourceShouldCacheImmediately as String] = true
        options[kCGImageSourceShouldCache as String] = true
        var frameDuration: TimeInterval = 0.1
        guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, options as CFDictionary) as NSDictionary?,
              let dictionaryProperty = dictionaryProperty(format),
              let containerProperties = frameProperties[dictionaryProperty] as? NSDictionary else {
            return frameDuration
        }

        if let unclampedDelayTimeProperty = unclampedDelayTimeProperty(format),
           let unclampedDelayTime = containerProperties[unclampedDelayTimeProperty] as? NSNumber {
            frameDuration = unclampedDelayTime.doubleValue
        } else if let delayTimeProperty = delayTimeProperty(format),
                  let delayTime = containerProperties[delayTimeProperty] as? NSNumber {
            frameDuration = delayTime.doubleValue
        }
        if frameDuration < 0.011 {
            frameDuration = 0.1
        }
        return frameDuration
    }
    
    private func createFrame(at index: Int, source: CGImageSource, scale: CGFloat, thumbnailSize: CGSize) -> UIImage? {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as NSDictionary?
        let pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Double ?? .zero
        let pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Double ?? .zero
        
        var decodingOptions: [AnyHashable: Any] = [:]
        var imageRef: CGImage?
        let createFullImage = thumbnailSize.width == 0 || thumbnailSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= thumbnailSize.width && pixelHeight <= thumbnailSize.height)
        if createFullImage {
            imageRef = CGImageSourceCreateImageAtIndex(source, index, decodingOptions as CFDictionary)
        } else {
            decodingOptions[kCGImageSourceCreateThumbnailWithTransform] = true
            var maxPixelSize: CGFloat
            let pixelRatio = pixelWidth / pixelHeight
            let thumbnailRatio = thumbnailSize.width / thumbnailSize.height
            if pixelRatio > thumbnailRatio {
                maxPixelSize = max(thumbnailSize.width, thumbnailSize.width / pixelRatio)
            } else {
                maxPixelSize = max(thumbnailSize.height, thumbnailSize.height * pixelRatio)
            }
            decodingOptions[kCGImageSourceThumbnailMaxPixelSize] = maxPixelSize
            decodingOptions[kCGImageSourceCreateThumbnailFromImageAlways] = true
            imageRef = CGImageSourceCreateThumbnailAtIndex(source, index, decodingOptions as CFDictionary)
        }
        guard let imageRef = imageRef else {
            return nil
        }

        let image = UIImage(cgImage: imageRef, scale: scale, orientation: .up)
        return image
    }
    
    private func createBitmapPDF(data: Data, thumbnailSize: CGSize) -> UIImage? {
        let pageNumber: Int = 0
        guard let provider = CGDataProvider(data: data as CFData),
            let document = CGPDFDocument(provider),
            let page = document.page(at: pageNumber + 1)
        else {
            return nil
        }

        let box = CGPDFBox.mediaBox
        let rect = page.getBoxRect(box)
        var targetRect = rect
        if !thumbnailSize.equalTo(CGSize.zero) {
            targetRect = CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height)
        }

        let xRatio = targetRect.size.width / rect.size.width
        let yRatio = targetRect.size.height / rect.size.height
        let xScale = min(xRatio, yRatio)
        let yScale = min(xRatio, yRatio)

        let drawRect = CGRect(x: 0, y: 0, width: targetRect.size.width / xScale, height: targetRect.size.height / yScale)
        let scaleTransform = CGAffineTransform(scaleX: xScale, y: yScale)
        let transform = page.getDrawingTransform(box, rect: drawRect, rotate: 0, preserveAspectRatio: true)

        UIGraphicsBeginImageContextWithOptions(targetRect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        context.translateBy(x: 0, y: targetRect.size.height)
        context.scaleBy(x: 1, y: -1)
        context.concatenate(scaleTransform)
        context.concatenate(transform)
        context.drawPDFPage(page)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

// MARK: - UIImage+AnimatedImage
@_spi(FW) extension UIImage {
    
    /// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
    public var fw_imageLoopCount: UInt {
        get {
            if let value = fw_propertyNumber(forName: "fw_imageLoopCount") {
                return value.uintValue
            }
            return .zero
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_imageLoopCount")
        }
    }

    /// 是否是动图，内部检查images数组
    public var fw_isAnimated: Bool {
        return self.images != nil
    }
    
    /// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
    public var fw_isVector: Bool {
        return ImageCoder.isVectorImage(self)
    }
    
    /// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回ImageFormatUndefined
    public var fw_imageFormat: ImageFormat {
        get {
            if let value = fw_propertyNumber(forName: "fw_imageFormat") {
                return .init(value.intValue)
            }
            return ImageCoder.imageFormat(from: self.cgImage?.utType)
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "fw_imageFormat")
        }
    }
    
}

// MARK: - Data+AnimatedImage
@_spi(FW) extension Data {
    
    /// 获取图片数据的格式，未知格式返回ImageFormatUndefined
    public static func fw_imageFormat(for imageData: Data?) -> ImageFormat {
        return ImageCoder.imageFormat(for: imageData)
    }
    
    /// 图片格式转化为UTType，未知格式返回kUTTypeImage
    public static func fw_utType(from imageFormat: ImageFormat) -> CFString {
        return ImageCoder.utType(from: imageFormat)
    }

    /// UTType转化为图片格式，未知格式返回ImageFormatUndefined
    public static func fw_imageFormat(from utType: CFString) -> ImageFormat {
        return ImageCoder.imageFormat(from: utType)
    }

    /// 图片格式转化为mimeType，未知格式返回application/octet-stream
    public static func fw_mimeType(from imageFormat: ImageFormat) -> String {
        return ImageCoder.mimeType(from: imageFormat)
    }
    
    /// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
    public static func fw_mimeType(from fileExtension: String) -> String {
        return ImageCoder.mimeType(from: fileExtension)
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
    public static func fw_base64String(for imageData: Data?) -> String? {
        return ImageCoder.base64String(for: imageData)
    }
    
    /// 图片base64字符串解码为数据，兼容格式：data:image/png;base64,数据
    public static func fw_imageData(for base64String: String?) -> Data? {
        return ImageCoder.imageData(for: base64String)
    }
    
}
