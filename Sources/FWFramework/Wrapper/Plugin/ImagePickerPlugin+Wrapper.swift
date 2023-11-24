//
//  ImagePickerPlugin+Wrapper.swift
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

extension Wrapper where Base: PHPhotoLibrary {

    /**
     快速创建照片选择器(仅图片)
     
     @param selectionLimit 最大选择数量，iOS14以下只支持单选
     @param allowsEditing 是否允许编辑，仅iOS14以下支持编辑
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) -> UIViewController? {
        return Base.fw_pickerController(selectionLimit: selectionLimit, allowsEditing: allowsEditing, completion: completion)
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
    public static func pickerController(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, shouldDismiss: Bool, completion: @escaping (UIViewController?, [Any], [Any], Bool) -> Void) -> UIViewController? {
        return Base.fw_pickerController(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, shouldDismiss: shouldDismiss, completion: completion)
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑
     
     @param selectionLimit 最大选择数量
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(selectionLimit: Int, cropController: ((UIImage) -> ImageCropController)?, completion: @escaping ([UIImage], [Any], Bool) -> Void) -> UIViewController? {
        return Base.fw_pickerController(selectionLimit: selectionLimit, cropController: cropController, completion: completion)
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 自定义图片选取插件，未设置时自动从插件池加载
    public var imagePickerPlugin: ImagePickerPlugin! {
        get { return base.fw_imagePickerPlugin }
        set { base.fw_imagePickerPlugin = newValue }
    }
    
    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImageCamera(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        base.fw_showImageCamera(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping (Any?, Any?, Bool) -> Void) {
        base.fw_showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImagePicker(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        base.fw_showImagePicker(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func showImagePicker(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) {
        base.fw_showImagePicker(selectionLimit: selectionLimit, allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    public func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping ([Any], [Any], Bool) -> Void) {
        base.fw_showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }
    
}

extension Wrapper where Base: UIView {
    
    /// 从Camera选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImageCamera(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        base.fw_showImageCamera(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从Camera选取单张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象(UIImage|PHLivePhoto|NSURL)，2为结果信息，3为是否取消
    public func showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping (Any?, Any?, Bool) -> Void) {
        base.fw_showImageCamera(filterType: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }

    /// 从图片库选取单张图片(简单版)
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片，2为是否取消
    public func showImagePicker(allowsEditing: Bool, completion: @escaping (UIImage?, Bool) -> Void) {
        base.fw_showImagePicker(allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(简单版)
    /// - Parameters:
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
    public func showImagePicker(selectionLimit: Int, allowsEditing: Bool, completion: @escaping ([UIImage], [Any], Bool) -> Void) {
        base.fw_showImagePicker(selectionLimit: selectionLimit, allowsEditing: allowsEditing, completion: completion)
    }

    /// 从图片库选取多张图片(详细版)
    /// - Parameters:
    ///   - filterType: 过滤类型，默认0同系统
    ///   - selectionLimit: 最大选择数量
    ///   - allowsEditing: 是否允许编辑
    ///   - customBlock: 自定义配置句柄，默认nil
    ///   - completion: 完成回调，主线程。参数1为对象数组(UIImage|PHLivePhoto|NSURL)，2位结果数组，3为是否取消
    public func showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)? = nil, completion: @escaping ([Any], [Any], Bool) -> Void) {
        base.fw_showImagePicker(filterType: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
    }
    
}

extension Wrapper where Base: UIImagePickerController {
    
    /**
     快速创建单选照片选择器(仅图片)，自动设置delegate
     
     @param sourceType 选择器类型
     @param allowsEditing 是否允许编辑
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func pickerController(sourceType: UIImagePickerController.SourceType, allowsEditing: Bool, completion: @escaping (UIImage?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
        return Base.fw_pickerController(sourceType: sourceType, allowsEditing: allowsEditing, completion: completion)
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
    public static func pickerController(sourceType: UIImagePickerController.SourceType, filterType: ImagePickerFilterType, allowsEditing: Bool, shouldDismiss: Bool, completion: @escaping (UIImagePickerController?, Any?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
        return Base.fw_pickerController(sourceType: sourceType, filterType: filterType, allowsEditing: allowsEditing, shouldDismiss: shouldDismiss, completion: completion)
    }

    /**
     快速创建单选照片选择器，使用自定义裁剪控制器编辑
     
     @param sourceType 选择器类型
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调。参数1为图片，2为信息字典，3为是否取消
     @return 照片选择器，不支持的返回nil
     */
    public static func pickerController(sourceType: UIImagePickerController.SourceType, cropController: ((UIImage) -> ImageCropController)?, completion: @escaping (UIImage?, [AnyHashable : Any]?, Bool) -> Void) -> UIImagePickerController? {
        return Base.fw_pickerController(sourceType: sourceType, cropController: cropController, completion: completion)
    }
    
}

@available(iOS 14, *)
extension Wrapper where Base: PHPickerViewController {
    
    /**
     快速创建多选照片选择器(仅图片)，自动设置delegate
     
     @param selectionLimit 最大选择数量
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(selectionLimit: Int, completion: @escaping ([UIImage], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
        return Base.fw_pickerController(selectionLimit: selectionLimit, completion: completion)
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
    public static func pickerController(filterType: ImagePickerFilterType, selectionLimit: Int, shouldDismiss: Bool, completion: @escaping (PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
        return Base.fw_pickerController(filterType: filterType, selectionLimit: selectionLimit, shouldDismiss: shouldDismiss, completion: completion)
    }

    /**
     快速创建照片选择器(仅图片)，使用自定义裁剪控制器编辑
     
     @param selectionLimit 最大选择数量
     @param cropController 自定义裁剪控制器句柄，nil时自动创建默认裁剪控制器
     @param completion 完成回调，主线程。参数1为图片数组，2为结果数组，3为是否取消
     @return 照片选择器
     */
    public static func pickerController(selectionLimit: Int, cropController: ((UIImage) -> ImageCropController)?, completion: @escaping ([UIImage], [PHPickerResult], Bool) -> Void) -> PHPickerViewController {
        return Base.fw_pickerController(selectionLimit: selectionLimit, cropController: cropController, completion: completion)
    }
    
    /// 自定义全局PHPickerConfiguration创建句柄，默认nil
    public static var pickerConfigurationBlock: (() -> PHPickerConfiguration)? {
        get { Base.fw_pickerConfigurationBlock }
        set { Base.fw_pickerConfigurationBlock = newValue }
    }
    
    /// 照片选择器是否已经dismiss，用于解决didFinishPicking回调多次问题
    public var pickerControllerDismissed: Bool {
        get { base.fw_pickerControllerDismissed }
        set { base.fw_pickerControllerDismissed = newValue }
    }
    
    /// 自定义照片选择器导出进度句柄，主线程回调，默认nil
    public var exportProgressBlock: ((_ picker: PHPickerViewController, _ finishedCount: Int, _ totalCount: Int) -> Void)? {
        get { base.fw_exportProgressBlock }
        set { base.fw_exportProgressBlock = newValue }
    }
    
}
