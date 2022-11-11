//
//  SDWebImageImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import SDWebImage
#if FWMacroSPM
import FWObjC
import FWFramework
#endif

/// SDWebImage图片插件，启用SDWebImage子模块后生效
@objc(FWSDWebImageImpl)
@objcMembers open class SDWebImageImpl: NSObject, ImagePlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = SDWebImageImpl()
    
    /// 图片加载完成是否显示渐变动画，默认false
    open var fadeAnimated = false
    
    /// 图片自定义句柄，setImageURL开始时调用
    open var customBlock: ((UIImageView) -> Void)?
    
    // MARK: - ImagePlugin
    public func animatedImageView() -> UIImageView {
        return SDAnimatedImageView()
    }
    
    public func imageDecode(
        _ data: Data,
        scale: CGFloat,
        options: [ImageCoderOptions : Any]? = nil
    ) -> UIImage? {
        var scaleFactor = scale
        if let scaleOption = options?[.optionScaleFactor] as? NSNumber {
            scaleFactor = scaleOption.doubleValue
        }
        var coderOptions: [SDImageCoderOption : Any] = [:]
        coderOptions[.decodeScaleFactor] = max(scaleFactor, 1)
        coderOptions[.decodeFirstFrameOnly] = false
        if let options = options {
            for (key, value) in options {
                coderOptions[.init(rawValue: key.rawValue)] = value
            }
        }
        return SDImageCodersManager.shared.decodedImage(with: data, options: coderOptions)
    }
    
    public func imageEncode(
        _ image: UIImage,
        options: [ImageCoderOptions : Any]? = nil
    ) -> Data? {
        var coderOptions: [SDImageCoderOption : Any] = [:]
        coderOptions[.encodeCompressionQuality] = 1
        coderOptions[.encodeFirstFrameOnly] = false
        if let options = options {
            for (key, value) in options {
                coderOptions[.init(rawValue: key.rawValue)] = value
            }
        }
        
        let imageFormat = image.sd_imageFormat
        let imageData = SDImageCodersManager.shared.encodedData(with: image, format: imageFormat, options: coderOptions)
        if imageData != nil || imageFormat == .undefined {
            return imageData
        }
        return SDImageCodersManager.shared.encodedData(with: image, format: .undefined, options: coderOptions)
    }
    
    public func imageURL(_ imageView: UIImageView) -> URL? {
        return imageView.sd_imageURL
    }
    
    public func imageView(
        _ imageView: UIImageView,
        setImageURL imageURL: URL?,
        placeholder: UIImage?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions : Any]?,
        completion: ((UIImage?, Error?) -> Void)?,
        progress: ((Double) -> Void)? = nil
    ) {
        if fadeAnimated && imageView.sd_imageTransition == nil {
            imageView.sd_imageTransition = SDWebImageTransition.fade
        }
        customBlock?(imageView)
        
        let targetOptions = SDWebImageOptions(rawValue: options.rawValue)
        var targetContext: [SDWebImageContextOption : Any]?
        if let context = context {
            targetContext = [:]
            for (key, value) in context {
                targetContext?[.init(rawValue: key.rawValue)] = value
            }
        }
        
        imageView.sd_setImage(
            with: imageURL,
            placeholderImage: placeholder,
            options: targetOptions.union(.retryFailed),
            context: targetContext,
            progress: progress != nil ? { receivedSize, expectedSize, _ in
                guard expectedSize > 0 else { return }
                if Thread.isMainThread {
                    progress?(Double(receivedSize) / Double(expectedSize))
                } else {
                    DispatchQueue.main.async {
                        progress?(Double(receivedSize) / Double(expectedSize))
                    }
                }
            } : nil,
            completed: completion != nil ? { image, error, _, _ in
                completion?(image, error)
            } : nil
        )
    }
    
    public func cancelImageRequest(_ imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }
    
    public func downloadImage(
        _ imageURL: URL?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions : Any]?,
        completion: @escaping (UIImage?, Data?, Error?) -> Void,
        progress: ((Double) -> Void)? = nil
    ) -> Any? {
        let targetOptions = SDWebImageOptions(rawValue: options.rawValue)
        var targetContext: [SDWebImageContextOption : Any]?
        if let context = context {
            targetContext = [:]
            for (key, value) in context {
                targetContext?[.init(rawValue: key.rawValue)] = value
            }
        }
        
        return SDWebImageManager.shared.loadImage(
            with: imageURL,
            options: targetOptions.union(.retryFailed),
            context: targetContext,
            progress: progress != nil ? { receivedSize, expectedSize, _ in
                guard expectedSize > 0 else { return }
                if Thread.isMainThread {
                    progress?(Double(receivedSize) / Double(expectedSize))
                } else {
                    DispatchQueue.main.async {
                        progress?(Double(receivedSize) / Double(expectedSize))
                    }
                }
            } : nil,
            completed: { image, data, error, _, _, _ in
                completion(image, data, error)
            }
        )
    }
    
    public func cancelImageDownload(_ receipt: Any?) {
        if let receipt = receipt as? SDWebImageCombinedOperation {
            receipt.cancel()
        }
    }
    
}

@objc extension Autoloader {
    
    func loadSDWebImage() {
        PluginManager.registerPlugin(ImagePlugin.self, with: SDWebImageImpl.self)
    }
    
}
