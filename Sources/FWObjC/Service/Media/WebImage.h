//
//  WebImage.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>
#import "ImagePlugin.h"
#import "AudioPlayer.h"
#import "PlayerCache.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAutoPurgingImageCache

/// 图片缓存协议
NS_SWIFT_NAME(ImageCache)
@protocol __FWImageCache <NSObject>

- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier;

- (BOOL)removeImageWithIdentifier:(NSString *)identifier;

- (BOOL)removeAllImages;

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier;
@end

/// 图片请求缓存协议
NS_SWIFT_NAME(ImageRequestCache)
@protocol __FWImageRequestCache <__FWImageCache>

- (BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

@end

/// 内存自动清理图片缓存
NS_SWIFT_NAME(AutoPurgingImageCache)
@interface __FWAutoPurgingImageCache : NSObject <__FWImageRequestCache>

@property (nonatomic, assign) UInt64 memoryCapacity;

@property (nonatomic, assign) UInt64 preferredMemoryUsageAfterPurge;

@property (nonatomic, assign, readonly) UInt64 memoryUsage;

- (instancetype)init;

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity;

@end

#pragma mark - __FWImageDownloader

typedef NS_ENUM(NSInteger, __FWImageDownloadPrioritization) {
    __FWImageDownloadPrioritizationFIFO,
    __FWImageDownloadPrioritizationLIFO
} NS_SWIFT_NAME(ImageDownloadPrioritization);

/// 图片下载凭据
NS_SWIFT_NAME(ImageDownloadReceipt)
@interface __FWImageDownloadReceipt : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) NSUUID *receiptID;

@end

@class __FWHTTPSessionManager;

/// 图片下载器，默认解码scale为1，同SDWebImage
NS_SWIFT_NAME(ImageDownloader)
@interface __FWImageDownloader : NSObject

@property (nonatomic, strong, nullable) id <__FWImageRequestCache> imageCache;

@property (nonatomic, strong) __FWHTTPSessionManager *sessionManager;

@property (nonatomic, assign) __FWImageDownloadPrioritization downloadPrioritization;

@property (class, nonatomic, strong) __FWImageDownloader *sharedDownloader;

+ (instancetype)defaultInstance;

+ (NSURLCache *)defaultURLCache;

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration;

- (instancetype)init;

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (instancetype)initWithSessionManager:(__FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(__FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(nullable id <__FWImageRequestCache>)imageCache;

- (nullable __FWImageDownloadReceipt *)downloadImageForURL:(nullable id)url
                                                 options:(__FWWebImageOptions)options
                                                 context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
                                                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (nullable __FWImageDownloadReceipt *)downloadImageForURL:(nullable id)url
                                           withReceiptID:(NSUUID *)receiptID
                                                 options:(__FWWebImageOptions)options
                                                 context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
                                                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (void)cancelTaskForImageDownloadReceipt:(__FWImageDownloadReceipt *)imageDownloadReceipt;

- (nullable NSURL *)imageURLForObject:(id)object;

- (nullable NSString *)imageOperationKeyForObject:(id)object;

- (void)downloadImageForObject:(id)object
                      imageURL:(nullable id)imageURL
                       options:(__FWWebImageOptions)options
                       context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
                   placeholder:(nullable void (^)(void))placeholder
                    completion:(nullable void (^)(UIImage * _Nullable image, BOOL isCache, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

- (void)cancelImageDownloadTask:(id)object;

- (nullable UIImage *)loadImageCacheForURL:(nullable id)url;

@end

NS_ASSUME_NONNULL_END
