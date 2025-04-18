//
//  ImagePickerPluginImpl.swift
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

// MARK: - ImagePickerPluginImpl
/// 默认图片选取插件
open class ImagePickerPluginImpl: NSObject, ImagePickerPlugin, @unchecked Sendable {
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePickerPluginImpl()

    /// 是否禁用iOS14+PHPickerViewController(支持多选、无需用户隐私授权)，默认false。设为true后始终使用UIImagePickerController(仅支持单选)
    open var photoPickerDisabled: Bool = false

    /// 是否启用iOS14+PHPickerViewController导航栏控制器，默认false。注意设为true后customBlock参数将变为UINavigationController
    open var photoNavigationEnabled: Bool = false

    /// 编辑单张图片时是否启用自定义裁剪控制器，默认false，使用系统方式
    open var cropControllerEnabled: Bool = false

    /// 是否全屏弹出，默认false，使用系统方式
    open var presentationFullScreen: Bool = false

    /// 自定义图片裁剪控制器句柄，启用自定义裁剪后生效
    open var cropControllerBlock: (@MainActor @Sendable (UIImage) -> ImageCropController)?

    /// 自定义视频质量，默认nil时不生效
    open var videoQuality: UIImagePickerController.QualityType?

    /// 自定义PHPicker导出进度句柄，主线程回调，默认nil
    open var exportProgressBlock: (@MainActor @Sendable (_ controller: UIViewController, _ finishedCount: Int, _ totalCount: Int) -> Void)?

    /// 图片选取全局自定义句柄，show方法自动调用
    open var customBlock: (@MainActor @Sendable (UIViewController) -> Void)?

    // MARK: - ImagePickerPlugin
    open func showImageCamera(
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable (Any?, Any?, Bool) -> Void,
        in viewController: UIViewController
    ) {
        var pickerController: UIImagePickerController?
        if cropControllerEnabled, filterType == .image, allowsEditing {
            pickerController = UIImagePickerController.fw.pickerController(sourceType: .camera, cropController: cropControllerBlock, completion: { image, info, cancel in
                completion(image, info, cancel)
            })
        } else {
            pickerController = UIImagePickerController.fw.pickerController(sourceType: .camera, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: true, completion: { _, object, info, cancel in
                completion(object, info, cancel)
            })
        }

        guard let pickerController else {
            completion(nil, nil, true)
            return
        }

        if let videoQuality {
            pickerController.videoQuality = videoQuality
        }

        if presentationFullScreen {
            pickerController.modalPresentationStyle = .fullScreen
        }
        self.customBlock?(pickerController)
        customBlock?(pickerController)
        viewController.present(pickerController, animated: true)
    }

    open func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void,
        in viewController: UIViewController
    ) {
        var pickerController: UIViewController?
        var usePhotoPicker = false
        if #available(iOS 14.0, *) {
            usePhotoPicker = !photoPickerDisabled
        }
        if usePhotoPicker {
            if cropControllerEnabled, filterType == .image, allowsEditing {
                pickerController = PHPhotoLibrary.fw.pickerController(selectionLimit: selectionLimit, cropController: cropControllerBlock, completion: { images, results, cancel in
                    completion(images, results, cancel)
                })
            } else {
                pickerController = PHPhotoLibrary.fw.pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, shouldDismiss: true, completion: { _, objects, results, cancel in
                    completion(objects, results, cancel)
                })
            }
        } else {
            if cropControllerEnabled, filterType == .image, allowsEditing {
                pickerController = UIImagePickerController.fw.pickerController(sourceType: .photoLibrary, cropController: cropControllerBlock, completion: { image, info, cancel in
                    completion(image != nil ? [image!] : [], info != nil ? [info!] : [], cancel)
                })
            } else {
                pickerController = UIImagePickerController.fw.pickerController(sourceType: .photoLibrary, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: true, completion: { _, object, info, cancel in
                    completion(object != nil ? [object!] : [], info != nil ? [info!] : [], cancel)
                })
            }
        }

        guard var pickerController else {
            completion([], [], true)
            return
        }

        if let videoQuality,
           let imagePicker = pickerController as? UIImagePickerController {
            imagePicker.videoQuality = videoQuality
        }

        if #available(iOS 14.0, *) {
            if let progressBlock = exportProgressBlock,
               let picker = pickerController as? PHPickerViewController {
                picker.fw.exportProgressBlock = { picker, finishedCount, totalCount in
                    let controller: UIViewController = picker.navigationController ?? picker
                    progressBlock(controller, finishedCount, totalCount)
                }
            }
        }

        if photoNavigationEnabled, !(pickerController is UINavigationController) {
            let navigationController = UINavigationController(rootViewController: pickerController)
            navigationController.isNavigationBarHidden = true
            pickerController = navigationController
        }

        if presentationFullScreen {
            pickerController.modalPresentationStyle = .fullScreen
        }
        self.customBlock?(pickerController)
        customBlock?(pickerController)
        viewController.present(pickerController, animated: true)
    }
}

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
