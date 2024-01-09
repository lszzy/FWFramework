//
//  ImagePickerPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Photos
import PhotosUI
import MobileCoreServices

// MARK: ImagePickerPlugin
/// 图片选择插件过滤类型
public struct ImagePickerFilterType: OptionSet {
    
    public let rawValue: UInt
    
    public static let image = ImagePickerFilterType(rawValue: 1 << 0)
    public static let livePhoto = ImagePickerFilterType(rawValue: 1 << 1)
    public static let video = ImagePickerFilterType(rawValue: 1 << 2)
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
}

/// 图片选取插件协议，应用可自定义图片选取插件实现
public protocol ImagePickerPlugin: AnyObject {
    
    /// 从Camera选取单张图片插件方法
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    ///   - viewController: 当前视图控制器
    func showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping (Any?, Any?, Bool) -> Void, in viewController: UIViewController)
    
    /// 从图片库选取多张图片插件方法
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    ///   - viewController: 当前视图控制器
    func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void, in viewController: UIViewController)
    
}

extension ImagePickerPlugin {
    
    /// 从Camera选取单张图片插件方法
    public func showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping (Any?, Any?, Bool) -> Void, in viewController: UIViewController) {
        ImagePickerPluginImpl.shared.showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: viewController)
    }
    
    /// 从图片库选取多张图片插件方法
    public func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void, in viewController: UIViewController) {
        ImagePickerPluginImpl.shared.showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: viewController)
    }
    
}

// MARK: UIViewController+ImagePickerPlugin
/// 通用相册：[PHPhotoLibrary sharedPhotoLibrary]
@_spi(FW) extension PHPhotoLibrary {

    /**
     快速创建照片选择器(仅图片)
     
     @param selectionLimit 最大选择数量，iOS14以下只支持单选
     @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func fw_pickerController(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) -> UIViewController? {
        return fw_pickerController(filterType: .image, selectionLimit: selectionLimit, allowsEditing: allowsEditing, shouldDismiss: true) { _, objects, results, cancel in
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
    public static func fw_pickerController(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, shouldDismiss: Bool, completion: @escaping (UIViewController?, [Any], [Any], Bool) -> Void) -> UIViewController? {
        if #available(iOS 14.0, *) {
            return PHPickerViewController.fw_pickerController(filterType: filterType, selectionLimit: selectionLimit, shouldDismiss: shouldDismiss) { picker, objects, results, cancel in
                completion(picker, objects, results, cancel)
            }
        } else {
            return UIImagePickerController.fw_pickerController(sourceType: .photoLibrary, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: shouldDismiss) { picker, object, info, cancel in
                completion(picker, object != nil ? [object!] : [], info != nil ? [info!] : [], cancel)
            }
        }
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑
     
     @param selectionLimit 最大选择数量，iOS14以下只支持单选
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func fw_pickerController(selectionLimit: Int, cropController: ((UIImage) -> ImageCropController)?, completion: @escaping ([UIImage], [Any], Bool) -> Void) -> UIViewController? {
        if #available(iOS 14.0, *) {
            return PHPickerViewController.fw_pickerController(selectionLimit: selectionLimit, cropController: cropController, completion: completion)
        } else {
            return UIImagePickerController.fw_pickerController(sourceType: .photoLibrary, cropController: cropController) { image, result, cancel in
                completion(image != nil ? [image!] : [], result != nil ? [result!] : [], cancel)
            }
        }
    }
    
}

@_spi(FW) extension UIViewController {
    
    /// 自定义图片选取插件，未设置时自动从插件池加载
    public var fw_imagePickerPlugin: ImagePickerPlugin! {
        get {
            if let pickerPlugin = fw_property(forName: "fw_imagePickerPlugin") as? ImagePickerPlugin {
                return pickerPlugin
            } else if let pickerPlugin = PluginManager.loadPlugin(ImagePickerPlugin.self) {
                return pickerPlugin
            }
            return ImagePickerPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_imagePickerPlugin")
        }
    }
    
    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func fw_showImageCamera(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        fw_showImageCamera(filterType: .image, allowsEditing: allowsEditing, customBlock: nil) { object, _, cancel in
            completion(object as? UIImage, cancel)
        }
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func fw_showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping (Any?, Any?, Bool) -> Void) {
        let plugin = self.fw_imagePickerPlugin ?? ImagePickerPluginImpl.shared
        plugin.showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: self)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func fw_showImagePicker(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        fw_showImagePicker(selectionLimit: 1, allowsEditing: allowsEditing) { images, _, cancel in
            completion(images.first, cancel)
        }
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func fw_showImagePicker(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) {
        fw_showImagePicker(filterType: .image, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: nil) { objects, results, cancel in
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
    public func fw_showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping ([Any], [Any], Bool) -> Void) {
        let plugin = self.fw_imagePickerPlugin ?? ImagePickerPluginImpl.shared
        plugin.showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion, in: self)
    }
    
}

@_spi(FW) extension UIView {
    
    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func fw_showImageCamera(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImageCamera(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func fw_showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping (Any?, Any?, Bool) -> Void) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func fw_showImagePicker(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImagePicker(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func fw_showImagePicker(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImagePicker(selectionLimit: selectionLimit, allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    public func fw_showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping ([Any], [Any], Bool) -> Void) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }
    
}

@_spi(FW) extension UIImagePickerController {
    
    private class ImagePickerControllerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        var filterType: ImagePickerFilterType = []
        var shouldDismiss: Bool = false
        var completionBlock: ((UIImagePickerController?, Any?, [AnyHashable: Any]?, Bool) -> Void)?
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var object: Any?
            let mediaType = info[.mediaType] as? String ?? ""
            let checkLivePhoto = self.filterType.contains(.livePhoto) || self.filterType.rawValue < 1
            let checkVideo = self.filterType.contains(.video) || self.filterType.rawValue < 1
            if checkLivePhoto && mediaType == (kUTTypeLivePhoto as String) {
                object = info[.livePhoto]
            } else if checkVideo && mediaType == (kUTTypeMovie as String) {
                // 视频文件在tmp临时目录中，为防止系统自动删除，统一拷贝到选择器目录
                if let url = info[.mediaURL] as? URL {
                    let filePath = AssetManager.imagePickerPath
                    try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                    if let fullPath = ((filePath as NSString).appendingPathComponent((url.absoluteString + UUID().uuidString).fw_md5Encode) as NSString).appendingPathExtension(url.pathExtension) {
                        let tempFileURL = URL(fileURLWithPath: fullPath)
                        do {
                            try FileManager.default.moveItem(at: url, to: tempFileURL)
                            object = tempFileURL
                        } catch { }
                    }
                }
            } else {
                object = info[.editedImage] ?? info[.originalImage]
            }
            
            let completion = self.completionBlock
            if self.shouldDismiss {
                picker.dismiss(animated: true) {
                    completion?(nil, object, info, false)
                }
            } else {
                completion?(picker, object, info, false)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            let completion = self.completionBlock
            if self.shouldDismiss {
                picker.dismiss(animated: true) {
                    completion?(nil, nil, nil, true)
                }
            } else {
                completion?(picker, nil, nil, true)
            }
        }
        
    }
    
    /**
     快速创建单选照片选择器(仅图片)，自动设置delegate
     
     @param sourceType 选择器类型
     @param allowsEditing 是否允许编辑
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func fw_pickerController(sourceType: UIImagePickerController.SourceType, allowsEditing: Bool, completion: @escaping (UIImage?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
        return fw_pickerController(sourceType: sourceType, filterType: .image, allowsEditing: allowsEditing, shouldDismiss: true) { _, object, info, cancel in
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
    public static func fw_pickerController(sourceType: UIImagePickerController.SourceType, filterType: ImagePickerFilterType, allowsEditing: Bool, shouldDismiss: Bool, completion: @escaping (UIImagePickerController?, Any?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
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
        
        let pickerDelegate = ImagePickerControllerDelegate()
        pickerDelegate.filterType = filterType
        pickerDelegate.shouldDismiss = shouldDismiss
        pickerDelegate.completionBlock = completion
        
        pickerController.fw_setProperty(pickerDelegate, forName: "fw_pickerDelegate")
        pickerController.delegate = pickerDelegate
        return pickerController
    }

    /**
     快速创建单选照片选择器，使用自定义裁剪控制器编辑
     
     @param sourceType 选择器类型
     @param cropControllerBlock 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func fw_pickerController(sourceType: UIImagePickerController.SourceType, cropController cropControllerBlock: ((UIImage) -> ImageCropController)?, completion: @escaping (UIImage?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
        let pickerController = UIImagePickerController.fw_pickerController(sourceType: sourceType, filterType: .image, allowsEditing: false, shouldDismiss: false) { picker, object, info, cancel in
            let originalImage = cancel ? nil : (object as? UIImage)
            if let originalImage = originalImage {
                var cropController: ImageCropController
                if let cropControllerBlock = cropControllerBlock {
                    cropController = cropControllerBlock(originalImage)
                } else {
                    cropController = ImageCropController(image: originalImage)
                    cropController.aspectRatioPreset = .presetSquare
                    cropController.aspectRatioLockEnabled = true
                    cropController.resetAspectRatioEnabled = false
                    cropController.aspectRatioPickerButtonHidden = true
                }
                cropController.onDidCropToImage = { image, cropRect, angle in
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

@available(iOS 14, *)
@_spi(FW) extension PHPickerViewController {
    
    @available(iOS 14, *)
    private class PickerViewControllerDelegate: NSObject, PHPickerViewControllerDelegate {
        
        var filterType: ImagePickerFilterType = []
        var shouldDismiss: Bool = false
        var completionBlock: ((PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void)?
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !picker.fw_pickerControllerDismissed else { return }
            picker.fw_pickerControllerDismissed = true
            
            let filterType = self.filterType
            let completion = self.completionBlock
            if self.shouldDismiss {
                PickerViewControllerDelegate.picker(picker, didFinishPicking: results, filterType: filterType) { picker, objects, results, cancel in
                    picker.dismiss(animated: true) {
                        completion?(nil, objects, results, cancel)
                    }
                }
            } else {
                PickerViewControllerDelegate.picker(picker, didFinishPicking: results, filterType: filterType) { picker, objects, results, cancel in
                    completion?(picker, objects, results, cancel)
                }
            }
        }
        
        static func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult], filterType: ImagePickerFilterType, completion: ((PHPickerViewController, [Any], [PHPickerResult], Bool) -> Void)?) {
            if results.count < 1 {
                completion?(picker, [], results, true)
                return
            }
            
            let totalCount = results.count
            var finishCount: Int = 0
            let progressBlock = picker.fw_exportProgressBlock
            if progressBlock != nil {
                DispatchQueue.main.async {
                    progressBlock?(picker, finishCount, totalCount)
                }
            }
            
            var objectDict: [Int: (Any, PHPickerResult)] = [:]
            let checkLivePhoto = filterType.contains(.livePhoto) || filterType.rawValue < 1
            let checkVideo = filterType.contains(.video) || filterType.rawValue < 1
            for (index, result) in results.enumerated() {
                // assetIdentifier为空，无法获取到PHAsset，且获取PHAsset需要用户授权
                let isVideo = checkVideo && result.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String)
                if !isVideo {
                    var objectClass: NSItemProviderReading.Type = UIImage.self
                    if checkLivePhoto, result.itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                        objectClass = PHLivePhoto.self
                    }
                    
                    result.itemProvider.loadObject(ofClass: objectClass) { object, error in
                        DispatchQueue.main.async {
                            if let image = object as? UIImage {
                                objectDict[index] = (image, result)
                            } else if let livePhoto = object as? PHLivePhoto {
                                objectDict[index] = (livePhoto, result)
                            }
                            
                            finishCount += 1
                            progressBlock?(picker, finishCount, totalCount)
                            if finishCount == totalCount {
                                let objectList = objectDict.sorted { $0.key < $1.key }
                                let sortedObjects = objectList.map { $0.value.0 }
                                let sortedResults = objectList.map { $0.value.1 }
                                completion?(picker, sortedObjects, sortedResults, false)
                            }
                        }
                    }
                    continue
                }
                
                // completionHandler完成后，临时文件url会被系统删除，所以在此期间移动临时文件到FWImagePicker目录
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { url, error in
                    var videoURL: URL?
                    if let url = url {
                        let filePath = AssetManager.imagePickerPath
                        try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                        if let fullPath = ((filePath as NSString).appendingPathComponent((url.absoluteString + UUID().uuidString).fw_md5Encode) as NSString).appendingPathExtension(url.pathExtension) {
                            let fileURL = URL(fileURLWithPath: fullPath)
                            do {
                                try FileManager.default.moveItem(at: url, to: fileURL)
                                videoURL = fileURL
                            } catch { }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        if let videoURL = videoURL {
                            objectDict[index] = (videoURL, result)
                        }
                        
                        finishCount += 1
                        progressBlock?(picker, finishCount, totalCount)
                        if finishCount == totalCount {
                            let objectList = objectDict.sorted { $0.key < $1.key }
                            let sortedObjects = objectList.map { $0.value.0 }
                            let sortedResults = objectList.map { $0.value.1 }
                            completion?(picker, sortedObjects, sortedResults, false)
                        }
                    }
                }
            }
        }
        
    }
    
    /**
     快速创建多选照片选择器(仅图片)，自动设置delegate
     
     @param selectionLimit 最大选择数量
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func fw_pickerController(selectionLimit: Int, completion: @escaping ([UIImage], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
        return fw_pickerController(filterType: .image, selectionLimit: selectionLimit, shouldDismiss: true) { _, objects, results, cancel in
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
    public static func fw_pickerController(filterType: ImagePickerFilterType, selectionLimit: Int, shouldDismiss: Bool, completion: @escaping (PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
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
        var configuration = PHPickerViewController.fw_pickerConfigurationBlock?() ?? PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        if subFilters.count > 0 {
            configuration.filter = PHPickerFilter.any(of: subFilters)
        }
        let pickerController = PHPickerViewController(configuration: configuration)
        
        let pickerDelegate = PickerViewControllerDelegate()
        pickerDelegate.filterType = filterType
        pickerDelegate.shouldDismiss = shouldDismiss
        pickerDelegate.completionBlock = completion
        
        pickerController.fw_setProperty(pickerDelegate, forName: "fw_pickerDelegate")
        pickerController.delegate = pickerDelegate
        return pickerController
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑
     
     @param selectionLimit 最大选择数量
     @param cropControllerBlock 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func fw_pickerController(selectionLimit: Int, cropController cropControllerBlock: ((UIImage) -> ImageCropController)?, completion: @escaping ([UIImage], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
        let pickerController = PHPickerViewController.fw_pickerController(filterType: .image, selectionLimit: selectionLimit, shouldDismiss: false) { picker, objects, results, cancel in
            if objects.count == 1, let originalImage = objects.first as? UIImage {
                var cropController: ImageCropController
                if let cropControllerBlock = cropControllerBlock {
                    cropController = cropControllerBlock(originalImage)
                } else {
                    cropController = ImageCropController(image: originalImage)
                    cropController.aspectRatioPreset = .presetSquare
                    cropController.aspectRatioLockEnabled = true
                    cropController.resetAspectRatioEnabled = false
                    cropController.aspectRatioPickerButtonHidden = true
                }
                cropController.onDidCropToImage = { image, cropRect, angle in
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
                picker?.fw_pickerControllerDismissed = false
            } else {
                picker?.dismiss(animated: true, completion: {
                    completion(objects as? [UIImage] ?? [], results, cancel)
                })
            }
        }
        return pickerController
    }
    
    /// 自定义全局PHPickerConfiguration创建句柄，默认nil
    public static var fw_pickerConfigurationBlock: (() -> PHPickerConfiguration)?
    
    /// 照片选择器是否已经dismiss，用于解决didFinishPicking回调多次问题
    public var fw_pickerControllerDismissed: Bool {
        get { fw_propertyBool(forName: #function) }
        set { fw_setPropertyBool(newValue, forName: #function) }
    }
    
    /// 自定义照片选择器导出进度句柄，主线程回调，默认nil
    public var fw_exportProgressBlock: ((_ picker: PHPickerViewController, _ finishedCount: Int, _ totalCount: Int) -> Void)? {
        get { fw_property(forName: #function) as? (PHPickerViewController, Int, Int) -> Void }
        set { fw_setPropertyCopy(newValue, forName: #function) }
    }
    
}
