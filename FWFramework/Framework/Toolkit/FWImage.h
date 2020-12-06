/*!
 @header     FWImage.h
 @indexgroup FWFramework
 @brief      FWImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/11/30
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImage+FWImage

/// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
FOUNDATION_EXPORT UIImage * _Nullable FWImageName(NSString *name);

/// 从图片文件或应用资源路径加载UIImage，支持动图，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
FOUNDATION_EXPORT UIImage * _Nullable FWImageFile(NSString *path);

/*!
 @brief UIImage+FWImage
 */
@interface UIImage (FWImage)

/// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
+ (nullable UIImage *)fwImageWithName:(NSString *)name;

/// 从图片文件加载UIImage，支持动图，支持绝对路径和bundle路径，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (nullable UIImage *)fwImageWithFile:(NSString *)path;

/// 从图片数据解码创建UIImage，scale为1，支持动图
+ (nullable UIImage *)fwImageWithData:(nullable NSData *)data;

/// 从图片数据解码创建UIImage，指定scale，支持动图
+ (nullable UIImage *)fwImageWithData:(nullable NSData *)data scale:(CGFloat)scale;

/// 下载网络图片并返回下载凭据
+ (nullable id)fwDownloadImage:(nullable id)url
                    completion:(void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

/// 指定下载凭据取消网络图片下载
+ (void)fwCancelImageDownload:(nullable id)receipt;

/// 从视图创建UIImage，生成截图，主线程调用
+ (nullable UIImage *)fwImageWithView:(UIView *)view;

/// 从颜色创建UIImage，默认尺寸1x1
+ (nullable UIImage *)fwImageWithColor:(UIColor *)color;

/// 从颜色创建UIImage，指定尺寸
+ (nullable UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size;

/// 从当前图片混合颜色创建UIImage，默认kCGBlendModeDestinationIn模式，适合透明图标
- (nullable UIImage *)fwImageWithTintColor:(UIColor *)tintColor;

/// 从当前UIImage混合颜色创建UIImage，自定义模式
- (nullable UIImage *)fwImageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

/// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
- (nullable UIImage *)fwCompressImageWithMaxLength:(NSInteger)maxLength;

/// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.1。不保证图片大小一定小于该大小
- (nullable NSData *)fwCompressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio;

/// 长边压缩图片尺寸，获取等比例的图片
- (nullable UIImage *)fwCompressImageWithMaxWidth:(NSInteger)maxWidth;

/// 通过指定图片最长边，获取等比例的图片size
- (CGSize)fwScaleSizeWithMaxWidth:(CGFloat)maxWidth;

/// 判断图片是否有透明通道
- (BOOL)fwHasAlpha;

@end

#pragma mark - UIImageView+FWImage

/*!
 @brief UIImageView+FWImage
 */
@interface UIImageView (FWImage)

/// 动画ImageView视图类，优先加载插件，默认UIImageView
@property (class, nonatomic, unsafe_unretained) Class fwImageViewAnimatedClass;

/// 加载网络图片，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(nullable id)url;

/// 加载网络图片，支持占位，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage;

/// 加载网络图片，支持占位和回调，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion;

/// 加载网络图片，支持占位、回调和进度，优先加载插件，默认使用框架网络库
- (void)fwSetImageWithURL:(nullable id)url
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                 progress:(nullable void (^)(double progress))progress;

/// 取消加载网络图片请求
- (void)fwCancelImageRequest;

@end

#pragma mark - FWImagePlugin

/// 图片插件协议，应用可自定义图片插件
@protocol FWImagePlugin <NSObject>

@optional

/// imageView加载网络图片插件方法
- (void)fwImageView:(UIImageView *)imageView
        setImageURL:(nullable NSURL *)imageURL
        placeholder:(nullable UIImage *)placeholder
         completion:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
           progress:(nullable void (^)(double progress))progress;

/// imageView取消加载网络图片请求插件方法
- (void)fwCancelImageRequest:(UIImageView *)imageView;

/// image下载网络图片插件方法，返回下载凭据
- (nullable id)fwDownloadImage:(nullable NSURL *)imageURL
                    completion:(void (^)(UIImage * _Nullable image, NSError * _Nullable error))completion
                      progress:(nullable void (^)(double progress))progress;

/// image取消下载网络图片插件方法，指定下载凭据
- (void)fwCancelImageDownload:(nullable id)receipt;

/// imageView动画视图类插件方法，默认使用UIImageView
- (Class)fwImageViewAnimatedClass;

/// image本地解码插件方法，默认使用系统方法
- (nullable UIImage *)fwImageDecode:(NSData *)data scale:(CGFloat)scale;

@end

#pragma mark - FWSDWebImagePlugin

/// SDWebImage图片插件，启用Component_SDWebImage组件后生效
@interface FWSDWebImagePlugin : NSObject <FWImagePlugin>

@property (class, nonatomic, readonly) FWSDWebImagePlugin *sharedInstance;

@end

NS_ASSUME_NONNULL_END
