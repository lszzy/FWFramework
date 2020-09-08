/*!
 @header     FWToolkitManager.h
 @indexgroup FWFramework
 @brief      FWToolkitManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIApplication+FWToolkit

// 是否是调试模式
#ifdef DEBUG
    #define FWIsDebug YES
#else
    #define FWIsDebug NO
#endif

/*!
 @brief UIApplication+FWToolkit
 */
@interface UIApplication (FWToolkit)

// 是否是调试模式
+ (BOOL)fwIsDebug;

@end

#pragma mark - UIDevice+FWToolkit

// 是否是模拟器
#if TARGET_OS_SIMULATOR
    #define FWIsSimulator YES
#else
    #define FWIsSimulator NO
#endif

// 是否是iPhone设备
#define FWIsIphone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? YES : NO)
// 是否是iPad设备
#define FWIsIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO)

// iOS系统版本，只获取第二级的版本号，如10.3.1返回10.3
#define FWIosVersion [[[UIDevice currentDevice] systemVersion] floatValue]
// 是否是指定iOS主版本
#define FWIsIos( version ) (FWIosVersion >= version && FWIosVersion < (version + 1) ? YES : NO)
// 是否是大于等于指定iOS主版本
#define FWIsIosLater( version ) (FWIosVersion >= version ? YES : NO)

/*!
 @brief UIDevice+FWToolkit
 */
@interface UIDevice (FWToolkit)

// 是否是模拟器
+ (BOOL)fwIsSimulator;

// 是否是iPhone
+ (BOOL)fwIsIphone;
// 是否是iPad
+ (BOOL)fwIsIpad;

// iOS系统版本
+ (float)fwIosVersion;
// 是否是指定iOS主版本
+ (BOOL)fwIsIos:(NSInteger)version;
// 是否是大于等于指定iOS主版本
+ (BOOL)fwIsIosLater:(NSInteger)version;

@end

#pragma mark - UIScreen+FWToolkit

/// 屏幕尺寸可扩展枚举
typedef NSInteger FWScreenInch NS_TYPED_EXTENSIBLE_ENUM;
static const FWScreenInch FWScreenInch35 = 35;
static const FWScreenInch FWScreenInch40 = 40;
static const FWScreenInch FWScreenInch47 = 47;
static const FWScreenInch FWScreenInch55 = 55;
static const FWScreenInch FWScreenInch58 = 58;
static const FWScreenInch FWScreenInch61 = 61;
static const FWScreenInch FWScreenInch65 = 65;

// 屏幕尺寸
#define FWScreenSize [UIScreen mainScreen].bounds.size
// 屏幕宽度
#define FWScreenWidth [UIScreen mainScreen].bounds.size.width
// 屏幕高度
#define FWScreenHeight [UIScreen mainScreen].bounds.size.height
// 屏幕像素比例
#define FWScreenScale [UIScreen mainScreen].scale
// 屏幕分辨率
#define FWScreenResolution CGSizeMake( [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale, [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale )

// 判断屏幕尺寸
#define FWIsScreenSize( width, height ) CGSizeEqualToSize(CGSizeMake(width, height), [UIScreen mainScreen].bounds.size)
// 判断屏幕分辨率
#define FWIsScreenResolution( width, height ) CGSizeEqualToSize(CGSizeMake(width, height), FWScreenResolution)
// 判断屏幕英寸
#define FWIsScreenInch( inch ) [UIScreen fwIsScreenInch:inch]
// 是否是iPhoneX系列全面屏幕
#define FWIsScreenX [UIScreen fwIsScreenX]

// 状态栏高度
#define FWStatusBarHeight (FWIsScreenX ? 44.0 : 20.0)
// 导航栏高度
#define FWNavigationBarHeight (FWIsScreenX ? 44.0 : 44.0)
// 标签栏高度
#define FWTabBarHeight (FWIsScreenX ? 83.0 : 49.0)
// 工具栏高度
#define FWToolBarHeight (FWIsScreenX ? 78.0 : 44.0)
// 顶部栏高度，包含状态栏、导航栏
#define FWTopBarHeight (FWStatusBarHeight + FWNavigationBarHeight)
// 底部栏高度，包含标签栏
#define FWBottomBarHeight FWTabBarHeight

/*!
 @brief UIScreen+FWToolkit
 */
@interface UIScreen (FWToolkit)

// 屏幕尺寸
+ (CGSize)fwScreenSize;
// 屏幕宽度
+ (CGFloat)fwScreenWidth;
// 屏幕高度
+ (CGFloat)fwScreenHeight;
// 屏幕像素比例
+ (CGFloat)fwScreenScale;
// 屏幕分辨率
+ (CGSize)fwScreenResolution;
// 获取一像素的大小
+ (CGFloat)fwPixelOne;

// 是否是指定尺寸屏幕
+ (BOOL)fwIsScreenSize:(CGSize)size;
// 是否是指定分辨率屏幕
+ (BOOL)fwIsScreenResolution:(CGSize)resolution;
// 是否是指定英寸屏幕
+ (BOOL)fwIsScreenInch:(FWScreenInch)inch;
// 是否是iPhoneX系列全面屏幕
+ (BOOL)fwIsScreenX;

// 检查是否含有安全区域，可用来判断iPhoneX
+ (BOOL)fwHasSafeAreaInsets;
// 获取安全区域距离
+ (UIEdgeInsets)fwSafeAreaInsets;

// 状态栏高度，与是否隐藏无关
+ (CGFloat)fwStatusBarHeight;
// 导航栏高度，与是否隐藏无关
+ (CGFloat)fwNavigationBarHeight;
// 标签栏高度，与是否隐藏无关
+ (CGFloat)fwTabBarHeight;
// 工具栏高度，与是否隐藏无关
+ (CGFloat)fwToolBarHeight;
// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
+ (CGFloat)fwTopBarHeight;
// 底部栏高度，包含标签栏，与是否隐藏无关
+ (CGFloat)fwBottomBarHeight;

@end

/*!
 @brief UIViewController+FWToolkit
 */
@interface UIViewController (FWToolkit)

// 当前状态栏高度，隐藏为0
- (CGFloat)fwStatusBarHeight;
// 当前导航栏高度，隐藏为0
- (CGFloat)fwNavigationBarHeight;
// 当前标签栏高度，隐藏为0
- (CGFloat)fwTabBarHeight;
// 当前工具栏高度，隐藏为0
- (CGFloat)fwToolBarHeight;
// 顶部栏高度，包含状态栏、导航栏，隐藏为0
- (CGFloat)fwTopBarHeight;
// 底部栏高度，包含标签栏，隐藏为0
- (CGFloat)fwBottomBarHeight;

@end

#pragma mark - UIColor+FWToolkit

// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/*!
 @brief UIColor主题分类
 */
@interface UIColor (FWToolkit)

// 从十六进制值初始化，格式：0x20B2AA，透明度为1.0
+ (UIColor *)fwColorWithHex:(long)hex;

// 从十六进制值初始化，格式：0x20B2AA，自定义透明度
+ (UIColor *)fwColorWithHex:(long)hex alpha:(CGFloat)alpha;

// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
+ (void)fwColorStandardARGB:(BOOL)enabled;

// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度为1.0，失败时返回clear
+ (UIColor *)fwColorWithHexString:(NSString *)hexString;

// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，自定义透明度，失败时返回clear
+ (UIColor *)fwColorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

// 从颜色字符串初始化，支持十六进制和颜色值，透明度为1.0，失败时返回clear
+ (UIColor *)fwColorWithString:(NSString *)string;

// 从颜色字符串初始化，支持十六进制和颜色值，自定义透明度，失败时返回clear
+ (UIColor *)fwColorWithString:(NSString *)string alpha:(CGFloat)alpha;

// 读取颜色的十六进制值RGB，不含透明度
- (long)fwHexValue;

// 读取颜色的十六进制字符串RGB，不含透明度
- (NSString *)fwHexString;

// 读取颜色的十六进制字符串RGBA|ARGB，包含透明度
- (NSString *)fwHexStringWithAlpha;

@end

#pragma mark - UIFont+FWToolkit

// 快速创建系统字体，字重可选，默认Regular
#define FWFontSize( size, ... ) [UIFont systemFontOfSize:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建细字体
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat size);
/// 快速创建普通字体
FOUNDATION_EXPORT UIFont * FWFontRegular(CGFloat size);
/// 快速创建粗体字体
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat size);
/// 快速创建斜体字体
FOUNDATION_EXPORT UIFont * FWFontItalic(CGFloat size);

/*!
 @brief UIFont快速创建分类
 */
@interface UIFont (FWToolkit)

// 返回系统字体的细体
+ (UIFont *)fwLightFontOfSize:(CGFloat)size;
// 返回系统字体的普通体
+ (UIFont *)fwFontOfSize:(CGFloat)size;
// 返回系统字体的粗体
+ (UIFont *)fwBoldFontOfSize:(CGFloat)size;
// 返回系统字体的斜体
+ (UIFont *)fwItalicFontOfSize:(CGFloat)size;

// 创建指定尺寸和weight的系统字体
+ (UIFont *)fwFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;

@end

NS_ASSUME_NONNULL_END
