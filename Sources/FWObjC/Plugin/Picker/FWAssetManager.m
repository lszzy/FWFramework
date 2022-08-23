//
//  FWAssetManager.m
//  
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAssetManager.h"
#import "FWRuntime.h"
#import <CoreServices/UTCoreTypes.h>

#pragma mark - FWAsset

static NSString * const kAssetInfoImageData = @"imageData";
static NSString * const kAssetInfoOriginInfo = @"originInfo";
static NSString * const kAssetInfoDataUTI = @"dataUTI";
static NSString * const kAssetInfoOrientation = @"orientation";
static NSString * const kAssetInfoSize = @"size";

@interface FWAsset ()

@property(nonatomic, copy) NSDictionary *phAssetInfo;
@end

@implementation FWAsset {
    PHAsset *_phAsset;
    float imageSize;
}

- (instancetype)initWithPHAsset:(PHAsset *)phAsset {
    if (self = [super init]) {
        _phAsset = phAsset;
        switch (phAsset.mediaType) {
            case PHAssetMediaTypeImage:
                _assetType = FWAssetTypeImage;
                if ([[phAsset fw_invokeGetter:@"uniformTypeIdentifier"] isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                    _assetSubType = FWAssetSubTypeGIF;
                } else {
                    if (phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                        _assetSubType = FWAssetSubTypeLivePhoto;
                    } else {
                        _assetSubType = FWAssetSubTypeImage;
                    }
                }
                break;
            case PHAssetMediaTypeVideo:
                _assetType = FWAssetTypeVideo;
                break;
            case PHAssetMediaTypeAudio:
                _assetType = FWAssetTypeAudio;
                break;
            default:
                _assetType = FWAssetTypeUnknow;
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
    [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:phImageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
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
    [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset
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
    [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset
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
    return [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:imageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
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
    return [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset targetSize:CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
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
    return [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:_phAsset targetSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 2, UIScreen.mainScreen.bounds.size.height * 2) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
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
        return [[[FWAssetManager sharedInstance] phCachingImageManager] requestLivePhotoForAsset:_phAsset targetSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width * 2, UIScreen.mainScreen.bounds.size.height * 2) contentMode:PHImageContentModeAspectFill options:livePhotoRequestOptions resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
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
        return [[[FWAssetManager sharedInstance] phCachingImageManager] requestPlayerItemForVideo:_phAsset options:videoRequestOptions resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
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
        return [[[FWAssetManager sharedInstance] phCachingImageManager] requestExportSessionForVideo:_phAsset options:videoRequestOptions exportPreset:exportPreset resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
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
    if (self.assetType != FWAssetTypeImage) {
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
                BOOL isGIF = self.assetSubType == FWAssetSubTypeGIF;
                BOOL isHEIC = [dataUTI isEqualToString:@"public.heic"];
                NSDictionary<NSString *, id> *originInfo = phAssetInfo[kAssetInfoOriginInfo];
                completion(phAssetInfo[kAssetInfoImageData], originInfo, isGIF, isHEIC);
            }
        }];
    } else {
        if (completion) {
            NSString *dataUTI = self.phAssetInfo[kAssetInfoDataUTI];
            BOOL isGIF = self.assetSubType == FWAssetSubTypeGIF;
            BOOL isHEIC = [@"public.heic" isEqualToString:dataUTI];
            NSDictionary<NSString *, id> *originInfo = self.phAssetInfo[kAssetInfoOriginInfo];
            completion(self.phAssetInfo[kAssetInfoImageData], originInfo, isGIF, isHEIC);
        }
    }
}

- (UIImageOrientation)imageOrientation {
    UIImageOrientation orientation;
    if (self.assetType == FWAssetTypeImage) {
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
    if (self.assetType == FWAssetTypeVideo) {
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        videoRequestOptions.networkAccessAllowed = YES;
        [[[FWAssetManager sharedInstance] phCachingImageManager] requestAVAssetForVideo:_phAsset options:videoRequestOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
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
    [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageDataForAsset:_phAsset options:imageRequestOptions resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
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
    _downloadStatus = FWAssetDownloadStatusDownloading;
}

- (void)updateDownloadStatusWithDownloadResult:(BOOL)succeed {
    _downloadStatus = succeed ? FWAssetDownloadStatusSucceed : FWAssetDownloadStatusFailed;
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
    if (self.assetType != FWAssetTypeVideo) {
        return 0;
    }
    return _phAsset.duration;
}

- (BOOL)isEqual:(id)object {
    if (!object) return NO;
    if (self == object) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    return [self.identifier isEqualToString:((FWAsset *)object).identifier];
}

@end

#pragma mark - FWAssetsGroup

@interface FWAssetGroup()

@property(nonatomic, strong, readwrite) PHAssetCollection *phAssetCollection;
@property(nonatomic, strong, readwrite) PHFetchResult *phFetchResult;

@end

@implementation FWAssetGroup

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
        [[[FWAssetManager sharedInstance] phCachingImageManager] requestImageForAsset:asset targetSize:CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale) contentMode:PHImageContentModeAspectFill options:pHImageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
            resultImage = result;
        }];
    }
    return resultImage;
}

- (void)enumerateAssetsWithOptions:(FWAlbumSortType)albumSortType usingBlock:(void (^)(FWAsset *resultAsset))enumerationBlock {
    NSInteger resultCount = self.phFetchResult.count;
    if (albumSortType == FWAlbumSortTypeReverse) {
        for (NSInteger i = resultCount - 1; i >= 0; i--) {
            PHAsset *pHAsset = self.phFetchResult[i];
            FWAsset *asset = [[FWAsset alloc] initWithPHAsset:pHAsset];
            if (enumerationBlock) {
                enumerationBlock(asset);
            }
        }
    } else {
        for (NSInteger i = 0; i < resultCount; i++) {
            PHAsset *pHAsset = self.phFetchResult[i];
            FWAsset *asset = [[FWAsset alloc] initWithPHAsset:pHAsset];
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

- (void)enumerateAssetsUsingBlock:(void (^)(FWAsset *resultAsset))enumerationBlock {
    [self enumerateAssetsWithOptions:FWAlbumSortTypePositive usingBlock:enumerationBlock];
}

@end

#pragma mark - FWAssetsManager

void FWImageWriteToSavedPhotosAlbumWithAlbumAssetsGroup(UIImage *image, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock) {
    [[FWAssetManager sharedInstance] saveImageWithImageRef:image.CGImage albumAssetsGroup:albumAssetsGroup orientation:image.imageOrientation completionBlock:completionBlock];
}

void FWSaveImageAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *imagePath, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock) {
    [[FWAssetManager sharedInstance] saveImageWithImagePathURL:[NSURL fileURLWithPath:imagePath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}

void FWSaveVideoAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *videoPath, FWAssetGroup *albumAssetsGroup, FWWriteAssetCompletionBlock completionBlock) {
    [[FWAssetManager sharedInstance] saveVideoWithVideoPathURL:[NSURL fileURLWithPath:videoPath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}



@implementation FWAssetManager {
    PHCachingImageManager *_phCachingImageManager;
}

+ (FWAssetManager *)sharedInstance {
    static dispatch_once_t onceToken;
    static FWAssetManager *instance = nil;
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

+ (FWAssetAuthorizationStatus)authorizationStatus {
    __block FWAssetAuthorizationStatus status;
    // 获取当前应用对照片的访问授权状态
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
        status = FWAssetAuthorizationStatusNotAuthorized;
    } else if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        status = FWAssetAuthorizationStatusNotDetermined;
    } else {
        status = FWAssetAuthorizationStatusAuthorized;
    }
    return status;
}

+ (void)requestAuthorization:(void(^)(FWAssetAuthorizationStatus status))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus phStatus) {
        FWAssetAuthorizationStatus status;
        if (phStatus == PHAuthorizationStatusRestricted || phStatus == PHAuthorizationStatusDenied) {
            status = FWAssetAuthorizationStatusNotAuthorized;
        } else if (phStatus == PHAuthorizationStatusNotDetermined) {
            status = FWAssetAuthorizationStatusNotDetermined;
        } else {
            status = FWAssetAuthorizationStatusAuthorized;
        }
        if (handler) {
            handler(status);
        }
    }];
}

- (void)enumerateAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbumIfSupported:(BOOL)showSmartAlbumIfSupported usingBlock:(void (^)(FWAssetGroup *resultAssetsGroup))enumerationBlock {
    // 根据条件获取所有合适的相册，并保存到临时数组中
    NSArray<PHAssetCollection *> *tempAlbumsArray = [PHPhotoLibrary fw_fetchAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:showEmptyAlbum showSmartAlbum:showSmartAlbumIfSupported];
    
    // 创建一个 PHFetchOptions，用于 FWAssetGroup 对资源的排序以及对内容类型进行控制
    PHFetchOptions *phFetchOptions = [PHPhotoLibrary fw_createFetchOptionsWithAlbumContentType:contentType];
    
    // 遍历结果，生成对应的 FWAssetGroup，并调用 enumerationBlock
    for (NSUInteger i = 0; i < tempAlbumsArray.count; i++) {
        PHAssetCollection *phAssetCollection = tempAlbumsArray[i];
        FWAssetGroup *assetsGroup = [[FWAssetGroup alloc] initWithPHCollection:phAssetCollection fetchAssetsOptions:phFetchOptions];
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

- (void)enumerateAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType usingBlock:(void (^)(FWAssetGroup *resultAssetsGroup))enumerationBlock {
    [self enumerateAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:NO showSmartAlbumIfSupported:YES usingBlock:enumerationBlock];
}

- (void)saveImageWithImageRef:(CGImageRef)imageRef albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup orientation:(UIImageOrientation)orientation completionBlock:(FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addImageToAlbum:imageRef
                                    albumAssetCollection:albumPhAssetCollection
                                             orientation:orientation
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               FWAsset *asset = [[FWAsset alloc] initWithPHAsset:phAsset];
                                               completionBlock(asset, error);
                                           } else {
                                               completionBlock(nil, error);
                                           }
                                       }];
}

- (void)saveImageWithImagePathURL:(NSURL *)imagePathURL albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup completionBlock:(FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addImageToAlbum:imagePathURL
                                    albumAssetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               FWAsset *asset = [[FWAsset alloc] initWithPHAsset:phAsset];
                                               completionBlock(asset, error);
                                           } else {
                                               completionBlock(nil, error);
                                           }
                                       }];
}

- (void)saveVideoWithVideoPathURL:(NSURL *)videoPathURL albumAssetsGroup:(FWAssetGroup *)albumAssetsGroup completionBlock:(FWWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把视频加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] fw_addVideoToAlbum:videoPathURL
                                    albumAssetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
                                           if (success) {
                                               PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                                               fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
                                               PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
                                               PHAsset *phAsset = fetchResult.lastObject;
                                               FWAsset *asset = [[FWAsset alloc] initWithPHAsset:phAsset];
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

@implementation PHPhotoLibrary (FWAssetManager)

- (void)fw_addImageToAlbum:(CGImageRef)imageRef albumAssetCollection:(PHAssetCollection *)albumAssetCollection orientation:(UIImageOrientation)orientation completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    UIImage *targetImage = [UIImage imageWithCGImage:imageRef scale:UIScreen.mainScreen.scale orientation:orientation];
    [self fw_addImageToAlbum:targetImage imagePathURL:nil albumAssetCollection:albumAssetCollection completionHandler:completionHandler];
}

- (void)fw_addImageToAlbum:(NSURL *)imagePathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void (^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    [self fw_addImageToAlbum:nil imagePathURL:imagePathURL albumAssetCollection:albumAssetCollection completionHandler:completionHandler];
}

- (void)fw_addImageToAlbum:(UIImage *)image imagePathURL:(NSURL *)imagePathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    __block NSDate *creationDate = nil;
    [self performChanges:^{
        // 创建一个以图片生成新的 PHAsset，这时图片已经被添加到“相机胶卷”
        
        PHAssetChangeRequest *assetChangeRequest;
        if (image) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } else if (imagePathURL) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imagePathURL];
        } else {
            return;
        }
        assetChangeRequest.creationDate = [NSDate date];
        creationDate = assetChangeRequest.creationDate;
        
        if (albumAssetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
            // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
            
            // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:albumAssetCollection];
            /**
             *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
             *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
             */
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
        
    } completionHandler:^(BOOL success, NSError *error) {
        if (completionHandler) {
            /**
             *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
             *  为了避免这种情况，这里该 block 主动放到主线程执行。
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL creatingSuccess = success && creationDate; // 若创建时间为 nil，则说明 performChanges 中传入的资源为空，因此需要同时判断 performChanges 是否执行成功以及资源是否有创建时间。
                completionHandler(creatingSuccess, creationDate, error);
            });
        }
    }];
}

- (void)fw_addVideoToAlbum:(NSURL *)videoPathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    __block NSDate *creationDate = nil;
    [self performChanges:^{
        // 创建一个以视频生成新的 PHAsset 的请求
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoPathURL];
        assetChangeRequest.creationDate = [NSDate date];
        creationDate = assetChangeRequest.creationDate;
        
        if (albumAssetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
            // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
            
            // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:albumAssetCollection];
            /**
             *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
             *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
             */
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
        
    } completionHandler:^(BOOL success, NSError *error) {
        if (completionHandler) {
            /**
             *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
             *  为了避免这种情况，这里该 block 主动放到主线程执行。
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success, creationDate, error);
            });
        }
    }];
}

+ (PHFetchOptions *)fw_createFetchOptionsWithAlbumContentType:(FWAlbumContentType)contentType {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    // 根据输入的内容类型过滤相册内的资源
    switch (contentType) {
        case FWAlbumContentTypeOnlyPhoto:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage];
            break;
            
        case FWAlbumContentTypeOnlyVideo:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i",PHAssetMediaTypeVideo];
            break;
            
        case FWAlbumContentTypeOnlyAudio:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i",PHAssetMediaTypeAudio];
            break;
            
        default:
            break;
    }
    return fetchOptions;
}

+ (NSArray<PHAssetCollection *> *)fw_fetchAllAlbumsWithAlbumContentType:(FWAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbum:(BOOL)showSmartAlbum {
    NSMutableArray<PHAssetCollection *> *tempAlbumsArray = [[NSMutableArray alloc] init];
    
    // 创建一个 PHFetchOptions，用于创建 FWAssetGroup 对资源的排序和类型进行控制
    PHFetchOptions *fetchOptions = [self fw_createFetchOptionsWithAlbumContentType:contentType];
    
    PHFetchResult *fetchResult;
    if (showSmartAlbum) {
        // 允许显示系统的“智能相册”
        // 获取保存了所有“智能相册”的 PHFetchResult
        fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    } else {
        // 不允许显示系统的智能相册，但由于在 PhotoKit 中，“相机胶卷”也属于“智能相册”，因此这里从“智能相册”中单独获取到“相机胶卷”
        fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    }
    // 循环遍历相册列表
    for (NSInteger i = 0; i < fetchResult.count; i++) {
        // 获取一个相册
        PHCollection *collection = fetchResult[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0，只有资源数量大于 0 的相册才会作为有效的相册显示
            PHFetchResult *currentFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
            if (currentFetchResult.count > 0 || showEmptyAlbum) {
                // 若相册不为空，或者允许显示空相册，则保存相册到结果数组
                // 判断如果是“相机胶卷”，则放到结果列表的第一位
                if (assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    [tempAlbumsArray insertObject:assetCollection atIndex:0];
                } else {
                    [tempAlbumsArray addObject:assetCollection];
                }
            }
        } else {
            NSAssert(NO, @"Fetch collection not PHCollection: %@", collection);
        }
    }
    
    // 获取所有用户自己建立的相册
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    // 循环遍历用户自己建立的相册
    for (NSInteger i = 0; i < topLevelUserCollections.count; i++) {
        // 获取一个相册
        PHCollection *collection = topLevelUserCollections[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            if (showEmptyAlbum) {
                // 允许显示空相册，直接保存相册到结果数组中
                [tempAlbumsArray addObject:assetCollection];
            } else {
                // 不允许显示空相册，需要判断当前相册是否为空
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
                // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0
                if (fetchResult.count > 0) {
                    [tempAlbumsArray addObject:assetCollection];
                }
            }
        }
    }
    
    // 获取从 macOS 设备同步过来的相册，同步过来的相册不允许删除照片，因此不会为空
    PHFetchResult *macCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    // 循环从 macOS 设备同步过来的相册
    for (NSInteger i = 0; i < macCollections.count; i++) {
        // 获取一个相册
        PHCollection *collection = macCollections[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            [tempAlbumsArray addObject:assetCollection];
        }
    }
    
    NSArray<PHAssetCollection *> *resultAlbumsArray = [tempAlbumsArray copy];
    return resultAlbumsArray;
}

+ (PHAsset *)fw_fetchLatestAssetWithAssetCollection:(PHAssetCollection *)assetCollection {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    // 按时间的先后对 PHAssetCollection 内的资源进行排序，最新的资源排在数组最后面
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
    // 获取 PHAssetCollection 内最后一个资源，即最新的资源
    PHAsset *latestAsset = fetchResult.lastObject;
    return latestAsset;
}

@end
