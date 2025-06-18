//
//  ImagePickerPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Photos
import PhotosUI
import UIKit

// MARK: - ImagePickerPluginImpl
/// 默认图片选取插件
open class ImagePickerPluginImpl: NSObject, ImagePickerPlugin, @unchecked Sendable {
    /// 图片选择器缓存文件存放目录，使用完成后需自行删除
    public nonisolated static var imagePickerPath: String {
        return FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "AssetManager", "ImagePicker"])
    }
    
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
    open var cropControllerBlock: (@MainActor @Sendable (UIImage) -> UIViewController & ImageCropControllerProtocol)?

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
