/*!
 @header     FWNetworkManager.h
 @indexgroup FWFramework
 @brief      FWNetworkManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/7/18
 */

#import "FWURLRequestSerialization.h"
#import "FWURLResponseSerialization.h"
#import "FWSecurityPolicy.h"
#import "FWNetworkReachabilityManager.h"
#import "FWURLSessionManager.h"
#import "FWHTTPSessionManager.h"

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

/// 图片下载器
@interface FWImageDownloader : NSObject

@property (nonatomic, strong, nullable) id <FWImageRequestCache> imageCache;

@property (nonatomic, strong) FWHTTPSessionManager *sessionManager;

@property (nonatomic, assign) FWImageDownloadPrioritization downloadPrioritization;

+ (instancetype)defaultInstance;

+ (NSURLCache *)defaultURLCache;

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration;

- (instancetype)init;

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (instancetype)initWithSessionManager:(FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(nullable id <FWImageRequestCache>)imageCache;

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                        progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                 withReceiptID:(NSUUID *)receiptID
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                       progress:(nullable void (^)(NSProgress *downloadProgress))progress;

- (void)cancelTaskForImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt;

@end

#pragma mark - UIImageView+FWNetwork

/// 异步加载网络图片分类
@interface UIImageView (FWNetwork)

/// 默认框架公用图片下载器
@property (class, nonatomic, strong) FWImageDownloader *fwSharedImageDownloader;

/// 动画ImageView视图类，优先加载插件，默认UIImageView
@property (class, nonatomic, unsafe_unretained) Class fwImageViewAnimatedClass;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                 progress:(nullable void (^)(double progress))progress;

/// 取消默认框架图片下载任务
- (void)fwCancelImageDownloadTask;

@end

#pragma mark - FWImagePlugin

/*!
 @brief 图片插件协议，应用可自定义图片实现
 */
@protocol FWImagePlugin <NSObject>

@optional

// 解析框架网络库图片插件方法，默认使用UIImage系统方法
- (nullable UIImage *)fwImageDecodeWithData:(NSData *)data scale:(CGFloat)scale;

// imageView动画视图类插件方法，默认使用UIImageView
- (Class)fwImageViewAnimatedClass;

// imageView加载网络图片插件方法，默认使用框架网络库
- (void)fwImageView:(UIImageView *)imageView
        setImageUrl:(NSString *)imageUrl
        placeholder:(nullable UIImage *)placeholder
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(double progress))progress;

@end

NS_ASSUME_NONNULL_END
