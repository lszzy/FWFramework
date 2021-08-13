/*!
 @header     FWAssetManager.h
 @indexgroup FWFramework
 @brief      FWAssetManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAsset

typedef NS_ENUM(NSUInteger, FWAssetType) {
    FWAssetTypeUnknow,
    FWAssetTypeImage,
    FWAssetTypeVideo,
    FWAssetTypeAudio
};

typedef NS_ENUM(NSUInteger, FWAssetSubType) {
    FWAssetSubTypeUnknow,
    FWAssetSubTypeImage,
    FWAssetSubTypeLivePhoto,
    FWAssetSubTypeGIF
};

/// Status when download asset from iCloud
typedef NS_ENUM(NSUInteger, FWAssetDownloadStatus) {
    FWAssetDownloadStatusSucceed,
    FWAssetDownloadStatusDownloading,
    FWAssetDownloadStatusCanceled,
    FWAssetDownloadStatusFailed
};

@class PHAsset;

/**
 *  相册里某一个资源的包装对象，该资源可能是图片、视频等。
 *  @note FWAsset 重写了 isEqual: 方法，只要两个 FWAsset 的 identifier 相同，则认为是同一个对象，以方便在数组、字典等容器中对大量 FWAsset 进行遍历查找等操作。
 */
@interface FWAsset : NSObject

@property(nonatomic, assign, readonly) FWAssetType assetType;
@property(nonatomic, assign, readonly) FWAssetSubType assetSubType;

- (instancetype)initWithPHAsset:(PHAsset *)phAsset;

@property(nonatomic, strong, readonly) PHAsset *phAsset;
@property(nonatomic, assign, readonly) FWAssetDownloadStatus downloadStatus; // 从 iCloud 下载资源大图的状态
@property(nonatomic, assign) double downloadProgress; // 从 iCloud 下载资源大图的进度
@property(nonatomic, assign) NSInteger requestID; // 从 iCloud 请求获得资源的大图的请求 ID
@property (nonatomic, copy, readonly) NSString *identifier;// Asset 的标识，每个 FWAsset 的 identifier 都不同。只要两个 FWAsset 的 identifier 相同则认为它们是同一个 asset

/// Asset 的原图（包含系统相册“编辑”功能处理后的效果）
- (nullable UIImage *)originImage;

/**
 *  Asset 的缩略图
 *
 *  @param size 指定返回的缩略图的大小，pt 为单位
 *
 *  @return Asset 的缩略图
 */
- (nullable UIImage *)thumbnailWithSize:(CGSize)size;

/**
 *  Asset 的预览图
 *
 *  @warning 输出与当前设备屏幕大小相同尺寸的图片，如果图片原图小于当前设备屏幕的尺寸，则只输出原图大小的图片
 *  @return Asset 的全屏图
 */
- (nullable UIImage *)previewImage;

/**
 *  异步请求 Asset 的原图，包含了系统照片“编辑”功能处理后的效果（剪裁，旋转和滤镜等），可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的原图以及图片信息，这个 block 会被多次调用，
 *                           其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直到获取到高清图。
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestOriginImageWithCompletion:(nullable void (^)(UIImage * _Nullable result, NSDictionary<NSString *, id> * _Nullable info))completion withProgressHandler:(nullable PHAssetImageProgressHandler)phProgressHandler;

/**
 *  异步请求 Asset 的缩略图，不会产生网络请求
 *
 *  @param size       指定返回的缩略图的大小
 *  @param completion 完成请求后调用的 block，参数中包含了请求的缩略图以及图片信息，这个 block 会被多次调用，
 *                    其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直到获取到高清图，这时 block 中的第二个参数（图片信息）返回的为 nil。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestThumbnailImageWithSize:(CGSize)size completion:(nullable void (^)(UIImage * _Nullable result, NSDictionary<NSString *, id> * _Nullable info))completion;

/**
 *  异步请求 Asset 的预览图，可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的预览图以及图片信息，这个 block 会被多次调用，
 *                           其中第一次调用获取到的尺寸很小的低清图，然后不断调用，直到获取到高清图。
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestPreviewImageWithCompletion:(nullable void (^)(UIImage * _Nullable result, NSDictionary<NSString *, id> * _Nullable info))completion withProgressHandler:(nullable PHAssetImageProgressHandler)phProgressHandler;

/**
 *  异步请求 Live Photo，可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的 Live Photo 以及相关信息，若 assetType 不是 FWAssetTypeLivePhoto 则为 nil
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @warning iOS 9.1 以下中并没有 Live Photo，因此无法获取有效结果。
 *
 *  @return 返回请求图片的请求 id
 */
- (NSInteger)requestLivePhotoWithCompletion:(nullable void (^)(PHLivePhoto * _Nullable livePhoto, NSDictionary<NSString *, id> * _Nullable info))completion withProgressHandler:(nullable PHAssetImageProgressHandler)phProgressHandler;

/**
 *  异步请求 AVPlayerItem，可能会有网络请求
 *
 *  @param completion        完成请求后调用的 block，参数中包含了请求的 AVPlayerItem 以及相关信息，若 assetType 不是 FWAssetTypeVideo 则为 nil
 *  @param phProgressHandler 处理请求进度的 handler，不在主线程上执行，在 block 中修改 UI 时注意需要手工放到主线程处理。
 *
 *  @return 返回请求 AVPlayerItem 的请求 id
 */
- (NSInteger)requestPlayerItemWithCompletion:(nullable void (^)(AVPlayerItem * _Nullable playerItem, NSDictionary<NSString *, id> * _Nullable info))completion withProgressHandler:(nullable PHAssetVideoProgressHandler)phProgressHandler;

/**
 *  异步请求图片的 Data
 *
 *  @param completion 完成请求后调用的 block，参数中包含了请求的图片 Data（若 assetType 不是 FWAssetTypeImage 或 FWAssetTypeLivePhoto 则为 nil），该图片是否为 GIF 的判断值，以及该图片的文件格式是否为 HEIC
 */
- (void)requestImageData:(nullable void (^)(NSData * _Nullable imageData, NSDictionary<NSString *, id> * _Nullable info, BOOL isGIF, BOOL isHEIC))completion;

/**
 * 获取图片的 UIImageOrientation 值，仅 assetType 为 FWAssetTypeImage 或 FWAssetTypeLivePhoto 时有效
 */
- (UIImageOrientation)imageOrientation;

/// 更新下载资源的结果
- (void)updateDownloadStatusWithDownloadResult:(BOOL)succeed;

/**
 * 获取 Asset 的体积（数据大小）
 */
- (void)assetSize:(nullable void (^)(long long size))completion;

- (NSTimeInterval)duration;

@end

#pragma mark - FWAssetGroup

/// 相册展示内容的类型
typedef NS_ENUM(NSUInteger, FWAlbumContentType) {
    FWAlbumContentTypeAll,                                  // 展示所有资源
    FWAlbumContentTypeOnlyPhoto,                            // 只展示照片
    FWAlbumContentTypeOnlyVideo,                            // 只展示视频
    FWAlbumContentTypeOnlyAudio                             // 只展示音频
};

/// 相册展示内容按日期排序的方式
typedef NS_ENUM(NSUInteger, FWAlbumSortType) {
    FWAlbumSortTypePositive,  // 日期最新的内容排在后面
    FWAlbumSortTypeReverse  // 日期最新的内容排在前面
};

@interface FWAssetGroup : NSObject

- (instancetype)initWithPHCollection:(PHAssetCollection *)phAssetCollection;

- (instancetype)initWithPHCollection:(PHAssetCollection *)phAssetCollection fetchAssetsOptions:(nullable PHFetchOptions *)pHFetchOptions;

/// 仅能通过 initWithPHCollection 和 initWithPHCollection:fetchAssetsOption 方法修改 phAssetCollection 的值
@property(nonatomic, strong, readonly) PHAssetCollection *phAssetCollection;

/// 仅能通过 initWithPHCollection 和 initWithPHCollection:fetchAssetsOption 方法修改 phAssetCollection 后，产生一个对应的 PHAssetsFetchResults 保存到 phFetchResult 中
@property(nonatomic, strong, readonly) PHFetchResult *phFetchResult;

/// 相册的名称
- (nullable NSString *)name;

/// 相册内的资源数量，包括视频、图片、音频（如果支持）这些类型的所有资源
- (NSInteger)numberOfAssets;

/**
 *  相册的缩略图，即系统接口中的相册海报（Poster Image）
 *
 *  @return 相册的缩略图
 */
- (nullable UIImage *)posterImageWithSize:(CGSize)size;

/**
 *  枚举相册内所有的资源
 *
 *  @param albumSortType    相册内资源的排序方式，可以选择日期最新的排在最前面，也可以选择日期最新的排在最后面
 *  @param enumerationBlock 枚举相册内资源时调用的 block，参数 result 表示每次枚举时对应的资源。
 *                          枚举所有资源结束后，enumerationBlock 会被再调用一次，这时 result 的值为 nil。
 *                          可以以此作为判断枚举结束的标记
 */
- (void)enumerateAssetsWithOptions:(FWAlbumSortType)albumSortType usingBlock:(nullable void (^)(FWAsset * _Nullable resultAsset))enumerationBlock;

/**
 *  枚举相册内所有的资源，相册内资源按日期最新的排在最后面
 *
 *  @param enumerationBlock 枚举相册内资源时调用的 block，参数 result 表示每次枚举时对应的资源。
 *                          枚举所有资源结束后，enumerationBlock 会被再调用一次，这时 result 的值为 nil。
 *                          可以以此作为判断枚举结束的标记
 */
- (void)enumerateAssetsUsingBlock:(nullable void (^)(FWAsset * _Nullable result))enumerationBlock;

@end

#pragma mark - FWAssetManager

/// Asset 授权的状态
typedef NS_ENUM(NSUInteger, FWAssetAuthorizationStatus) {
    FWAssetAuthorizationStatusNotDetermined,      // 还不确定有没有授权
    FWAssetAuthorizationStatusAuthorized,         // 已经授权
    FWAssetAuthorizationStatusNotAuthorized       // 手动禁止了授权
};

typedef void (^FWWriteAssetCompletionBlock)(FWAsset * _Nullable asset, NSError * _Nullable error);

/// 保存图片到指定相册（传入 UIImage）
extern void FWImageWriteToSavedPhotosAlbumWithAlbumAssetsGroup(UIImage *image, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock);

/// 保存图片到指定相册（传入图片路径）
extern void FWSaveImageAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *imagePath, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock);

/// 保存视频到指定相册
extern void FWSaveVideoAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *videoPath, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock);

/**
 *  构建 FWAssetManager 这个对象并提供单例的调用方式主要出于下面两点考虑：
 *  1. 保存照片/视频的方法较为复杂，为了方便封装系统接口，同时灵活地扩展功能，需要有一个独立对象去管理这些方法。
 *  2. 使用 PhotoKit 获取图片，基本都需要一个 PHCachingImageManager 的实例，为了减少消耗，
 *     FWAssetManager 单例内部也构建了一个 PHCachingImageManager，并且暴露给外面，方便获取
 *     PHCachingImageManager 的实例。
 *
 * @see https://github.com/Tencent/QMUI_iOS
 */
@interface FWAssetManager : NSObject

/// 获取 FWAssetManager 的单例
+ (instancetype)sharedInstance;

/// 获取当前应用的“照片”访问授权状态
+ (FWAssetAuthorizationStatus)authorizationStatus;

/**
 *  调起系统询问是否授权访问“照片”的 UIAlertView
 *  @param handler 授权结束后调用的 block，默认不在主线程上执行，如果需要在 block 中修改 UI，记得 dispatch 到 mainqueue
 */
+ (void)requestAuthorization:(nullable void(^)(FWAssetAuthorizationStatus status))handler;

/**
 *  获取所有的相册，包括个人收藏，最近添加，自拍这类“智能相册”
 *
 *  @param contentType               相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
 *  @param showEmptyAlbum            是否显示空相册（经过 contentType 过滤后仍为空的相册）
 *  @param showSmartAlbumIfSupported 是否显示"智能相册"
 *  @param enumerationBlock          参数 resultAssetsGroup 表示每次枚举时对应的相册。枚举所有相册结束后，enumerationBlock 会被再调用一次，
 *                                   这时 resultAssetsGroup 的值为 nil。可以以此作为判断枚举结束的标记。
 */
- (void)enumerateAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbumIfSupported:(BOOL)showSmartAlbumIfSupported usingBlock:(nullable void (^)(FWAssetGroup * _Nullable resultAssetsGroup))enumerationBlock;

/// 获取所有相册，默认显示系统的“智能相册”，不显示空相册（经过 contentType 过滤后为空的相册）
- (void)enumerateAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType usingBlock:(nullable void (^)(FWAssetGroup * _Nullable resultAssetsGroup))enumerationBlock;

/**
 *  保存图片或视频到指定的相册
 *
 *  @warning 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
 *           因为系统没有把图片和视频直接保存到指定相册的接口，都只能先保存到“相机胶卷”，从而生成了 Asset 对象，
 *           再把 Asset 对象添加到指定相册中，从而达到保存资源到指定相册的效果。
 *           即使调用 PhotoKit 保存图片或视频到指定相册的新接口也是如此，并且官方 PhotoKit SampleCode 中例子也是表现如此，
 *           因此这应该是一个合符官方预期的表现。
 *  @warning 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
 */
- (void)saveImageWithImageRef:(CGImageRef)imageRef albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup orientation:(UIImageOrientation)orientation completionBlock:(FWWriteAssetCompletionBlock)completionBlock;

- (void)saveImageWithImagePathURL:(NSURL *)imagePathURL albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup completionBlock:(FWWriteAssetCompletionBlock)completionBlock;

- (void)saveVideoWithVideoPathURL:(NSURL *)videoPathURL albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup completionBlock:(FWWriteAssetCompletionBlock)completionBlock;

/// 获取一个 PHCachingImageManager 的实例
- (PHCachingImageManager *)phCachingImageManager;

@end


@interface PHPhotoLibrary (FWAssetManager)

/**
 *  根据 contentType 的值产生一个合适的 PHFetchOptions，并把内容以资源创建日期排序，创建日期较新的资源排在前面
 *
 *  @param contentType 相册的内容类型
 *
 *  @return 返回一个合适的 PHFetchOptions
 */
+ (PHFetchOptions *)createFetchOptionsWithAlbumContentType:(FWAlbumContentType)contentType;

/**
 *  获取所有相册
 *
 *  @param contentType    相册的内容类型，设定了内容类型后，所获取的相册中只包含对应类型的资源
 *  @param showEmptyAlbum 是否显示空相册（经过 contentType 过滤后仍为空的相册）
 *  @param showSmartAlbum 是否显示“智能相册”
 *
 *  @return 返回包含所有合适相册的数组
 */
+ (NSArray<PHAssetCollection *> *)fetchAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbum:(BOOL)showSmartAlbum;

/// 获取一个 PHAssetCollection 中创建日期最新的资源
+ (nullable PHAsset *)fetchLatestAssetWithAssetCollection:(PHAssetCollection *)assetCollection;

/**
 *  保存图片或视频到指定的相册
 *
 *  @warning 无论用户保存到哪个自行创建的相册，系统都会在“相机胶卷”相册中同时保存这个图片。
 *           原因请参考 FWAssetManager 对象的保存图片和视频方法的注释。
 *  @warning 无法通过该方法把图片保存到“智能相册”，“智能相册”只能由系统控制资源的增删。
 */
- (void)addImageToAlbum:(CGImageRef)imageRef albumAssetCollection:(PHAssetCollection *)albumAssetCollection orientation:(UIImageOrientation)orientation completionHandler:(nullable void(^)(BOOL success, NSDate * _Nullable creationDate, NSError * _Nullable error))completionHandler;

- (void)addImageToAlbum:(NSURL *)imagePathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(nullable void(^)(BOOL success, NSDate * _Nullable creationDate, NSError * _Nullable error))completionHandler;

- (void)addVideoToAlbum:(NSURL *)videoPathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(nullable void(^)(BOOL success, NSDate * _Nullable creationDate, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
