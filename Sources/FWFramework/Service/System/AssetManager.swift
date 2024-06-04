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
public enum AssetType: UInt {
    case unknown = 0
    case image
    case video
    case audio
}

/// 资源子类型枚举
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
    
    /// 根据唯一标志初始化
    public static func asset(identifier: String) -> Asset? {
        let phAssets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        if let phAsset = phAssets.firstObject {
            return Asset(phAsset: phAsset)
        }
        return nil
    }
    
    /// 初始化方法
    public init(phAsset: PHAsset) {
        self.phAsset = phAsset
        super.init()
        
        switch phAsset.mediaType {
        case .image:
            self.assetType = .image
            if (phAsset.fw.invokeGetter("uniformTypeIdentifier") as? String) == (kUTTypeGIF as String) {
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
     异步请求 视频AVAsset，可能会有网络请求

     - Parameters:
       - completion: 完成请求后调用的 block，参数中包含了请求的 AVAsset 以及相关信息
       - progressHandler: 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
     
     - Returns: 返回请求 视频AVAsset 的请求 id
     */
    @discardableResult
    public func requestAVAsset(completion: ((_ asset: AVAsset?, _ audioMix: AVAudioMix?, _ info: [AnyHashable: Any]?) -> Void)?, progressHandler: PHAssetVideoProgressHandler? = nil) -> Int {
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = true
        videoRequestOptions.progressHandler = progressHandler
        
        let videoRequestId = AssetManager.shared.phCachingImageManager.requestAVAsset(forVideo: phAsset, options: videoRequestOptions) { asset, audioMix, info in
            completion?(asset, audioMix, info)
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
@objc public enum AlbumSortType: UInt {
    /// 日期最新的内容排在后面
    case positive = 0
    /// 日期最新的内容排在前面
    case reverse
}

/// 资源分组
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
    
    /// AssetGroup 的标识，每个 AssetGroup 的 identifier 都不同。只要两个 AssetGroup 的 identifier 相同则认为它们是同一个 assetGroup
    public var identifier: String {
        return phAssetCollection.localIdentifier
    }
    
    /// 根据唯一标志初始化
    public static func assetGroup(identifier: String) -> AssetGroup? {
        let phAssetCollections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
        if let phAssetCollection = phAssetCollections.firstObject {
            return AssetGroup(phAssetCollection: phAssetCollection)
        }
        return nil
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
    
    /// 重写比较方法，只要两个 AssetGroup 的 identifier 相同则认为它们是同一个 assetGroup
    public override func isEqual(_ object: Any?) -> Bool {
        if let assetGroup = object as? AssetGroup,
           assetGroup.identifier == identifier {
            return true
        }
        return super.isEqual(object)
    }
    
}

// MARK: - AssetManager
/// Asset 授权的状态
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
public class AssetManager {
    
    // MARK: - Static
    /// 获取 AssetManager 的单例
    public static let shared = AssetManager()
    
    /// 资源管理器临时文件存放目录，使用完成后需自行删除
    public static var cachePath: String {
        let cachePath = FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "AssetManager"])
        return cachePath
    }
    
    /// LivePhoto导出文件存放路径，使用完成后需自行删除
    public static var livePhotoPath: String {
        return cachePath.fw.appendingPath("LivePhoto")
    }
    
    /// 视频导出文件建议存放路径，使用完成后需自行删除
    public static var videoExportPath: String {
        return cachePath.fw.appendingPath("VideoExport")
    }
    
    /// 图片选择器缓存文件存放目录，使用完成后需自行删除
    public static var imagePickerPath: String {
        return cachePath.fw.appendingPath("ImagePicker")
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

    /**
     *  获取所有相册
     *
     *  @param albumContentType 相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
     *  @param showEmptyAlbum 是否显示空相册（经过 contentType 过滤后仍为空的相册）
     *  @param showSmartAlbum 是否显示“智能相册”
     *
     *  @return 返回包含所有合适相册的数组
     */
    public static func fetchAllAlbums(albumContentType: AlbumContentType, showEmptyAlbum: Bool, showSmartAlbum: Bool) -> [PHAssetCollection] {
        var albumsArray: [PHAssetCollection] = []
        // 创建一个 PHFetchOptions，用于创建 AssetGroup 对资源的排序和类型进行控制
        let fetchOptions = createFetchOptions(albumContentType: albumContentType)
        
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

    /// 获取一个 PHAssetCollection 中创建日期最新的资源，可指定创建日期
    public static func fetchLatestAsset(assetCollection: PHAssetCollection, creationDate: Date? = nil) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        // 如果指定了创建日期，直接筛选指定创建日期资源，获取最后一个资源即可
        if let fetchDate = creationDate as? NSDate {
            fetchOptions.predicate = NSPredicate(format: "creationDate = %@", fetchDate)
        // 按时间的先后对 PHAssetCollection 内的资源进行排序，最新的资源排在数组最后面，获取最后一个资源即可
        } else {
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        }
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        let latestAsset = fetchResult.lastObject
        return latestAsset
    }
    
    /**
     *  根据 contentType 的值产生一个合适的 PHFetchOptions，并把内容以资源创建日期排序，创建日期较新的资源排在前面
     *
     *  @param albumContentType 相册的内容类型
     *
     *  @return 返回一个合适的 PHFetchOptions
     */
    public static func createFetchOptions(albumContentType: AlbumContentType) -> PHFetchOptions {
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
    
    /// 保存图片到指定相册（传入 UIImage）
    public static func saveImage(image: UIImage?, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        guard let image = image, let cgImage = image.cgImage else {
            completion(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil))
            return
        }
        
        AssetManager.shared.saveImage(imageRef: cgImage, orientation: image.imageOrientation, albumAssetsGroup: albumAssetsGroup, completion: completion)
    }
    
    /// 保存图片到指定相册（传入 图片路径）
    public static func saveImage(imagePath: String, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        AssetManager.shared.saveImage(imagePathURL: URL(fileURLWithPath: imagePath), albumAssetsGroup: albumAssetsGroup, completion: completion)
    }
    
    /// 保存视频到指定相册（传入 视频路径）
    public static func saveVideo(videoPath: String, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        AssetManager.shared.saveVideo(videoPathURL: URL(fileURLWithPath: videoPath), albumAssetsGroup: albumAssetsGroup, completion: completion)
    }
    
    // MARK: - Public
    /// 获取一个 PHCachingImageManager 的实例
    public lazy var phCachingImageManager = PHCachingImageManager()
    
    /// 初始化方法
    public init() {}
    
    /// 获取所有的相册，包括个人收藏，最近添加，自拍这类“智能相册”
    ///
    /// - Parameters:
    ///   - albumContentType: 相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
    ///   - showEmptyAlbum: 是否显示空相册（经过 contentType 过滤后仍为空的相册），默认false
    ///   - showSmartAlbum: 是否显示"智能相册"，默认true
    ///   - block: 参数 resultAssetsGroup 表示每次枚举时对应的相册。枚举所有相册结束后，enumerationBlock 会被再调用一次，这时 resultAssetsGroup 的值为 nil。可以以此作为判断枚举结束的标记。
    public func enumerateAllAlbums(albumContentType: AlbumContentType, showEmptyAlbum: Bool = false, showSmartAlbum: Bool = true, using block: ((AssetGroup?) -> Void)?) {
        // 根据条件获取所有合适的相册，并保存到临时数组中
        let albumsArray = AssetManager.fetchAllAlbums(albumContentType: albumContentType, showEmptyAlbum: showEmptyAlbum, showSmartAlbum: showSmartAlbum)
        // 创建一个 PHFetchOptions，用于 AssetGroup 对资源的排序以及对内容类型进行控制
        let phFetchOptions = AssetManager.createFetchOptions(albumContentType: albumContentType)
        // 遍历结果，生成对应的 AssetGroup，并调用 enumerationBlock
        for i in 0 ..< albumsArray.count {
            let assetsGroup = AssetGroup(phAssetCollection: albumsArray[i], fetchAssetsOptions: phFetchOptions)
            block?(assetsGroup)
        }
        
        // 所有结果遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举相册结束的标记
        block?(nil)
    }
    
    /// 保存图片到指定相册（传入 CGImage）
    ///
    /// 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
    /// * 原因请参考 AssetManager 对象的保存图片和视频方法的注释。
    /// 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
    public func saveImage(imageRef: CGImage, orientation: UIImage.Orientation, photoLibrary: PHPhotoLibrary? = nil, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        let image = UIImage(cgImage: imageRef, scale: UIScreen.main.scale, orientation: orientation)
        let assetCollection = albumAssetsGroup.phAssetCollection
        addImage(image: image, imagePathURL: nil, photoLibrary: photoLibrary ?? .shared(), assetCollection: assetCollection) { success, creationDate, error in
            if success {
                let phAsset = AssetManager.fetchLatestAsset(assetCollection: assetCollection, creationDate: creationDate)
                var asset: Asset?
                if let phAsset = phAsset {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /// 保存图片到指定相册（传入 图片路径URL）
    ///
    /// 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
    /// * 原因请参考 AssetManager 对象的保存图片和视频方法的注释。
    /// 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
    public func saveImage(imagePathURL: URL, photoLibrary: PHPhotoLibrary? = nil, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        let assetCollection = albumAssetsGroup.phAssetCollection
        addImage(image: nil, imagePathURL: imagePathURL, photoLibrary: photoLibrary ?? .shared(), assetCollection: assetCollection) { success, creationDate, error in
            if success {
                let phAsset = AssetManager.fetchLatestAsset(assetCollection: assetCollection, creationDate: creationDate)
                var asset: Asset?
                if let phAsset = phAsset {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /// 保存视频到指定相册（传入 视频路径URL）
    ///
    /// 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
    /// * 原因请参考 AssetManager 对象的保存图片和视频方法的注释。
    /// 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
    public func saveVideo(videoPathURL: URL, photoLibrary: PHPhotoLibrary? = nil, albumAssetsGroup: AssetGroup, completion: @escaping (Asset?, Error?) -> Void) {
        let assetCollection = albumAssetsGroup.phAssetCollection
        addVideo(videoPathURL: videoPathURL, photoLibrary: photoLibrary ?? .shared(), assetCollection: assetCollection) { success, creationDate, error in
            if success {
                let phAsset = AssetManager.fetchLatestAsset(assetCollection: assetCollection, creationDate: creationDate)
                var asset: Asset?
                if let phAsset = phAsset {
                    asset = Asset(phAsset: phAsset)
                }
                completion(asset, error)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Private
    private func addImage(image: UIImage?, imagePathURL: URL?, photoLibrary: PHPhotoLibrary, assetCollection: PHAssetCollection, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        var creationDate: Date?
        photoLibrary.performChanges {
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

    private func addVideo(videoPathURL: URL, photoLibrary: PHPhotoLibrary, assetCollection: PHAssetCollection, completionHandler: ((Bool, Date?, Error?) -> Void)?) {
        var creationDate: Date?
        photoLibrary.performChanges {
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
    
}

// MARK: - AssetLivePhoto
/// [LivePhoto](https://github.com/LimitPoint/LivePhoto)
public class AssetLivePhoto {
    
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
    
    private static let shared = AssetLivePhoto()
    
    private static let queue = DispatchQueue(label: "site.wuyong.queue.asset.async", attributes: .concurrent)
    
    private lazy var cacheDirectory: URL = {
        let fullDirectory = URL(fileURLWithPath: AssetManager.livePhotoPath, isDirectory: true)
        if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
            try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return fullDirectory
    }()
    
    public init() {}
    
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

// MARK: - AssetSessionExporterError
/// Session export errors.
public enum AssetSessionExporterError: Error, CustomStringConvertible {
    case setupFailure
    case readingFailure
    case writingFailure
    case cancelled
    
    public var description: String {
        get {
            switch self {
            case .setupFailure:
                return "Setup failure"
            case .readingFailure:
                return "Reading failure"
            case .writingFailure:
                return "Writing failure"
            case .cancelled:
                return "Cancelled"
            }
        }
    }
}

/// 🔄 AssetSessionExporter, export and transcode media in Swift
///
/// [NextLevelSessionExporter](https://github.com/NextLevel/NextLevelSessionExporter)
open class AssetSessionExporter: NSObject {
    
    /// Initiates a AssetSessionExport on the asset
    ///
    /// - Parameters:
    ///   - asset: The asset to export
    ///   - outputFileType: type of resulting file to create
    ///   - outputURL: location of resulting file
    ///   - metadata: data to embed in the result
    ///   - videoInputConfiguration: video input configuration
    ///   - videoOutputConfiguration: video output configuration
    ///   - audioOutputConfiguration: audio output configuration
    ///   - progressHandler: progress fraction handler
    ///   - completionHandler: completion handler
    public static func export(
        asset: AVAsset,
        outputFileType: AVFileType? = AVFileType.mp4,
        outputURL: URL,
        metadata: [AVMetadataItem]? = nil,
        videoInputConfiguration: [String : Any]? = nil,
        videoOutputConfiguration: [String : Any],
        audioOutputConfiguration: [String : Any],
        progressHandler: AssetSessionExporter.ProgressHandler? = nil,
        completionHandler: AssetSessionExporter.CompletionHandler? = nil
    ) {
        let exporter = AssetSessionExporter(withAsset: asset)
        exporter.outputFileType = outputFileType
        exporter.outputURL = outputURL
        exporter.videoOutputConfiguration = videoOutputConfiguration
        exporter.audioOutputConfiguration = audioOutputConfiguration
        exporter.export(progressHandler: progressHandler, completionHandler: completionHandler)
    }
    
    /// The natural dimensions of the asset.
    public static func naturalSize(for asset: AVAsset) -> CGSize {
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        } else {
            return CGSize.zero
        }
    }

    /// Input asset for export, provided when initialized.
    public var asset: AVAsset?
    
    /// Enables video composition and parameters for the session.
    public var videoComposition: AVVideoComposition?
    
    /// Enables audio mixing and parameters for the session.
    public var audioMix: AVAudioMix?
    
    /// Output file location for the session.
    public var outputURL: URL?
    
    /// Output file type. UTI string defined in `AVMediaFormat.h`.
    public var outputFileType: AVFileType? = AVFileType.mp4
    
    /// Time range or limit of an export from `kCMTimeZero` to `kCMTimePositiveInfinity`
    public var timeRange: CMTimeRange
    
    /// Indicates if an export session should expect media data in real time.
    public var expectsMediaDataInRealTime: Bool = false
    
    /// Indicates if an export should be optimized for network use.
    public var optimizeForNetworkUse: Bool = false
    
    /// Metadata to be added to an export.
    public var metadata: [AVMetadataItem]?
    
    /// Video input configuration dictionary, using keys defined in `<CoreVideo/CVPixelBuffer.h>`
    public var videoInputConfiguration: [String : Any]?
    
    /// Video output configuration dictionary, using keys defined in `<AVFoundation/AVVideoSettings.h>`
    public var videoOutputConfiguration: [String : Any]?
    
    /// Audio output configuration dictionary, using keys defined in `<AVFoundation/AVAudioSettings.h>`
    public var audioOutputConfiguration: [String : Any]?
    
    /// Export session status state.
    public var status: AVAssetExportSession.Status {
        get {
            if let writer = self._writer {
                switch writer.status {
                case .writing:
                    return .exporting
                case .failed:
                    return .failed
                case .completed:
                    return .completed
                case.cancelled:
                    return .cancelled
                case .unknown:
                    fallthrough
                @unknown default:
                    break
                }
            }
            return .unknown
        }
    }
    
    /// Session exporting progress from 0 to 1.
    public var progress: Float {
        get {
            return self._progress
        }
    }
    
    // private instance vars
    
    fileprivate let InputQueueLabel = "AssetSessionExporterInputQueue"

    fileprivate var _writer: AVAssetWriter?
    fileprivate var _reader: AVAssetReader?
    fileprivate var _pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    fileprivate var _inputQueue: DispatchQueue
    
    fileprivate var _videoOutput: AVAssetReaderVideoCompositionOutput?
    fileprivate var _audioOutput: AVAssetReaderAudioMixOutput?
    fileprivate var _videoInput: AVAssetWriterInput?
    fileprivate var _audioInput: AVAssetWriterInput?
    
    fileprivate var _progress: Float = 0
    
    fileprivate var _progressHandler: ProgressHandler?
    fileprivate var _renderHandler: RenderHandler?
    fileprivate var _completionHandler: CompletionHandler?
    
    fileprivate var _duration: TimeInterval = 0
    fileprivate var _lastSamplePresentationTime: CMTime = .invalid
    
    /// Initializes a session with an asset to export.
    ///
    /// - Parameter asset: The asset to export.
    public convenience init(withAsset asset: AVAsset) {
        self.init()
        self.asset = asset
    }
    
    public override init() {
        self._inputQueue = DispatchQueue(label: InputQueueLabel, autoreleaseFrequency: .workItem, target: DispatchQueue.global())
        self.timeRange = CMTimeRange(start: CMTime.zero, end: CMTime.positiveInfinity)
        super.init()
    }
    
    deinit {
        self._writer = nil
        self._reader = nil
        self._pixelBufferAdaptor = nil
        self._videoOutput = nil
        self._audioOutput = nil
        self._videoInput = nil
        self._audioInput = nil
    }
    
    // subclass and add more checks, if needed
    open func validateVideoOutputConfiguration() -> Bool {
        guard let videoOutputConfiguration = self.videoOutputConfiguration else {
            return false
        }

        let videoWidth = videoOutputConfiguration[AVVideoWidthKey] as? NSNumber
        let videoHeight = videoOutputConfiguration[AVVideoHeightKey] as? NSNumber
        if videoWidth == nil || videoHeight == nil {
            return false
        }
                
        return true
    }
}

extension AssetSessionExporter {
    
    /// Completion handler type for when an export finishes.
    public typealias CompletionHandler = (Swift.Result<AVAssetExportSession.Status, Error>) -> Void
    
    /// Progress handler type
    public typealias ProgressHandler = (_ progress: Float) -> Void
    
    /// Render handler type for frame processing
    public typealias RenderHandler = (_ renderFrame: CVPixelBuffer, _ presentationTime: CMTime, _ resultingBuffer: CVPixelBuffer) -> Void
    
    /// Initiates an export session.
    ///
    /// - Parameter completionHandler: Handler called when an export session completes.
    /// - Throws: Failure indication thrown when an error has occurred during export.
    public func export(renderHandler: RenderHandler? = nil,
                       progressHandler: ProgressHandler? = nil,
                       completionHandler: CompletionHandler? = nil) {
        guard let asset = self.asset,
              let outputURL = self.outputURL,
              let outputFileType = self.outputFileType else {
            print("AssetSessionExporter, an asset and output URL are required for encoding")
            DispatchQueue.main.async {
                self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            }
            return
        }
        
        if self._writer?.status == .writing {
            self._writer?.cancelWriting()
            self._writer = nil
        }
        
        if self._reader?.status == .reading {
            self._reader?.cancelReading()
            self._reader = nil
        }
        
        self._progress = 0
        
        do {
            self._reader = try AVAssetReader(asset: asset)
        } catch {
            print("AssetSessionExporter, could not setup a reader for the provided asset \(asset)")
            DispatchQueue.main.async {
                self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            }
        }
        
        do {
            self._writer = try AVAssetWriter(outputURL: outputURL, fileType: outputFileType)
        } catch {
            print("AssetSessionExporter, could not setup a reader for the provided asset \(asset)")
            DispatchQueue.main.async {
                self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            }
        }

        // if a video configuration exists, validate it (otherwise, proceed as audio)
        if let _ = self.videoOutputConfiguration, self.validateVideoOutputConfiguration() == false {
            print("AssetSessionExporter, could not setup with the specified video output configuration")
            DispatchQueue.main.async {
                self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            }
        }
        
        self._progressHandler = progressHandler
        self._renderHandler = renderHandler
        self._completionHandler = completionHandler != nil ? { result in
            if Thread.isMainThread {
                completionHandler?(result)
            } else {
                DispatchQueue.main.async {
                    completionHandler?(result)
                }
            }
        } : nil
        
        self._reader?.timeRange = self.timeRange
        self._writer?.shouldOptimizeForNetworkUse = self.optimizeForNetworkUse
        
        if let metadata = self.metadata {
            self._writer?.metadata = metadata
        }
        
        if self.timeRange.duration.isValid && self.timeRange.duration.isPositiveInfinity == false {
            self._duration = CMTimeGetSeconds(self.timeRange.duration)
        } else {
            self._duration = CMTimeGetSeconds(asset.duration)
        }
        
        if self.videoOutputConfiguration?.keys.contains(AVVideoCodecKey) == false {
            print("AssetSessionExporter, warning a video output configuration codec wasn't specified")
            if #available(iOS 11.0, *) {
                self.videoOutputConfiguration?[AVVideoCodecKey] = AVVideoCodecType.h264
            } else {
                self.videoOutputConfiguration?[AVVideoCodecKey] = AVVideoCodecH264
            }
        }
        
        self.setupVideoOutput(withAsset: asset)
        self.setupAudioOutput(withAsset: asset)
        self.setupAudioInput()
        
        // export
        
        self._writer?.startWriting()
        self._reader?.startReading()
        self._writer?.startSession(atSourceTime: self.timeRange.start)
        
        let group = DispatchGroup()
        group.enter()
        group.enter()
    
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if let videoInput = self._videoInput,
           let videoOutput = self._videoOutput,
           videoTracks.count > 0 {
            videoInput.requestMediaDataWhenReady(on: self._inputQueue, using: {
                if self.encode(readySamplesFromReaderOutput: videoOutput, toWriterInput: videoInput) == false {
                    group.leave()
                }
            })
        } else {
            group.leave()
        }
        
        if let audioInput = self._audioInput,
            let audioOutput = self._audioOutput {
            audioInput.requestMediaDataWhenReady(on: self._inputQueue, using: {
                if self.encode(readySamplesFromReaderOutput: audioOutput, toWriterInput: audioInput) == false {
                    group.leave()
                }
            })
        } else {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.finish()
        }
    }
    
    /// Cancels any export in progress.
    public func cancelExport() {
        self._inputQueue.async {
            if self._writer?.status == .writing {
                self._writer?.cancelWriting()
            }
            
            if self._reader?.status == .reading {
                self._reader?.cancelReading()
            }
            
            DispatchQueue.main.async {
                self.complete()
                self.reset()
            }
        }
    }
    
}

extension AssetSessionExporter {
    
    private func setupVideoOutput(withAsset asset: AVAsset) {
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        
        guard videoTracks.count > 0 else {
            return
        }
        
        self._videoOutput = AVAssetReaderVideoCompositionOutput(videoTracks: videoTracks, videoSettings: self.videoInputConfiguration)
        self._videoOutput?.alwaysCopiesSampleData = false
        
        if let videoComposition = self.videoComposition {
            self._videoOutput?.videoComposition = videoComposition
        } else {
            self._videoOutput?.videoComposition = self.createVideoComposition()
        }
        
        if let videoOutput = self._videoOutput,
            let reader = self._reader {
            if reader.canAdd(videoOutput) {
                reader.add(videoOutput)
            }
        }
        
        // video input
        if self._writer?.canApply(outputSettings: self.videoOutputConfiguration, forMediaType: AVMediaType.video) == true {
            self._videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: self.videoOutputConfiguration)
            self._videoInput?.expectsMediaDataInRealTime = self.expectsMediaDataInRealTime
        } else {
            print("Unsupported output configuration")
            return
        }
        
        if let writer = self._writer,
            let videoInput = self._videoInput {
            if writer.canAdd(videoInput) {
                writer.add(videoInput)
            }
            
            // setup pixelbuffer adaptor
            
            var pixelBufferAttrib: [String : Any] = [:]
            pixelBufferAttrib[kCVPixelBufferPixelFormatTypeKey as String] = NSNumber(integerLiteral: Int(kCVPixelFormatType_32RGBA))
            if let videoComposition = self._videoOutput?.videoComposition {
                pixelBufferAttrib[kCVPixelBufferWidthKey as String] = NSNumber(integerLiteral: Int(videoComposition.renderSize.width))
                pixelBufferAttrib[kCVPixelBufferHeightKey as String] = NSNumber(integerLiteral: Int(videoComposition.renderSize.height))
            }
            pixelBufferAttrib["IOSurfaceOpenGLESTextureCompatibility"] = NSNumber(booleanLiteral:  true)
            pixelBufferAttrib["IOSurfaceOpenGLESFBOCompatibility"] = NSNumber(booleanLiteral:  true)
            
            self._pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: pixelBufferAttrib)
        }
    }
    
    private func setupAudioOutput(withAsset asset: AVAsset) {
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        
        guard audioTracks.count > 0 else {
            self._audioOutput = nil
            return
        }

        self._audioOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: nil)
        self._audioOutput?.alwaysCopiesSampleData = false
        self._audioOutput?.audioMix = self.audioMix
        if let reader = self._reader,
            let audioOutput = self._audioOutput {
            if reader.canAdd(audioOutput) {
                reader.add(audioOutput)
            }
        }
    }
    
    private func setupAudioInput() {
        guard let _ = self._audioOutput else {
            return
        }
        
        self._audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: self.audioOutputConfiguration)
        self._audioInput?.expectsMediaDataInRealTime = self.expectsMediaDataInRealTime
        if let writer = self._writer, let audioInput = self._audioInput {
            if writer.canAdd(audioInput) {
                writer.add(audioInput)
            }
        }
    }
    
}

extension AssetSessionExporter {
    
    // called on the inputQueue
    internal func encode(readySamplesFromReaderOutput output: AVAssetReaderOutput, toWriterInput input: AVAssetWriterInput) -> Bool {
        while input.isReadyForMoreMediaData {
            guard self._reader?.status == .reading && self._writer?.status == .writing,
                  let sampleBuffer = output.copyNextSampleBuffer() else {
                input.markAsFinished()
                return false
            }
            
            var handled = false
            var error = false
            if self._videoOutput == output {
                // determine progress
                self._lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer) - self.timeRange.start
                let progress = self._duration == 0 ? 1 : Float(CMTimeGetSeconds(self._lastSamplePresentationTime) / self._duration)
                self.updateProgress(progress: progress)
                
                // prepare progress frames
                if let pixelBufferAdaptor = self._pixelBufferAdaptor,
                    let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool,
                    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    
                    var toRenderBuffer: CVPixelBuffer? = nil
                    let result = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &toRenderBuffer)
                    if result == kCVReturnSuccess {
                        if let toBuffer = toRenderBuffer {
                            self._renderHandler?(pixelBuffer, self._lastSamplePresentationTime, toBuffer)
                            if pixelBufferAdaptor.append(toBuffer, withPresentationTime:self._lastSamplePresentationTime) == false {
                                error = true
                            }
                            handled = true
                        }
                    }
                }
            }
            
            if handled == false && input.append(sampleBuffer) == false {
                error = true
            }
            
            if error {
                return false
            }
        }
        return true
    }
    
    internal func createVideoComposition() -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition()
        
        if let asset = self.asset,
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
            
            // determine the framerate
            
            var frameRate: Float = 0
            if let videoConfiguration = self.videoOutputConfiguration {
                if let videoCompressionConfiguration = videoConfiguration[AVVideoCompressionPropertiesKey] as? [String: Any] {
                    if let trackFrameRate = videoCompressionConfiguration[AVVideoAverageNonDroppableFrameRateKey] as? NSNumber {
                        frameRate = trackFrameRate.floatValue
                    }
                }
            } else {
                frameRate = videoTrack.nominalFrameRate
            }
            
            if frameRate == 0 {
                frameRate = 30
            }
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            
            // determine the appropriate size and transform
            
            if let videoConfiguration = self.videoOutputConfiguration {
                
                let videoWidth = videoConfiguration[AVVideoWidthKey] as? NSNumber
                let videoHeight = videoConfiguration[AVVideoHeightKey] as? NSNumber
                
                // validated to be non-nil byt this point
                let width = videoWidth?.intValue ?? 0
                let height = videoHeight?.intValue ?? 0
                
                let targetSize = CGSize(width: width, height: height)
                var naturalSize = videoTrack.naturalSize
                
                var transform = videoTrack.preferredTransform
                
                let rect = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
                let transformedRect = rect.applying(transform)
                // transformedRect should have origin at 0 if correct; otherwise add offset to correct it
                transform.tx -= transformedRect.origin.x;
                transform.ty -= transformedRect.origin.y;
                
                
                let videoAngleInDegrees = atan2(transform.b, transform.a) * 180 / .pi
                if videoAngleInDegrees == 90 || videoAngleInDegrees == -90 {
                    let tempWidth = naturalSize.width
                    naturalSize.width = naturalSize.height
                    naturalSize.height = tempWidth
                }
                videoComposition.renderSize = naturalSize
                
                // center the video
                
                var ratio: CGFloat = 0
                let xRatio: CGFloat = targetSize.width / naturalSize.width
                let yRatio: CGFloat = targetSize.height / naturalSize.height
                ratio = min(xRatio, yRatio)
                
                let postWidth = naturalSize.width * ratio
                let postHeight = naturalSize.height * ratio
                let transX = (targetSize.width - postWidth) * 0.5
                let transY = (targetSize.height - postHeight) * 0.5
                
                var matrix = CGAffineTransform(translationX: (transX / xRatio), y: (transY / yRatio))
                matrix = matrix.scaledBy(x: (ratio / xRatio), y: (ratio / yRatio))
                transform = transform.concatenating(matrix)
                
                // make the composition
                
                let compositionInstruction = AVMutableVideoCompositionInstruction()
                compositionInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)
                
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                layerInstruction.setTransform(transform, at: CMTime.zero)
                
                compositionInstruction.layerInstructions = [layerInstruction]
                videoComposition.instructions = [compositionInstruction]
                
            }
        }
        
        return videoComposition
    }
    
    internal func updateProgress(progress: Float) {
        self.willChangeValue(forKey: "progress")
        self._progress = progress
        self.didChangeValue(forKey: "progress")
        self._progressHandler?(progress)
    }
    
    // always called on the main thread
    internal func finish() {
        if self._reader?.status == .cancelled || self._writer?.status == .cancelled {
            self.complete()
        } else if self._writer?.status == .failed {
            self._reader?.cancelReading()
            self.complete()
        } else if self._reader?.status == .failed {
            self._writer?.cancelWriting()
            self.complete()
        } else {
            self._writer?.finishWriting {
                self.complete()
            }
        }
    }
    
    // always called on the main thread
    internal func complete() {
        if self._reader?.status == .cancelled || self._writer?.status == .cancelled {
            guard let outputURL = self.outputURL else {
                self._completionHandler?(.failure(AssetSessionExporterError.cancelled))
                return
            }
            if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self._completionHandler?(.failure(AssetSessionExporterError.cancelled))
            return
        }
        
        guard let reader = self._reader else {
            self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            self._completionHandler = nil
            return
        }
        
        guard let writer = self._writer else {
            self._completionHandler?(.failure(AssetSessionExporterError.setupFailure))
            self._completionHandler = nil
            return
        }
        
        switch reader.status {
        case .failed:
            guard let outputURL = self.outputURL else {
                self._completionHandler?(.failure(reader.error ?? AssetSessionExporterError.readingFailure))
                return
            }
            if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self._completionHandler?(.failure(reader.error ?? AssetSessionExporterError.readingFailure))
            return
        default:
            // do nothing
            break
        }
        
        switch writer.status {
        case .failed:
            guard let outputURL = self.outputURL else {
                self._completionHandler?(.failure(writer.error ?? AssetSessionExporterError.writingFailure))
                return
            }
            if FileManager.default.fileExists(atPath: outputURL.absoluteString) {
                try? FileManager.default.removeItem(at: outputURL)
            }
            self._completionHandler?(.failure(writer.error ?? AssetSessionExporterError.writingFailure))
            return
        default:
            // do nothing
            break
        }

        self._completionHandler?(.success(self.status))
        self._completionHandler = nil
    }
    
    internal func reset() {
        self._progress = 0
        self._writer = nil
        self._reader = nil
        self._pixelBufferAdaptor = nil
        
        self._videoOutput = nil
        self._audioOutput = nil
        self._videoInput = nil
        self._audioInput = nil

        self._progressHandler = nil
        self._renderHandler = nil
        self._completionHandler = nil
    }
    
}
