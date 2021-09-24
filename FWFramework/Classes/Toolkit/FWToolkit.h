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
#import "FWFoundation.h"
#import "FWIcon.h"
#import "FWTheme.h"
#import "FWUIKit.h"

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

/// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
+ (BOOL)fwIsSystemURL:(id)url;

/// 判断URL是否HTTP链接，支持NSString|NSURL
+ (BOOL)fwIsHttpURL:(id)url;

/// 判断URL是否是AppStore链接，支持NSString|NSURL
+ (BOOL)fwIsAppStoreURL:(id)url;

/// 打开AppStore下载页
+ (void)fwOpenAppStore:(NSString *)appId;

/// 打开系统应用设置页
+ (void)fwOpenAppSettings;

/// 打开系统分享
+ (void)fwOpenActivityItems:(NSArray *)activityItems excludedTypes:(nullable NSArray<UIActivityType> *)excludedTypes;

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

#pragma mark - UIImage+FWToolkit

/*!
 @brief UIImage+FWToolkit
 */
@interface UIImage (FWToolkit)

/// 从视图创建UIImage，生成截图，主线程调用
+ (nullable UIImage *)fwImageWithView:(UIView *)view;

/// 从颜色创建UIImage，默认尺寸1x1
+ (nullable UIImage *)fwImageWithColor:(UIColor *)color;

/// 从颜色创建UIImage，指定尺寸
+ (nullable UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size;

/// 从颜色创建UIImage，指定尺寸和圆角
+ (nullable UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius;

/// 从block创建UIImage，指定尺寸
+ (nullable UIImage *)fwImageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef context))block;

/// 从当前图片创建指定透明度的图片
- (nullable UIImage *)fwImageWithAlpha:(CGFloat)alpha;

/// 从当前图片混合颜色创建UIImage，默认kCGBlendModeDestinationIn模式，适合透明图标
- (nullable UIImage *)fwImageWithTintColor:(UIColor *)tintColor;

/// 从当前UIImage混合颜色创建UIImage，自定义模式
- (nullable UIImage *)fwImageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

/// 缩放图片到指定大小
- (nullable UIImage *)fwImageWithScaleSize:(CGSize)size;

/// 缩放图片到指定大小，指定模式
- (nullable UIImage *)fwImageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/// 按指定模式绘制图片
- (void)fwDrawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds;

/// 裁剪指定区域图片
- (nullable UIImage *)fwImageWithCropRect:(CGRect)rect;

/// 指定颜色填充图片边缘
- (nullable UIImage *)fwImageWithInsets:(UIEdgeInsets)insets color:(nullable UIColor *)color;

/// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets;

/// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode;

/// 生成圆角图片
- (nullable UIImage *)fwImageWithCornerRadius:(CGFloat)radius;

/// 按角度常数(0~360)转动图片，默认图片尺寸适应内容
- (nullable UIImage *)fwImageWithRotateDegree:(CGFloat)degree;

/// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪
- (nullable UIImage *)fwImageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize;

/// 生成mark图片
- (nullable UIImage *)fwImageWithMaskImage:(UIImage *)maskImage;

/// 图片合并，并制定叠加图片的起始位置
- (nullable UIImage *)fwImageWithMergeImage:(UIImage *)image atPoint:(CGPoint)point;

/// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
- (nullable UIImage *)fwCompressImageWithMaxLength:(NSInteger)maxLength;

/// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.1。不保证图片大小一定小于该大小
- (nullable NSData *)fwCompressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio;

/// 长边压缩图片尺寸，获取等比例的图片
- (nullable UIImage *)fwCompressImageWithMaxWidth:(NSInteger)maxWidth;

/// 通过指定图片最长边，获取等比例的图片size
- (CGSize)fwScaleSizeWithMaxWidth:(CGFloat)maxWidth;

/// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fwOriginalImage;

/// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fwTemplateImage;

/// 判断图片是否有透明通道
@property (nonatomic, assign, readonly) BOOL fwHasAlpha;

/// 获取当前图片的像素大小，多倍图会放大到一倍
@property (nonatomic, assign, readonly) CGSize fwPixelSize;

@end

#pragma mark - UIView+FWToolkit

/*!
 @brief UIView+FWToolkit
 */
@interface UIView (FWToolkit)

/// 顶部纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat fwTop;

/// 底部纵坐标，frame.origin.y + frame.size.height
@property (nonatomic, assign) CGFloat fwBottom;

/// 左边横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat fwLeft;

/// 右边横坐标，frame.origin.x + frame.size.width
@property (nonatomic, assign) CGFloat fwRight;

/// 宽度，frame.size.width
@property (nonatomic, assign) CGFloat fwWidth;

/// 高度，frame.size.height
@property (nonatomic, assign) CGFloat fwHeight;

/// 中心横坐标，center.x
@property (nonatomic, assign) CGFloat fwCenterX;

/// 中心纵坐标，center.y
@property (nonatomic, assign) CGFloat fwCenterY;

/// 起始横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat fwX;

/// 起始纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat fwY;

/// 起始坐标，frame.origin
@property (nonatomic, assign) CGPoint fwOrigin;

/// 大小，frame.size
@property (nonatomic, assign) CGSize fwSize;

@end

#pragma mark - UIViewController+FWToolkit

/// 视图控制器生命周期状态枚举
typedef NS_OPTIONS(NSUInteger, FWViewControllerVisibleState) {
    /// 未触发ViewDidLoad
    FWViewControllerVisibleStateReady = 0,
    /// 已触发ViewDidLoad
    FWViewControllerVisibleStateDidLoad,
    /// 已触发ViewWillAppear
    FWViewControllerVisibleStateWillAppear,
    /// 已触发ViewDidAppear
    FWViewControllerVisibleStateDidAppear,
    /// 已触发ViewWillDisappear
    FWViewControllerVisibleStateWillDisappear,
    /// 已触发ViewDidDisappear
    FWViewControllerVisibleStateDidDisappear,
};

/*!
 @brief UIViewController+FWToolkit
 */
@interface UIViewController (FWToolkit)

/// 当前生命周期状态，默认Ready
@property (nonatomic, assign, readonly) FWViewControllerVisibleState fwVisibleState;

/// 生命周期变化时通知句柄，默认nil
@property (nonatomic, copy, nullable) void (^fwVisibleStateChanged)(__kindof UIViewController *viewController, FWViewControllerVisibleState visibleState);

/// 将要dealloc时执行句柄，默认nil
@property (nonatomic, copy, nullable) void (^fwWillDeallocBlock)(__kindof UIViewController *viewController);

@end

NS_ASSUME_NONNULL_END
