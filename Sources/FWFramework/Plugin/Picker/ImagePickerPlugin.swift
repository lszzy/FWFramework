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
#if FWMacroSPM
import FWObjC
#endif

/// 通用相册：[PHPhotoLibrary sharedPhotoLibrary]
@_spi(FW) extension PHPhotoLibrary {
    
    /// 保存图片或视频到指定的相册
    ///
    /// 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
    /// * 原因请参考 AssetManager 对象的保存图片和视频方法的注释。
    /// 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
    public func fw_addImage(toAlbum imageRef: CGImage, assetCollection: PHAssetCollection, orientation: UIImage.Orientation, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        let targetImage = UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: orientation)
        fw_addImage(toAlbum: targetImage, imagePathURL: nil, assetCollection: assetCollection, completionHandler: completionHandler)
    }

    public func fw_addImage(toAlbum imagePathURL: URL, assetCollection: PHAssetCollection, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        fw_addImage(toAlbum: nil, imagePathURL: imagePathURL, assetCollection: assetCollection, completionHandler: completionHandler)
    }
    
    private func fw_addImage(toAlbum image: UIImage?, imagePathURL: URL?, assetCollection: PHAssetCollection, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        var creationDate: Date?
        self.performChanges {
            // 创建一个以图片生成新的 PHAsset，这时图片已经被添加到“相机胶卷”
            var assetChangeRequest: PHAssetChangeRequest?
            if let image = image {
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            } else if let imagePathURL = imagePathURL {
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imagePathURL)
            } else {
                return
            }
            assetChangeRequest?.creationDate = Date()
            creationDate = assetChangeRequest?.creationDate
            
            if assetCollection.assetCollectionType == .album {
                // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
                // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                /**
                 *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
                 *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
                 */
                if let placeholder = assetChangeRequest?.placeholderForCreatedAsset {
                    assetCollectionChangeRequest?.addAssets(NSArray(object: placeholder))
                }
            }
        } completionHandler: { success, error in
            if completionHandler != nil {
                /**
                 *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
                 *  为了避免这种情况，这里该 block 主动放到主线程执行。
                 */
                DispatchQueue.main.async {
                    // 若创建时间为 nil，则说明 performChanges 中传入的资源为空，因此需要同时判断 performChanges 是否执行成功以及资源是否有创建时间。
                    let creatingSuccess = success && creationDate != nil
                    completionHandler?(creatingSuccess, creationDate, error)
                }
            }
        }
    }

    public func fw_addVideo(toAlbum videoPathURL: URL, assetCollection: PHAssetCollection, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        var creationDate: Date?
        self.performChanges {
            // 创建一个以视频生成新的 PHAsset 的请求
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoPathURL)
            assetChangeRequest?.creationDate = Date()
            creationDate = assetChangeRequest?.creationDate
            
            if assetCollection.assetCollectionType == .album {
                // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
                // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                /**
                 *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
                 *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
                 */
                if let placeholder = assetChangeRequest?.placeholderForCreatedAsset {
                    assetCollectionChangeRequest?.addAssets(NSArray(object: placeholder))
                }
            }
        } completionHandler: { success, error in
            if completionHandler != nil {
                /**
                 *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
                 *  为了避免这种情况，这里该 block 主动放到主线程执行。
                 */
                DispatchQueue.main.async {
                    completionHandler?(success, creationDate, error)
                }
            }
        }
    }
    
    /**
     *  根据 contentType 的值产生一个合适的 PHFetchOptions，并把内容以资源创建日期排序，创建日期较新的资源排在前面
     *
     *  @param albumContentType 相册的内容类型
     *
     *  @return 返回一个合适的 PHFetchOptions
     */
    public static func fw_createFetchOptions(albumContentType: AlbumContentType) -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        // 根据输入的内容类型过滤相册内的资源
        switch albumContentType {
        case .onlyPhoto:
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.image.rawValue)
        case .onlyVideo:
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.video.rawValue)
        case .onlyAudio:
            fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.audio.rawValue)
        case .onlyLivePhoto:
            fetchOptions.predicate = NSPredicate(format: "(mediaType = %i) AND ((mediaSubtype & %d) == %d)", PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoLive.rawValue, PHAssetMediaSubtype.photoLive.rawValue)
        default:
            break
        }
        return fetchOptions
    }

    /**
     *  获取所有相册
     *
     *  @param albumContentType 相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
     *  @param showEmptyAlbum 是否显示空相册（经过 contentType 过滤后仍为空的相册）
     *  @param showSmartAlbum 是否显示“智能相册”
     *
     *  @return 返回包含所有合适相册的数组
     */
    public static func fw_fetchAllAlbums(albumContentType: AlbumContentType, showEmptyAlbum: Bool, showSmartAlbum: Bool) -> [PHAssetCollection] {
        var albumsArray: [PHAssetCollection] = []
        // 创建一个 PHFetchOptions，用于创建 AssetGroup 对资源的排序和类型进行控制
        let fetchOptions = fw_createFetchOptions(albumContentType: albumContentType)
        
        var fetchResult: PHFetchResult<PHAssetCollection>
        if showSmartAlbum {
            // 允许显示系统的“智能相册”
            // 获取保存了所有“智能相册”的 PHFetchResult
            fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        } else {
            // 不允许显示系统的智能相册，但由于在 PhotoKit 中，“相机胶卷”也属于“智能相册”，因此这里从“智能相册”中单独获取到“相机胶卷”
            fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        }
        // 循环遍历相册列表
        for i in 0 ..< fetchResult.count {
            // 获取一个相册
            let assetCollection = fetchResult[i]
            // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0，只有资源数量大于 0 的相册才会作为有效的相册显示
            let currentFetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            if currentFetchResult.count > 0 || showEmptyAlbum {
                // 若相册不为空，或者允许显示空相册，则保存相册到结果数组
                // 判断如果是“相机胶卷”，则放到结果列表的第一位
                if assetCollection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    albumsArray.insert(assetCollection, at: 0)
                } else {
                    albumsArray.append(assetCollection)
                }
            }
        }
        
        // 获取所有用户自己建立的相册
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        // 循环遍历用户自己建立的相册
        for i in 0 ..< topLevelUserCollections.count {
            // 获取一个相册
            if let assetCollection = topLevelUserCollections[i] as? PHAssetCollection {
                if showEmptyAlbum {
                    // 允许显示空相册，直接保存相册到结果数组中
                    albumsArray.append(assetCollection)
                } else {
                    // 不允许显示空相册，需要判断当前相册是否为空
                    let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
                    // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0
                    if fetchResult.count > 0 {
                        albumsArray.append(assetCollection)
                    }
                }
            }
        }
        
        // 获取从 macOS 设备同步过来的相册，同步过来的相册不允许删除照片，因此不会为空
        let macCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil)
        // 循环从 macOS 设备同步过来的相册
        for i in 0 ..< macCollections.count {
            // 获取一个相册
            albumsArray.append(macCollections[i])
        }
        
        return albumsArray
    }

    /// 获取一个 PHAssetCollection 中创建日期最新的资源
    public static func fw_fetchLatestAsset(assetCollection: PHAssetCollection) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        // 按时间的先后对 PHAssetCollection 内的资源进行排序，最新的资源排在数组最后面
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        // 获取 PHAssetCollection 内最后一个资源，即最新的资源
        let latestAsset = fetchResult.lastObject
        return latestAsset
    }

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
    public func fw_showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping (Any?, Any?, Bool) -> Void) {
        var plugin: ImagePickerPlugin
        if let pickerPlugin = self.fw_imagePickerPlugin, pickerPlugin.responds(to: #selector(ImagePickerPlugin.viewController(_:showImageCamera:allowsEditing:customBlock:completion:))) {
            plugin = pickerPlugin
        } else {
            plugin = ImagePickerPluginImpl.shared
        }
        plugin.viewController?(self, showImageCamera: filterType, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
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
    public func fw_showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void) {
        var plugin: ImagePickerPlugin
        if let pickerPlugin = self.fw_imagePickerPlugin, pickerPlugin.responds(to: #selector(ImagePickerPlugin.viewController(_:showImagePicker:selectionLimit:allowsEditing:customBlock:completion:))) {
            plugin = pickerPlugin
        } else {
            plugin = ImagePickerPluginImpl.shared
        }
        plugin.viewController?(self, showImagePicker: filterType, selectionLimit: selectionLimit, allowsEditing: allowsEditing, customBlock: customBlock, completion: completion)
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
    public func fw_showImageCamera(filterType: ImagePickerFilterType, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping (Any?, Any?, Bool) -> Void) {
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
    public func fw_showImagePicker(filterType: ImagePickerFilterType, selectionLimit: Int, allowsEditing: Bool, customBlock: ((Any) -> Void)?, completion: @escaping ([Any], [Any], Bool) -> Void) {
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
                object = info[.mediaURL]
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
                cropController.onDidCropToRect = { image, cropRect, angle in
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
            let filterType = self.filterType
            let completion = self.completionBlock
            if self.shouldDismiss {
                picker.dismiss(animated: true) {
                    PickerViewControllerDelegate.picker(nil, didFinishPicking: results, filterType: filterType, completion: completion)
                }
            } else {
                PickerViewControllerDelegate.picker(picker, didFinishPicking: results, filterType: filterType, completion: completion)
            }
        }
        
        static func picker(_ picker: PHPickerViewController?, didFinishPicking results: [PHPickerResult], filterType: ImagePickerFilterType, completion: ((PHPickerViewController?, [Any], [PHPickerResult], Bool) -> Void)?) {
            if completion == nil { return }
            if results.count < 1 {
                completion?(picker, [], results, true)
                return
            }
            
            var objects: [Any] = []
            let totalCount = results.count
            var finishCount: Int = 0
            let checkLivePhoto = filterType.contains(.livePhoto) || filterType.rawValue < 1
            let checkVideo = filterType.contains(.video) || filterType.rawValue < 1
            for result in results {
                let isVideo = checkVideo && result.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String)
                if !isVideo {
                    var objectClass: NSItemProviderReading.Type = UIImage.self
                    if checkLivePhoto, result.itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                        objectClass = PHLivePhoto.self
                    }
                    
                    result.itemProvider.loadObject(ofClass: objectClass) { object, error in
                        DispatchQueue.main.async {
                            if let image = object as? UIImage {
                                objects.append(image)
                            } else if let livePhoto = object as? PHLivePhoto {
                                objects.append(livePhoto)
                            }
                            
                            finishCount += 1
                            if finishCount == totalCount {
                                completion?(picker, objects, results, false)
                            }
                        }
                    }
                    continue
                }
                
                // completionHandler完成后，临时文件url会被系统删除，所以在此期间移动临时文件到FWImagePicker目录
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { url, error in
                    var fileURL: URL?
                    if let url = url {
                        let filePath = AssetManager.cachePath
                        try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                        if let fullPath = ((filePath as NSString).appendingPathComponent(url.absoluteString.fw_md5Encode) as NSString).appendingPathExtension(url.pathExtension) {
                            let tempFileURL = NSURL.fileURL(withPath: fullPath)
                            do {
                                try FileManager.default.moveItem(at: url, to: tempFileURL)
                                fileURL = tempFileURL
                            } catch { }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        if let fileURL = fileURL {
                            objects.append(fileURL)
                        }
                        
                        finishCount += 1
                        if finishCount == totalCount {
                            completion?(picker, objects, results, false)
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
        
        var configuration = PHPickerConfiguration()
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
                cropController.onDidCropToRect = { image, cropRect, angle in
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
            } else {
                picker?.dismiss(animated: true, completion: {
                    completion(objects as? [UIImage] ?? [], results, cancel)
                })
            }
        }
        return pickerController
    }
    
}
