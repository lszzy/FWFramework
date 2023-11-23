//
//  ImagePickerPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Photos
import PhotosUI
#if FWMacroSPM
import FWObjC
#endif

// MARK: - ImagePickerPluginImpl
/// 默认图片选取插件
open class ImagePickerPluginImpl: NSObject, ImagePickerPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePickerPluginImpl()

    /// 是否禁用iOS14+PHPickerViewController(支持多选)，默认false。设为true后始终使用UIImagePickerController(仅支持单选)
    open var photoPickerDisabled: Bool = false
    
    /// 是否启用iOS14+PHPickerViewController导航栏控制器，默认false。注意设为true后customBlock参数将变为UINavigationController
    open var photoNavigationEnabled: Bool = false

    /// 编辑单张图片时是否启用自定义裁剪控制器，默认false，使用系统方式
    open var cropControllerEnabled: Bool = false
    
    /// 是否全屏弹出，默认false，使用系统方式
    open var presentationFullScreen: Bool = false
    
    /// 自定义图片裁剪控制器句柄，启用自定义裁剪后生效
    open var cropControllerBlock: ((UIImage) -> ImageCropController)?
    
    /// 自定义视频导出质量，默认nil时不处理
    open var videoExportPreset: String?
    
    /// 自定义视频质量，默认nil时不生效
    open var videoQuality: UIImagePickerController.QualityType?

    /// 图片选取全局自定义句柄，show方法自动调用
    open var customBlock: ((UIViewController) -> Void)?
    
    // MARK: - ImagePickerPlugin
    open func showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping (Any?, Any?, Bool) -> Void, in viewController: UIViewController) {
        var pickerController: UIImagePickerController?
        if cropControllerEnabled, filterType == .image, allowsEditing {
            pickerController = UIImagePickerController.fw_pickerController(sourceType: .camera, cropController: cropControllerBlock, completion: { image, info, cancel in
                completion(image, info, cancel)
            })
        } else {
            pickerController = UIImagePickerController.fw_pickerController(sourceType: .camera, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: true, completion: { picker, object, info, cancel in
                completion(object, info, cancel)
            })
        }
        
        guard let pickerController = pickerController else {
            completion(nil, nil, true)
            return
        }
        
        if let videoQuality = videoQuality {
            pickerController.videoQuality = videoQuality
        }
        
        if presentationFullScreen {
            pickerController.modalPresentationStyle = .fullScreen
        }
        self.customBlock?(pickerController)
        customBlock?(pickerController)
        viewController.present(pickerController, animated: true)
    }
    
    open func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void, in viewController: UIViewController) {
        var pickerController: UIViewController?
        var usePhotoPicker = false
        if #available(iOS 14.0, *) {
            usePhotoPicker = !photoPickerDisabled
        }
        if usePhotoPicker {
            if cropControllerEnabled, filterType == .image, allowsEditing {
                pickerController = PHPhotoLibrary.fw_pickerController(selectionLimit: selectionLimit, cropController: cropControllerBlock, completion: { images, results, cancel in
                    completion(images, results, cancel)
                })
            } else {
                pickerController = PHPhotoLibrary.fw_pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, shouldDismiss: true, completion: { picker, objects, results, cancel in
                    completion(objects, results, cancel)
                })
            }
        } else {
            if cropControllerEnabled, filterType == .image, allowsEditing {
                pickerController = UIImagePickerController.fw_pickerController(sourceType: .photoLibrary, cropController: cropControllerBlock, completion: { image, info, cancel in
                    completion(image != nil ? [image!] : [], info != nil ? [info!] : [], cancel)
                })
            } else {
                pickerController = UIImagePickerController.fw_pickerController(sourceType: .photoLibrary, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: true, completion: { picker, object, info, cancel in
                    completion(object != nil ? [object!] : [], info != nil ? [info!] : [], cancel)
                })
            }
        }
        
        guard var pickerController = pickerController else {
            completion([], [], true)
            return
        }
        
        if #available(iOS 14.0, *) {
            if let videoExportPreset = videoExportPreset,
               let phPicker = pickerController as? PHPickerViewController {
                phPicker.fw_videoExportPreset = videoExportPreset
            }
        }
        if let videoQuality = videoQuality,
           let imagePicker = pickerController as? UIImagePickerController {
            imagePicker.videoQuality = videoQuality
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
open class ImagePickerControllerImpl: NSObject, ImagePickerPlugin {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = ImagePickerControllerImpl()

    /// 是否显示相册列表控制器，默认为NO，点击titleView切换相册
    open var showsAlbumController: Bool = false

    /// 自定义相册列表控制器句柄，默认nil时使用自带控制器
    open var albumControllerBlock: (() -> ImageAlbumController)?

    /// 自定义图片预览控制器句柄，默认nil时使用自带控制器
    open var previewControllerBlock: (() -> ImagePickerPreviewController)?

    /// 自定义图片选取控制器句柄，默认nil时使用自带控制器
    open var pickerControllerBlock: (() -> ImagePickerController)?

    /// 自定义图片裁剪控制器句柄，预览控制器未自定义时生效，默认nil时使用自带控制器
    open var cropControllerBlock: ((UIImage) -> ImageCropController)?
    
    /// 自定义视频导出质量，默认nil时不处理
    open var videoExportPreset: String?

    /// 图片选取全局自定义句柄，show方法自动调用
    open var customBlock: ((ImagePickerController) -> Void)?
    
    // MARK: - ImagePickerPlugin
    open func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void, in viewController: UIViewController) {
        if showsAlbumController {
            let albumController = albumController(filterType: filterType)
            albumController.pickerControllerBlock = {
                return ImagePickerControllerImpl.shared.pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
            }
            
            let navigationController = UINavigationController(rootViewController: albumController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        } else {
            let pickerController = pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
            pickerController.albumControllerBlock = {
                return ImagePickerControllerImpl.shared.albumController(filterType: filterType)
            }
            pickerController.refresh(filterType: filterType)
            
            let navigationController = UINavigationController(rootViewController: pickerController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: true)
        }
    }
    
    // MARK: - Private
    private func pickerController(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void) -> ImagePickerController {
        var pickerController: ImagePickerController
        if let pickerControllerBlock = pickerControllerBlock {
            pickerController = pickerControllerBlock()
        } else {
            pickerController = ImagePickerController()
        }
        pickerController.allowsMultipleSelection = selectionLimit != 1
        pickerController.maximumSelectImageCount = selectionLimit > 0 ? UInt(selectionLimit) : UInt.max
        pickerController.shouldRequestImage = true
        pickerController.filterType = .init(rawValue: filterType.rawValue)
        pickerController.previewControllerBlock = {
            return ImagePickerControllerImpl.shared.previewController(allowsEditing: allowsEditing)
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
        
        if let videoExportPreset = videoExportPreset {
            pickerController.videoExportPreset = videoExportPreset
        }
        
        self.customBlock?(pickerController)
        customBlock?(pickerController)
        return pickerController
    }
    
    private func albumController(filterType: ImagePickerFilterType) -> ImageAlbumController {
        var albumController: ImageAlbumController
        if let albumControllerBlock = albumControllerBlock {
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
        if let previewControllerBlock = previewControllerBlock {
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
