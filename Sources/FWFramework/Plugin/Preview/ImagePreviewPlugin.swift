//
//  ImagePreviewPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - ImagePreviewPlugin
/// 图片预览插件协议，应用可自定义图片预览插件实现
public protocol ImagePreviewPlugin: AnyObject {
    
    /// 显示图片预览方法
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图句柄，支持UIView|NSValue.CGRect，默认nil
    ///   - placeholderImage: 占位图或缩略图句柄，默认nil
    ///   - renderBlock: 自定义渲染句柄，默认nil
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - viewController: 当前视图控制器
    func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)?, customBlock: ((Any) -> Void)?, in viewController: UIViewController)
    
}

extension ImagePreviewPlugin {
    
    /// 显示图片预览方法
    public func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)?, customBlock: ((Any) -> Void)?, in viewController: UIViewController) {
        ImagePreviewPluginImpl.shared.showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: placeholderImage, renderBlock: renderBlock, customBlock: customBlock, in: viewController)
    }
    
}


// MARK: - UIViewController+ImagePreviewPlugin
@_spi(FW) extension UIViewController {
    
    /// 自定义图片预览插件，未设置时自动从插件池加载
    public var fw_imagePreviewPlugin: ImagePreviewPlugin! {
        get {
            if let previewPlugin = fw_property(forName: "fw_imagePreviewPlugin") as? ImagePreviewPlugin {
                return previewPlugin
            } else if let previewPlugin = PluginManager.loadPlugin(ImagePreviewPlugin.self) {
                return previewPlugin
            }
            return ImagePreviewPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_imagePreviewPlugin")
        }
    }
    
    /// 显示图片预览(简单版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图，可选，支持UIView|NSValue.CGRect，默认nil
    public func fw_showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)? = nil) {
        fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: nil, renderBlock: nil, customBlock: nil)
    }

    /// 显示图片预览(详细版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图句柄，支持UIView|NSValue.CGRect，默认nil
    ///   - placeholderImage: 占位图或缩略图句柄，默认nil
    ///   - renderBlock: 自定义渲染句柄，默认nil
    ///   - customBlock: 自定义句柄，默认nil
    public func fw_showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let plugin = self.fw_imagePreviewPlugin ?? ImagePreviewPluginImpl.shared
        plugin.showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: placeholderImage, renderBlock: renderBlock, customBlock: customBlock, in: self)
    }
    
}

@_spi(FW) extension UIView {
    
    /// 显示图片预览(简单版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图，可选，支持UIView|NSValue.CGRect，默认nil
    public func fw_showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)? = nil) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView)
    }

    /// 显示图片预览(详细版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图句柄，支持UIView|NSValue.CGRect，默认nil
    ///   - placeholderImage: 占位图或缩略图句柄，默认nil
    ///   - renderBlock: 自定义渲染句柄，默认nil
    ///   - customBlock: 自定义句柄，默认nil
    public func fw_showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: placeholderImage, renderBlock: renderBlock, customBlock: customBlock)
    }
    
}
