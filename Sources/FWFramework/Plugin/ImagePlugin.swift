//
//  ImagePlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension FW {
    /// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
    public static func image(_ named: String, bundle: Bundle? = nil) -> UIImage? {
        return UIImage.__fw_imageNamed(named, bundle: bundle)
    }
}

extension Wrapper where Base: UIImage {

    /// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)。支持设置图片解码选项
    public static func imageNamed(_ name: String, bundle: Bundle? = nil, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        return Base.__fw_imageNamed(name, bundle: bundle, options: options)
    }

    /// 从图片文件路径解码创建UIImage，自动识别scale，支持动图
    public static func image(contentsOfFile: String) -> UIImage? {
        return Base.__fw_image(withContentsOfFile: contentsOfFile)
    }

    /// 从图片数据解码创建UIImage，默认scale为1，支持动图。支持设置图片解码选项
    public static func image(data: Data?, scale: CGFloat = 1, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        return Base.__fw_image(with: data, scale: scale, options: options)
    }

    /// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
    public static func data(image: UIImage?, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        return Base.__fw_data(with: image, options: options)
    }

    /// 下载网络图片并返回下载凭据
    @discardableResult
    public static func downloadImage(_ url: Any?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return Base.__fw_downloadImage(url, completion: completion, progress: progress)
    }

    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func downloadImage(_ url: Any?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return Base.__fw_downloadImage(url, options: options, context: context, completion: completion, progress: progress)
    }

    /// 指定下载凭据取消网络图片下载
    public static func cancelImageDownload(_ receipt: Any?) {
        Base.__fw_cancelDownload(receipt)
    }
    
}

extension Wrapper where Base: UIImageView {
    
    /// 自定义图片插件，未设置时自动从插件池加载
    public var imagePlugin: ImagePlugin? {
        get { return base.__fw_imagePlugin }
        set { base.__fw_imagePlugin = newValue }
    }

    /// 当前正在加载的网络图片URL
    public var imageURL: URL? {
        return base.__fw_imageURL
    }

    /// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
    public func setImage(url: Any?, placeholderImage: UIImage? = nil, completion: ((UIImage?, Error?) -> Void)? = nil) {
        base.__fw_setImage(withURL: url, placeholderImage: placeholderImage, completion: completion)
    }

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: Any?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        base.__fw_setImage(withURL: url, placeholderImage: placeholderImage, options: options, context: context, completion: completion, progress: progress)
    }

    /// 取消加载网络图片请求
    public func cancelImageRequest() {
        base.__fw_cancelImageRequest()
    }
    
    /// 加载指定URL的本地缓存图片
    public func loadImageCache(url: Any?) -> UIImage? {
        return base.__fw_loadImageCache(withURL: url)
    }
    
    /// 清除所有本地图片缓存
    public static func clearImageCaches(completion: (() -> Void)? = nil) {
        Base.__fw_clearImageCaches(completion)
    }
    
    /// 创建动画ImageView视图，优先加载插件，默认UIImageView
    public static func animatedImageView() -> UIImageView {
        return Base.__fw_animatedImageView()
    }
    
}
