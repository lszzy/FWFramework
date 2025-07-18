//
//  ImagePluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ImagePluginImpl
/// 默认图片插件
open class ImagePluginImpl: NSObject, ImagePlugin, ImageCoderPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePluginImpl()

    /// 图片加载完成是否显示渐变动画，默认false
    open var fadeAnimated: Bool = false

    /// 图片加载时是否显示动画指示器，默认false
    open var showsIndicator = false

    /// 图片占位图存在时是否隐藏动画指示器，默认false
    open var hidesPlaceholderIndicator = false

    /// 自定义动画指示器句柄，参数为是否有placeholder，默认nil
    open var customIndicatorBlock: (@MainActor @Sendable (UIView, Bool) -> (UIView & IndicatorViewPlugin)?)?

    /// 自定义图片处理句柄，setImageURL开始时调用
    open var customBlock: (@MainActor @Sendable (UIView) -> Void)?

    /// 自定义图片进度句柄，setImageURL下载时调用
    open var customProgressBlock: (@MainActor @Sendable (UIView, CGFloat) -> Void)?

    /// 自定义图片完成句柄，setImageURL完成时调用
    open var customCompletionBlock: (@MainActor @Sendable (UIView, UIImage?, Error?) -> Void)?

    /// 自定义图片取消句柄，cancelImageRequest时调用
    open var customCancelBlock: (@MainActor @Sendable (UIView) -> Void)?

    // MARK: - ImagePlugin
    open func animatedImageView() -> UIImageView {
        UIImageView()
    }

    open func imageURL(for view: UIView) -> URL? {
        ImageDownloader.shared.imageURL(for: view)
    }

    open func setImageURL(
        url imageURL: URL?,
        placeholder: UIImage?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]?,
        setImageBlock block: (@MainActor @Sendable (UIImage?) -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil,
        for view: UIView
    ) {
        let setImageBlock = block ?? { image in
            if let imageView = view as? UIImageView {
                imageView.image = image
            } else if let button = view as? UIButton {
                button.setImage(image, for: .normal)
            }
        }

        var indicatorView: (UIView & IndicatorViewPlugin)?
        if showsIndicator && !view.fw.hidesImageIndicator &&
            !(hidesPlaceholderIndicator && placeholder != nil) {
            if let indicator = view.viewWithTag(2061) as? (UIView & IndicatorViewPlugin) {
                indicatorView = indicator
            } else {
                if customIndicatorBlock != nil {
                    indicatorView = customIndicatorBlock?(view, placeholder != nil)
                } else {
                    let style: IndicatorViewStyle = placeholder != nil ? .imagePlaceholder : .image
                    indicatorView = UIView.fw.indicatorView(style: style)
                    if style.indicatorColor == nil {
                        indicatorView?.indicatorColor = (style == .image) ? .gray : .white
                    }
                }
                if let indicatorView {
                    indicatorView.tag = 2061
                    view.addSubview(indicatorView)
                    (indicatorView as UIView).fw.alignCenter(autoScale: false)
                }
            }
        }
        if let indicatorView {
            view.bringSubviewToFront(indicatorView)
            if !indicatorView.isAnimating {
                indicatorView.startAnimating()
            }
            indicatorView.isHidden = false
        }
        customBlock?(view)

        ImageDownloader.shared.downloadImage(for: view, imageURL: imageURL, options: options, context: context, placeholder: {
            if !options.contains(.delayPlaceholder) {
                setImageBlock(placeholder)
            }
        }, completion: { [weak self] image, isCache, error in
            if let indicatorView {
                if indicatorView.isAnimating {
                    indicatorView.stopAnimating()
                }
                indicatorView.isHidden = true
            }
            self?.customCompletionBlock?(view, image, error)

            let autoSetImage = !((image != nil && options.contains(.avoidSetImage) && completion != nil) || (image == nil && !options.contains(.delayPlaceholder)))
            let delayPlaceholder = autoSetImage && options.contains(.delayPlaceholder) ? placeholder : nil
            if autoSetImage, ImagePluginImpl.shared.fadeAnimated, !isCache {
                let originalOperationKey = ImageDownloader.shared.imageOperationKey(for: view)
                UIView.transition(with: view, duration: 0, options: [], animations: {
                    let operationKey = ImageDownloader.shared.imageOperationKey(for: view)
                    if operationKey == nil || operationKey != originalOperationKey { return }
                }, completion: { _ in
                    UIView.transition(with: view, duration: 0.5, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        let operationKey = ImageDownloader.shared.imageOperationKey(for: view)
                        if operationKey == nil || operationKey != originalOperationKey { return }

                        setImageBlock(image ?? delayPlaceholder)
                    }, completion: nil)
                })
            } else if autoSetImage {
                setImageBlock(image ?? delayPlaceholder)
            }

            completion?(image, error)
        }, progress: customProgressBlock != nil ? { @MainActor @Sendable [weak self] value in
            self?.customProgressBlock?(view, value)
            progress?(value)
        } : progress)
    }

    open func cancelImageRequest(for view: UIView) {
        if showsIndicator, let indicatorView = view.viewWithTag(2061) as? (UIView & IndicatorViewPlugin) {
            if indicatorView.isAnimating {
                indicatorView.stopAnimating()
            }
            indicatorView.isHidden = true
        }
        customCancelBlock?(view)

        ImageDownloader.shared.cancelImageDownloadTask(view)
    }

    open func loadImageCache(_ imageURL: URL?) -> UIImage? {
        ImageDownloader.shared.loadImageCache(for: imageURL)
    }

    open func clearImageCaches(_ completion: (@MainActor @Sendable () -> Void)? = nil) {
        ImageDownloader.shared.clearImageCaches(completion)
    }

    open func downloadImage(
        _ imageURL: URL?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]?,
        completion: @escaping @MainActor @Sendable (UIImage?, Data?, Error?) -> Void,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil
    ) -> Any? {
        ImageDownloader.shared.downloadImage(for: imageURL, options: options, context: context, success: { [weak self] _, _, responseObject in
            let imageData = ImageResponseSerializer.cachedResponseData(for: responseObject)
            if options.contains(.queryMemoryData), imageData == nil {
                DispatchQueue.global().async { [weak self] in
                    let imageData = self?.imageEncode(responseObject)
                    DispatchQueue.main.async {
                        completion(responseObject, imageData, nil)
                    }
                }
            } else {
                if !options.contains(.queryMemoryData) {
                    ImageResponseSerializer.clearCachedResponseData(for: responseObject)
                }
                DispatchQueue.fw.mainAsync {
                    completion(responseObject, imageData, nil)
                }
            }
        }, failure: { _, _, error in
            DispatchQueue.fw.mainAsync {
                completion(nil, nil, error)
            }
        }, progress: progress != nil ? { @MainActor @Sendable downloadProgress in
            DispatchQueue.fw.mainAsync {
                progress?(downloadProgress.fractionCompleted)
            }
        } : nil)
    }

    open func cancelImageDownload(_ receipt: Any?) {
        if let receipt = receipt as? ImageDownloadReceipt {
            ImageDownloader.shared.cancelTask(for: receipt)
        }
    }

    // MARK: - ImageCoderPlugin
    open func imageDecode(
        _ data: Data,
        scale: CGFloat,
        options: [ImageCoderOptions: Any]? = nil
    ) -> UIImage? {
        ImageCoder.shared.decodedImage(data: data, scale: scale, options: options)
    }

    open func imageEncode(
        _ image: UIImage,
        options: [ImageCoderOptions: Any]? = nil
    ) -> Data? {
        let imageFormat = image.fw.imageFormat
        let imageData = ImageCoder.shared.encodedData(image: image, format: imageFormat, options: options)
        if imageData != nil || imageFormat == .undefined {
            return imageData
        }
        return ImageCoder.shared.encodedData(image: image, format: .undefined, options: options)
    }
}
