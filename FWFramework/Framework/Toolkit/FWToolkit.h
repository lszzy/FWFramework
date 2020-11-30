/*!
 @header     FWToolkit.h
 @indexgroup FWFramework
 @brief      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>
#import "FWAdaptive.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWDynamicLayout.h"
#import "FWHelper.h"
#import "FWTheme.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIApplication+FWToolkit

/*!
 @brief UIApplication+FWToolkit
 @discussion 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app
 */
@interface UIApplication (FWToolkit)

/// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
+ (BOOL)fwCanOpenURL:(id)url;

/// 打开URL，支持NSString|NSURL，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fwOpenURL:(id)url;

/// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fwOpenURL:(id)url completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
+ (void)fwOpenUniversalLinks:(id)url completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开AppStore下载页
+ (void)fwOpenAppStore:(NSString *)appId;

/// 判断URL是否是AppStore链接，支持NSString|NSURL
+ (BOOL)fwIsAppStoreURL:(id)url;

/// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
+ (BOOL)fwIsSystemURL:(id)url;

/// 判断URL是否HTTP链接，支持NSString|NSURL
+ (BOOL)fwIsHttpURL:(id)url;

/// 打开内部浏览器，支持NSString|NSURL
+ (void)fwOpenSafariController:(id)url;

/// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
+ (void)fwOpenSafariController:(id)url completionHandler:(nullable void (^)(void))completion;

@end

#pragma mark - UIColor+FWToolkit

/// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

/// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/*!
 @brief UIColor+FWToolkit
 */
@interface UIColor (FWToolkit)

/// 从十六进制值初始化，格式：0x20B2AA，透明度为1.0
+ (UIColor *)fwColorWithHex:(long)hex;

/// 从十六进制值初始化，格式：0x20B2AA，自定义透明度
+ (UIColor *)fwColorWithHex:(long)hex alpha:(CGFloat)alpha;

/// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
+ (void)fwColorStandardARGB:(BOOL)enabled;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度为1.0，失败时返回clear
+ (UIColor *)fwColorWithHexString:(NSString *)hexString;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，自定义透明度，失败时返回clear
+ (UIColor *)fwColorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/// 从颜色字符串初始化，支持十六进制和颜色值，透明度为1.0，失败时返回clear
+ (UIColor *)fwColorWithString:(NSString *)string;

/// 从颜色字符串初始化，支持十六进制和颜色值，自定义透明度，失败时返回clear
+ (UIColor *)fwColorWithString:(NSString *)string alpha:(CGFloat)alpha;

/// 读取颜色的十六进制值RGB，不含透明度
- (long)fwHexValue;

/// 读取颜色的透明度值，范围0~1
- (CGFloat)fwAlphaValue;

/// 读取颜色的十六进制字符串RGB，不含透明度
- (NSString *)fwHexString;

/// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
- (NSString *)fwHexStringWithAlpha;

@end

#pragma mark - UIFont+FWToolkit

/// 快速创建系统字体，字重可选，默认Regular
#define FWFontSize( size, ... ) [UIFont fwFontOfSize:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建细字体
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat size);
/// 快速创建普通字体
FOUNDATION_EXPORT UIFont * FWFontRegular(CGFloat size);
/// 快速创建粗体字体
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat size);
/// 快速创建斜体字体
FOUNDATION_EXPORT UIFont * FWFontItalic(CGFloat size);

/*!
 @brief UIFont+FWToolkit
 */
@interface UIFont (FWToolkit)

/// 返回系统字体的细体
+ (UIFont *)fwLightFontOfSize:(CGFloat)size;
/// 返回系统字体的普通体
+ (UIFont *)fwFontOfSize:(CGFloat)size;
/// 返回系统字体的粗体
+ (UIFont *)fwBoldFontOfSize:(CGFloat)size;
/// 返回系统字体的斜体
+ (UIFont *)fwItalicFontOfSize:(CGFloat)size;

/// 创建指定尺寸和weight的系统字体
+ (UIFont *)fwFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;

@end

#pragma mark - UIImage+FWToolkit

/// 使用文件名方式加载UIImage，不支持动图。会被系统缓存，适用于大量复用的小资源图
FOUNDATION_EXPORT UIImage * _Nullable FWImageName(NSString *name);

/// 从图片文件或应用资源路径加载UIImage，支持动图，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
FOUNDATION_EXPORT UIImage * _Nullable FWImageFile(NSString *path);

/*!
 @brief UIImage+FWToolkit
 */
@interface UIImage (FWToolkit)

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

@end

#pragma mark - UIImageView+FWToolkit

/*!
 @brief UIImageView+FWToolkit
 */
@interface UIImageView (FWToolkit)

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
