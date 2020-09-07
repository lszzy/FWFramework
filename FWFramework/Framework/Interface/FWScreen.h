/*!
 @header     FWScreen.h
 @indexgroup FWFramework
 @brief      FWScreen
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
