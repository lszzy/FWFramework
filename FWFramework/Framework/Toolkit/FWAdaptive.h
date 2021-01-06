/*!
 @header     FWAdaptive.h
 @indexgroup FWFramework
 @brief      FWAdaptive
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIApplication+FWAdaptive

/// 是否是调试模式
#ifdef DEBUG
    #define FWIsDebug YES
#else
    #define FWIsDebug NO
#endif

/*!
 @brief UIApplication+FWAdaptive
 */
@interface UIApplication (FWAdaptive)

/// 是否是调试模式
+ (BOOL)fwIsDebug;

@end

#pragma mark - UIDevice+FWAdaptive

/// 是否是模拟器
#if TARGET_OS_SIMULATOR
    #define FWIsSimulator YES
#else
    #define FWIsSimulator NO
#endif

/// 是否是iPhone设备
#define FWIsIphone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? YES : NO)
/// 是否是iPad设备
#define FWIsIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO)

/// iOS系统版本，只获取第二级的版本号，如10.3.1返回10.3
#define FWIosVersion [[[UIDevice currentDevice] systemVersion] floatValue]
/// 是否是指定iOS主版本
#define FWIsIos( version ) (FWIosVersion >= version && FWIosVersion < (version + 1) ? YES : NO)
/// 是否是大于等于指定iOS主版本
#define FWIsIosLater( version ) (FWIosVersion >= version ? YES : NO)

/*!
 @brief UIDevice+FWAdaptive
 */
@interface UIDevice (FWAdaptive)

/// 是否是模拟器
+ (BOOL)fwIsSimulator;

/// 是否是iPhone
+ (BOOL)fwIsIphone;
/// 是否是iPad
+ (BOOL)fwIsIpad;

/// iOS系统版本
+ (float)fwIosVersion;
/// 是否是指定iOS主版本
+ (BOOL)fwIsIos:(NSInteger)version;
/// 是否是大于等于指定iOS主版本
+ (BOOL)fwIsIosLater:(NSInteger)version;

@end

#pragma mark - UIScreen+FWAdaptive

/// 屏幕尺寸可扩展枚举
typedef NSInteger FWScreenInch NS_TYPED_EXTENSIBLE_ENUM;
static const FWScreenInch FWScreenInch35 = 35;
static const FWScreenInch FWScreenInch40 = 40;
static const FWScreenInch FWScreenInch47 = 47;
static const FWScreenInch FWScreenInch54 = 54;
static const FWScreenInch FWScreenInch55 = 55;
static const FWScreenInch FWScreenInch58 = 58;
static const FWScreenInch FWScreenInch61 = 61;
static const FWScreenInch FWScreenInch65 = 65;
static const FWScreenInch FWScreenInch67 = 67;

/// 屏幕尺寸
#define FWScreenSize [UIScreen mainScreen].bounds.size
/// 屏幕宽度
#define FWScreenWidth [UIScreen mainScreen].bounds.size.width
/// 屏幕高度
#define FWScreenHeight [UIScreen mainScreen].bounds.size.height
/// 屏幕像素比例
#define FWScreenScale [UIScreen mainScreen].scale
/// 屏幕分辨率
#define FWScreenResolution CGSizeMake( [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale, [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale )

/// 判断屏幕尺寸
#define FWIsScreenSize( width, height ) CGSizeEqualToSize(CGSizeMake(width, height), [UIScreen mainScreen].bounds.size)
/// 判断屏幕分辨率
#define FWIsScreenResolution( width, height ) CGSizeEqualToSize(CGSizeMake(width, height), FWScreenResolution)
/// 判断屏幕英寸
#define FWIsScreenInch( inch ) [UIScreen fwIsScreenInch:inch]
/// 是否是iPhoneX系列全面屏幕
#define FWIsScreenX [UIScreen fwIsScreenX]

/// 状态栏高度
#define FWStatusBarHeight [UIScreen fwStatusBarHeight]
/// 导航栏高度
#define FWNavigationBarHeight [UIScreen fwNavigationBarHeight]
/// 标签栏高度
#define FWTabBarHeight [UIScreen fwTabBarHeight]
/// 工具栏高度
#define FWToolBarHeight [UIScreen fwToolBarHeight]
/// 顶部栏高度，包含状态栏、导航栏
#define FWTopBarHeight [UIScreen fwTopBarHeight]
/// 底部栏高度，包含标签栏
#define FWBottomBarHeight [UIScreen fwBottomBarHeight]

/// 当前屏幕宽度缩放比例
#define FWScaleFactorWidth [UIScreen fwScaleFactorWidth]
/// 当前屏幕高度缩放比例
#define FWScaleFactorHeight [UIScreen fwScaleFactorHeight]

/*!
 @brief UIScreen+FWAdaptive
 */
@interface UIScreen (FWAdaptive)

/// 屏幕尺寸
+ (CGSize)fwScreenSize;
/// 屏幕宽度
+ (CGFloat)fwScreenWidth;
/// 屏幕高度
+ (CGFloat)fwScreenHeight;
/// 屏幕像素比例
+ (CGFloat)fwScreenScale;
/// 屏幕分辨率
+ (CGSize)fwScreenResolution;
/// 获取一像素的大小
+ (CGFloat)fwPixelOne;

/// 是否是指定尺寸屏幕
+ (BOOL)fwIsScreenSize:(CGSize)size;
/// 是否是指定分辨率屏幕
+ (BOOL)fwIsScreenResolution:(CGSize)resolution;
/// 是否是指定英寸屏幕
+ (BOOL)fwIsScreenInch:(FWScreenInch)inch;
/// 是否是iPhoneX系列全面屏幕
+ (BOOL)fwIsScreenX;

/// 检查是否含有安全区域，可用来判断iPhoneX
+ (BOOL)fwHasSafeAreaInsets;
/// 获取安全区域距离
+ (UIEdgeInsets)fwSafeAreaInsets;

/// 状态栏高度，与是否隐藏无关
+ (CGFloat)fwStatusBarHeight;
/// 导航栏高度，与是否隐藏无关
+ (CGFloat)fwNavigationBarHeight;
/// 标签栏高度，与是否隐藏无关
+ (CGFloat)fwTabBarHeight;
/// 工具栏高度，与是否隐藏无关
+ (CGFloat)fwToolBarHeight;
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
+ (CGFloat)fwTopBarHeight;
/// 底部栏高度，包含标签栏，与是否隐藏无关
+ (CGFloat)fwBottomBarHeight;

/// 指定缩放比例原始设计图尺寸，默认{375,812}
+ (void)fwSetScaleFactorSize:(CGSize)size;
/// 获取当前屏幕宽度缩放比例
+ (CGFloat)fwScaleFactorWidth;
/// 获取当前屏幕高度缩放比例
+ (CGFloat)fwScaleFactorHeight;

@end

/*!
 @brief UIViewController+FWAdaptive
 */
@interface UIViewController (FWAdaptive)

/// 当前状态栏高度，隐藏为0
- (CGFloat)fwStatusBarHeight;
/// 当前导航栏高度，隐藏为0
- (CGFloat)fwNavigationBarHeight;
/// 当前标签栏高度，隐藏为0
- (CGFloat)fwTabBarHeight;
/// 当前工具栏高度，隐藏为0
- (CGFloat)fwToolBarHeight;
/// 顶部栏高度，包含状态栏、导航栏，隐藏为0
- (CGFloat)fwTopBarHeight;
/// 底部栏高度，包含标签栏，隐藏为0
- (CGFloat)fwBottomBarHeight;

@end

NS_ASSUME_NONNULL_END
