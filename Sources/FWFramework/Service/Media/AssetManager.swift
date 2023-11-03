//
//  AssetManager.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

// MARK: - Asset
/// 资源类型枚举
@objc(__FWAssetType)
public enum AssetType: UInt {
    case unknown = 0
    case image
    case video
    case audio
}

/// 资源子类型枚举
@objc(__FWAssetSubType)
public enum AssetSubType: UInt {
    case unknown = 0
    case image
    case livePhoto
    case gif
}

/// 资源下载状态枚举
public enum AssetDownloadStatus: UInt {
    case succeed = 0
    case downloading
    case canceled
    case failed
}

/// 相册里某一个资源的包装对象，该资源可能是图片、视频等
///
/// Asset 重写了 isEqual: 方法，只要两个 Asset 的 identifier 相同，则认为是同一个对象，以方便在数组、字典等容器中对大量 Asset 进行遍历查找等操作
@objcMembers
@objc(__FWAsset)
public class Asset: NSObject {
    
    /// 只读PHAsset对象
    public let phAsset: PHAsset
    /// 只读资源类型
    public private(set) var assetType: AssetType = .unknown
    /// 只读资源子类型
    public private(set) var assetSubType: AssetSubType = .unknown
    /// 从 iCloud 下载资源大图的状态
    public private(set) var downloadStatus: AssetDownloadStatus = .succeed
    /// 从 iCloud 下载资源大图的进度
    public var downloadProgress: Double = 0 {
        didSet { downloadStatus = .downloading }
    }
    /// 从 iCloud 请求获得资源的大图的请求 ID
    public var requestID: Int = 0
    /// 自定义编辑后的图片，用于实现图片裁剪等功能，默认nil
    public var editedImage: UIImage?
    /// 自定义请求结果对象，用于保存请求结果场景，默认nil
    public var requestObject: Any?
    /// 自定义请求结果信息，用于保存请求结果场景，默认nil
    public var requestInfo: [AnyHashable: Any]?
    /// Asset 的标识，每个 Asset 的 identifier 都不同。只要两个 Asset 的 identifier 相同则认为它们是同一个 asset
    public var identifier: String {
        return phAsset.localIdentifier
    }
    
    private var phAssetInfo: [AnyHashable: Any]?
    
    private static let kAssetInfoImageData = "imageData"
    private static let kAssetInfoOriginInfo = "originInfo"
    private static let kAssetInfoDataUTI = "dataUTI"
    private static let kAssetInfoOrientation = "orientation"
    private static let kAssetInfoSize = "size"
    
    /// 初始化方法
    public init(phAsset: PHAsset) {
        self.phAsset = phAsset
        super.init()
        
        switch phAsset.mediaType {
        case .image:
            self.assetType = .image
            if (phAsset.fw_invokeGetter("uniformTypeIdentifier") as? String) == (kUTTypeGIF as String) {
                self.assetSubType = .gif
            } else {
                if phAsset.mediaSubtypes.contains(.photoLive) {
                    self.assetSubType = .livePhoto
                } else {
                    self.assetSubType = .image
                }
            }
        case .video:
            self.assetType = .video
        case .audio:
            self.assetType = .audio
        default:
            self.assetType = .unknown
        }
    }
    
    /// Asset 的原图（包含系统相册“编辑”功能处理后的效果）
    public var originImage: UIImage? {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = true
        
        var resultImage: UIImage?
        AssetManager.shared.phCachingImageManager.requestImageDataAndOrientation(for: phAsset, options: imageRequestOptions, resultHandler: { imageData, _, _, _ in
            if let imageData = imageData {
                resultImage = UIImage(data: imageData)
            }
        })
        return resultImage
    }
    
    /// Asset 的缩略图，size 指定返回的缩略图的大小，pt 为单位
    public func thumbnailImage(size: CGSize) -> UIImage? {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.isSynchronous = true
        
        // 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
        var resultImage: UIImage?
        AssetManager.shared.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: .aspectFill, options: imageRequestOptions) { result, _ in
            resultImage = result
        }
        return resultImage
    }
    
    /// Asset 的预览图，输出与当前设备屏幕大小相同尺寸的图片，如果图片原图小于当前设备屏幕的尺寸，则只输出原图大小的图片
    public var previewImage: UIImage? {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = true
        
        var resultImage: UIImage?
        AssetManager.shared.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2), contentMode: .aspectFill, options: imageRequestOptions) { result, _ in
            resultImage = result
        }
        return resultImage
    }
    
    /**
     异步请求 Asset 的原图，包含了系统照片“编辑”功能处理后的效果（剪裁，旋转和滤镜等），可能会有网络请求

     - Parameters:
       - completion: 请求完成后调用的闭包，包含请求的原图和图片信息。该闭包会被多次调用，第一次调用获取到的是低清图，然后不断调用直到获取到高清图。
       - progressHandler: 处理请求进度的处理程序，在闭包中修改 UI 时需要手动放到主线程处理。

     - Returns: 返回请求图片的请求 id
     */
    @discardableResult
    public func requestOriginImage(completion: ((_ result: UIImage?, _ info: [AnyHashable: Any]?, _ finished: Bool) -> Void)?, progressHandler: PHAssetImageProgressHandler? = nil) -> Int {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.progressHandler = progressHandler
        
        let imageRequestId = AssetManager.shared.phCachingImageManager.requestImageDataAndOrientation(for: phAsset, options: imageRequestOptions) { imageData, _, _, info in
            var image: UIImage?
            if let imageData = imageData {
                image = UIImage(data: imageData)
            }
            completion?(image, info, true)
        }
        return Int(imageRequestId)
    }

    /**
     异步请求 Asset 的缩略图，不会产生网络请求

     - Parameters:
       - size: 指定返回的缩略图的大小
       - completion: 请求完成后调用的闭包，包含请求的缩略图和图片信息。该闭包会被多次调用，第一次调用获取到的是低清图，然后不断调用直到获取到高清图，此时闭包中的第二个参数（图片信息）为 nil。

     - Returns: 返回请求图片的请求 id
     */
    @discardableResult
    public func requestThumbnailImage(size: CGSize, completion: ((_ result: UIImage?, _ info: [AnyHashable: Any]?, _ finished: Bool) -> Void)?) -> Int {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.resizeMode = .fast
        
        // 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
        let imageRequestId = AssetManager.shared.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: .aspectFill, options: imageRequestOptions) { result, info in
            let downloadSucceed = (result != nil && info == nil) || (!Asset.isValueTrue(info, key: PHImageCancelledKey) && info?[PHImageErrorKey] == nil && !Asset.isValueTrue(info, key: PHImageResultIsDegradedKey))
            let downloadFailed = info?[PHImageErrorKey] != nil
            completion?(result, info, downloadSucceed || downloadFailed)
        }
        return Int(imageRequestId)
    }

    /**
     异步请求 Asset 的预览图，可能会有网络请求

     - Parameters:
       - completion: 请求完成后调用的闭包，包含请求的预览图和图片信息。该闭包会被多次调用，第一次调用获取到的是低清图，然后不断调用直到获取到高清图。
       - progressHandler: 处理请求进度的处理程序，在闭包中修改 UI 时需要手动放到主线程处理。

     - Returns: 返回请求图片的请求 id
     */
    @discardableResult
    public func requestPreviewImage(completion: ((_ result: UIImage?, _ info: [AnyHashable: Any]?, _ finished: Bool) -> Void)?, progressHandler: PHAssetImageProgressHandler? = nil) -> Int {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.progressHandler = progressHandler
        
        let imageRequestId = AssetManager.shared.phCachingImageManager.requestImage(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2), contentMode: .aspectFill, options: imageRequestOptions) { result, info in
            let downloadSucceed = (result != nil && info == nil) || (!Asset.isValueTrue(info, key: PHImageCancelledKey) && info?[PHImageErrorKey] == nil && !Asset.isValueTrue(info, key: PHImageResultIsDegradedKey))
            let downloadFailed = info?[PHImageErrorKey] != nil
            completion?(result, info, downloadSucceed || downloadFailed)
        }
        return Int(imageRequestId)
    }

    /**
     异步请求 Live Photo，可能会有网络请求

     - Parameters:
       - completion: 请求完成后调用的闭包，包含请求的 Live Photo 和相关信息。如果 assetType 不是 AssetTypeLivePhoto，则为 nil。
       - progressHandler: 处理请求进度的处理程序，在闭包中修改 UI 时需要手动放到主线程处理。

     - Returns: 返回请求 Live Photo 的请求 id
     */
    @discardableResult
    public func requestLivePhoto(completion: ((_ livePhoto: PHLivePhoto?, _ info: [AnyHashable: Any]?, _ finished: Bool) -> Void)?, progressHandler: PHAssetImageProgressHandler? = nil) -> Int {
        let livePhotoRequestOptions = PHLivePhotoRequestOptions()
        livePhotoRequestOptions.isNetworkAccessAllowed = true
        livePhotoRequestOptions.progressHandler = progressHandler
        
        let livePhotoRequestId = AssetManager.shared.phCachingImageManager.requestLivePhoto(for: phAsset, targetSize: CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2), contentMode: .aspectFill, options: livePhotoRequestOptions) { livePhoto, info in
            let downloadSucceed = (livePhoto != nil && info == nil) || (!Asset.isValueTrue(info, key: PHLivePhotoInfoCancelledKey) && info?[PHLivePhotoInfoErrorKey] == nil && !Asset.isValueTrue(info, key: PHLivePhotoInfoIsDegradedKey) && !Asset.isValueTrue(info, key: PHImageCancelledKey) && info?[PHImageErrorKey] == nil && !Asset.isValueTrue(info, key: PHImageResultIsDegradedKey))
            let downloadFailed = info?[PHLivePhotoInfoErrorKey] != nil || info?[PHImageErrorKey] != nil
            completion?(livePhoto, info, downloadSucceed || downloadFailed)
        }
        return Int(livePhotoRequestId)
    }
    
    /**
     异步请求 AVPlayerItem，可能会有网络请求

     - Parameters:
       - completion: 完成请求后调用的 block，参数中包含了请求的 AVPlayerItem 以及相关信息，若 assetType 不是 AssetTypeVideo 则为 nil
       - progressHandler: 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
     
     - Returns: 返回请求 AVPlayerItem 的请求 id
     */
    @discardableResult
    public func requestPlayerItem(completion: ((_ playerItem: AVPlayerItem?, _ info: [AnyHashable: Any]?) -> Void)?, progressHandler: PHAssetVideoProgressHandler? = nil) -> Int {
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = progressHandler
        
        let videoRequestId = AssetManager.shared.phCachingImageManager.requestPlayerItem(forVideo: phAsset, options: videoRequestOptions) { playerItem, info in
            completion?(playerItem, info)
        }
        return Int(videoRequestId)
    }

    /**
     异步请求 视频文件URL，可能会有网络请求

     - Parameters:
       - outputURL: 视频输出文件URL路径，如果路径已存在会导出失败
       - exportPreset: 导出视频选项配置
       - completion: 完成请求后调用的 block，参数中包含了请求的 文件URL 以及相关信息，若 assetType 不是 AssetTypeVideo 则为 nil
       - progressHandler: 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
     
     - Returns: 返回请求 视频文件URL 的请求 id
     */
    @discardableResult
    public func requestVideoURL(outputURL: URL, exportPreset: String, completion: ((_ videoURL: URL?, _ info: [AnyHashable: Any]?) -> Void)?, progressHandler: PHAssetVideoProgressHandler? = nil) -> Int {
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = progressHandler
        
        let videoRequestId = AssetManager.shared.phCachingImageManager.requestExportSession(forVideo: phAsset, options: videoRequestOptions, exportPreset: exportPreset) { exportSession, info in
            guard let exportSession = exportSession else {
                completion?(nil, info)
                return
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.exportAsynchronously {
                if exportSession.status == .completed {
                    completion?(outputURL, info)
                } else {
                    completion?(nil, info)
                }
            }
        }
        return Int(videoRequestId)
    }

    /**
     异步请求图片的 Data

     - Parameter completion: 完成请求后调用的 block，参数中包含了请求的图片 Data（若 assetType 不是 AssetTypeImage 或 AssetTypeLivePhoto 则为 nil），该图片是否为 GIF 的判断值，以及该图片的文件格式是否为 HEIC
     */
    public func requestImageData(completion: ((_ imageData: Data?, _ info: [AnyHashable: Any]?, _ isGIF: Bool, _ isHEIC: Bool) -> Void)?) {
        guard assetType == .image else {
            completion?(nil, nil, false, false)
            return
        }
        
        if let phAssetInfo = phAssetInfo {
            let imageData = phAssetInfo[Asset.kAssetInfoImageData] as? Data
            let originInfo = phAssetInfo[Asset.kAssetInfoOriginInfo] as? [AnyHashable: Any]
            let dataUTI = phAssetInfo[Asset.kAssetInfoDataUTI] as? String
            let isGIF = assetSubType == .gif
            let isHEIC = "public.heic" == dataUTI
            completion?(imageData, originInfo, isGIF, isHEIC)
        } else {
            requestPhAssetInfo { [weak self] phAssetInfo in
                self?.phAssetInfo = phAssetInfo
                
                let imageData = phAssetInfo[Asset.kAssetInfoImageData] as? Data
                let originInfo = phAssetInfo[Asset.kAssetInfoOriginInfo] as? [AnyHashable: Any]
                let dataUTI = phAssetInfo[Asset.kAssetInfoDataUTI] as? String
                let isGIF = self?.assetSubType == .gif
                let isHEIC = "public.heic" == dataUTI
                completion?(imageData, originInfo, isGIF, isHEIC)
            }
        }
    }
    
    private func requestPhAssetInfo(completion: (([AnyHashable: Any]) -> Void)?) {
        if assetType == .video {
            let videoRequestOptions = PHVideoRequestOptions()
            videoRequestOptions.isNetworkAccessAllowed = true
            
            AssetManager.shared.phCachingImageManager.requestAVAsset(forVideo: phAsset, options: videoRequestOptions) { asset, _, info in
                var phAssetInfo: [AnyHashable: Any] = [:]
                if let info = info {
                    phAssetInfo[Asset.kAssetInfoOriginInfo] = info
                }
                if let asset = asset as? AVURLAsset {
                    var size: AnyObject?
                    try? (asset.url as NSURL).getResourceValue(&size, forKey: .fileSizeKey)
                    phAssetInfo[Asset.kAssetInfoSize] = size
                }
                completion?(phAssetInfo)
            }
        } else {
            requestImagePhAssetInfo(synchronous: false, completion: completion)
        }
    }
    
    private func requestImagePhAssetInfo(synchronous: Bool, completion: (([AnyHashable: Any]) -> Void)?) {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = synchronous
        imageRequestOptions.isNetworkAccessAllowed = true
        
        AssetManager.shared.phCachingImageManager.requestImageDataAndOrientation(for: phAsset, options: imageRequestOptions) { imageData, dataUTI, exifOrientation, info in
            var phAssetInfo: [AnyHashable: Any] = [:]
            if let imageData = imageData {
                phAssetInfo[Asset.kAssetInfoImageData] = imageData
                phAssetInfo[Asset.kAssetInfoSize] = NSNumber(value: imageData.count)
            }
            if let info = info {
                phAssetInfo[Asset.kAssetInfoOriginInfo] = info
            }
            if let dataUTI = dataUTI {
                phAssetInfo[Asset.kAssetInfoDataUTI] = dataUTI
            }
            phAssetInfo[Asset.kAssetInfoOrientation] = NSNumber(value: ImageCoder.imageOrientation(from: exifOrientation).rawValue)
            completion?(phAssetInfo)
        }
    }
    
    private static func isValueTrue(_ info: [AnyHashable: Any]?, key: String) -> Bool {
        let number = info?[key] as? NSNumber
        return number?.boolValue ?? false
    }
    
    /// 获取图片的 UIImageOrientation 值，仅 assetType 为 AssetTypeImage 或 AssetTypeLivePhoto 时有效
    public var imageOrientation: UIImage.Orientation {
        var orientation: UIImage.Orientation = .up
        if assetType == .image {
            if phAssetInfo == nil {
                requestImagePhAssetInfo(synchronous: true) { [weak self] phAssetInfo in
                    self?.phAssetInfo = phAssetInfo
                }
            }
            let number = phAssetInfo?[Asset.kAssetInfoOrientation] as? NSNumber
            orientation = .init(rawValue: number?.intValue ?? 0) ?? .up
        }
        return orientation
    }
    
    /// 更新下载资源的结果
    public func updateDownloadStatus(downloadResult succeed: Bool) {
        downloadStatus = succeed ? .succeed : .failed
    }
    
    /// 获取 Asset 的体积（数据大小）
    public func assetSize(completion: ((Int64) -> Void)?) {
        if let phAssetInfo = phAssetInfo {
            let number = phAssetInfo[Asset.kAssetInfoSize] as? NSNumber
            completion?(number?.int64Value ?? 0)
        } else {
            requestPhAssetInfo { [weak self] phAssetInfo in
                self?.phAssetInfo = phAssetInfo
                DispatchQueue.main.async {
                    let number = phAssetInfo[Asset.kAssetInfoSize] as? NSNumber
                    completion?(number?.int64Value ?? 0)
                }
            }
        }
    }
    
    /// 获取 Asset 的总时长（仅视频）
    public var duration: TimeInterval {
        guard assetType == .video else { return 0 }
        return phAsset.duration
    }
    
    /// 重写比较方法，只要两个 Asset 的 identifier 相同则认为它们是同一个 asset
    public override func isEqual(_ object: Any?) -> Bool {
        if let asset = object as? Asset,
           asset.identifier == identifier {
            return true
        }
        return super.isEqual(object)
    }
    
}

// MARK: - AssetGroup
/// 相册展示内容的类型
@objc
public enum AlbumContentType: UInt {
    /// 展示所有资源
    case all = 0
    /// 只展示照片
    case onlyPhoto
    /// 只展示视频
    case onlyVideo
    /// 只展示音频
    case onlyAudio
    /// 只展示LivePhoto
    case onlyLivePhoto
}

/// 相册展示内容按日期排序的方式
@objc
public enum AlbumSortType: UInt {
    /// 日期最新的内容排在后面
    case positive = 0
    /// 日期最新的内容排在前面
    case reverse
}

/// 资源分组
@objcMembers
@objc(__FWAssetGroup)
public class AssetGroup: NSObject {
    
    /// 只读PHAssetCollection对象
    public let phAssetCollection: PHAssetCollection
    /// 只读PHFetchResult对象
    public let phFetchResult: PHFetchResult<PHAsset>
    
    /// 相册的名称
    public var name: String? {
        let resultName = phAssetCollection.localizedTitle ?? ""
        return NSLocalizedString(resultName, comment: resultName)
    }
    
    /// 相册内的资源数量，包括视频、图片、音频（如果支持）这些类型的所有资源
    public var numberOfAssets: Int {
        return phFetchResult.count
    }
    
    /// 初始化方法
    public init(phAssetCollection: PHAssetCollection, fetchAssetsOptions: PHFetchOptions? = nil) {
        self.phAssetCollection = phAssetCollection
        self.phFetchResult = PHAsset.fetchAssets(in: phAssetCollection, options: fetchAssetsOptions)
        super.init()
    }
    
    /// 相册的缩略图，即系统接口中的相册海报（Poster Image）
    public func posterImage(size: CGSize) -> UIImage? {
        // 系统的隐藏相册不应该显示缩略图
        if phAssetCollection.assetCollectionSubtype == .smartAlbumAllHidden {
            return nil
        }
        
        var resultImage: UIImage?
        let count = phFetchResult.count
        if count > 0 {
            let asset = phFetchResult[count - 1]
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.isSynchronous = true
            imageRequestOptions.resizeMode = .exact
            // targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
            AssetManager.shared.phCachingImageManager.requestImage(for: asset, targetSize: CGSize(width: size.width * UIScreen.main.scale, height: size.height * UIScreen.main.scale), contentMode: .aspectFill, options: imageRequestOptions) { result, _ in
                resultImage = result
            }
        }
        return resultImage
    }
    
    /// 枚举相册内所有的资源
    ///
    /// - Parameters:
    ///   - options: 相册内资源的排序方式，可以选择日期最新的排在最前面，默认日期最新的排在最后面
    ///   - block: 枚举相册内资源时调用的 block，参数 result 表示每次枚举时对应的资源。枚举所有资源结束后，enumerationBlock 会被再调用一次，这时 result 的值为 nil。可以以此作为判断枚举结束的标记
    public func enumerateAssets(options: AlbumSortType = .positive, using block: ((Asset?) -> Void)?) {
        let resultCount = phFetchResult.count
        if options == .reverse {
            for i in (0 ..< resultCount).reversed() {
                let asset = Asset(phAsset: phFetchResult[i])
                block?(asset)
            }
        } else {
            for i in 0 ..< resultCount {
                let asset = Asset(phAsset: phFetchResult[i])
                block?(asset)
            }
        }
        
        // For 循环遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举资源结束的标记
        block?(nil)
    }
    
}

// MARK: - AssetManager
/// Asset 授权的状态
@objc(__FWAssetAuthorizationStatus)
public enum AssetAuthorizationStatus: UInt {
    /// 还不确定有没有授权
    case notDetermined = 0
    /// 已经授权
    case authorized
    /// 手动禁止了授权
    case notAuthorized
}

/// 构建 AssetManager 这个对象并提供单例的调用方式主要出于下面两点考虑：
/// 1. 保存照片/视频的方法较为复杂，为了方便封装系统接口，同时灵活地扩展功能，需要有一个独立对象去管理这些方法。
///  2. 使用 PhotoKit 获取图片，基本都需要一个 PHCachingImageManager 的实例，为了减少消耗，AssetManager 单例内部也构建了一个 PHCachingImageManager，并且暴露给外面，方便获取PHCachingImageManager 的实例。
///
///  [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
@objcMembers
@objc(__FWAssetManager)
public class AssetManager: NSObject {
    
    /// 获取 AssetManager 的单例
    public static let shared = AssetManager()
    
    /// 资源管理器临时文件存放目录，使用完成后需自行删除
    public static var cachePath: String {
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        return (cachesPath as NSString).appendingPathComponent("FWAssetManager")
    }
    
    /// 获取当前应用的“照片”访问授权状态
    public static var authorizationStatus: AssetAuthorizationStatus {
        let status: AssetAuthorizationStatus
        let phStatus = PHPhotoLibrary.authorizationStatus()
        if phStatus == .restricted || phStatus == .denied {
            status = .notAuthorized
        } else if phStatus == .notDetermined {
            status = .notDetermined
        } else {
            status = .authorized
        }
        return status
    }
    
    /// 调起系统询问是否授权访问“照片”的 UIAlertView
    ///
    /// - Parameter completion: 授权结束后调用的 block，默认不在主线程上执行，如果需要在 block 中修改 UI，记得 dispatch 到 mainqueue
    public static func requestAuthorization(completion: ((AssetAuthorizationStatus) -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { phStatus in
            let status: AssetAuthorizationStatus
            if phStatus == .restricted || phStatus == .denied {
                status = .notAuthorized
            } else if phStatus == .notDetermined {
                status = .notDetermined
            } else {
                status = .authorized
            }
            completion?(status)
        }
    }
    
    /// 保存图片到指定相册（传入 UIImage）
    public static func saveImage(image: UIImage?, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        guard let image = image, let cgImage = image.cgImage else {
            completion(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil))
            return
        }
        
        AssetManager.shared.saveImage(imageRef: cgImage, albumAssetsGroup: albumAssetsGroup, orientation: image.imageOrientation, completion: completion)
    }
    
    /// 保存图片到指定相册（传入 图片路径）
    public static func saveImage(imagePath: String, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        AssetManager.shared.saveImage(imagePathURL: NSURL.fileURL(withPath: imagePath), albumAssetsGroup: albumAssetsGroup, completion: completion)
    }
    
    /// 保存视频到指定相册（传入 视频路径）
    public static func saveVideo(videoPath: String, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        AssetManager.shared.saveVideo(videoPathURL: NSURL.fileURL(withPath: videoPath), albumAssetsGroup: albumAssetsGroup, completion: completion)
    }
    
    /// 获取一个 PHCachingImageManager 的实例
    public lazy var phCachingImageManager = PHCachingImageManager()
    
    /// 获取所有的相册，包括个人收藏，最近添加，自拍这类“智能相册”
    ///
    /// - Parameters:
    ///   - albumContentType: 相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
    ///   - showEmptyAlbum: 是否显示空相册（经过 contentType 过滤后仍为空的相册），默认false
    ///   - showSmartAlbum: 是否显示"智能相册"，默认true
    ///   - block: 参数 resultAssetsGroup 表示每次枚举时对应的相册。枚举所有相册结束后，enumerationBlock 会被再调用一次，这时 resultAssetsGroup 的值为 nil。可以以此作为判断枚举结束的标记。
    public func enumerateAllAlbums(albumContentType: AlbumContentType, showEmptyAlbum: Bool = false, showSmartAlbum: Bool = true, using block: ((AssetGroup?) -> Void)?) {
        // 根据条件获取所有合适的相册，并保存到临时数组中
        let albumsArray = PHPhotoLibrary.fw_fetchAllAlbums(albumContentType: albumContentType, showEmptyAlbum: showEmptyAlbum, showSmartAlbum: showSmartAlbum)
        // 创建一个 PHFetchOptions，用于 AssetGroup 对资源的排序以及对内容类型进行控制
        let phFetchOptions = PHPhotoLibrary.fw_createFetchOptions(albumContentType: albumContentType)
        // 遍历结果，生成对应的 AssetGroup，并调用 enumerationBlock
        for i in 0 ..< albumsArray.count {
            let assetsGroup = AssetGroup(phAssetCollection: albumsArray[i], fetchAssetsOptions: phFetchOptions)
            block?(assetsGroup)
        }
        
        // 所有结果遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举相册结束的标记
        block?(nil)
    }
    
    /// 保存图片到指定相册（传入 CGImage）
    public func saveImage(imageRef: CGImage, albumAssetsGroup: AssetGroup, orientation: UIImage.Orientation, completion: @escaping (Asset?, Error?) -> Void) {
        let assetCollection = albumAssetsGroup.phAssetCollection
        PHPhotoLibrary.shared().fw_addImage(toAlbum: assetCollection, imageRef: imageRef, orientation: orientation) { success, creationDate, error in
            if success {
                let fetchOptions = PHFetchOptions()
                let fetchDate = creationDate as? NSDate ?? NSDate()
                fetchOptions.predicate = NSPredicate(format: "creationDate = %@", fetchDate)
                let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
                var asset: Asset?
                if let phAsset = fetchResult.lastObject {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /// 保存图片到指定相册（传入 图片路径URL）
    public func saveImage(imagePathURL: URL, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        let assetCollection = albumAssetsGroup.phAssetCollection
        PHPhotoLibrary.shared().fw_addImage(toAlbum: assetCollection, imagePathURL: imagePathURL) { success, creationDate, error in
            if success {
                let fetchOptions = PHFetchOptions()
                let fetchDate = creationDate as? NSDate ?? NSDate()
                fetchOptions.predicate = NSPredicate(format: "creationDate = %@", fetchDate)
                let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
                var asset: Asset?
                if let phAsset = fetchResult.lastObject {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /// 保存视频到指定相册（传入 视频路径URL）
    public func saveVideo(videoPathURL: URL, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        let assetCollection = albumAssetsGroup.phAssetCollection
        PHPhotoLibrary.shared().fw_addVideo(toAlbum: assetCollection, videoPathURL: videoPathURL) { success, creationDate, error in
            if success {
                let fetchOptions = PHFetchOptions()
                let fetchDate = creationDate as? NSDate ?? NSDate()
                fetchOptions.predicate = NSPredicate(format: "creationDate = %@", fetchDate)
                let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
                var asset: Asset?
                if let phAsset = fetchResult.lastObject {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
}

// MARK: - LivePhoto
/// [LivePhoto](https://github.com/LimitPoint/LivePhoto)
public class LivePhoto {
    
    /// LivePhoto资源定义
    public typealias Resources = (pairedImage: URL, pairedVideo: URL)
    
    /// 导出LivePhoto资源
    public class func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (Resources?) -> Void) {
        queue.async {
            shared.extractResources(from: livePhoto, completion: completion)
        }
    }
    
    /// 生成LivePhoto对象
    public class func generate(from imageURL: URL, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, Resources?) -> Void) {
        queue.async {
            shared.generate(from: imageURL, videoURL: videoURL, progress: progress, completion: completion)
        }
    }
    
    /// 保存LivePhoto资源到相册
    public class func saveToLibrary(_ resources: Resources, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: PHAssetResourceType.pairedVideo, fileURL: resources.pairedVideo, options: options)
            creationRequest.addResource(with: PHAssetResourceType.photo, fileURL: resources.pairedImage, options: options)
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        })
    }
    
    private static let shared = LivePhoto()
    
    private static let queue = DispatchQueue(label: "site.wuyong.queue.asset.async", attributes: .concurrent)
    
    private lazy var cacheDirectory: URL = {
        let fullDirectory = URL(fileURLWithPath: AssetManager.cachePath, isDirectory: true)
        if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
            try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return fullDirectory
    }()
    
    private func generate(from imageURL: URL, videoURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (PHLivePhoto?, Resources?) -> Void) {
        let assetIdentifier = UUID().uuidString
        guard let pairedImageURL = addAssetID(assetIdentifier, toImage: imageURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("jpg")) else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        addAssetID(assetIdentifier, toVideo: videoURL, saveTo: cacheDirectory.appendingPathComponent(assetIdentifier).appendingPathExtension("mov"), progress: progress) { (_videoURL) in
            if let pairedVideoURL = _videoURL {
                _ = PHLivePhoto.request(withResourceFileURLs: [pairedVideoURL, pairedImageURL], placeholderImage: nil, targetSize: CGSize.zero, contentMode: PHImageContentMode.aspectFit, resultHandler: { (livePhoto: PHLivePhoto?, info: [AnyHashable : Any]) -> Void in
                    if let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Bool, isDegraded {
                        return
                    }
                    DispatchQueue.main.async {
                        completion(livePhoto, (pairedImageURL, pairedVideoURL))
                    }
                })
            } else {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, to directoryURL: URL, completion: @escaping (Resources?) -> Void) {
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var keyPhotoURL: URL?
        var videoURL: URL?
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { (data) in
                buffer.append(data)
            }) { (error) in
                if error == nil {
                    if resource.type == .pairedVideo {
                        videoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    } else {
                        keyPhotoURL = self.saveAssetResource(resource, to: directoryURL, resourceData: buffer as Data)
                    }
                } else {
                    print(error as Any)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            guard let pairedPhotoURL = keyPhotoURL, let pairedVideoURL = videoURL else {
                completion(nil)
                return
            }
            completion((pairedPhotoURL, pairedVideoURL))
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (Resources?) -> Void) {
        extractResources(from: livePhoto, to: cacheDirectory, completion: completion)
    }
    
    private func saveAssetResource(_ resource: PHAssetResource, to directory: URL, resourceData: Data) -> URL? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(resource.uniformTypeIdentifier as CFString,kUTTagClassFilenameExtension)?.takeRetainedValue()
        
        guard let ext = fileExtension else {
            return nil
        }
        
        var fileUrl = directory.appendingPathComponent(NSUUID().uuidString)
        fileUrl = fileUrl.appendingPathExtension(ext as String)
        
        do {
            try resourceData.write(to: fileUrl, options: [Data.WritingOptions.atomic])
        } catch {
            print("Could not save resource \(resource) to filepath \(String(describing: fileUrl))")
            return nil
        }
        
        return fileUrl
    }
    
    func addAssetID(_ assetIdentifier: String, toImage imageURL: URL, saveTo destinationURL: URL) -> URL? {
        guard let imageDestination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeJPEG, 1, nil),
              let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
                var imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable : Any] else { return nil }
        let assetIdentifierKey = "17"
        let assetIdentifierInfo = [assetIdentifierKey : assetIdentifier]
        imageProperties[kCGImagePropertyMakerAppleDictionary] = assetIdentifierInfo
        CGImageDestinationAddImage(imageDestination, imageRef, imageProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        return destinationURL
    }
    
    var audioReader: AVAssetReader?
    var videoReader: AVAssetReader?
    var assetWriter: AVAssetWriter?
    
    func addAssetID(_ assetIdentifier: String, toVideo videoURL: URL, saveTo destinationURL: URL, progress: @escaping (CGFloat) -> Void, completion: @escaping (URL?) -> Void) {
        
        var audioWriterInput: AVAssetWriterInput?
        var audioReaderOutput: AVAssetReaderOutput?
        let videoAsset = AVURLAsset(url: videoURL)
        let frameCount = countFrames(asset: videoAsset, exact: false)
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        do {
            // Create the Asset Writer
            assetWriter = try AVAssetWriter(outputURL: destinationURL, fileType: .mov)
            // Create Video Reader Output
            videoReader = try AVAssetReader(asset: videoAsset)
            let videoReaderSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            videoReader?.add(videoReaderOutput)
            // Create Video Writer Input
            let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : videoTrack.naturalSize.width, AVVideoHeightKey : videoTrack.naturalSize.height])
            videoWriterInput.transform = videoTrack.preferredTransform
            videoWriterInput.expectsMediaDataInRealTime = true
            assetWriter?.add(videoWriterInput)
            // Create Audio Reader Output & Writer Input
            if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
                do {
                    let _audioReader = try AVAssetReader(asset: videoAsset)
                    let _audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
                    _audioReader.add(_audioReaderOutput)
                    audioReader = _audioReader
                    audioReaderOutput = _audioReaderOutput
                    let _audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                    _audioWriterInput.expectsMediaDataInRealTime = false
                    assetWriter?.add(_audioWriterInput)
                    audioWriterInput = _audioWriterInput
                } catch {
                    print(error)
                }
            }
            // Create necessary identifier metadata and still image time metadata
            let assetIdentifierMetadata = metadataForAssetID(assetIdentifier)
            let stillImageTimeMetadataAdapter = createMetadataAdaptorForStillImageTime()
            assetWriter?.metadata = [assetIdentifierMetadata]
            assetWriter?.add(stillImageTimeMetadataAdapter.assetWriterInput)
            // Start the Asset Writer
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: CMTime.zero)
            // Add still image metadata
            let _stillImagePercent: Float = 0.5
            stillImageTimeMetadataAdapter.append(AVTimedMetadataGroup(items: [metadataItemForStillImageTime()],timeRange: makeStillImageTimeRange(asset: videoAsset, percent: _stillImagePercent, inFrameCount: frameCount)))
            // For end of writing / progress
            var writingVideoFinished = false
            var writingAudioFinished = false
            var currentFrameCount = 0
            func didCompleteWriting() {
                guard writingAudioFinished && writingVideoFinished else { return }
                assetWriter?.finishWriting {
                    if self.assetWriter?.status == .completed {
                        completion(destinationURL)
                    } else {
                        completion(nil)
                    }
                }
            }
            // Start writing video
            if videoReader?.startReading() ?? false {
                videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoWriterInputQueue")) {
                    while videoWriterInput.isReadyForMoreMediaData {
                        if let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()  {
                            currentFrameCount += 1
                            let percent:CGFloat = CGFloat(currentFrameCount)/CGFloat(frameCount)
                            DispatchQueue.main.async {
                                progress(percent)
                            }
                            if !videoWriterInput.append(sampleBuffer) {
                                print("Cannot write: \(String(describing: self.assetWriter?.error?.localizedDescription))")
                                self.videoReader?.cancelReading()
                            }
                        } else {
                            videoWriterInput.markAsFinished()
                            writingVideoFinished = true
                            didCompleteWriting()
                        }
                    }
                }
            } else {
                writingVideoFinished = true
                didCompleteWriting()
            }
            // Start writing audio
            if audioReader?.startReading() ?? false {
                audioWriterInput?.requestMediaDataWhenReady(on: DispatchQueue(label: "audioWriterInputQueue")) {
                    while audioWriterInput?.isReadyForMoreMediaData ?? false {
                        guard let sampleBuffer = audioReaderOutput?.copyNextSampleBuffer() else {
                            audioWriterInput?.markAsFinished()
                            writingAudioFinished = true
                            didCompleteWriting()
                            return
                        }
                        audioWriterInput?.append(sampleBuffer)
                    }
                }
            } else {
                writingAudioFinished = true
                didCompleteWriting()
            }
        } catch {
            print(error)
            completion(nil)
        }
    }
    
    private func metadataForAssetID(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyContentIdentifier =  "com.apple.quicktime.content.identifier"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyContentIdentifier as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
    
    private func createMetadataAdaptorForStillImageTime() -> AVAssetWriterInputMetadataAdaptor {
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as NSString:
            "\(keySpaceQuickTimeMetadata)/\(keyStillImageTime)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as NSString:
            "com.apple.metadata.datatype.int8"            ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [spec] as CFArray, formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
                                       outputSettings: nil, sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
    
    private func metadataItemForStillImageTime() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        let keyStillImageTime = "com.apple.quicktime.still-image-time"
        let keySpaceQuickTimeMetadata = "mdta"
        item.key = keyStillImageTime as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace(rawValue: keySpaceQuickTimeMetadata)
        item.value = 0 as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.int8"
        return item
    }
    
    private func countFrames(asset: AVAsset, exact:Bool) -> Int {
        var frameCount = 0
        if let videoReader = try? AVAssetReader(asset: asset)  {
            if let videoTrack = asset.tracks(withMediaType: .video).first {
                frameCount = Int(CMTimeGetSeconds(asset.duration) * Float64(videoTrack.nominalFrameRate))
                
                if exact {
                    frameCount = 0
                    let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
                    videoReader.add(videoReaderOutput)
                    videoReader.startReading()
                    
                    while true {
                        let sampleBuffer = videoReaderOutput.copyNextSampleBuffer()
                        if sampleBuffer == nil {
                            break
                        }
                        frameCount += 1
                    }
                    
                    videoReader.cancelReading()
                }
            }
        }
        return frameCount
    }
    
    private func makeStillImageTimeRange(asset: AVAsset, percent:Float, inFrameCount:Int = 0) -> CMTimeRange {
        var time = asset.duration
        var frameCount = inFrameCount
        if frameCount == 0 {
            frameCount = countFrames(asset: asset, exact: true)
        }
        
        let frameDuration = Int64(Float(time.value) / Float(frameCount))
        time.value = Int64(Float(time.value) * percent)
        return CMTimeRangeMake(start: time, duration: CMTimeMake(value: frameDuration, timescale: time.timescale))
    }
    
}
