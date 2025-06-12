//
//  SDWebImageImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import SDWebImage
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
@_spi(FW) import FWUIKit
#endif

// MARK: - SDWebImageImpl
/// SDWebImage图片插件，启用SDWebImage子模块后生效
open class SDWebImageImpl: NSObject, ImagePlugin, ImageCoderPlugin, @unchecked Sendable {
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

    /// 自定义动画指示器句柄，参数为是否有placeholder，默认nil
    open var customIndicatorBlock: (@MainActor @Sendable (UIView, Bool) -> SDWebImageIndicator?)?

    /// 图片自定义句柄，setImageURL开始时调用
    open var customBlock: (@MainActor @Sendable (UIView) -> Void)?

    // MARK: - ImagePlugin
    open func animatedImageView() -> UIImageView {
        SDAnimatedImageView()
    }

    open func imageURL(for view: UIView) -> URL? {
        view.sd_imageURL
    }

    open func setImageURL(
        url imageURL: URL?,
        placeholder: UIImage?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]?,
        setImageBlock: (@MainActor @Sendable (UIImage?) -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil,
        for view: UIView
    ) {
        if fadeAnimated && view.sd_imageTransition == nil {
            view.sd_imageTransition = SDWebImageTransition.fade
        }
        if showsIndicator && !view.fw.hidesImageIndicator &&
            !(hidesPlaceholderIndicator && placeholder != nil) &&
            view.sd_imageIndicator == nil {
            if customIndicatorBlock != nil {
                view.sd_imageIndicator = customIndicatorBlock?(view, placeholder != nil)
            } else {
                view.sd_imageIndicator = SDWebImagePluginIndicator(style: placeholder != nil ? .imagePlaceholder : .image)
            }
        }
        customBlock?(view)

        let targetOptions = SDWebImageOptions(rawValue: options.rawValue)
        var targetContext: [SDWebImageContextOption: Any] = [:]
        if view is SDAnimatedImageView {
            targetContext[.animatedImageClass] = SDAnimatedImage.self
        }
        if let context {
            for (key, value) in context {
                if key == .thumbnailPixelSize {
                    targetContext[.imageThumbnailPixelSize] = value
                } else {
                    targetContext[.init(rawValue: key.rawValue)] = value
                }
            }
        }

        let sdImageBlock: SDSetImageBlock = { @MainActor @Sendable image, _, _, _ in
            setImageBlock?(image)
        }
        let sdProgressBlock: SDImageLoaderProgressBlock = { @Sendable receivedSize, expectedSize, _ in
            guard expectedSize > 0 else { return }
            DispatchQueue.fw.mainAsync {
                progress?(Double(receivedSize) / Double(expectedSize))
            }
        }
        let sdCompletionBlock: SDInternalCompletionBlock = { @Sendable image, _, error, _, _, _ in
            DispatchQueue.fw.mainAsync {
                completion?(image, error)
            }
        }

        view.sd_internalSetImage(
            with: imageURL,
            placeholderImage: placeholder,
            options: targetOptions.union(.retryFailed),
            context: !targetContext.isEmpty ? targetContext : nil,
            setImageBlock: setImageBlock != nil ? sdImageBlock : nil,
            progress: progress != nil ? sdProgressBlock : nil,
            completed: completion != nil ? sdCompletionBlock : nil
        )
    }

    open func cancelImageRequest(for view: UIView) {
        var cancelSelecter = NSSelectorFromString("sd_cancelLatestImageLoad")
        if view.responds(to: cancelSelecter) {
            view.perform(cancelSelecter)
            return
        }

        cancelSelecter = NSSelectorFromString("sd_cancelCurrentImageLoad")
        if view.responds(to: cancelSelecter) {
            view.perform(cancelSelecter)
        }
    }

    open func loadImageCache(_ imageURL: URL?) -> UIImage? {
        guard let cacheKey = SDWebImageManager.shared.cacheKey(for: imageURL) else { return nil }
        let cachedImage = SDImageCache.shared.imageFromCache(forKey: cacheKey)
        return cachedImage
    }

    open func clearImageCaches(_ completion: (@MainActor @Sendable () -> Void)? = nil) {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: {
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?()
                }
            }
        })
    }

    open func downloadImage(
        _ imageURL: URL?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]?,
        completion: @escaping @MainActor @Sendable (UIImage?, Data?, Error?) -> Void,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil
    ) -> Any? {
        let targetOptions = SDWebImageOptions(rawValue: options.rawValue)
        var targetContext: [SDWebImageContextOption: Any]?
        if let context {
            targetContext = [:]
            for (key, value) in context {
                if key == .thumbnailPixelSize {
                    targetContext?[.imageThumbnailPixelSize] = value
                } else {
                    targetContext?[.init(rawValue: key.rawValue)] = value
                }
            }
        }

        let sdProgressBlock: SDImageLoaderProgressBlock = { @Sendable receivedSize, expectedSize, _ in
            guard expectedSize > 0 else { return }
            DispatchQueue.fw.mainAsync {
                progress?(Double(receivedSize) / Double(expectedSize))
            }
        }

        return SDWebImageManager.shared.loadImage(
            with: imageURL,
            options: targetOptions.union(.retryFailed),
            context: targetContext,
            progress: progress != nil ? sdProgressBlock : nil,
            completed: { @Sendable [weak self] image, data, error, _, _, _ in
                if options.contains(.queryMemoryData), data == nil, let image {
                    DispatchQueue.global().async { [weak self] in
                        let imageData = self?.imageEncode(image)
                        DispatchQueue.main.async {
                            completion(image, imageData, error)
                        }
                    }
                } else {
                    DispatchQueue.fw.mainAsync {
                        completion(image, data, error)
                    }
                }
            }
        )
    }

    open func cancelImageDownload(_ receipt: Any?) {
        if let receipt = receipt as? SDWebImageCombinedOperation {
            receipt.cancel()
        }
    }

    // MARK: - ImageCoderPlugin
    open func imageDecode(
        _ data: Data,
        scale: CGFloat,
        options: [ImageCoderOptions: Any]? = nil
    ) -> UIImage? {
        var scaleFactor = scale
        if let scaleOption = options?[.scaleFactor] as? NSNumber {
            scaleFactor = scaleOption.doubleValue
        }
        var coderOptions: [SDImageCoderOption: Any] = [:]
        coderOptions[.decodeScaleFactor] = max(scaleFactor, 1)
        coderOptions[.decodeFirstFrameOnly] = false
        if let options {
            for (key, value) in options {
                coderOptions[.init(rawValue: key.rawValue)] = value
            }
        }
        return SDImageCodersManager.shared.decodedImage(with: data, options: coderOptions)
    }

    open func imageEncode(
        _ image: UIImage,
        options: [ImageCoderOptions: Any]? = nil
    ) -> Data? {
        var coderOptions: [SDImageCoderOption: Any] = [:]
        coderOptions[.encodeCompressionQuality] = 1
        coderOptions[.encodeFirstFrameOnly] = false
        if let options {
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
}

// MARK: - SDWebImagePluginIndicator
/// SDWebImage指示器插件Indicator
@MainActor open class SDWebImagePluginIndicator: NSObject {
    open lazy var indicatorView: UIView = {
        let result = UIView.fw.indicatorView(style: style)
        if style.indicatorColor == nil {
            result.indicatorColor = (style == .image) ? .gray : .white
        }
        result.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        return result
    }() {
        didSet {
            indicatorView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        }
    }

    private var style: IndicatorViewStyle = .image

    override public init() {
        super.init()
    }

    public init(style: IndicatorViewStyle) {
        super.init()
        self.style = style
    }

    open func startAnimatingIndicator() {
        guard let indicatorView = indicatorView as? UIView & IndicatorViewPlugin else { return }

        indicatorView.startAnimating()
        indicatorView.isHidden = false
    }

    open func stopAnimatingIndicator() {
        guard let indicatorView = indicatorView as? UIView & IndicatorViewPlugin else { return }

        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }
}

#if swift(>=6.0)
extension SDWebImagePluginIndicator: @preconcurrency SDWebImageIndicator {}
#else
extension SDWebImagePluginIndicator: SDWebImageIndicator {}
#endif

// MARK: - SDWebImageProgressPluginIndicator
@MainActor open class SDWebImageProgressPluginIndicator: NSObject {
    open lazy var indicatorView: UIView = {
        let result = UIView.fw.progressView(style: style)
        result.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        return result
    }() {
        didSet {
            indicatorView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        }
    }

    open var animated: Bool = true

    private var style: ProgressViewStyle = .default

    override public init() {
        super.init()
    }

    public init(style: ProgressViewStyle) {
        super.init()
        self.style = style
    }

    open func startAnimatingIndicator() {
        guard let indicatorView = indicatorView as? UIView & ProgressViewPlugin else { return }

        indicatorView.isHidden = false
        indicatorView.progress = 0
    }

    open func stopAnimatingIndicator() {
        guard let indicatorView = indicatorView as? UIView & ProgressViewPlugin else { return }

        indicatorView.progress = 1
        indicatorView.isHidden = true
    }

    open func updateProgress(_ progress: Double) {
        guard let indicatorView = indicatorView as? UIView & ProgressViewPlugin else { return }

        indicatorView.setProgress(progress, animated: animated)
    }
}

#if swift(>=6.0)
extension SDWebImageProgressPluginIndicator: @preconcurrency SDWebImageIndicator {}
#else
extension SDWebImageProgressPluginIndicator: SDWebImageIndicator {}
#endif

// MARK: - Autoloader+SDWebImage
@objc extension Autoloader {
    static func loadPlugin_SDWebImage() {
        PluginManager.presetPlugin(ImagePlugin.self, object: SDWebImageImpl.self)
        PluginManager.presetPlugin(ImageCoderPlugin.self, object: SDWebImageImpl.self)
    }
}
