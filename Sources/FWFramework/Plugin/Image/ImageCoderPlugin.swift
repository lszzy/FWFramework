//
//  ImageCoderPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/8.
//

import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
    public static func image(_ named: String, bundle: Bundle? = nil) -> UIImage? {
        UIImage.fw.imageNamed(named, bundle: bundle)
    }
}

// MARK: - Wrapper+UIImage
extension Wrapper where Base: UIImage {
    /// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)。支持设置图片解码选项
    public static func imageNamed(
        _ name: String,
        bundle: Bundle? = nil,
        options: [ImageCoderOptions: Any]? = nil
    ) -> UIImage? {
        if name.isEmpty || name.hasSuffix("/") { return nil }
        if (name as NSString).isAbsolutePath {
            let data = NSData(contentsOfFile: name)
            let scale = stringPathScale(name)
            return image(data: data as? Data, scale: scale, options: options)
        }

        var path: String?
        var scale: CGFloat = 1
        let bundle = bundle ?? Bundle.main
        let res = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let exts = !ext.isEmpty ? [ext] : ["", "png", "jpeg", "jpg", "gif", "webp", "apng", "svg"]
        let scales = bundlePreferredScales()
        for s in scales {
            scale = s
            let scaledName = appendingNameScale(res, scale: scale)
            for e in exts {
                path = bundle.path(forResource: scaledName, ofType: e)
                if path != nil { break }
            }
            if path != nil { break }
        }

        var data: Data?
        if let path, !path.isEmpty {
            data = NSData(contentsOfFile: path) as? Data
        }
        if (data?.count ?? 0) < 1 {
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return image(data: data, scale: scale, options: options)
    }

    private static func bundlePreferredScales() -> [CGFloat] {
        let screenScale = UIScreen.fw.screenScale
        if screenScale <= 1 {
            return [1, 2, 3]
        } else if screenScale <= 2 {
            return [2, 3, 1]
        } else {
            return [3, 2, 1]
        }
    }

    private static func appendingNameScale(_ string: String, scale: CGFloat) -> String {
        if abs(scale - 1) <= CGFloat.leastNonzeroMagnitude || string.isEmpty || string.hasSuffix("/") { return string }
        return string.appendingFormat("@%@x", NSNumber(value: scale))
    }

    private static func stringPathScale(_ string: String) -> CGFloat {
        if string.isEmpty || string.hasSuffix("/") { return 1 }
        let name = (string as NSString).deletingPathExtension
        var scale: CGFloat = 1
        let pattern = try? NSRegularExpression(pattern: "@[0-9]+\\.?[0-9]*x$", options: .anchorsMatchLines)
        pattern?.enumerateMatches(in: name, options: [], range: NSMakeRange(0, (name as NSString).length), using: { result, _, _ in
            if let result, result.range.location >= 3 {
                let scaleString = (string as NSString).substring(with: NSMakeRange(result.range.location + 1, result.range.length - 1))
                scale = (scaleString as NSString).doubleValue
            }
        })
        return scale
    }

    /// 从图片文件路径解码创建UIImage，自动识别scale，支持动图
    public static func image(contentsOfFile path: String) -> UIImage? {
        let data = NSData(contentsOfFile: path) as? Data
        let scale = stringPathScale(path)
        return image(data: data, scale: scale)
    }

    /// 从图片数据解码创建UIImage，默认scale为1，支持动图。支持设置图片解码选项
    public static func image(
        data: Data?,
        scale: CGFloat = 1,
        options: [ImageCoderOptions: Any]? = nil
    ) -> UIImage? {
        guard let data, data.count > 0 else { return nil }

        let imageCoderPlugin: ImageCoderPlugin? = PluginManager.loadPlugin(ImageCoderPlugin.self) ?? ImagePluginImpl.shared
        if let imageCoderPlugin {
            return imageCoderPlugin.imageDecode(data, scale: scale, options: options)
        }

        var targetScale = scale
        if let scaleFactor = options?[.scaleFactor] as? NSNumber {
            targetScale = scaleFactor.doubleValue
        }
        return UIImage(data: data, scale: max(targetScale, 1))
    }

    /// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
    public static func data(
        image: UIImage?,
        options: [ImageCoderOptions: Any]? = nil
    ) -> Data? {
        guard let image else { return nil }

        let imageCoderPlugin: ImageCoderPlugin? = PluginManager.loadPlugin(ImageCoderPlugin.self) ?? ImagePluginImpl.shared
        if let imageCoderPlugin {
            return imageCoderPlugin.imageEncode(image, options: options)
        }

        if image.fw.hasAlpha {
            return image.pngData()
        } else {
            return image.jpegData(compressionQuality: 1)
        }
    }
}

// MARK: - ImageCoderPlugin
/// 图片解码器插件协议，应用可自定义图片解码器插件
public protocol ImageCoderPlugin: AnyObject {
    /// image本地解码插件方法，默认使用系统方法
    func imageDecode(
        _ data: Data,
        scale: CGFloat,
        options: [ImageCoderOptions: Any]?
    ) -> UIImage?

    /// image本地编码插件方法，默认使用系统方法
    func imageEncode(
        _ image: UIImage,
        options: [ImageCoderOptions: Any]?
    ) -> Data?
}

extension ImageCoderPlugin {
    /// image本地解码插件方法，默认使用系统方法
    public func imageDecode(
        _ data: Data,
        scale: CGFloat,
        options: [ImageCoderOptions: Any]?
    ) -> UIImage? {
        ImagePluginImpl.shared.imageDecode(data, scale: scale, options: options)
    }

    /// image本地编码插件方法，默认使用系统方法
    public func imageEncode(
        _ image: UIImage,
        options: [ImageCoderOptions: Any]?
    ) -> Data? {
        ImagePluginImpl.shared.imageEncode(image, options: options)
    }
}

// MARK: - FrameworkAutoloader+ImagePlugin
extension FrameworkAutoloader {
    @objc static func loadPlugin_ImagePlugin() {
        ModuleBundle.imageNamedBlock = { name, bundle in
            UIImage.fw.imageNamed(name, bundle: bundle)
        }

        ImageResponseSerializer.imageDecodeBlock = { data, scale, options in
            UIImage.fw.image(data: data, scale: scale, options: options)
        }
    }
}
