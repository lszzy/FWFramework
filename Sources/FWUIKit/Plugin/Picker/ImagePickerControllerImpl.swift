//
//  ImagePickerControllerImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Photos
import PhotosUI
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - ImagePickerControllerImpl
/// 自定义图片选取插件
open class ImagePickerControllerImpl: NSObject, ImagePickerPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePickerControllerImpl()

    /// 是否显示相册列表控制器，默认为NO，点击titleView切换相册
    open var showsAlbumController: Bool = false

    /// 自定义相册列表控制器句柄，默认nil时使用自带控制器
    open var albumControllerBlock: (@MainActor @Sendable () -> ImageAlbumController)?

    /// 自定义图片预览控制器句柄，默认nil时使用自带控制器
    open var previewControllerBlock: (@MainActor @Sendable () -> ImagePickerPreviewController)?

    /// 自定义图片选取控制器句柄，默认nil时使用自带控制器
    open var pickerControllerBlock: (@MainActor @Sendable () -> ImagePickerController)?

    /// 自定义图片裁剪控制器句柄，预览控制器未自定义时生效，默认nil时使用自带控制器
    open var cropControllerBlock: (@MainActor @Sendable (UIImage) -> ImageCropController)?

    /// 自定义视频导出质量，默认nil时不处理
    open var videoExportPreset: String?

    /// 图片选取全局自定义句柄，show方法自动调用
    open var customBlock: (@MainActor @Sendable (ImagePickerController) -> Void)?

    // MARK: - ImagePickerPlugin
    open func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void,
        in viewController: UIViewController
    ) {
        if showsAlbumController {
            let albumController = albumController(filterType: filterType)
            albumController.pickerControllerBlock = {
                ImagePickerControllerImpl.shared.pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
            }

            let navigationController = UINavigationController(rootViewController: albumController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        } else {
            let pickerController = pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
            pickerController.albumControllerBlock = {
                ImagePickerControllerImpl.shared.albumController(filterType: filterType)
            }
            pickerController.refresh(filterType: filterType)

            let navigationController = UINavigationController(rootViewController: pickerController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        }
    }

    // MARK: - Private
    private func pickerController(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void
    ) -> ImagePickerController {
        var pickerController: ImagePickerController
        if let pickerControllerBlock {
            pickerController = pickerControllerBlock()
        } else {
            pickerController = ImagePickerController()
        }
        pickerController.allowsMultipleSelection = selectionLimit != 1
        pickerController.maximumSelectImageCount = selectionLimit > 0 ? UInt(selectionLimit) : UInt.max
        pickerController.shouldRequestImage = true
        pickerController.filterType = .init(rawValue: filterType.rawValue)
        pickerController.previewControllerBlock = {
            ImagePickerControllerImpl.shared.previewController(allowsEditing: allowsEditing)
        }
        pickerController.didCancelPicking = {
            completion([], [], true)
        }
        pickerController.didFinishPicking = { imagesAssetArray in
            var objects: [Any] = []
            var results: [Any] = []
            for imagesAsset in imagesAssetArray {
                if let requestObject = imagesAsset.requestObject {
                    objects.append(requestObject)
                    results.append(imagesAsset.requestInfo ?? [:])
                }
            }
            completion(objects, results, objects.count < 1)
        }

        if let videoExportPreset {
            pickerController.videoExportPreset = videoExportPreset
        }

        self.customBlock?(pickerController)
        customBlock?(pickerController)
        return pickerController
    }

    private func albumController(filterType: ImagePickerFilterType) -> ImageAlbumController {
        var albumController: ImageAlbumController
        if let albumControllerBlock {
            albumController = albumControllerBlock()
        } else {
            albumController = ImageAlbumController()
            albumController.pickDefaultAlbumGroup = showsAlbumController
        }
        albumController.contentType = ImagePickerController.albumContentType(filterType: filterType)
        return albumController
    }

    private func previewController(allowsEditing: Bool) -> ImagePickerPreviewController {
        var previewController: ImagePickerPreviewController
        if let previewControllerBlock {
            previewController = previewControllerBlock()
        } else {
            previewController = ImagePickerPreviewController()
        }
        previewController.showsEditButton = allowsEditing
        if previewController.cropControllerBlock == nil, cropControllerBlock != nil {
            previewController.cropControllerBlock = cropControllerBlock
        }
        return previewController
    }
}
