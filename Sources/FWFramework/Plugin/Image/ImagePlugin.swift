//
//  ImagePlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
    public static func image(_ named: String, bundle: Bundle? = nil) -> UIImage? {
        return UIImage.fw_imageNamed(named, bundle: bundle)
    }
}

// MARK: - Wrapper+UIImage
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

    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return Base.fw_downloadImage(url, options: options, context: context, completion: completion, progress: progress)
    }

    /// 指定下载凭据取消网络图片下载
    public static func cancelImageDownload(_ receipt: Any?) {
        Base.fw_cancelImageDownload(receipt)
    }
}

// MARK: - Wrapper+UIView
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

// MARK: - Wrapper+UIImageView
extension Wrapper where Base: UIImageView {
    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage? = nil, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
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

// MARK: - Wrapper+UIButton
extension Wrapper where Base: UIButton {
    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(url: URLParameter?, placeholderImage: UIImage? = nil, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        base.fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, completion: completion, progress: progress)
    }
}

// MARK: - ImagePlugin
/// 网络图片加载选项，默认兼容SDWebImage
public struct WebImageOptions: OptionSet {
    
    public let rawValue: UInt
    
    /// 是否图片缓存存在时仍重新请求(依赖NSURLCache)
    public static let refreshCached: WebImageOptions = .init(rawValue: 1 << 3)
    /// 是否延迟占位，将加载占位图作为错误占位图
    public static let delayPlaceholder: WebImageOptions = .init(rawValue: 1 << 8)
    /// 禁止调用imageView.setImage:显示图片
    public static let avoidSetImage: WebImageOptions = .init(rawValue: 1 << 10)
    /// 忽略图片缓存，始终重新请求
    public static let ignoreCache: WebImageOptions = .init(rawValue: 1 << 16)
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

/// 图片插件协议，应用可自定义图片插件
public protocol ImagePlugin: AnyObject {
    /// 获取view正在加载的URL插件方法
    func imageURL(for view: UIView) -> URL?
    
    /// view加载网络图片插件方法
    func setImageURL(url: URL?, placeholder: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?, for view: UIView)
    
    /// view取消加载网络图片请求插件方法
    func cancelImageRequest(for view: UIView)
    
    /// 加载指定URL的本地缓存图片
    func loadImageCache(_ imageURL: URL?) -> UIImage?
    
    /// 清除所有本地图片缓存
    func clearImageCaches(_ completion: (() -> Void)?)
    
    /// image下载网络图片插件方法，返回下载凭据
    func downloadImage(_ imageURL: URL?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)?) -> Any?
    
    /// image取消下载网络图片插件方法，指定下载凭据
    func cancelImageDownload(_ receipt: Any?)
    
    /// 创建动画视图插件方法，默认使用UIImageView
    func animatedImageView() -> UIImageView
    
    /// image本地解码插件方法，默认使用系统方法
    func imageDecode(_ data: Data, scale: CGFloat, options: [ImageCoderOptions: Any]?) -> UIImage?
    
    /// image本地编码插件方法，默认使用系统方法
    func imageEncode(_ image: UIImage, options: [ImageCoderOptions: Any]?) -> Data?
}

extension ImagePlugin {
    
    /// 获取view正在加载的URL插件方法
    public func imageURL(for view: UIView) -> URL? {
        return ImagePluginImpl.shared.imageURL(for: view)
    }
    
    /// view加载网络图片插件方法
    public func setImageURL(url: URL?, placeholder: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?, for view: UIView) {
        ImagePluginImpl.shared.setImageURL(url: url, placeholder: placeholder, options: options, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress, for: view)
    }
    
    /// view取消加载网络图片请求插件方法
    public func cancelImageRequest(for view: UIView) {
        ImagePluginImpl.shared.cancelImageRequest(for: view)
    }
    
    /// 加载指定URL的本地缓存图片
    public func loadImageCache(_ imageURL: URL?) -> UIImage? {
        return ImagePluginImpl.shared.loadImageCache(imageURL)
    }
    
    /// 清除所有本地图片缓存
    public func clearImageCaches(_ completion: (() -> Void)?) {
        ImagePluginImpl.shared.clearImageCaches(completion)
    }
    
    /// image下载网络图片插件方法，返回下载凭据
    public func downloadImage(_ imageURL: URL?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)?) -> Any? {
        return ImagePluginImpl.shared.downloadImage(imageURL, options: options, context: context, completion: completion, progress: progress)
    }
    
    /// image取消下载网络图片插件方法，指定下载凭据
    public func cancelImageDownload(_ receipt: Any?) {
        ImagePluginImpl.shared.cancelImageDownload(receipt)
    }
    
    /// 创建动画视图插件方法，默认使用UIImageView
    public func animatedImageView() -> UIImageView {
        return ImagePluginImpl.shared.animatedImageView()
    }
    
    /// image本地解码插件方法，默认使用系统方法
    public func imageDecode(_ data: Data, scale: CGFloat, options: [ImageCoderOptions: Any]?) -> UIImage? {
        return ImagePluginImpl.shared.imageDecode(data, scale: scale, options: options)
    }
    
    /// image本地编码插件方法，默认使用系统方法
    public func imageEncode(_ image: UIImage, options: [ImageCoderOptions: Any]?) -> Data? {
        return ImagePluginImpl.shared.imageEncode(image, options: options)
    }
    
}

// MARK: - UIView+ImagePlugin
@_spi(FW) extension UIImage {

    /// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)。支持设置图片解码选项
    public static func fw_imageNamed(_ name: String, bundle: Bundle? = nil, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        if name.isEmpty || name.hasSuffix("/") { return nil }
        if (name as NSString).isAbsolutePath {
            let data = NSData(contentsOfFile: name)
            let scale = fw_stringPathScale(name)
            return fw_image(data: data as? Data, scale: scale, options: options)
        }
        
        var path: String?
        var scale: CGFloat = 1
        let bundle = bundle ?? Bundle.main
        let res = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let exts = !ext.isEmpty ? [ext] : ["", "png", "jpeg", "jpg", "gif", "webp", "apng", "svg"]
        let scales = fw_bundlePreferredScales()
        for s in scales {
            scale = s
            let scaledName = fw_appendingNameScale(res, scale: scale)
            for e in exts {
                path = bundle.path(forResource: scaledName, ofType: e)
                if path != nil { break }
            }
            if path != nil { break }
        }
        
        var data: Data?
        if let path = path, !path.isEmpty {
            data = NSData(contentsOfFile: path) as? Data
        }
        if (data?.count ?? 0) < 1 {
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return fw_image(data: data, scale: scale, options: options)
    }
    
    private static func fw_bundlePreferredScales() -> [CGFloat] {
        let screenScale = UIScreen.main.scale
        if screenScale <= 1 {
            return [1, 2, 3]
        } else if screenScale <= 2 {
            return [2, 3, 1]
        } else {
            return [3, 2, 1]
        }
    }
    
    private static func fw_appendingNameScale(_ string: String, scale: CGFloat) -> String {
        if abs(scale - 1) <= CGFloat.leastNonzeroMagnitude || string.isEmpty || string.hasSuffix("/") { return string }
        return string.appendingFormat("@%@x", NSNumber(value: scale))
    }
    
    private static func fw_stringPathScale(_ string: String) -> CGFloat {
        if string.isEmpty || string.hasSuffix("/") { return 1 }
        let name = (string as NSString).deletingPathExtension
        var scale: CGFloat = 1
        let pattern = try? NSRegularExpression(pattern: "@[0-9]+\\.?[0-9]*x$", options: .anchorsMatchLines)
        pattern?.enumerateMatches(in: name, options: [], range: NSMakeRange(0, (name as NSString).length), using: { result, _, _ in
            if let result = result, result.range.location >= 3 {
                let scaleString = (string as NSString).substring(with: NSMakeRange(result.range.location + 1, result.range.length - 1))
                scale = (scaleString as NSString).doubleValue
            }
        })
        return scale
    }

    /// 从图片文件路径解码创建UIImage，自动识别scale，支持动图
    public static func fw_image(contentsOfFile path: String) -> UIImage? {
        let data = NSData(contentsOfFile: path) as? Data
        let scale = fw_stringPathScale(path)
        return fw_image(data: data, scale: scale)
    }

    /// 从图片数据解码创建UIImage，默认scale为1，支持动图。支持设置图片解码选项
    public static func fw_image(data: Data?, scale: CGFloat = 1, options: [ImageCoderOptions: Any]? = nil) -> UIImage? {
        guard let data = data, data.count > 0 else { return nil }
        
        let imagePlugin: ImagePlugin? = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        if let imagePlugin = imagePlugin {
            return imagePlugin.imageDecode(data, scale: scale, options: options)
        }
        
        var targetScale = scale
        if let scaleFactor = options?[.scaleFactor] as? NSNumber {
            targetScale = scaleFactor.doubleValue
        }
        return UIImage(data: data, scale: max(targetScale, 1))
    }

    /// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
    public static func fw_data(image: UIImage?, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        guard let image = image else { return nil }
        
        let imagePlugin: ImagePlugin? = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        if let imagePlugin = imagePlugin {
            return imagePlugin.imageEncode(image, options: options)
        }
        
        if image.fw_hasAlpha {
            return image.pngData()
        } else {
            return image.jpegData(compressionQuality: 1)
        }
    }

    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func fw_downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        let imageURL = url?.urlValue
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        return imagePlugin.downloadImage(imageURL, options: options, context: context, completion: completion, progress: progress)
    }

    /// 指定下载凭据取消网络图片下载
    public static func fw_cancelImageDownload(_ receipt: Any?) {
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        imagePlugin.cancelImageDownload(receipt)
    }
    
}

@_spi(FW) extension UIView {
    
    /// 自定义图片插件，未设置时自动从插件池加载
    public var fw_imagePlugin: ImagePlugin! {
        get {
            if let imagePlugin = fw_property(forName: "fw_imagePlugin") as? ImagePlugin {
                return imagePlugin
            } else if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) {
                return imagePlugin
            }
            return ImagePluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_imagePlugin")
        }
    }

    /// 当前正在加载的网络图片URL
    public var fw_imageURL: URL? {
        let imagePlugin = self.fw_imagePlugin ?? ImagePluginImpl.shared
        return imagePlugin.imageURL(for: self)
    }

    /// 加载网络图片内部方法，支持占位、选项、图片句柄、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: URLParameter?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?) {
        // 兼容URLRequest.cachePolicy缓存策略
        var targetOptions = options
        if let urlRequest = url as? URLRequest,
            (urlRequest.cachePolicy == .reloadIgnoringLocalCacheData ||
             urlRequest.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData ||
             urlRequest.cachePolicy == .reloadIgnoringCacheData) {
            targetOptions.formUnion(.ignoreCache)
        }
        
        let imageURL = url?.urlValue
        let imagePlugin = self.fw_imagePlugin ?? ImagePluginImpl.shared
        imagePlugin.setImageURL(url: imageURL, placeholder: placeholderImage, options: targetOptions, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress, for: self)
    }

    /// 取消加载网络图片请求
    public func fw_cancelImageRequest() {
        let imagePlugin = self.fw_imagePlugin ?? ImagePluginImpl.shared
        imagePlugin.cancelImageRequest(for: self)
    }
    
    /// 加载指定URL的本地缓存图片
    public func fw_loadImageCache(url: URLParameter?) -> UIImage? {
        let imageURL = url?.urlValue
        let imagePlugin = self.fw_imagePlugin ?? ImagePluginImpl.shared
        return imagePlugin.loadImageCache(imageURL)
    }
    
    /// 是否隐藏全局图片加载指示器，默认false，仅全局图片指示器开启时生效
    public var fw_hidesImageIndicator: Bool {
        get { fw_propertyBool(forName: #function) }
        set { fw_setPropertyBool(newValue, forName: #function) }
    }
    
}

@_spi(FW) extension UIImageView {

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: URLParameter?, placeholderImage: UIImage? = nil, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }
    
    /// 加载指定URL的本地缓存图片
    public static func fw_loadImageCache(url: URLParameter?) -> UIImage? {
        let imageURL = url?.urlValue
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        return imagePlugin.loadImageCache(imageURL)
    }

    /// 清除所有本地图片缓存
    public static func fw_clearImageCaches(completion: (() -> Void)? = nil) {
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        imagePlugin.clearImageCaches(completion)
    }
    
    /// 创建动画ImageView视图，优先加载插件，默认UIImageView
    public static func fw_animatedImageView() -> UIImageView {
        let imagePlugin: ImagePlugin? = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        if let imagePlugin = imagePlugin {
            return imagePlugin.animatedImageView()
        }
        
        return UIImageView()
    }
    
}

@_spi(FW) extension UIButton {

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: URLParameter?, placeholderImage: UIImage? = nil, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }
    
}

// MARK: - Concurrency+ImagePlugin
#if compiler(>=5.6.0) && canImport(_Concurrency)
extension Wrapper where Base: UIImage {
    /// 异步下载网络图片
    public static func downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil) async throws -> UIImage {
        try await Base.fw_downloadImage(url, options: options, context: context)
    }
}

@_spi(FW) extension UIImage {
    
    /// 异步下载网络图片
    public static func fw_downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil) async throws -> UIImage {
        let target = NSObject()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                target.fw_tempObject = UIImage.fw_downloadImage(url, options: options, context: context) { image, _, error in
                    if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: error ?? RequestError.unknown)
                    }
                }
            }
        } onCancel: {
            UIImage.fw_cancelImageDownload(target.fw_tempObject)
        }
    }
    
}
#endif

// MARK: - FrameworkAutoloader+ImagePlugin
extension FrameworkAutoloader {
    
    @objc static func loadPlugin_ImagePlugin() {
        ModuleBundle.imageNamedBlock = { name, bundle in
            return UIImage.fw_imageNamed(name, bundle: bundle)
        }
        
        ImageResponseSerializer.imageDecodeBlock = { data, scale, options in
            return UIImage.fw_image(data: data, scale: scale, options: options)
        }
    }
    
}
