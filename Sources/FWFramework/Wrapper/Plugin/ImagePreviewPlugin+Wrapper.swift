//
//  ImagePreviewPlugin+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: UIViewController {
    
    /// 自定义图片预览插件，未设置时自动从插件池加载
    public var imagePreviewPlugin: ImagePreviewPlugin! {
        get { return base.fw_imagePreviewPlugin }
        set { base.fw_imagePreviewPlugin = newValue }
    }
    
    /// 显示图片预览(简单版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图，可选，支持UIView|NSValue.CGRect，默认nil
    public func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)? = nil) {
        base.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView)
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
    public func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: placeholderImage, renderBlock: renderBlock, customBlock: customBlock)
    }
    
}

extension Wrapper where Base: UIView {
    
    /// 显示图片预览(简单版)
    /// - Parameters:
    ///   - imageURLs: 预览图片列表，支持NSString|UIImage|PHLivePhoto|AVPlayerItem类型
    ///   - imageInfos: 自定义图片信息数组
    ///   - currentIndex: 当前索引，默认0
    ///   - sourceView: 来源视图，可选，支持UIView|NSValue.CGRect，默认nil
    public func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)? = nil) {
        base.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView)
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
    public func showImagePreview(imageURLs: [Any], imageInfos: [Any]?, currentIndex: Int, sourceView: ((Int) -> Any?)?, placeholderImage: ((Int) -> UIImage?)?, renderBlock: ((UIView, Int) -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showImagePreview(imageURLs: imageURLs, imageInfos: imageInfos, currentIndex: currentIndex, sourceView: sourceView, placeholderImage: placeholderImage, renderBlock: renderBlock, customBlock: customBlock)
    }
    
}
