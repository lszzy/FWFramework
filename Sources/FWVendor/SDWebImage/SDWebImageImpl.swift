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
open class SDWebImageImpl: NSObject, ImagePlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = SDWebImageImpl()
    
    /// 图片加载完成是否显示渐变动画，默认false
    open var fadeAnimated = false
    
    /// 图片加载时是否显示动画指示器，默认false
    open var showsIndicator = false
    
    /// 图片占位图存在时是否隐藏动画指示器，默认false
    open var hidesPlaceholderIndicator = false
    
    /// 自定义动画指示器句柄，默认nil时为medium灰色
    open var customIndicatorBlock: ((UIView) -> SDWebImageIndicator?)?
    
    /// 图片自定义句柄，setImageURL开始时调用
    open var customBlock: ((UIView) -> Void)?
    
    // MARK: - ImagePlugin
    open func animatedImageView() -> UIImageView {
        return SDAnimatedImageView()
    }
    
    open func imageDecode(
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
    
    open func imageEncode(
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
    
    open func imageURL(_ view: UIView) -> URL? {
        return view.sd_imageURL
    }
    
    open func view(
        _ view: UIView,
        setImageURL imageURL: URL?,
        placeholder: UIImage?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions : Any]?,
        setImageBlock: ((UIImage?) -> Void)?,
        completion: ((UIImage?, Error?) -> Void)?,
        progress: ((Double) -> Void)? = nil
    ) {
        if fadeAnimated && view.sd_imageTransition == nil {
            view.sd_imageTransition = SDWebImageTransition.fade
        }
        if showsIndicator && view.sd_imageIndicator == nil &&
            !(hidesPlaceholderIndicator && placeholder != nil) {
            if customIndicatorBlock != nil {
                view.sd_imageIndicator = customIndicatorBlock?(view)
            } else {
                let indicator = SDWebImageActivityIndicator.medium
                indicator.indicatorView.color = ViewPluginImpl.indicatorViewColor
                view.sd_imageIndicator = indicator
            }
        }
        customBlock?(view)
        
        let targetOptions = SDWebImageOptions(rawValue: options.rawValue)
        var targetContext: [SDWebImageContextOption : Any]?
        if let context = context {
            targetContext = [:]
            for (key, value) in context {
                if key == .optionThumbnailPixelSize {
                    targetContext?[.imageThumbnailPixelSize] = value
                } else {
                    targetContext?[.init(rawValue: key.rawValue)] = value
                }
            }
        }
        
        view.sd_internalSetImage(
            with: imageURL,
            placeholderImage: placeholder,
            options: targetOptions.union(.retryFailed),
            context: targetContext,
            setImageBlock: setImageBlock != nil ? { image, _, _, _ in
                setImageBlock?(image)
            } : nil,
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
            completed: completion != nil ? { image, _, error, _, _, _ in
                completion?(image, error)
            } : nil
        )
    }
    
    open func cancelImageRequest(_ view: UIView) {
        view.sd_cancelCurrentImageLoad()
    }
    
    open func downloadImage(
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
                if key == .optionThumbnailPixelSize {
                    targetContext?[.imageThumbnailPixelSize] = value
                } else {
                    targetContext?[.init(rawValue: key.rawValue)] = value
                }
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
    
    open func cancelImageDownload(_ receipt: Any?) {
        if let receipt = receipt as? SDWebImageCombinedOperation {
            receipt.cancel()
        }
    }
    
}

@objc extension Autoloader {
    
    func loadSDWebImage() {
        PluginManager.registerPlugin(ImagePlugin.self, object: SDWebImageImpl.self)
    }
    
}
