//
//  ImagePickerPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import MobileCoreServices
import Photos
import PhotosUI
import UIKit

// MARK: - Wrapper+PHPhotoLibrary
/// 通用相册：[PHPhotoLibrary sharedPhotoLibrary]
@MainActor extension Wrapper where Base: PHPhotoLibrary {
    /**
     快速创建照片选择器(仅图片)

     @param selectionLimit 最大选择数量，iOS14以下只支持单选
     @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        selectionLimit: Int,
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable ([UIImage], [Any], Bool) -> Void
    ) -> UIViewController? {
        pickerController(filterType: .image, selectionLimit: selectionLimit, allowsEditing: allowsEditing, shouldDismiss: true) { _, objects, results, cancel in
            completion(objects as? [UIImage] ?? [], results, cancel)
        }
    }

    /**
     快速创建照片选择器，可自定义dismiss流程

     @param filterType 过滤类型，默认0同系统
     @param selectionLimit 最大选择数量，iOS14以下只支持单选
     @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
     @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
     @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组(UIImage|PHLivePhoto|NSURL)，3位结果数组，4为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        shouldDismiss: Bool,
        completion: @escaping @MainActor @Sendable (UIViewController?, [Any], [Any], Bool) -> Void
    ) -> UIViewController? {
        if #available(iOS 14.0, *) {
            return PHPickerViewController.fw.pickerController(filterType: filterType, selectionLimit: selectionLimit, shouldDismiss: shouldDismiss) { picker, objects, results, cancel in
                completion(picker, objects, results, cancel)
            }
        } else {
            return UIImagePickerController.fw.pickerController(sourceType: .photoLibrary, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: shouldDismiss) { picker, object, info, cancel in
                completion(picker, object != nil ? [object!] : [], info != nil ? [info!] : [], cancel)
            }
        }
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑

     @param selectionLimit 最大选择数量
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        selectionLimit: Int,
        cropController: (@MainActor @Sendable (UIImage) -> ImageCropController)?,
        completion: @escaping @MainActor @Sendable ([UIImage], [Any], Bool) -> Void
    ) -> UIViewController? {
        if #available(iOS 14.0, *) {
            return PHPickerViewController.fw.pickerController(selectionLimit: selectionLimit, cropController: cropController, completion: completion)
        } else {
            return UIImagePickerController.fw.pickerController(sourceType: .photoLibrary, cropController: cropController) { image, result, cancel in
                completion(image != nil ? [image!] : [], result != nil ? [result!] : [], cancel)
            }
        }
    }
}

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 自定义图片选取插件，未设置时自动从插件池加载
    public var imagePickerPlugin: ImagePickerPlugin! {
        get {
            if let pickerPlugin = property(forName: "imagePickerPlugin") as? ImagePickerPlugin {
                return pickerPlugin
            } else if let pickerPlugin = PluginManager.loadPlugin(ImagePickerPlugin.self) {
                return pickerPlugin
            }
            return ImagePickerPluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "imagePickerPlugin")
        }
    }

    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImageCamera(
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable (UIImage?, Bool) -> Void
    ) {
        showImageCamera(filterType: .image, allowsEditing: allowsEditing, customBlock: nil) { object, _, cancel in
            completion(object as? UIImage, cancel)
        }
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func showImageCamera(
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        completion: @escaping @MainActor @Sendable (Any?, Any?, Bool) -> Void
    ) {
        let plugin = imagePickerPlugin ?? ImagePickerPluginImpl.shared
        plugin.showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: base)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImagePicker(
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable (UIImage?, Bool) -> Void
    ) {
        showImagePicker(selectionLimit: 1, allowsEditing: allowsEditing) { images, _, cancel in
            completion(images.first, cancel)
        }
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func showImagePicker(
        selectionLimit: Int,
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable ([UIImage], [Any], Bool) -> Void
    ) {
        showImagePicker(filterType: .image, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: nil) { objects, results, cancel in
            completion(objects as? [UIImage] ?? [], results, cancel)
        }
    }

    /// 从图片库选取多张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    public func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void
    ) {
        let plugin = imagePickerPlugin ?? ImagePickerPluginImpl.shared
        plugin.showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: base)
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImageCamera(
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable (UIImage?, Bool) -> Void
    ) {
        var ctrl = viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw.showImageCamera(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func showImageCamera(
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        completion: @escaping @MainActor @Sendable (Any?, Any?, Bool) -> Void
    ) {
        var ctrl = viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw.showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImagePicker(
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable (UIImage?, Bool) -> Void
    ) {
        var ctrl = viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw.showImagePicker(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func showImagePicker(
        selectionLimit: Int,
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable ([UIImage], [Any], Bool) -> Void
    ) {
        var ctrl = viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw.showImagePicker(selectionLimit: selectionLimit, allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    public func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void
    ) {
        var ctrl = viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw.showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }
}

// MARK: - Wrapper+UIImagePickerController
@MainActor extension Wrapper where Base: UIImagePickerController {
    /**
     快速创建单选照片选择器(仅图片)，自动设置delegate

     @param sourceType 选择器类型
     @param allowsEditing 是否允许编辑
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func pickerController(
        sourceType: UIImagePickerController.SourceType,
        allowsEditing: Bool,
        completion: @escaping @MainActor @Sendable (UIImage?, [AnyHashable: Any]?, Bool) -> Void
    ) -> UIImagePickerController? {
        pickerController(sourceType: sourceType, filterType: .image, allowsEditing: allowsEditing, shouldDismiss: true) { _, object, info, cancel in
            completion(object as? UIImage, info, cancel)
        }
    }

    /**
     快速创建单选照片选择器，可自定义dismiss流程，自动设置delegate

     @param sourceType 选择器类型
     @param filterType 过滤类型，默认0同系统
     @param allowsEditing 是否允许编辑
     @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
     @param completion 完成回调。参数1为照片选择器，2为对象(UIImage|PHLivePhoto|NSURL)，3为信息字典，4为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func pickerController(
        sourceType: UIImagePickerController.SourceType,
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        shouldDismiss: Bool,
        completion: @escaping @MainActor @Sendable (UIImagePickerController?, Any?, [AnyHashable: Any]?, Bool) -> Void
    ) -> UIImagePickerController? {
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            return nil
        }

        var mediaTypes: [String] = []
        if filterType.contains(.image) {
            mediaTypes.append(kUTTypeImage as String)
        }
        if filterType.contains(.livePhoto) {
            if !mediaTypes.contains(kUTTypeImage as String) {
                mediaTypes.append(kUTTypeImage as String)
            }
            mediaTypes.append(kUTTypeLivePhoto as String)
        }
        if filterType.contains(.video) {
            mediaTypes.append(kUTTypeMovie as String)
        }

        let pickerController = UIImagePickerController()
        pickerController.sourceType = sourceType
        pickerController.allowsEditing = allowsEditing
        if mediaTypes.count > 0 {
            pickerController.mediaTypes = mediaTypes
        }

        let pickerDelegate = ImagePickerControllerTarget()
        pickerDelegate.filterType = filterType
        pickerDelegate.shouldDismiss = shouldDismiss
        pickerDelegate.completionBlock = completion

        pickerController.fw.setProperty(pickerDelegate, forName: "pickerDelegate")
        pickerController.delegate = pickerDelegate
        return pickerController
    }

    /**
     快速创建单选照片选择器，使用自定义裁剪控制器编辑

     @param sourceType 选择器类型
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func pickerController(
        sourceType: UIImagePickerController.SourceType,
        cropController cropControllerBlock: (@MainActor @Sendable (UIImage) -> ImageCropController)?,
        completion: @escaping @MainActor @Sendable (UIImage?, [AnyHashable: Any]?, Bool) -> Void
    ) -> UIImagePickerController? {
        let pickerController = UIImagePickerController.fw.pickerController(sourceType: sourceType, filterType: .image, allowsEditing: false, shouldDismiss: false) { picker, object, info, cancel in
            let originalImage = cancel ? nil : (object as? UIImage)
            if let originalImage {
                var cropController: ImageCropController
                if let cropControllerBlock {
                    cropController = cropControllerBlock(originalImage)
                } else {
                    cropController = ImageCropController(image: originalImage)
                    cropController.aspectRatioPreset = .presetSquare
                    cropController.aspectRatioLockEnabled = true
                    cropController.resetAspectRatioEnabled = false
                    cropController.aspectRatioPickerButtonHidden = true
                }
                cropController.onDidCropToImage = { image, _, _ in
                    picker?.dismiss(animated: true, completion: {
                        completion(image, info, false)
                    })
                }
                cropController.onDidFinishCancelled = { _ in
                    if picker?.sourceType == .camera {
                        picker?.dismiss(animated: true, completion: {
                            completion(nil, nil, true)
                        })
                    } else {
                        picker?.popViewController(animated: true)
                    }
                }
                picker?.pushViewController(cropController, animated: true)
            } else {
                picker?.dismiss(animated: true, completion: {
                    completion(nil, nil, true)
                })
            }
        }
        return pickerController
    }
}

// MARK: - Wrapper+PHPickerViewController
@available(iOS 14, *)
@MainActor extension Wrapper where Base: PHPickerViewController {
    /**
     快速创建多选照片选择器(仅图片)，自动设置delegate

     @param selectionLimit 最大选择数量
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        selectionLimit: Int,
        completion: @escaping @MainActor @Sendable ([UIImage], [PHPickerResult], Bool) -> Void
    ) -> PHPickerViewController {
        pickerController(filterType: .image, selectionLimit: selectionLimit, shouldDismiss: true) { _, objects, results, cancel in
            completion(objects as? [UIImage] ?? [], results, cancel)
        }
    }

    /**
     快速创建多选照片选择器，可自定义dismiss流程，自动设置delegate
     @note 当选择视频时，completion回调对象为NSURL临时文件路径，使用完毕后可手工删除或等待系统自动删除

     @param filterType 过滤类型，默认0同系统
     @param selectionLimit 最大选择数量
     @param shouldDismiss 是否先关闭照片选择器再回调，如果先关闭则回调参数1为nil
     @param completion 完成回调，主线程。参数1为照片选择器，2为对象数组(UIImage|PHLivePhoto|NSURL)，3为结果数组，4为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        shouldDismiss: Bool,
        completion: @escaping @MainActor @Sendable (PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void
    ) -> PHPickerViewController {
        var subFilters: [PHPickerFilter] = []
        if filterType.contains(.image) {
            subFilters.append(PHPickerFilter.images)
        }
        if filterType.contains(.livePhoto) {
            subFilters.append(PHPickerFilter.livePhotos)
        }
        if filterType.contains(.video) {
            subFilters.append(PHPickerFilter.videos)
        }

        // 注意preferredAssetRepresentationMode默认值为automatic会自动转码视频，导出会变慢。如果无需视频转码，可设置为current加快导出
        var configuration = PHPickerViewController.fw.pickerConfigurationBlock?() ?? PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        if subFilters.count > 0 {
            configuration.filter = PHPickerFilter.any(of: subFilters)
        }
        let pickerController = PHPickerViewController(configuration: configuration)

        let pickerDelegate = PickerViewControllerTarget()
        pickerDelegate.filterType = filterType
        pickerDelegate.shouldDismiss = shouldDismiss
        pickerDelegate.completionBlock = completion

        pickerController.fw.setProperty(pickerDelegate, forName: "pickerDelegate")
        pickerController.delegate = pickerDelegate
        return pickerController
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑

     @param selectionLimit 最大选择数量
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(
        selectionLimit: Int,
        cropController cropControllerBlock: (@MainActor @Sendable (UIImage) -> ImageCropController)?,
        completion: @escaping @MainActor @Sendable ([UIImage], [PHPickerResult], Bool) -> Void
    ) -> PHPickerViewController {
        let pickerController = PHPickerViewController.fw.pickerController(filterType: .image, selectionLimit: selectionLimit, shouldDismiss: false) { picker, objects, results, cancel in
            if objects.count == 1, let originalImage = objects.first as? UIImage {
                var cropController: ImageCropController
                if let cropControllerBlock {
                    cropController = cropControllerBlock(originalImage)
                } else {
                    cropController = ImageCropController(image: originalImage)
                    cropController.aspectRatioPreset = .presetSquare
                    cropController.aspectRatioLockEnabled = true
                    cropController.resetAspectRatioEnabled = false
                    cropController.aspectRatioPickerButtonHidden = true
                }
                cropController.onDidCropToImage = { image, _, _ in
                    picker?.presentingViewController?.dismiss(animated: true, completion: {
                        completion([image], results, false)
                    })
                }
                cropController.onDidFinishCancelled = { _ in
                    if picker?.navigationController != nil {
                        picker?.navigationController?.popViewController(animated: true)
                    } else {
                        picker?.dismiss(animated: true, completion: nil)
                    }
                }
                if picker?.navigationController != nil {
                    picker?.navigationController?.pushViewController(cropController, animated: true)
                } else {
                    picker?.present(cropController, animated: true, completion: nil)
                }
                picker?.fw.pickerControllerDismissed = false
            } else {
                picker?.dismiss(animated: true, completion: {
                    completion(objects as? [UIImage] ?? [], results, cancel)
                })
            }
        }
        return pickerController
    }

    /// 自定义全局PHPickerConfiguration创建句柄，默认nil
    public static var pickerConfigurationBlock: (@MainActor @Sendable () -> PHPickerConfiguration)? {
        get { PHPickerViewController.innerPickerConfigurationBlock }
        set { PHPickerViewController.innerPickerConfigurationBlock = newValue }
    }

    /// 照片选择器是否已经dismiss，用于解决didFinishPicking回调多次问题
    public var pickerControllerDismissed: Bool {
        get { propertyBool(forName: #function) }
        set { setPropertyBool(newValue, forName: #function) }
    }

    /// 自定义照片选择器导出进度句柄，主线程回调，默认nil
    public var exportProgressBlock: (@MainActor @Sendable (_ picker: PHPickerViewController, _ finishedCount: Int, _ totalCount: Int) -> Void)? {
        get { property(forName: #function) as? @MainActor @Sendable (PHPickerViewController, Int, Int) -> Void }
        set { setPropertyCopy(newValue, forName: #function) }
    }
}

// MARK: ImagePickerPlugin
/// 图片选择插件过滤类型
public struct ImagePickerFilterType: OptionSet, Sendable {
    public let rawValue: UInt

    public static let image = ImagePickerFilterType(rawValue: 1 << 0)
    public static let livePhoto = ImagePickerFilterType(rawValue: 1 << 1)
    public static let video = ImagePickerFilterType(rawValue: 1 << 2)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

/// 图片选取插件协议，应用可自定义图片选取插件实现
@MainActor public protocol ImagePickerPlugin: AnyObject {
    /// 从Camera选取单张图片插件方法
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    ///   - viewController: 当前视图控制器
    func showImageCamera(
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable (Any?, Any?, Bool) -> Void,
        in viewController: UIViewController
    )

    /// 从图片库选取多张图片插件方法
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    ///   - viewController: 当前视图控制器
    func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void,
        in viewController: UIViewController
    )
}

extension ImagePickerPlugin {
    /// 从Camera选取单张图片插件方法
    public func showImageCamera(
        filterType: ImagePickerFilterType,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable (Any?, Any?, Bool) -> Void,
        in viewController: UIViewController
    ) {
        ImagePickerPluginImpl.shared.showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: viewController)
    }

    /// 从图片库选取多张图片插件方法
    public func showImagePicker(
        filterType: ImagePickerFilterType,
        selectionLimit: Int,
        allowsEditing: Bool,
        customBlock: (@MainActor @Sendable (Any) -> Void)?,
        completion: @escaping @MainActor @Sendable ([Any], [Any], Bool) -> Void,
        in viewController: UIViewController
    ) {
        ImagePickerPluginImpl.shared.showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: viewController)
    }
}

// MARK: - ImagePickerControllerTarget
private class ImagePickerControllerTarget: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var filterType: ImagePickerFilterType = []
    var shouldDismiss: Bool = false
    var completionBlock: (@MainActor @Sendable (UIImagePickerController?, Any?, [AnyHashable: Any]?, Bool) -> Void)?

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var object: Any?
        let mediaType = info[.mediaType] as? String ?? ""
        let checkLivePhoto = filterType.contains(.livePhoto) || filterType.rawValue < 1
        let checkVideo = filterType.contains(.video) || filterType.rawValue < 1
        if checkLivePhoto && mediaType == (kUTTypeLivePhoto as String) {
            object = info[.livePhoto]
        } else if checkVideo && mediaType == (kUTTypeMovie as String) {
            // 视频文件在tmp临时目录中，为防止系统自动删除，统一拷贝到选择器目录
            if let url = info[.mediaURL] as? URL {
                let filePath = AssetManager.imagePickerPath
                try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                if let fullPath = ((filePath as NSString).appendingPathComponent((url.absoluteString + UUID().uuidString).fw.md5Encode) as NSString).appendingPathExtension(url.pathExtension) {
                    let tempFileURL = URL(fileURLWithPath: fullPath)
                    do {
                        try FileManager.default.moveItem(at: url, to: tempFileURL)
                        object = tempFileURL
                    } catch {}
                }
            }
        } else {
            object = info[.editedImage] ?? info[.originalImage]
        }

        let completion = completionBlock
        if shouldDismiss {
            picker.dismiss(animated: true) {
                completion?(nil, object, info, false)
            }
        } else {
            completion?(picker, object, info, false)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        let completion = completionBlock
        if shouldDismiss {
            picker.dismiss(animated: true) {
                completion?(nil, nil, nil, true)
            }
        } else {
            completion?(picker, nil, nil, true)
        }
    }
}

// MARK: - PickerViewControllerTarget
@available(iOS 14, *)
@MainActor private class PickerViewControllerTarget: NSObject, PHPickerViewControllerDelegate {
    var filterType: ImagePickerFilterType = []
    var shouldDismiss: Bool = false
    var completionBlock: (@MainActor @Sendable (PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void)?

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !picker.fw.pickerControllerDismissed else { return }
        picker.fw.pickerControllerDismissed = true

        let filterType = filterType
        let completion = completionBlock
        if shouldDismiss {
            PickerViewControllerTarget.picker(picker, didFinishPicking: results, filterType: filterType) { picker, objects, results, cancel in
                picker.dismiss(animated: true) {
                    completion?(nil, objects, results, cancel)
                }
            }
        } else {
            PickerViewControllerTarget.picker(picker, didFinishPicking: results, filterType: filterType) { picker, objects, results, cancel in
                completion?(picker, objects, results, cancel)
            }
        }
    }

    static func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult],
        filterType: ImagePickerFilterType,
        completion: (@MainActor @Sendable (PHPickerViewController, [Any], [PHPickerResult], Bool) -> Void)?
    ) {
        if results.count < 1 {
            completion?(picker, [], results, true)
            return
        }

        let totalCount = results.count
        var finishCount = 0
        let progressBlock = picker.fw.exportProgressBlock
        if progressBlock != nil {
            DispatchQueue.fw.mainAsync {
                progressBlock?(picker, finishCount, totalCount)
            }
        }

        let sendableObjectDict = SendableObject<[Int: (Any, PHPickerResult)]>([:])
        let checkLivePhoto = filterType.contains(.livePhoto) || filterType.rawValue < 1
        let checkVideo = filterType.contains(.video) || filterType.rawValue < 1
        for (index, result) in results.enumerated() {
            // assetIdentifier为空，无法获取到PHAsset，且获取PHAsset需要用户授权
            let sendableResult = SendableObject(result)
            let isVideo = checkVideo && result.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String)
            if !isVideo {
                var objectClass: NSItemProviderReading.Type = UIImage.self
                if checkLivePhoto, result.itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                    objectClass = PHLivePhoto.self
                }

                result.itemProvider.loadObject(ofClass: objectClass) { object, _ in
                    let sendableObject = SendableObject(object)
                    DispatchQueue.main.async {
                        if let image = sendableObject.object as? UIImage {
                            sendableObjectDict.object[index] = (image, sendableResult.object)
                        } else if let livePhoto = sendableObject.object as? PHLivePhoto {
                            sendableObjectDict.object[index] = (livePhoto, sendableResult.object)
                        }

                        finishCount += 1
                        progressBlock?(picker, finishCount, totalCount)
                        if finishCount == totalCount {
                            let objectList = sendableObjectDict.object.sorted { $0.key < $1.key }
                            let sortedObjects = objectList.map(\.value.0)
                            let sortedResults = objectList.map(\.value.1)
                            completion?(picker, sortedObjects, sortedResults, false)
                        }
                    }
                }
                continue
            }

            // completionHandler完成后，临时文件url会被系统删除，所以在此期间移动临时文件到FWImagePicker目录
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { url, _ in
                var videoURL: URL?
                if let url {
                    let filePath = AssetManager.imagePickerPath
                    try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                    if let fullPath = ((filePath as NSString).appendingPathComponent((url.absoluteString + UUID().uuidString).fw.md5Encode) as NSString).appendingPathExtension(url.pathExtension) {
                        let fileURL = URL(fileURLWithPath: fullPath)
                        do {
                            try FileManager.default.moveItem(at: url, to: fileURL)
                            videoURL = fileURL
                        } catch {}
                    }
                }

                let resultURL = videoURL
                DispatchQueue.main.async {
                    if let resultURL {
                        sendableObjectDict.object[index] = (resultURL, sendableResult.object)
                    }

                    finishCount += 1
                    progressBlock?(picker, finishCount, totalCount)
                    if finishCount == totalCount {
                        let objectList = sendableObjectDict.object.sorted { $0.key < $1.key }
                        let sortedObjects = objectList.map(\.value.0)
                        let sortedResults = objectList.map(\.value.1)
                        completion?(picker, sortedObjects, sortedResults, false)
                    }
                }
            }
        }
    }
}

@available(iOS 14, *)
extension PHPickerViewController {
    fileprivate static var innerPickerConfigurationBlock: (@MainActor @Sendable () -> PHPickerConfiguration)?
}
