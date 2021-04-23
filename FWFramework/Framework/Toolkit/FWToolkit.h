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
#import "FWImage.h"
#import "FWTheme.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSAttributedString+FWToolkit

/*!
 @brief NSAttributedString+FWToolkit
 */
@interface NSAttributedString (FWToolkit)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

@end

#pragma mark - NSDate+FWToolkit

/*!
 @brief NSDate+FWToolkit
 */
@interface NSDate (FWToolkit)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

@end

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
@property (nonatomic, assign, readonly) long fwHexValue;

/// 读取颜色的透明度值，范围0~1
@property (nonatomic, assign, readonly) CGFloat fwAlphaValue;

/// 读取颜色的十六进制字符串RGB，不含透明度
@property (nonatomic, copy, readonly) NSString *fwHexString;

/// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
@property (nonatomic, copy, readonly) NSString *fwHexStringWithAlpha;

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

#pragma mark - UIDevice+FWToolkit

/*!
 @brief UIDevice+FWToolkit
 */
@interface UIDevice (FWToolkit)

/// 设置设备token原始Data，格式化并保存
+ (void)fwSetDeviceTokenData:(nullable NSData *)tokenData;

/// 获取设备Token格式化后的字符串
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceToken;

/// 获取设备模型，格式："iPhone6,1"
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceModel;

/// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFV;

/// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Component_Tracking组件后生效
@property (class, nonatomic, copy, readonly, nullable) NSString *fwDeviceIDFA;

@end

#pragma mark - UIView+FWToolkit

/*!
 @brief UIView+FWToolkit
 */
@interface UIView (FWToolkit)

/// 获取响应的视图控制器
@property (nonatomic, strong, readonly, nullable) __kindof UIViewController *fwViewController;

@end

#pragma mark - UIScrollView+FWToolkit

/*!
 @brief UIScrollView+FWToolkit
 */
@interface UIScrollView (FWToolkit)

/// 滚动视图自定义浮层，用于显示空界面、骨架屏等，支持UIScrollView|UITableView|UICollectionView
@property (nonatomic, strong, readonly) UIView *fwOverlayView;

/// 是否显示自定义浮层
@property (nonatomic, assign, readonly) BOOL fwHasOverlayView;

/// 显示自定义浮层，自动添加到滚动视图
- (void)fwShowOverlayView;

/// 显示自定义浮层，自动添加到滚动视图并执行渐变动画
- (void)fwShowOverlayViewAnimated:(BOOL)animated;

/// 隐藏自定义浮层，自动从滚动视图移除
- (void)fwHideOverlayView;

@end

NS_ASSUME_NONNULL_END
