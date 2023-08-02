//
//  AnimatedImage.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import MobileCoreServices
import ImageIO

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

    /// 是否启用HEIC动图，因系统解码性能原因，默认为NO，禁用HEIC动图
    open var heicsEnabled: Bool = false

    /// 解析图片数据到Image，可指定scale
    open func decodedImage(with data: Data?, scale: CGFloat, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        // Implementation goes here
        return nil
    }

    /// 编码UIImage到图片数据，可指定格式
    open func encodedData(with image: UIImage?, format: ImageFormat, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        // Implementation goes here
        return nil
    }

    /// 获取图片数据的格式，未知格式返回undefined
    open class func imageFormat(for imageData: Data?) -> ImageFormat {
        // Implementation goes here
        return .undefined
    }

    /// 图片格式转化为UTType，未知格式返回kUTTypeImage
    open class func utType(from imageFormat: ImageFormat) -> CFString {
        // Implementation goes here
        return kUTTypeImage
    }

    /// UTType转化为图片格式，未知格式返回ImageFormat.undefined
    open class func imageFormat(from utType: CFString?) -> ImageFormat {
        // Implementation goes here
        return .undefined
    }

    /// 图片格式转化为mimeType，未知格式返回application/octet-stream
    open class func mimeType(from imageFormat: ImageFormat) -> String {
        // Implementation goes here
        return "application/octet-stream"
    }

    /// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
    open class func mimeType(from extension: String) -> String {
        // Implementation goes here
        return "application/octet-stream"
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式
    open class func base64String(for imageData: Data?) -> String? {
        // Implementation goes here
        return nil
    }

    /// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
    open class func isVectorImage(_ image: UIImage?) -> Bool {
        // Implementation goes here
        return false
    }
    
}

// MARK: - UIImage+AnimatedImage
@_spi(FW) extension UIImage {
    
    /// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
    public var fw_imageLoopCount: UInt {
        get {
            if let value = fw_property(forName: "fw_imageLoopCount") as? NSNumber {
                return value.uintValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_imageLoopCount")
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
            if let value = fw_property(forName: "fw_imageFormat") as? NSNumber {
                return .init(value.intValue)
            }
            return ImageCoder.imageFormat(from: self.cgImage?.utType)
        }
        set {
            fw_setProperty(NSNumber(value: newValue.rawValue), forName: "fw_imageFormat")
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
    public static func fw_mimeType(from ext: String) -> String {
        return ImageCoder.mimeType(from: ext)
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
    public static func fw_base64String(for imageData: Data?) -> String? {
        return ImageCoder.base64String(for: imageData)
    }
    
}
