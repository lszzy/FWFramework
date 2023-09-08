//
//  ImagePlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWImagePlugin

/// 本地图片解码编码选项，默认兼容SDWebImage
typedef NSString * __FWImageCoderOptions NS_EXTENSIBLE_STRING_ENUM NS_SWIFT_NAME(ImageCoderOptions);
/// 图片解码scale选项，默认未指定时为1
FOUNDATION_EXPORT __FWImageCoderOptions const __FWImageCoderOptionScaleFactor;
/// 图片解码缩略图像素尺寸选项，默认未指定时为zero
FOUNDATION_EXPORT __FWImageCoderOptions const __FWImageCoderOptionThumbnailPixelSize;

/// 网络图片加载选项，默认兼容SDWebImage
typedef NS_OPTIONS(NSUInteger, __FWWebImageOptions) {
    /// 空选项，默认值
    __FWWebImageOptionNone = 0,
    /// 是否图片缓存存在时仍重新请求(依赖NSURLCache)
    __FWWebImageOptionRefreshCached = 1 << 3,
    /// 禁止调用imageView.setImage:显示图片
    __FWWebImageOptionAvoidSetImage = 1 << 10,
    /// 忽略图片缓存，始终重新请求
    __FWWebImageOptionIgnoreCache = 1 << 16,
} NS_SWIFT_NAME(WebImageOptions);

/// 图片插件协议，应用可自定义图片插件
NS_SWIFT_NAME(ImagePlugin)
@protocol __FWImagePlugin <NSObject>

@optional

/// 获取view正在加载的URL插件方法
- (nullable NSURL *)imageURL:(UIView *)view;

/// view加载网络图片插件方法
- (void)view:(UIView *)view
        setImageURL:(nullable NSURL *)imageURL
        placeholder:(nullable UIImage *)placeholder
            options:(__FWWebImageOptions)options
            context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
      setImageBlock:(nullable void (^)(UIView *view, UIImage * _Nullable image))setImageBlock
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(double progress))progress;

/// view取消加载网络图片请求插件方法
- (void)cancelImageRequest:(UIView *)view;

/// image下载网络图片插件方法，返回下载凭据
- (nullable id)downloadImage:(nullable NSURL *)imageURL
                       options:(__FWWebImageOptions)options
                       context:(nullable NSDictionary<__FWImageCoderOptions, id> *)context
                    completion:(void (^)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

/// image取消下载网络图片插件方法，指定下载凭据
- (void)cancelImageDownload:(nullable id)receipt;

/// 创建动画视图插件方法，默认使用UIImageView
- (UIImageView *)animatedImageView;

/// image本地解码插件方法，默认使用系统方法
- (nullable UIImage *)imageDecode:(NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary<__FWImageCoderOptions, id> *)options;

/// image本地编码插件方法，默认使用系统方法
- (nullable NSData *)imageEncode:(UIImage *)image options:(nullable NSDictionary<__FWImageCoderOptions, id> *)options;

@end

NS_ASSUME_NONNULL_END
