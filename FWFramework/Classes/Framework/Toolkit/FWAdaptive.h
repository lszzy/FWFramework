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
@property (class, nonatomic, assign, readonly) BOOL fwIsDebug;

@end

#pragma mark - UIDevice+FWAdaptive

/// 是否是模拟器
#if TARGET_OS_SIMULATOR
    #define FWIsSimulator YES
#else
    #define FWIsSimulator NO
#endif

/// 是否是iPhone设备
#define FWIsIphone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
/// 是否是iPad设备
#define FWIsIpad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
/// 是否是Mac设备
#define FWIsMac [UIDevice fwIsMac]

/// 界面是否横屏
#define FWIsLandscape UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)
/// 设备是否横屏，无论支不支持横屏
#define FWIsDeviceLandscape UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])

/// iOS系统版本，只获取第二级的版本号，如10.3.1返回10.3
#define FWIosVersion [[[UIDevice currentDevice] systemVersion] doubleValue]
/// 是否是指定iOS主版本
#define FWIsIos( version ) (FWIosVersion >= version && FWIosVersion < (version + 1))
/// 是否是大于等于指定iOS主版本
#define FWIsIosLater( version ) (FWIosVersion >= version)

/// 设备尺寸，跟横竖屏无关
#define FWDeviceSize CGSizeMake(FWDeviceWidth, FWDeviceHeight)
/// 设备宽度，跟横竖屏无关
#define FWDeviceWidth MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
/// 设备高度，跟横竖屏无关
#define FWDeviceHeight MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
/// 设备分辨率，跟横竖屏无关
#define FWDeviceResolution CGSizeMake(FWDeviceWidth * [UIScreen mainScreen].scale, FWDeviceHeight * [UIScreen mainScreen].scale)

/*!
 @brief UIDevice+FWAdaptive
 */
@interface UIDevice (FWAdaptive)

/// 是否是模拟器
@property (class, nonatomic, assign, readonly) BOOL fwIsSimulator;

/// 是否是iPhone
@property (class, nonatomic, assign, readonly) BOOL fwIsIphone;
/// 是否是iPad
@property (class, nonatomic, assign, readonly) BOOL fwIsIpad;
/// 是否是Mac
@property (class, nonatomic, assign, readonly) BOOL fwIsMac;

/// 界面是否横屏
@property (class, nonatomic, assign, readonly) BOOL fwIsLandscape;
/// 设备是否横屏，无论支不支持横屏
@property (class, nonatomic, assign, readonly) BOOL fwIsDeviceLandscape;
/// 设置界面方向，支持旋转方向时生效
+ (BOOL)fwSetDeviceOrientation:(UIDeviceOrientation)orientation;

/// iOS系统版本
@property (class, nonatomic, assign, readonly) double fwIosVersion;
/// 是否是指定iOS主版本
+ (BOOL)fwIsIos:(NSInteger)version;
/// 是否是大于等于指定iOS主版本
+ (BOOL)fwIsIosLater:(NSInteger)version;

/// 设备尺寸，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGSize fwDeviceSize;
/// 设备宽度，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGFloat fwDeviceWidth;
/// 设备高度，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGFloat fwDeviceHeight;
/// 设备分辨率，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGSize fwDeviceResolution;

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

/// 屏幕尺寸，随横竖屏变化
#define FWScreenSize [UIScreen mainScreen].bounds.size
/// 屏幕宽度，随横竖屏变化
#define FWScreenWidth [UIScreen mainScreen].bounds.size.width
/// 屏幕高度，随横竖屏变化
#define FWScreenHeight [UIScreen mainScreen].bounds.size.height
/// 屏幕像素比例
#define FWScreenScale [UIScreen mainScreen].scale
/// 判断屏幕英寸
#define FWIsScreenInch( inch ) [UIScreen fwIsScreenInch:inch]
/// 是否是全面屏屏幕
#define FWIsNotchedScreen [UIScreen fwIsNotchedScreen]

/// 状态栏高度，与是否隐藏无关
#define FWStatusBarHeight [UIScreen fwStatusBarHeight]
/// 导航栏高度，与是否隐藏无关
#define FWNavigationBarHeight [UIScreen fwNavigationBarHeight]
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
#define FWTopBarHeight [UIScreen fwTopBarHeight]
/// 标签栏高度，与是否隐藏无关
#define FWTabBarHeight [UIScreen fwTabBarHeight]
/// 工具栏高度，与是否隐藏无关
#define FWToolBarHeight [UIScreen fwToolBarHeight]

/// 当前屏幕宽度缩放比例
#define FWScaleFactorWidth [UIScreen fwScaleFactorWidth]
/// 当前屏幕高度缩放比例
#define FWScaleFactorHeight [UIScreen fwScaleFactorHeight]

/// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
CG_INLINE CGFloat FWFlatScale(CGFloat floatValue, CGFloat scale) {
    floatValue = (floatValue == CGFLOAT_MIN) ? 0 : floatValue;
    scale = scale ?: [UIScreen mainScreen].scale;
    CGFloat flattedValue = ceil(floatValue * scale) / scale;
    return flattedValue;
}

/// 基于当前设备的屏幕倍数，对传进来的floatValue进行像素取整
CG_INLINE CGFloat FWFlatValue(CGFloat floatValue) {
    return FWFlatScale(floatValue, 0);
}

/*!
 @brief UIScreen+FWAdaptive
 */
@interface UIScreen (FWAdaptive)

/// 屏幕尺寸
@property (class, nonatomic, assign, readonly) CGSize fwScreenSize;
/// 屏幕宽度
@property (class, nonatomic, assign, readonly) CGFloat fwScreenWidth;
/// 屏幕高度
@property (class, nonatomic, assign, readonly) CGFloat fwScreenHeight;
/// 屏幕像素比例
@property (class, nonatomic, assign, readonly) CGFloat fwScreenScale;
/// 是否是指定英寸屏幕
+ (BOOL)fwIsScreenInch:(FWScreenInch)inch;
/// 是否是全面屏屏幕
@property (class, nonatomic, assign, readonly) BOOL fwIsNotchedScreen;

/// 获取一像素的大小
@property (class, nonatomic, assign, readonly) CGFloat fwPixelOne;
/// 检查是否含有安全区域，可用来判断iPhoneX
@property (class, nonatomic, assign, readonly) BOOL fwHasSafeAreaInsets;
/// 获取安全区域距离
@property (class, nonatomic, assign, readonly) UIEdgeInsets fwSafeAreaInsets;

/// 状态栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fwStatusBarHeight;
/// 导航栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fwNavigationBarHeight;
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fwTopBarHeight;
/// 标签栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fwTabBarHeight;
/// 工具栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fwToolBarHeight;

/// 指定缩放比例原始设计图尺寸，默认{375,812}
+ (void)fwSetScaleFactorSize:(CGSize)size;
/// 获取当前屏幕宽度缩放比例
@property (class, nonatomic, assign, readonly) CGFloat fwScaleFactorWidth;
/// 获取当前屏幕高度缩放比例
@property (class, nonatomic, assign, readonly) CGFloat fwScaleFactorHeight;

@end

/*!
 @brief UIViewController+FWAdaptive
 */
@interface UIViewController (FWAdaptive)

/// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwStatusBarHeight;
/// 当前导航栏布局和可见高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwNavigationBarHeight;
/// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwTopBarHeight;
/// 当前标签栏布局和可见高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwTabBarHeight;
/// 当前工具栏布局和可见高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwToolBarHeight;

/// 当前状态栏安全高度，状态栏隐藏时为0
@property (nonatomic, assign, readonly) CGFloat fwSafeStatusBarHeight;
/// 当前顶部栏安全高度，状态栏和导航栏全部隐藏时为0
@property (nonatomic, assign, readonly) CGFloat fwSafeTopBarHeight;

@end

NS_ASSUME_NONNULL_END
