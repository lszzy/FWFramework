/*!
 @header     FWWebImage.h
 @indexgroup FWFramework
 @brief      FWWebImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAnimatedImage

/// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
FOUNDATION_EXPORT UIImage * _Nullable FWImageName(NSString *name);

/// 从图片文件或应用资源路径加载UIImage，支持动图，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
FOUNDATION_EXPORT UIImage * _Nullable FWImageFile(NSString *path);

/// 图片格式可扩展枚举
typedef NSInteger FWImageFormat NS_TYPED_EXTENSIBLE_ENUM;
static const FWImageFormat FWImageFormatUndefined = -1;
static const FWImageFormat FWImageFormatJPEG      = 0;
static const FWImageFormat FWImageFormatPNG       = 1;
static const FWImageFormat FWImageFormatGIF       = 2;
static const FWImageFormat FWImageFormatTIFF      = 3;
static const FWImageFormat FWImageFormatWebP      = 4; //iOS14+
static const FWImageFormat FWImageFormatHEIC      = 5; //iOS13+
static const FWImageFormat FWImageFormatHEIF      = 6; //iOS13+
static const FWImageFormat FWImageFormatPDF       = 7;
static const FWImageFormat FWImageFormatSVG       = 8;

#pragma mark - UIImage+FWAnimated

/*!
 @brief UIImage+FWAnimated
 
 @see https://github.com/SDWebImage/SDWebImage
 */
@interface UIImage (FWAnimated)

/// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
+ (nullable UIImage *)fwImageWithName:(NSString *)name;

/// 从图片文件加载UIImage，支持动图，支持绝对路径和bundle路径，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (nullable UIImage *)fwImageWithFile:(NSString *)path;

/// 从图片数据解码创建UIImage，scale为1，支持动图
+ (nullable UIImage *)fwImageWithData:(nullable NSData *)data;

/// 从图片数据解码创建UIImage，指定scale，支持动图
+ (nullable UIImage *)fwImageWithData:(nullable NSData *)data scale:(CGFloat)scale;

#pragma mark - Property

/// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
@property (nonatomic, assign) NSUInteger fwImageLoopCount;

/// 是否是动图，内部检查images数组
@property (nonatomic, assign, readonly) BOOL fwIsAnimated;

/// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
@property (nonatomic, assign, readonly) BOOL fwIsVector;

/// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回FWImageFormatUndefined
@property (nonatomic, assign) FWImageFormat fwImageFormat;

@end

#pragma mark - NSData+FWAnimated

/// 扩展系统UTType
#define kFWUTTypeHEIC ((__bridge CFStringRef)@"public.heic")
#define kFWUTTypeHEIF ((__bridge CFStringRef)@"public.heif")
#define kFWUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
#define kFWUTTypeWebP ((__bridge CFStringRef)@"org.webmproject.webp")

/*!
 @brief NSData+FWAnimated
 */
@interface NSData (FWAnimated)

/// 获取图片数据的格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fwImageFormatForImageData:(nullable NSData *)data;

/// 图片格式转化为UTType，未知格式返回kUTTypeImage
+ (nonnull CFStringRef)fwUTTypeFromImageFormat:(FWImageFormat)format CF_RETURNS_NOT_RETAINED;

/// UTType转化为图片格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fwImageFormatFromUTType:(nonnull CFStringRef)uttype;

@end

#pragma mark - FWImageFrame

/*!
 @brief 动图单帧对象
 */
@interface FWImageFrame : NSObject

/// 单帧图片
@property (nonatomic, strong, readonly) UIImage *image;

/// 单帧时长
@property (nonatomic, assign, readonly) NSTimeInterval duration;

/// 创建单帧对象
- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration;

/// 根据单帧对象创建动图Image
+ (nullable UIImage *)animatedImageWithFrames:(nullable NSArray<FWImageFrame *> *)frames;

/// 从动图Image创建单帧对象数组
+ (nullable NSArray<FWImageFrame *> *)framesFromAnimatedImage:(nullable UIImage *)animatedImage;

@end

#pragma mark - FWImageCoder

/// 图片解码器，支持动图
@interface FWImageCoder : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWImageCoder *sharedInstance;

/// 是否启用HEIC动图，因系统解码性能原因，默认为NO，禁用HEIC动图
@property (nonatomic, assign) BOOL heicsEnabled;

/// 解析图片数据到Image，可指定scale
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data scale:(CGFloat)scale;

@end

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

/// 加载网络图片，支持占位，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage;

/// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

/// 加载网络图片，支持占位、回调和进度，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                 progress:(nullable void (^)(double progress))progress;

/// 取消默认框架图片下载任务
- (void)fwCancelImageDownloadTask;

@end

#pragma mark - FWImagePlugin

/// 图片插件协议，应用可自定义图片插件
@protocol FWImagePlugin <NSObject>

@optional

/// imageView动画视图类插件方法，默认使用UIImageView
- (Class)fwImageViewAnimatedClass;

/// image本地解码插件方法，默认使用框架解码库
- (nullable UIImage *)fwImageDecode:(NSData *)data scale:(CGFloat)scale;

/// imageView加载网络图片插件方法，默认使用框架网络库
- (void)fwImageView:(UIImageView *)imageView
        setImageURL:(NSURL *)imageURL
        placeholder:(nullable UIImage *)placeholder
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(double progress))progress;

@end

#if FWCOMPONENT_SDWEBIMAGE_ENABLED

/// SDWebImage图片插件
@interface FWSDWebImagePlugin : NSObject <FWImagePlugin>

@property (class, nonatomic, readonly) FWSDWebImagePlugin *sharedInstance;

@end

#endif

NS_ASSUME_NONNULL_END
