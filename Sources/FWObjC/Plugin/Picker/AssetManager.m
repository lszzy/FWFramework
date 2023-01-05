//
//  AssetManager.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AssetManager.h"
#import <CoreServices/UTCoreTypes.h>

#if FWMacroSPM

@interface NSObject ()

- (nullable id)fw_invokeGetter:(NSString *)name;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWAsset

static NSString * const kAssetInfoImageData = @"imageData";
static NSString * const kAssetInfoOriginInfo = @"originInfo";
static NSString * const kAssetInfoDataUTI = @"dataUTI";
static NSString * const kAssetInfoOrientation = @"orientation";
static NSString * const kAssetInfoSize = @"size";

@interface __FWAsset ()

@property(nonatomic, copy) NSDictionary *phAssetInfo;
@end

@implementation __FWAsset {
    PHAsset *_phAsset;
    float imageSize;
}

- (instancetype)initWithPHAsset:(PHAsset *)phAsset {
    if (self = [super init]) {
        _phAsset = phAsset;
        switch (phAsset.mediaType) {
            case PHAssetMediaTypeImage:
                _assetType = __FWAssetTypeImage;
                if ([[phAsset __fw_invokeGetter:@"uniformTypeIdentifier"] isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                    _assetSubType = __FWAssetSubTypeGIF;
                } else {
                    if (phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                        _assetSubType = __FWAssetSubTypeLivePhoto;
                    } else {
                        _assetSubType = __FWAssetSubTypeImage;
                    }
                }
                break;
            case PHAssetMediaTypeVideo:
                _assetType = __FWAssetTypeVideo;
                break;
            case PHAssetMediaTypeAudio:
                _assetType = __FWAssetTypeAudio;
                break;
            default:
                _assetType = __FWAssetTypeUnknow;
                break;
        }
    }
    return self;
}

- (PHAsset *)phAsset {
    return _phAsset;
}

- (UIImage *)originImage {
    __block UIImage *resultImage = nil;
    PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
    phImageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    phImageRequestOptions.networkAccessAllowed = YES;
    phImageRequestOptions.synchronous = YES;
    [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:phImageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        resultImage = [UIImage imageWithData:imageData];
    }];
    return resultImage;
}

- (UIImage *)thumbnailImageWithSize:(CGSize)size {
    __block UIImage *resultImage;
    PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
    phImageRequestOptions.networkAccessAllowed = YES;
    phImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    phImageRequestOptions.synchronous = YES;
        // 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
    [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset
                                                                          targetSize:CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale)
                                                                         contentMode:PHImageContentModeAspectFill options:phImageRequestOptions
                                                                       resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                           resultImage = result;
                                                                       }];

    return resultImage;
}

- (UIImage *)previewImage {
    __block UIImage *resultImage = nil;
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES;
    imageRequestOptions.synchronous = YES;
    [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset
                                                                        targetSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 2, UIScreen.mainScreen.bounds.size.height * 2)
                                                                       contentMode:PHImageContentModeAspectFill
                                                                           options:imageRequestOptions
                                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
                                                                         resultImage = result;
                                                                     }];
    return resultImage;
}

- (NSInteger)requestOriginImageWithCompletion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info, BOOL finished))completion withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES; // 允许访问网络
    imageRequestOptions.progressHandler = phProgressHandler;
    return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:imageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (completion) {
            completion([UIImage imageWithData:imageData], info, YES);
        }
    }];
}

- (NSInteger)requestThumbnailImageWithSize:(CGSize)size completion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info, BOOL finished))completion {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    imageRequestOptions.networkAccessAllowed = YES;
    // 在 PHImageManager 中，targetSize 等 size 都是使用 px 作为单位，因此需要对targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
    return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset targetSize:CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
        BOOL downloadSucceed = (result && !info) || (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        BOOL downloadFailed = [info objectForKey:PHImageErrorKey] != nil;
        if (completion) {
            completion(result, info, downloadSucceed || downloadFailed);
        }
    }];
}

- (NSInteger)requestPreviewImageWithCompletion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info, BOOL finished))completion withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.networkAccessAllowed = YES; // 允许访问网络
    imageRequestOptions.progressHandler = phProgressHandler;
    return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset targetSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 2, UIScreen.mainScreen.bounds.size.height * 2) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
        BOOL downloadSucceed = (result && !info) || (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        BOOL downloadFailed = [info objectForKey:PHImageErrorKey] != nil;
        if (completion) {
            completion(result, info, downloadSucceed || downloadFailed);
        }
    }];
}

- (NSInteger)requestLivePhotoWithCompletion:(void (^)(PHLivePhoto *livePhoto, NSDictionary<NSString *, id> *info, BOOL finished))completion withProgressHandler:(PHAssetImageProgressHandler)phProgressHandler {
    if ([[PHCachingImageManager class] instancesRespondToSelector:@selector(requestLivePhotoForAsset:targetSize:contentMode:options:resultHandler:)]) {
        PHLivePhotoRequestOptions *livePhotoRequestOptions = [[PHLivePhotoRequestOptions alloc] init];
        livePhotoRequestOptions.networkAccessAllowed = YES; // 允许访问网络
        livePhotoRequestOptions.progressHandler = phProgressHandler;
        return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestLivePhotoForAsset:_phAsset targetSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 2, UIScreen.mainScreen.bounds.size.height * 2) contentMode:PHImageContentModeAspectFill options:livePhotoRequestOptions resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            BOOL downloadSucceed = (livePhoto && !info) || (![[info objectForKey:PHLivePhotoInfoCancelledKey] boolValue] && ![info objectForKey:PHLivePhotoInfoErrorKey] && ![[info objectForKey:PHLivePhotoInfoIsDegradedKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            BOOL downloadFailed = [info objectForKey:PHLivePhotoInfoErrorKey] || [info objectForKey:PHImageErrorKey];
            if (completion) {
                completion(livePhoto, info, downloadSucceed || downloadFailed);
            }
        }];
    } else {
        if (completion) {
            completion(nil, nil, NO);
        }
        return 0;
    }
}

- (NSInteger)requestPlayerItemWithCompletion:(void (^)(AVPlayerItem *playerItem, NSDictionary<NSString *, id> *info))completion withProgressHandler:(PHAssetVideoProgressHandler)phProgressHandler {
    if ([[PHCachingImageManager class] instancesRespondToSelector:@selector(requestPlayerItemForVideo:options:resultHandler:)]) {
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        videoRequestOptions.networkAccessAllowed = YES; // 允许访问网络
        videoRequestOptions.progressHandler = phProgressHandler;
        return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestPlayerItemForVideo:_phAsset options:videoRequestOptions resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion) {
                completion(playerItem, info);
            }
        }];
    } else {
        if (completion) {
            completion(nil, nil);
        }
        return 0;
    }
}

- (NSInteger)requestVideoURLWithOutputURL:(NSURL *)outputURL exportPreset:(NSString *)exportPreset completion:(void (^)(NSURL * _Nullable, NSDictionary<NSString *,id> * _Nullable))completion withProgressHandler:(PHAssetVideoProgressHandler)phProgressHandler {
    if ([[PHCachingImageManager class] instancesRespondToSelector:@selector(requestExportSessionForVideo:options:exportPreset:resultHandler:)]) {
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        videoRequestOptions.networkAccessAllowed = YES; // 允许访问网络
        videoRequestOptions.progressHandler = phProgressHandler;
        return [[[__FWAssetManager sharedInstance] phCachingImageManager] requestExportSessionForVideo:_phAsset options:videoRequestOptions exportPreset:exportPreset resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
            if (!exportSession) {
                if (completion) {
                    completion(nil, info);
                }
                return;
            }
            
            exportSession.outputURL = outputURL;
            exportSession.outputFileType = AVFileTypeMPEG4;
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    if (completion) {
                        completion(outputURL, info);
                    }
                } else {
                    if (completion) {
                        completion(nil, info);
                    }
                }
            }];
        }];
    } else {
        if (completion) {
            completion(nil, nil);
        }
        return 0;
    }
}

- (void)requestImageDataWithCompletion:(void (^)(NSData *imageData, NSDictionary<NSString *, id> *info, BOOL isGIF, BOOL isHEIC))completion {
    if (self.assetType != __FWAssetTypeImage) {
        if (completion) {
            completion(nil, nil, NO, NO);
        }
        return;
    }
    __weak __typeof(self)weakSelf = self;
    if (!self.phAssetInfo) {
        // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
        [self requestPhAssetInfo:^(NSDictionary *phAssetInfo) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.phAssetInfo = phAssetInfo;
            if (completion) {
                NSString *dataUTI = phAssetInfo[kAssetInfoDataUTI];
                BOOL isGIF = self.assetSubType == __FWAssetSubTypeGIF;
                BOOL isHEIC = [dataUTI isEqualToString:@"public.heic"];
                NSDictionary<NSString *, id> *originInfo = phAssetInfo[kAssetInfoOriginInfo];
                completion(phAssetInfo[kAssetInfoImageData], originInfo, isGIF, isHEIC);
            }
        }];
    } else {
        if (completion) {
            NSString *dataUTI = self.phAssetInfo[kAssetInfoDataUTI];
            BOOL isGIF = self.assetSubType == __FWAssetSubTypeGIF;
            BOOL isHEIC = [@"public.heic" isEqualToString:dataUTI];
            NSDictionary<NSString *, id> *originInfo = self.phAssetInfo[kAssetInfoOriginInfo];
            completion(self.phAssetInfo[kAssetInfoImageData], originInfo, isGIF, isHEIC);
        }
    }
}

- (UIImageOrientation)imageOrientation {
    UIImageOrientation orientation;
    if (self.assetType == __FWAssetTypeImage) {
        if (!self.phAssetInfo) {
            // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
            __weak __typeof(self)weakSelf = self;
            [self requestImagePhAssetInfo:^(NSDictionary *phAssetInfo) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.phAssetInfo = phAssetInfo;
            } synchronous:YES];
        }
        // 从 PhAssetInfo 中获取 UIImageOrientation 对应的字段
        orientation = (UIImageOrientation)[self.phAssetInfo[kAssetInfoOrientation] integerValue];
    } else {
        orientation = UIImageOrientationUp;
    }
    return orientation;
}

- (NSString *)identifier {
    return _phAsset.localIdentifier;
}

- (void)requestPhAssetInfo:(void (^)(NSDictionary *))completion {
    if (!_phAsset) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    if (self.assetType == __FWAssetTypeVideo) {
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        videoRequestOptions.networkAccessAllowed = YES;
        [[[__FWAssetManager sharedInstance] phCachingImageManager] requestAVAssetForVideo:_phAsset options:videoRequestOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                NSMutableDictionary *tempInfo = [[NSMutableDictionary alloc] init];
                if (info) {
                    [tempInfo setObject:info forKey:kAssetInfoOriginInfo];
                }
                AVURLAsset *urlAsset = (AVURLAsset*)asset;
                NSNumber *size;
                [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
                [tempInfo setObject:size forKey:kAssetInfoSize];
                if (completion) {
                    completion(tempInfo);
                }
            }
        }];
    } else {
        [self requestImagePhAssetInfo:^(NSDictionary *phAssetInfo) {
            if (completion) {
                completion(phAssetInfo);
            }
        } synchronous:NO];
    }
}

- (void)requestImagePhAssetInfo:(void (^)(NSDictionary *))completion synchronous:(BOOL)synchronous {
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = synchronous;
    imageRequestOptions.networkAccessAllowed = YES;
    [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:imageRequestOptions resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        if (info) {
            NSMutableDictionary *tempInfo = [[NSMutableDictionary alloc] init];
            if (imageData) {
                [tempInfo setObject:imageData forKey:kAssetInfoImageData];
                [tempInfo setObject:@(imageData.length) forKey:kAssetInfoSize];
            }
            [tempInfo setObject:info forKey:kAssetInfoOriginInfo];
            if (dataUTI) {
                [tempInfo setObject:dataUTI forKey:kAssetInfoDataUTI];
            }
            [tempInfo setObject:@(orientation) forKey:kAssetInfoOrientation];
            if (completion) {
                completion(tempInfo);
            }
        }
    }];
}

- (void)setDownloadProgress:(double)downloadProgress {
    _downloadProgress = downloadProgress;
    _downloadStatus = __FWAssetDownloadStatusDownloading;
}

- (void)updateDownloadStatusWithDownloadResult:(BOOL)succeed {
    _downloadStatus = succeed ? __FWAssetDownloadStatusSucceed : __FWAssetDownloadStatusFailed;
}

- (void)assetSize:(void (^)(long long size))completion {
    if (!self.phAssetInfo) {
        // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
        __weak __typeof(self)weakSelf = self;
        [self requestPhAssetInfo:^(NSDictionary *phAssetInfo) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.phAssetInfo = phAssetInfo;
            if (completion) {
                /**
                 *  这里不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
                 *  为了避免这种情况，这里该 block 主动放到主线程执行。
                 */
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion([phAssetInfo[kAssetInfoSize] longLongValue]);
                });
            }
        }];
    } else {
        if (completion) {
            completion([self.phAssetInfo[kAssetInfoSize] longLongValue]);
        }
    }
}

- (NSTimeInterval)duration {
    if (self.assetType != __FWAssetTypeVideo) {
        return 0;
    }
    return _phAsset.duration;
}

- (BOOL)isEqual:(id)object {
    if (!object) return NO;
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    return [self.identifier isEqualToString:((__FWAsset *)object).identifier];
}

@end

#pragma mark - __FWAssetsGroup

@interface __FWAssetGroup()

@property(nonatomic, strong, readwrite) PHAssetCollection *phAssetCollection;
@property(nonatomic, strong, readwrite) PHFetchResult *phFetchResult;

@end

@implementation __FWAssetGroup

- (instancetype)initWithPHCollection:(PHAssetCollection *)phAssetCollection fetchAssetsOptions:(PHFetchOptions *)pHFetchOptions {
    self = [super init];
    if (self) {
        self.phFetchResult = [PHAsset fetchAssetsInAssetCollection:phAssetCollection options:pHFetchOptions];
        self.phAssetCollection = phAssetCollection;
    }
    return self;
}

- (instancetype)initWithPHCollection:(PHAssetCollection *)phAssetCollection {
    return [self initWithPHCollection:phAssetCollection fetchAssetsOptions:nil];
}

- (NSInteger)numberOfAssets {
    return self.phFetchResult.count;
}

- (NSString *)name {
    NSString *resultName = self.phAssetCollection.localizedTitle;
    return NSLocalizedString(resultName, resultName);
}

- (UIImage *)posterImageWithSize:(CGSize)size {
    // 系统的隐藏相册不应该显示缩略图
    if (self.phAssetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
        return nil;
    }
    
    __block UIImage *resultImage;
    NSInteger count = self.phFetchResult.count;
    if (count > 0) {
        PHAsset *asset = self.phFetchResult[count - 1];
        PHImageRequestOptions *pHImageRequestOptions = [[PHImageRequestOptions alloc] init];
        pHImageRequestOptions.synchronous = YES; // 同步请求
        pHImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        // targetSize 中对传入的 Size 进行处理，宽高各自乘以 ScreenScale，从而得到正确的图片
        [[[__FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:asset targetSize:CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale) contentMode:PHImageContentModeAspectFill options:pHImageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
            resultImage = result;
        }];
    }
    return resultImage;
}

- (void)enumerateAssetsWithOptions:(__FWAlbumSortType)albumSortType usingBlock:(void (^)(__FWAsset *resultAsset))enumerationBlock {
    NSInteger resultCount = self.phFetchResult.count;
    if (albumSortType == __FWAlbumSortTypeReverse) {
        for (NSInteger i = resultCount - 1; i >= 0; i--) {
            PHAsset *pHAsset = self.phFetchResult[i];
            __FWAsset *asset = [[__FWAsset alloc] initWithPHAsset:pHAsset];
            if (enumerationBlock) {
                enumerationBlock(asset);
            }
        }
    } else {
        for (NSInteger i = 0; i < resultCount; i++) {
            PHAsset *pHAsset = self.phFetchResult[i];
            __FWAsset *asset = [[__FWAsset alloc] initWithPHAsset:pHAsset];
            if (enumerationBlock) {
                enumerationBlock(asset);
            }
        }
    }
    /**
     *  For 循环遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举资源结束的标记。
     */
    if (enumerationBlock) {
        enumerationBlock(nil);
    }
}

- (void)enumerateAssetsUsingBlock:(void (^)(__FWAsset *resultAsset))enumerationBlock {
    [self enumerateAssetsWithOptions:__FWAlbumSortTypePositive usingBlock:enumerationBlock];
}

@end

#pragma mark - __FWAssetsManager

void __FWImageWriteToSavedPhotosAlbumWithAlbumAssetsGroup(UIImage *image, __FWAssetGroup *albumAssetsGroup, __FWWriteAssetCompletionBlock completionBlock) {
    [[__FWAssetManager sharedInstance] saveImageWithImageRef:image.CGImage albumAssetsGroup:albumAssetsGroup orientation:image.imageOrientation completionBlock:completionBlock];
}

void __FWSaveImageAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *imagePath, __FWAssetGroup *albumAssetsGroup, __FWWriteAssetCompletionBlock completionBlock) {
    [[__FWAssetManager sharedInstance] saveImageWithImagePathURL:[NSURL fileURLWithPath:imagePath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}

void __FWSaveVideoAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *videoPath, __FWAssetGroup *albumAssetsGroup, __FWWriteAssetCompletionBlock completionBlock) {
    [[__FWAssetManager sharedInstance] saveVideoWithVideoPathURL:[NSURL fileURLWithPath:videoPath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}



@implementation __FWAssetManager {
    PHCachingImageManager *_phCachingImageManager;
}

+ (__FWAssetManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static __FWAssetManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

/**
 * 重写 +allocWithZone 方法，使得在给对象分配内存空间的时候，就指向同一份数据
 */

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (__FWAssetAuthorizationStatus)authorizationStatus {
    __block __FWAssetAuthorizationStatus status;
    // 获取当前应用对照片的访问授权状态
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
        status = __FWAssetAuthorizationStatusNotAuthorized;
    } else if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        status = __FWAssetAuthorizationStatusNotDetermined;
    } else {
        status = __FWAssetAuthorizationStatusAuthorized;
    }
    return status;
}

+ (void)requestAuthorization:(void(^)(__FWAssetAuthorizationStatus status))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus phStatus) {
        __FWAssetAuthorizationStatus status;
        if (phStatus == PHAuthorizationStatusRestricted || phStatus == PHAuthorizationStatusDenied) {
            status = __FWAssetAuthorizationStatusNotAuthorized;
        } else if (phStatus == PHAuthorizationStatusNotDetermined) {
            status = __FWAssetAuthorizationStatusNotDetermined;
        } else {
            status = __FWAssetAuthorizationStatusAuthorized;
        }
        if (handler) {
            handler(status);
        }
    }];
}

- (void)enumerateAllAlbumsWithAlbumContentType:(__FWAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbumIfSupported:(BOOL)showSmartAlbumIfSupported usingBlock:(void (^)(__FWAssetGroup *resultAssetsGroup))enumerationBlock {
    // 根据条件获取所有合适的相册，并保存到临时数组中
    NSArray<PHAssetCollection *> *tempAlbumsArray = [PHPhotoLibrary fw_fetchAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:showEmptyAlbum showSmartAlbum:showSmartAlbumIfSupported];
    
    // 创建一个 PHFetchOptions，用于 __FWAssetGroup 对资源的排序以及对内容类型进行控制
    PHFetchOptions *phFetchOptions = [PHPhotoLibrary fw_createFetchOptionsWithAlbumContentType:contentType];
    
    // 遍历结果，生成对应的 __FWAssetGroup，并调用 enumerationBlock
    for (NSUInteger i = 0; i < tempAlbumsArray.count; i++) {
        PHAssetCollection *phAssetCollection = tempAlbumsArray[i];
        __FWAssetGroup *assetsGroup = [[__FWAssetGroup alloc] initWithPHCollection:phAssetCollection fetchAssetsOptions:phFetchOptions];
        if (enumerationBlock) {
            enumerationBlock(assetsGroup);
        }
    }
    
    /**
     *  所有结果遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举相册结束的标记。
     */
    if (enumerationBlock) {
        enumerationBlock(nil);
    }
}

- (void)enumerateAllAlbumsWithAlbumContentType:(__FWAlbumContentType)contentType usingBlock:(void (^)(__FWAssetGroup *resultAssetsGroup))enumerationBlock {
    [self enumerateAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:NO showSmartAlbumIfSupported:YES usingBlock:enumerationBlock];
}

- (void)saveImageWithImageRef:(CGImageRef)imageRef albumAssetsGroup:(__FWAssetGroup *)albumAssetsGroup orientation:(UIImageOrientation)orientation completionBlock:(__FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addImageToAlbum:imageRef
                                            assetCollection:albumPhAssetCollection
                                             orientation:orientation
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               __FWAsset *asset = [[__FWAsset alloc] initWithPHAsset:phAsset];
                                               completionBlock(asset, error);
                                           } else {
                                               completionBlock(nil, error);
                                           }
                                       }];
}

- (void)saveImageWithImagePathURL:(NSURL *)imagePathURL albumAssetsGroup:(__FWAssetGroup *)albumAssetsGroup completionBlock:(__FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addImageToAlbum:imagePathURL
                                            assetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               __FWAsset *asset = [[__FWAsset alloc] initWithPHAsset:phAsset];
                                               completionBlock(asset, error);
                                           } else {
                                               completionBlock(nil, error);
                                           }
                                       }];
}

- (void)saveVideoWithVideoPathURL:(NSURL *)videoPathURL albumAssetsGroup:(__FWAssetGroup *)albumAssetsGroup completionBlock:(__FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把视频加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addVideoToAlbum:videoPathURL
                                            assetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               __FWAsset *asset = [[__FWAsset alloc] initWithPHAsset:phAsset];
                                               completionBlock(asset, error);
                                           } else {
                                               completionBlock(nil, error);
                                           }
                                       }];
}

- (PHCachingImageManager *)phCachingImageManager {
    if (!_phCachingImageManager) {
        _phCachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _phCachingImageManager;
}

@end
