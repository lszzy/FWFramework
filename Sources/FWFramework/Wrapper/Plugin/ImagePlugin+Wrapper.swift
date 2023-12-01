//
//  ImagePlugin+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WrapperGlobal+ImagePlugin
extension WrapperGlobal {
    
    /// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
    public static func image(_ named: String, bundle: Bundle? = nil) -> UIImage? {
        return UIImage.fw_imageNamed(named, bundle: bundle)
    }
    
}

// MARK: - Wrapper+ImagePlugin
extension Wrapper where Base: UIImage {

    /// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)。支持设置图片解码选项
    public static func imageNamed(_ name: String, bundle: Bundle? = nil, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        return Base.fw_imageNamed(name, bundle: bundle, options: options)
    }

    /// 从图片文件路径解码创建UIImage，自动识别scale，支持动图
    public static func image(contentsOfFile: String) -> UIImage? {
        return Base.fw_image(contentsOfFile: contentsOfFile)
    }

    /// 从图片数据解码创建UIImage，默认scale为1，支持动图。支持设置图片解码选项
    public static func image(data: Data?, scale: CGFloat = 1, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        return Base.fw_image(data: data, scale: scale, options: options)
    }

    /// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
    public static func data(image: UIImage?, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        return Base.fw_data(image: image, options: options)
    }

    /// 下载网络图片并返回下载凭据
    @discardableResult
    public static func downloadImage(_ url: URLParameter?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return Base.fw_downloadImage(url, completion: completion, progress: progress)
    }

    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func downloadImage(_ url: URLParameter?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return Base.fw_downloadImage(url, options: options, context: context, completion: completion, progress: progress)
    }

    /// 指定下载凭据取消网络图片下载
    public static func cancelImageDownload(_ receipt: Any?) {
        Base.fw_cancelImageDownload(receipt)
    }
    
}

extension Wrapper where Base: UIView {
    
    /// 自定义图片插件，未设置时自动从插件池加载
    public var imagePlugin: ImagePlugin? {
        get { return base.fw_imagePlugin }
        set { base.fw_imagePlugin = newValue }
    }

    /// 当前正在加载的网络图片URL
    public var imageURL: URL? {
        return base.fw_imageURL
    }
    
    /// 加载网络图片内部方法，支持占位、选项、图片句柄、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress)
    }

    /// 取消加载网络图片请求
    public func cancelImageRequest() {
        base.fw_cancelImageRequest()
    }
    
    /// 加载指定URL的本地缓存图片
    public func loadImageCache(url: URLParameter?) -> UIImage? {
        return base.fw_loadImageCache(url: url)
    }
    
    /// 是否隐藏全局图片加载指示器，默认false，仅全局图片指示器开启时生效
    public var hidesImageIndicator: Bool {
        get { base.fw_hidesImageIndicator }
        set { base.fw_hidesImageIndicator = newValue }
    }
    
}

extension Wrapper where Base: UIImageView {

    /// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage? = nil, completion: ((UIImage?, Error?) -> Void)? = nil) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, completion: completion)
    }

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, completion: completion, progress: progress)
    }
    
    /// 加载指定URL的本地缓存图片
    public static func loadImageCache(url: URLParameter?) -> UIImage? {
        return Base.fw_loadImageCache(url: url)
    }

    /// 清除所有本地图片缓存
    public static func clearImageCaches(completion: (() -> Void)? = nil) {
        Base.fw_clearImageCaches(completion: completion)
    }
    
    /// 创建动画ImageView视图，优先加载插件，默认UIImageView
    public static func animatedImageView() -> UIImageView {
        return Base.fw_animatedImageView()
    }
    
}

extension Wrapper where Base: UIButton {
    
    /// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage? = nil, completion: ((UIImage?, Error?) -> Void)? = nil) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, completion: completion)
    }

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, completion: completion, progress: progress)
    }
    
}
