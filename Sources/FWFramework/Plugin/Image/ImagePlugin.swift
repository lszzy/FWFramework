//
//  ImagePlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIImage
extension Wrapper where Base: UIImage {
    /// 下载网络图片并返回下载凭据，指定option
    @discardableResult
    public static func downloadImage(
        _ url: URLParameter?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]? = nil,
        completion: @escaping @MainActor @Sendable (UIImage?, Data?, Error?) -> Void,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil
    ) -> Any? {
        let imageURL = url?.urlValue
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        return imagePlugin.downloadImage(imageURL, options: options, context: context, completion: completion, progress: progress)
    }

    /// 指定下载凭据取消网络图片下载
    public static func cancelImageDownload(_ receipt: Any?) {
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        imagePlugin.cancelImageDownload(receipt)
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 自定义图片插件，未设置时自动从插件池加载
    public var imagePlugin: ImagePlugin? {
        get {
            if let imagePlugin = property(forName: "imagePlugin") as? ImagePlugin {
                return imagePlugin
            } else if let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) {
                return imagePlugin
            }
            return ImagePluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "imagePlugin")
        }
    }

    /// 当前正在加载的网络图片URL
    public var imageURL: URL? {
        let imagePlugin = imagePlugin ?? ImagePluginImpl.shared
        return imagePlugin.imageURL(for: base)
    }

    /// 加载网络图片内部方法，支持占位、选项、图片句柄、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(
        url: URLParameter?,
        placeholderImage: UIImage?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        setImageBlock: (@MainActor @Sendable (UIImage?) -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)?
    ) {
        // 兼容URLRequest.cachePolicy缓存策略
        var targetOptions = options
        if let urlRequest = url as? URLRequest,
           urlRequest.cachePolicy == .reloadIgnoringLocalCacheData ||
           urlRequest.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData ||
           urlRequest.cachePolicy == .reloadIgnoringCacheData {
            targetOptions.formUnion(.ignoreCache)
        }

        let imageURL = url?.urlValue
        let imagePlugin = imagePlugin ?? ImagePluginImpl.shared
        imagePlugin.setImageURL(url: imageURL, placeholder: placeholderImage, options: targetOptions, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress, for: base)
    }

    /// 取消加载网络图片请求
    public func cancelImageRequest() {
        let imagePlugin = imagePlugin ?? ImagePluginImpl.shared
        imagePlugin.cancelImageRequest(for: base)
    }

    /// 加载指定URL的本地缓存图片
    public func loadImageCache(url: URLParameter?) -> UIImage? {
        let imageURL = url?.urlValue
        let imagePlugin = imagePlugin ?? ImagePluginImpl.shared
        return imagePlugin.loadImageCache(imageURL)
    }

    /// 是否隐藏全局图片加载指示器，默认false，仅全局图片指示器开启时生效
    public var hidesImageIndicator: Bool {
        get { propertyBool(forName: #function) }
        set { setPropertyBool(newValue, forName: #function) }
    }
}

// MARK: - Wrapper+UIImageView
@MainActor extension Wrapper where Base: UIImageView {
    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(
        url: URLParameter?,
        placeholderImage: UIImage? = nil,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]? = nil,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)? = nil,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil
    ) {
        setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }

    /// 加载指定URL的本地缓存图片
    public nonisolated static func loadImageCache(url: URLParameter?) -> UIImage? {
        let imageURL = url?.urlValue
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        return imagePlugin.loadImageCache(imageURL)
    }

    /// 清除所有本地图片缓存
    public nonisolated static func clearImageCaches(completion: (@MainActor @Sendable () -> Void)? = nil) {
        let imagePlugin = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        imagePlugin.clearImageCaches(completion)
    }

    /// 创建动画ImageView视图，优先加载插件，默认UIImageView
    public static func animatedImageView() -> UIImageView {
        let imagePlugin: ImagePlugin? = PluginManager.loadPlugin(ImagePlugin.self) ?? ImagePluginImpl.shared
        if let imagePlugin {
            return imagePlugin.animatedImageView()
        }

        return UIImageView()
    }
}

// MARK: - Wrapper+UIButton
@MainActor extension Wrapper where Base: UIButton {
    /// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
    public func setImage(
        url: URLParameter?,
        placeholderImage: UIImage? = nil,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]? = nil,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)? = nil,
        progress: (@MainActor @Sendable (Double) -> Void)? = nil
    ) {
        setImage(url: url, placeholderImage: placeholderImage, options: options, context: context, setImageBlock: nil, completion: completion, progress: progress)
    }
}

// MARK: - ImagePlugin
/// 网络图片加载选项，默认兼容SDWebImage
public struct WebImageOptions: OptionSet, Sendable {
    public let rawValue: UInt

    /// 是否图片缓存存在时仍重新请求(依赖NSURLCache)
    public static let refreshCached: WebImageOptions = .init(rawValue: 1 << 3)
    /// 是否延迟占位，将加载占位图作为错误占位图
    public static let delayPlaceholder: WebImageOptions = .init(rawValue: 1 << 8)
    /// 禁止调用imageView.setImage:显示图片
    public static let avoidSetImage: WebImageOptions = .init(rawValue: 1 << 10)
    /// 图片缓存存在时是否查询Data数据
    public static let queryMemoryData: WebImageOptions = .init(rawValue: 1 << 12)
    /// 忽略图片缓存，始终重新请求
    public static let ignoreCache: WebImageOptions = .init(rawValue: 1 << 16)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

/// 图片插件协议，应用可自定义图片插件
public protocol ImagePlugin: AnyObject {
    /// 创建动画视图插件方法，默认使用UIImageView
    @MainActor func animatedImageView() -> UIImageView

    /// 获取view正在加载的URL插件方法
    @MainActor func imageURL(for view: UIView) -> URL?

    /// view加载网络图片插件方法
    @MainActor func setImageURL(
        url: URL?,
        placeholder: UIImage?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        setImageBlock: (@MainActor @Sendable (UIImage?) -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)?,
        for view: UIView
    )

    /// view取消加载网络图片请求插件方法
    @MainActor func cancelImageRequest(for view: UIView)

    /// 加载指定URL的本地缓存图片
    func loadImageCache(_ imageURL: URL?) -> UIImage?

    /// 清除所有本地图片缓存
    func clearImageCaches(_ completion: (@MainActor @Sendable () -> Void)?)

    /// image下载网络图片插件方法，返回下载凭据
    func downloadImage(
        _ imageURL: URL?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        completion: @escaping @MainActor @Sendable (UIImage?, Data?, Error?) -> Void,
        progress: (@MainActor @Sendable (Double) -> Void)?
    ) -> Any?

    /// image取消下载网络图片插件方法，指定下载凭据
    func cancelImageDownload(_ receipt: Any?)
}

extension ImagePlugin {
    /// 创建动画视图插件方法，默认使用UIImageView
    @MainActor public func animatedImageView() -> UIImageView {
        ImagePluginImpl.shared.animatedImageView()
    }

    /// 获取view正在加载的URL插件方法
    @MainActor public func imageURL(for view: UIView) -> URL? {
        ImagePluginImpl.shared.imageURL(for: view)
    }

    /// view加载网络图片插件方法
    @MainActor public func setImageURL(
        url: URL?,
        placeholder: UIImage?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        setImageBlock: (@MainActor @Sendable (UIImage?) -> Void)?,
        completion: (@MainActor @Sendable (UIImage?, Error?) -> Void)?,
        progress: (@MainActor @Sendable (Double) -> Void)?,
        for view: UIView
    ) {
        ImagePluginImpl.shared.setImageURL(url: url, placeholder: placeholder, options: options, context: context, setImageBlock: setImageBlock, completion: completion, progress: progress, for: view)
    }

    /// view取消加载网络图片请求插件方法
    @MainActor public func cancelImageRequest(for view: UIView) {
        ImagePluginImpl.shared.cancelImageRequest(for: view)
    }

    /// 加载指定URL的本地缓存图片
    public func loadImageCache(_ imageURL: URL?) -> UIImage? {
        ImagePluginImpl.shared.loadImageCache(imageURL)
    }

    /// 清除所有本地图片缓存
    public func clearImageCaches(_ completion: (@MainActor @Sendable () -> Void)?) {
        ImagePluginImpl.shared.clearImageCaches(completion)
    }

    /// image下载网络图片插件方法，返回下载凭据
    public func downloadImage(
        _ imageURL: URL?,
        options: WebImageOptions,
        context: [ImageCoderOptions: Any]?,
        completion: @escaping @MainActor @Sendable (UIImage?, Data?, Error?) -> Void,
        progress: (@MainActor @Sendable (Double) -> Void)?
    ) -> Any? {
        ImagePluginImpl.shared.downloadImage(imageURL, options: options, context: context, completion: completion, progress: progress)
    }

    /// image取消下载网络图片插件方法，指定下载凭据
    public func cancelImageDownload(_ receipt: Any?) {
        ImagePluginImpl.shared.cancelImageDownload(receipt)
    }
}

// MARK: - Concurrency+ImagePlugin
extension Wrapper where Base: UIImage {
    /// 异步下载网络图片
    public static func downloadImage(
        _ url: URLParameter?,
        options: WebImageOptions = [],
        context: [ImageCoderOptions: Any]? = nil
    ) async throws -> UIImage {
        let sendableTarget = SendableValue(NSObject())
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let receipt = UIImage.fw.downloadImage(url, options: options, context: context) { image, _, error in
                    if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: error ?? RequestError.unknown)
                    }
                }
                sendableTarget.value.fw.setProperty(receipt, forName: #function)
            }
        } onCancel: {
            let receipt = sendableTarget.value.fw.property(forName: #function)
            UIImage.fw.cancelImageDownload(receipt)
        }
    }
}
