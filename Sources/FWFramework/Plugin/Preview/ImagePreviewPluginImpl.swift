//
//  ImagePreviewPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 默认图片预览插件
open class ImagePreviewPluginImpl: NSObject, ImagePreviewPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePreviewPluginImpl()

    /// 自定义图片预览控制器句柄，默认nil时使用自带控制器，显示分页，点击图片|视频时关闭，present样式为zoom
    open var previewControllerBlock: (@MainActor @Sendable () -> ImagePreviewController)?

    /// 图片预览全局自定义句柄，show方法自动调用
    open var customBlock: (@MainActor @Sendable (ImagePreviewController) -> Void)?

    // MARK: - ImagePreviewPlugin
    open func showImagePreview(
        imageURLs: [Any],
        imageInfos: [Any]?,
        currentIndex: Int,
        sourceView: (@MainActor @Sendable (Int) -> Any?)?,
        placeholderImage: (@MainActor @Sendable (Int) -> UIImage?)?,
        renderBlock: (@MainActor @Sendable (UIView, Int) -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        in viewController: UIViewController
    ) {
        var previewController: ImagePreviewController
        if let previewControllerBlock {
            previewController = previewControllerBlock()
        } else {
            previewController = ImagePreviewController()
            previewController.showsPageLabel = true
            previewController.dismissingWhenTappedImage = true
            previewController.dismissingWhenTappedVideo = true
            previewController.presentingStyle = .zoom
        }

        previewController.imagePreviewView.placeholderImage = placeholderImage
        previewController.imagePreviewView.renderZoomImageView = renderBlock
        previewController.sourceImageView = sourceView
        previewController.imagePreviewView.imageURLs = imageURLs
        previewController.imagePreviewView.imageInfos = imageInfos

        self.customBlock?(previewController)
        customBlock?(previewController)
        previewController.imagePreviewView.currentImageIndex = currentIndex
        viewController.present(previewController, animated: true)
    }
}
