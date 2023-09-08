//
//  ImagePluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 默认图片插件
open class ImagePluginImpl: NSObject, ImagePlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePluginImpl()

    /// 图片加载完成是否显示渐变动画，默认false
    open var fadeAnimated: Bool = false
    
    /// 图片加载时是否显示进度指示器，默认false
    open var showsIndicator = false
    
    /// 自定义进度指示器句柄，默认nil
    open var customIndicatorBlock: ((UIView) -> (UIView & ProgressViewPlugin)?)?

    /// 图片自定义句柄，setImageURL开始时调用
    open var customBlock: ((UIView) -> Void)?
    
    // MARK: - ImagePlugin
    open func animatedImageView() -> UIImageView {
        return UIImageView()
    }
    
    open func imageDecode(_ data: Data, scale: CGFloat, options: [ImageCoderOptions : Any]? = nil) -> UIImage? {
        return ImageCoder.shared.decodedImage(data: data, scale: scale, options: options)
    }
    
    open func imageEncode(_ image: UIImage, options: [ImageCoderOptions : Any]? = nil) -> Data? {
        let imageFormat = image.fw_imageFormat
        let imageData = ImageCoder.shared.encodedData(image: image, format: imageFormat, options: options)
        if imageData != nil || imageFormat == .undefined {
            return imageData
        }
        return ImageCoder.shared.encodedData(image: image, format: .undefined, options: options)
    }
    
    open func imageURL(_ view: UIView) -> URL? {
        return ImageDownloader.shared.imageURL(for: view)
    }
    
    open func view(_ view: UIView, setImageURL imageURL: URL?, placeholder: UIImage?, options: WebImageOptions = [], context: [ImageCoderOptions : Any]?, setImageBlock block: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)? = nil) {
        let setImageBlock = block ?? { image in
            if let imageView = view as? UIImageView {
                imageView.image = image
            } else if let button = view as? UIButton {
                button.setImage(image, for: .normal)
            }
        }
        
        var progressView: (UIView & ProgressViewPlugin)?
        if showsIndicator {
            if let indicatorView = view.viewWithTag(2061) as? (UIView & ProgressViewPlugin) {
                progressView = indicatorView
            } else {
                if customIndicatorBlock != nil {
                    progressView = customIndicatorBlock?(view)
                } else {
                    let indicator = UIView.fw_progressView(style: .default)
                    indicator.indicatorColor = .gray
                    progressView = indicator
                }
                if let progressView = progressView {
                    progressView.tag = 2061
                    view.addSubview(progressView)
                    progressView.fw_alignCenter()
                }
            }
        }
        if let progressView = progressView {
            view.bringSubviewToFront(progressView)
            progressView.progress = 0.01
            progressView.isHidden = false
        }
        customBlock?(view)
        
        ImageDownloader.shared.downloadImage(for: view, imageURL: imageURL, options: options, context: context, placeholder: {
            setImageBlock(placeholder)
        }, completion: { image, isCache, error in
            if let progressView = progressView {
                progressView.progress = 1
                progressView.isHidden = true
            }
            
            let autoSetImage = image != nil && (!(options.contains(.avoidSetImage)) || completion == nil)
            if autoSetImage, ImagePluginImpl.shared.fadeAnimated, !isCache {
                let originalOperationKey = ImageDownloader.shared.imageOperationKey(for: view)
                UIView.transition(with: view, duration: 0, options: [], animations: {
                    let operationKey = ImageDownloader.shared.imageOperationKey(for: view)
                    if operationKey == nil || operationKey != originalOperationKey { return }
                }, completion: { finished in
                    UIView.transition(with: view, duration: 0.5, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        let operationKey = ImageDownloader.shared.imageOperationKey(for: view)
                        if operationKey == nil || operationKey != originalOperationKey { return }
                        
                        setImageBlock(image)
                    }, completion: nil)
                })
            } else if autoSetImage {
                setImageBlock(image)
            }
            
            completion?(image, error)
        }, progress: progressView != nil ? { value in
            progressView?.progress = value
            progress?(value)
        } : progress)
    }
    
    open func cancelImageRequest(_ view: UIView) {
        ImageDownloader.shared.cancelImageDownloadTask(view)
    }
    
    open func downloadImage(_ imageURL: URL?, options: WebImageOptions = [], context: [ImageCoderOptions : Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return ImageDownloader.shared.downloadImage(forURL: imageURL, options: options, context: context, success: { request, response, responseObject in
            let imageData = ImageResponseSerializer.cachedResponseData(for: responseObject)
            ImageResponseSerializer.clearCachedResponseData(for: responseObject)
            completion(responseObject, imageData, nil)
        }, failure: { request, response, error in
            completion(nil, nil, error)
        }, progress: progress != nil ? { downloadProgress in
            progress?(downloadProgress.fractionCompleted)
        } : nil)
    }
    
    open func cancelImageDownload(_ receipt: Any?) {
        if let receipt = receipt as? ImageDownloadReceipt {
            ImageDownloader.shared.cancelTask(for: receipt)
        }
    }
    
}
