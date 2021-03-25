/*!
 @header     FWWebImage.h
 @indexgroup FWFramework
 @brief      FWWebImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>
#import "FWImage.h"
#import "FWAnimatedImage.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAutoPurgingImageCache

/// 图片缓存协议
@protocol FWImageCache <NSObject>

- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier;

- (BOOL)removeImageWithIdentifier:(NSString *)identifier;

- (BOOL)removeAllImages;

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier;
@end

/// 图片请求缓存协议
@protocol FWImageRequestCache <FWImageCache>

- (BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier;

@end

/// 内存自动清理图片缓存
@interface FWAutoPurgingImageCache : NSObject <FWImageRequestCache>

@property (nonatomic, assign) UInt64 memoryCapacity;

@property (nonatomic, assign) UInt64 preferredMemoryUsageAfterPurge;

@property (nonatomic, assign, readonly) UInt64 memoryUsage;

- (instancetype)init;

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity;

@end

#pragma mark - FWImageDownloader

typedef NS_ENUM(NSInteger, FWImageDownloadPrioritization) {
    FWImageDownloadPrioritizationFIFO,
    FWImageDownloadPrioritizationLIFO
};

/// 图片下载凭据
@interface FWImageDownloadReceipt : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) NSUUID *receiptID;

@end

@class FWHTTPSessionManager;

/// 图片下载器
@interface FWImageDownloader : NSObject

@property (nonatomic, strong, nullable) id <FWImageRequestCache> imageCache;

@property (nonatomic, strong) FWHTTPSessionManager *sessionManager;

@property (nonatomic, assign) FWImageDownloadPrioritization downloadPrioritization;

@property (class, nonatomic, strong) FWImageDownloader *sharedDownloader;

+ (instancetype)defaultInstance;

+ (NSURLCache *)defaultURLCache;

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration;

- (instancetype)init;

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (instancetype)initWithSessionManager:(FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(nullable id <FWImageRequestCache>)imageCache;

- (nullable FWImageDownloadReceipt *)downloadImageForURL:(nullable id)url
                                                 options:(FWImageOptions)options
                                                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (nullable FWImageDownloadReceipt *)downloadImageForURL:(nullable id)url
                                           withReceiptID:(NSUUID *)receiptID
                                                 options:(FWImageOptions)options
                                                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (void)cancelTaskForImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt;

- (nullable NSURL *)imageURLForObject:(id)object;

- (void)downloadImageForObject:(id)object
                      imageURL:(nullable id)imageURL
                       options:(FWImageOptions)options
                   placeholder:(nullable void (^)(void))placeholder
                    completion:(nullable void (^)(UIImage * _Nullable image, BOOL isCache, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

- (void)cancelImageDownloadTask:(id)object;

@end

#pragma mark - FWAppImagePlugin

/// 应用默认图片插件
@interface FWAppImagePlugin : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWAppImagePlugin *sharedInstance;

/// 图片加载完成是否显示渐变动画，默认NO
@property (nonatomic, assign) BOOL fadeAnimated;

/// 图片前置过滤器，setImageURL开始时调用
@property (nonatomic, copy, nullable) void (^preFilter)(UIImageView *imageView);

/// 图片后置过滤器，setImageURL完成时调用
@property (nonatomic, copy, nullable) void (^postFilter)(UIImageView *imageView, UIImage * _Nullable image);

@end

NS_ASSUME_NONNULL_END
