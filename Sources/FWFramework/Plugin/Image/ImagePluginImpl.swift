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
    public static let shared = ImagePluginImpl()

    /// 图片加载完成是否显示渐变动画，默认NO
    open var fadeAnimated: Bool = false

    /// 图片自定义句柄，setImageURL开始时调用
    open var customBlock: ((UIImageView) -> Void)?
    
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
    
    open func imageURL(_ imageView: UIImageView) -> URL? {
        return ImageDownloader.shared.imageURL(for: imageView)
    }
    
    open func imageView(_ imageView: UIImageView, setImageURL imageURL: URL?, placeholder: UIImage?, options: WebImageOptions = [], context: [ImageCoderOptions : Any]?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)? = nil) {
        customBlock?(imageView)
        
        ImageDownloader.shared.downloadImage(for: imageView, imageURL: imageURL, options: options, context: context, placeholder: {
            imageView.image = placeholder
        }, completion: { image, isCache, error in
            let autoSetImage = image != nil && (!(options.contains(.avoidSetImage)) || completion == nil)
            if autoSetImage, ImagePluginImpl.shared.fadeAnimated, !isCache {
                let originalOperationKey = ImageDownloader.shared.imageOperationKey(for: imageView)
                UIView.transition(with: imageView, duration: 0, options: [], animations: {
                    let operationKey = ImageDownloader.shared.imageOperationKey(for: imageView)
                    if operationKey == nil || operationKey != originalOperationKey { return }
                }, completion: { finished in
                    UIView.transition(with: imageView, duration: 0.5, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        let operationKey = ImageDownloader.shared.imageOperationKey(for: imageView)
                        if operationKey == nil || operationKey != originalOperationKey { return }
                        
                        imageView.image = image
                    }, completion: nil)
                })
            } else if autoSetImage {
                imageView.image = image
            }
            
            completion?(image, error)
        }, progress: progress)
    }
    
    open func cancelImageRequest(_ imageView: UIImageView) {
        ImageDownloader.shared.cancelImageDownloadTask(imageView)
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
