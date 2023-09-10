//
//  FWImagePlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImagePlugin

/// 本地图片解码编码选项，默认兼容SDWebImage
typedef NSString * FWImageCoderOptions NS_EXTENSIBLE_STRING_ENUM NS_SWIFT_NAME(ImageCoderOptions);
/// 图片解码scale选项，默认未指定时为1
FOUNDATION_EXPORT FWImageCoderOptions const FWImageCoderOptionScaleFactor;

/// 网络图片加载选项，默认兼容SDWebImage
typedef NS_OPTIONS(NSUInteger, FWWebImageOptions) {
    /// 空选项，默认值
    FWWebImageOptionNone = 0,
    /// 是否图片缓存存在时仍重新请求(依赖NSURLCache)
    FWWebImageOptionRefreshCached = 1 << 3,
    /// 禁止调用imageView.setImage:显示图片
    FWWebImageOptionAvoidSetImage = 1 << 10,
    /// 忽略图片缓存，始终重新请求
    FWWebImageOptionIgnoreCache = 1 << 16,
} NS_SWIFT_NAME(WebImageOptions);

/// 图片插件协议，应用可自定义图片插件
NS_SWIFT_NAME(ImagePlugin)
@protocol FWImagePlugin <NSObject>

@optional

/// 获取imageView正在加载的URL插件方法
- (nullable NSURL *)imageURL:(UIImageView *)imageView;

/// imageView加载网络图片插件方法
- (void)imageView:(UIImageView *)imageView
        setImageURL:(nullable NSURL *)imageURL
        placeholder:(nullable UIImage *)placeholder
            options:(FWWebImageOptions)options
            context:(nullable NSDictionary<FWImageCoderOptions, id> *)context
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(double progress))progress;

/// imageView取消加载网络图片请求插件方法
- (void)cancelImageRequest:(UIImageView *)imageView;

/// 加载指定URL的本地缓存图片
- (nullable UIImage *)loadImageCache:(nullable NSURL *)imageURL;

/// 清除所有本地图片缓存
- (void)clearImageCaches:(nullable void(^)(void))completion;

/// image下载网络图片插件方法，返回下载凭据
- (nullable id)downloadImage:(nullable NSURL *)imageURL
                       options:(FWWebImageOptions)options
                       context:(nullable NSDictionary<FWImageCoderOptions, id> *)context
                    completion:(void (^)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

/// image取消下载网络图片插件方法，指定下载凭据
- (void)cancelImageDownload:(nullable id)receipt;

/// 创建动画视图插件方法，默认使用UIImageView
- (UIImageView *)animatedImageView;

/// image本地解码插件方法，默认使用系统方法
- (nullable UIImage *)imageDecode:(NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary<FWImageCoderOptions, id> *)options;

/// image本地编码插件方法，默认使用系统方法
- (nullable NSData *)imageEncode:(UIImage *)image options:(nullable NSDictionary<FWImageCoderOptions, id> *)options;

@end

#pragma mark - UIImage+FWImagePlugin

/// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
FOUNDATION_EXPORT UIImage * _Nullable FWImageNamed(NSString *name) NS_SWIFT_UNAVAILABLE("");

@interface UIImage (FWImagePlugin)

/// 根据名称加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
+ (nullable UIImage *)fw_imageNamed:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)
+ (nullable UIImage *)fw_imageNamed:(NSString *)name bundle:(nullable NSBundle *)bundle NS_REFINED_FOR_SWIFT;

/// 根据名称从指定bundle加载UIImage，优先加载图片文件(无缓存)，文件不存在时尝试系统imageNamed方式(有缓存)。支持设置图片解码选项
+ (nullable UIImage *)fw_imageNamed:(NSString *)name bundle:(nullable NSBundle *)bundle options:(nullable NSDictionary<FWImageCoderOptions, id> *)options NS_REFINED_FOR_SWIFT;

/// 从图片文件路径解码创建UIImage，自动识别scale，支持动图
+ (nullable UIImage *)fw_imageWithContentsOfFile:(NSString *)path NS_REFINED_FOR_SWIFT;

/// 从图片数据解码创建UIImage，scale为1，支持动图
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data NS_REFINED_FOR_SWIFT;

/// 从图片数据解码创建UIImage，指定scale，支持动图
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale NS_REFINED_FOR_SWIFT;

/// 从图片数据解码创建UIImage，指定scale，支持动图。支持设置图片解码选项
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary<FWImageCoderOptions, id> *)options NS_REFINED_FOR_SWIFT;

/// 从UIImage编码创建图片数据，支持动图
+ (nullable NSData *)fw_dataWithImage:(nullable UIImage *)image NS_REFINED_FOR_SWIFT;

/// 从UIImage编码创建图片数据，支持动图。支持设置图片编码选项
+ (nullable NSData *)fw_dataWithImage:(nullable UIImage *)image options:(nullable NSDictionary<FWImageCoderOptions, id> *)options NS_REFINED_FOR_SWIFT;

/// 下载网络图片并返回下载凭据
+ (nullable id)fw_downloadImage:(nullable id)url
                    completion:(void (^)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress NS_REFINED_FOR_SWIFT;

/// 下载网络图片并返回下载凭据，指定option
+ (nullable id)fw_downloadImage:(nullable id)url
                       options:(FWWebImageOptions)options
                       context:(nullable NSDictionary<FWImageCoderOptions, id> *)context
                    completion:(void (^)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress NS_REFINED_FOR_SWIFT;

/// 指定下载凭据取消网络图片下载
+ (void)fw_cancelImageDownload:(nullable id)receipt NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIImageView+FWImagePlugin

@interface UIImageView (FWImagePlugin)

/// 自定义图片插件，未设置时自动从插件池加载
@property (nonatomic, strong, nullable) id<FWImagePlugin> fw_imagePlugin NS_REFINED_FOR_SWIFT;

/// 当前正在加载的网络图片URL
@property (nonatomic, copy, readonly, nullable) NSURL *fw_imageURL NS_REFINED_FOR_SWIFT;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fw_setImageWithURL:(nullable id)url NS_REFINED_FOR_SWIFT;

/// 加载网络图片，支持占位，优先加载插件，默认使用框架网络库
- (void)fw_setImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage NS_REFINED_FOR_SWIFT;

/// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
- (void)fw_setImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion NS_REFINED_FOR_SWIFT;

/// 加载网络图片，支持占位、选项、回调和进度，优先加载插件，默认使用框架网络库
- (void)fw_setImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage
                  options:(FWWebImageOptions)options
                  context:(nullable NSDictionary<FWImageCoderOptions, id> *)context
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                 progress:(nullable void (^)(double progress))progress NS_REFINED_FOR_SWIFT;

/// 取消加载网络图片请求
- (void)fw_cancelImageRequest NS_REFINED_FOR_SWIFT;

/// 加载指定URL的本地缓存图片
- (nullable UIImage *)fw_loadImageCacheWithURL:(nullable id)url NS_REFINED_FOR_SWIFT;

/// 清除所有本地图片缓存
+ (void)fw_clearImageCaches:(nullable void(^)(void))completion NS_REFINED_FOR_SWIFT;

/// 创建动画ImageView视图，优先加载插件，默认UIImageView
+ (UIImageView *)fw_animatedImageView NS_SWIFT_NAME(__fw_animatedImageView()) NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
