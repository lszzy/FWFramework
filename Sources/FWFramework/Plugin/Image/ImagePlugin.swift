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

extension WrapperGlobal {
    
    /// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
    public static func image(_ named: String, bundle: Bundle? = nil) -> UIImage? {
        return UIImage.fw_imageNamed(named, bundle: bundle)
    }
    
}

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
        
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.imageDecode(_:scale:options:))) {
            return imagePlugin.imageDecode?(data, scale: scale, options: options)
        }
        
        var targetScale = scale
        if let scaleFactor = options?[ImageCoderOptions.optionScaleFactor] as? NSNumber {
            targetScale = scaleFactor.doubleValue
        }
        return UIImage(data: data, scale: max(targetScale, 1))
    }

    /// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
    public static func fw_data(image: UIImage?, options: [ImageCoderOptions: Any]? = nil) -> Data? {
        guard let image = image else { return nil }
        
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.imageEncode(_:options:))) {
            return imagePlugin.imageEncode?(image, options: options)
        }
        
        if image.fw_hasAlpha {
            return image.pngData()
        } else {
            return image.jpegData(compressionQuality: 1)
        }
    }

    /// 下载网络图片并返回下载凭据
    @discardableResult
    public static func fw_downloadImage(_ url: Any?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        return fw_downloadImage(url, options: [], context: nil, completion: completion, progress: progress)
    }

    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func fw_downloadImage(_ url: Any?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, completion: @escaping (UIImage?, Data?, Error?) -> Void, progress: ((Double) -> Void)? = nil) -> Any? {
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.downloadImage(_:options:context:completion:progress:))) {
            let imageURL = UIImage.fw_imageURL(for: url)
            return imagePlugin.downloadImage?(imageURL, options: options, context: context, completion: completion, progress: progress)
        }
        return nil
    }

    /// 指定下载凭据取消网络图片下载
    public static func fw_cancelImageDownload(_ receipt: Any?) {
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.cancelImageDownload(_:))) {
            imagePlugin.cancelImageDownload?(receipt)
        }
    }
    
    fileprivate static func fw_imageURL(for url: Any?) -> URL? {
        var imageURL: URL?
        if let string = url as? String, !string.isEmpty {
            imageURL = URL.fw_url(string: string)
        } else if let nsurl = url as? URL {
            imageURL = nsurl
        } else if let urlRequest = url as? URLRequest {
            imageURL = urlRequest.url
        }
        return imageURL
    }
    
}

@_spi(FW) extension UIView {
    
    /// 自定义图片插件，未设置时自动从插件池加载
    public var fw_imagePlugin: ImagePlugin? {
        get {
            if let imagePlugin = fw_property(forName: "fw_imagePlugin") as? ImagePlugin {
                return imagePlugin
            }
            return PluginManager.loadPlugin(ImagePlugin.self)
        }
        set {
            fw_setProperty(newValue, forName: "fw_imagePlugin")
        }
    }

    /// 当前正在加载的网络图片URL
    public var fw_imageURL: URL? {
        if let imagePlugin = self.fw_imagePlugin,
           imagePlugin.responds(to: #selector(ImagePlugin.imageURL(_:))) {
            return imagePlugin.imageURL?(self)
        }
        return nil
    }

    /// 加载网络图片内部方法，支持占位、选项、图片句柄、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: Any?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]?, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?) {
        if let imagePlugin = self.fw_imagePlugin,
           imagePlugin.responds(to: #selector(ImagePlugin.view(_:setImageURL:placeholder:options:context:setImageBlock:completion:progress:))) {
            let imageURL = UIImage.fw_imageURL(for: url)
            imagePlugin.view?(self, setImageURL: imageURL, placeholder: placeholderImage, options: options, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress)
        }
    }

    /// 取消加载网络图片请求
    public func fw_cancelImageRequest() {
        if let imagePlugin = self.fw_imagePlugin,
           imagePlugin.responds(to: #selector(ImagePlugin.cancelImageRequest(_:))) {
            imagePlugin.cancelImageRequest?(self)
        }
    }
    
    /// 加载指定URL的本地缓存图片
    public func fw_loadImageCache(url: Any?) -> UIImage? {
        if let imagePlugin = self.fw_imagePlugin,
           imagePlugin.responds(to: #selector(ImagePlugin.loadImageCache(_:))) {
            let imageURL = UIImage.fw_imageURL(for: url)
            return imagePlugin.loadImageCache?(imageURL)
        }
        
        return nil
    }
    
    /// 是否隐藏全局图片加载指示器，默认false，仅全局图片指示器开启时生效
    public var fw_hidesImageIndicator: Bool {
        get { fw_propertyBool(forName: #function) }
        set { fw_setPropertyBool(newValue, forName: #function) }
    }
    
}

@_spi(FW) extension UIImageView {

    /// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: Any?, placeholderImage: UIImage? = nil, completion: ((UIImage?, Error?) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: [], context: nil, completion: completion, progress: nil)
    }

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: Any?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }
    
    /// 加载指定URL的本地缓存图片
    public static func fw_loadImageCache(url: Any?) -> UIImage? {
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.loadImageCache(_:))) {
            let imageURL = UIImage.fw_imageURL(for: url)
            return imagePlugin.loadImageCache?(imageURL)
        }
        
        return nil
    }

    /// 清除所有本地图片缓存
    public static func fw_clearImageCaches(completion: (() -> Void)? = nil) {
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.clearImageCaches(_:))) {
            imagePlugin.clearImageCaches?(completion)
        }
    }
    
    /// 创建动画ImageView视图，优先加载插件，默认UIImageView
    public static func fw_animatedImageView() -> UIImageView {
        if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self),
           imagePlugin.responds(to: #selector(ImagePlugin.animatedImageView)) {
            return imagePlugin.animatedImageView!()
        }
        
        return UIImageView()
    }
    
}

@_spi(FW) extension UIButton {

    /// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: Any?, placeholderImage: UIImage? = nil, completion: ((UIImage?, Error?) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: [], context: nil, completion: completion, progress: nil)
    }

    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func fw_setImage(url: Any?, placeholderImage: UIImage?, options: WebImageOptions, context: [ImageCoderOptions: Any]? = nil, completion: ((UIImage?, Error?) -> Void)? = nil, progress: ((Double) -> Void)? = nil) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }
    
}

// MARK: - ImagePluginAutoloader
internal class ImagePluginAutoloader: AutoloadProtocol {
    
    static func autoload() {
        PluginManager.presetPlugin(ImagePlugin.self, object: ImagePluginImpl.self)
    }
    
}
