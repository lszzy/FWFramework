/**
 @header     FWAdaptive.h
 @indexgroup FWFramework
      FWAdaptive
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWApplicationClassWrapper+FWAdaptive

/// 是否是调试模式
#ifdef DEBUG
    #define FWIsDebug YES
#else
    #define FWIsDebug NO
#endif

@interface FWApplicationClassWrapper (FWAdaptive)

/// 是否是调试模式
@property (nonatomic, assign, readonly) BOOL isDebug;

@end

#pragma mark - FWDeviceClassWrapper+FWAdaptive

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
#define FWIsMac [UIDevice.fw isMac]

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

@interface FWDeviceClassWrapper (FWAdaptive)

/// 是否是模拟器
@property (nonatomic, assign, readonly) BOOL isSimulator;

/// 是否是iPhone
@property (nonatomic, assign, readonly) BOOL isIphone;
/// 是否是iPad
@property (nonatomic, assign, readonly) BOOL isIpad;
/// 是否是Mac
@property (nonatomic, assign, readonly) BOOL isMac;

/// 界面是否横屏
@property (nonatomic, assign, readonly) BOOL isLandscape;
/// 设备是否横屏，无论支不支持横屏
@property (nonatomic, assign, readonly) BOOL isDeviceLandscape;
/// 设置界面方向，支持旋转方向时生效
- (BOOL)setDeviceOrientation:(UIDeviceOrientation)orientation;

/// iOS系统版本
@property (nonatomic, assign, readonly) double iosVersion;
/// 是否是指定iOS主版本
- (BOOL)isIos:(NSInteger)version;
/// 是否是大于等于指定iOS主版本
- (BOOL)isIosLater:(NSInteger)version;

/// 设备尺寸，跟横竖屏无关
@property (nonatomic, assign, readonly) CGSize deviceSize;
/// 设备宽度，跟横竖屏无关
@property (nonatomic, assign, readonly) CGFloat deviceWidth;
/// 设备高度，跟横竖屏无关
@property (nonatomic, assign, readonly) CGFloat deviceHeight;
/// 设备分辨率，跟横竖屏无关
@property (nonatomic, assign, readonly) CGSize deviceResolution;

@end

#pragma mark - FWScreenClassWrapper+FWAdaptive

/// 屏幕尺寸可扩展枚举
typedef NSInteger FWScreenInch NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ScreenInch);
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
#define FWIsScreenInch( inch ) [UIScreen.fw isScreenInch:inch]
/// 是否是全面屏屏幕
#define FWIsNotchedScreen [UIScreen.fw isNotchedScreen]
/// 屏幕一像素的大小
#define FWPixelOne [UIScreen.fw pixelOne]
/// 屏幕安全区域距离
#define FWSafeAreaInsets [UIScreen.fw safeAreaInsets]

/// 状态栏高度，与是否隐藏无关
#define FWStatusBarHeight [UIScreen.fw statusBarHeight]
/// 导航栏高度，与是否隐藏无关
#define FWNavigationBarHeight [UIScreen.fw navigationBarHeight]
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
#define FWTopBarHeight [UIScreen.fw topBarHeight]
/// 标签栏高度，与是否隐藏无关
#define FWTabBarHeight [UIScreen.fw tabBarHeight]
/// 工具栏高度，与是否隐藏无关
#define FWToolBarHeight [UIScreen.fw toolBarHeight]

/// 当前屏幕宽度缩放比例
#define FWRelativeScale [UIScreen.fw relativeScale]
/// 当前屏幕高度缩放比例
#define FWRelativeHeightScale [UIScreen.fw relativeHeightScale]

/// 获取相对设计图宽度等比例缩放值
FOUNDATION_EXPORT CGFloat FWRelativeValue(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图高度等比例缩放值
FOUNDATION_EXPORT CGFloat FWRelativeHeight(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图等比例缩放size
FOUNDATION_EXPORT CGSize FWRelativeSize(CGSize size) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图等比例缩放point
FOUNDATION_EXPORT CGPoint FWRelativePoint(CGPoint point) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图等比例缩放rect
FOUNDATION_EXPORT CGRect FWRelativeRect(CGRect rect) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图等比例缩放insets
FOUNDATION_EXPORT UIEdgeInsets FWRelativeInsets(UIEdgeInsets insets) NS_SWIFT_UNAVAILABLE("");

/// 基于当前设备的屏幕倍数，对传进来的floatValue进行像素取整
FOUNDATION_EXPORT CGFloat FWFlatValue(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
FOUNDATION_EXPORT CGFloat FWFlatScale(CGFloat value, CGFloat scale) NS_SWIFT_UNAVAILABLE("");

@interface FWScreenClassWrapper (FWAdaptive)

/// 屏幕尺寸
@property (nonatomic, assign, readonly) CGSize screenSize;
/// 屏幕宽度
@property (nonatomic, assign, readonly) CGFloat screenWidth;
/// 屏幕高度
@property (nonatomic, assign, readonly) CGFloat screenHeight;
/// 屏幕像素比例
@property (nonatomic, assign, readonly) CGFloat screenScale;
/// 是否是指定英寸屏幕
- (BOOL)isScreenInch:(FWScreenInch)inch;
/// 是否是全面屏屏幕
@property (nonatomic, assign, readonly) BOOL isNotchedScreen;

/// 获取一像素的大小
@property (nonatomic, assign, readonly) CGFloat pixelOne;
/// 检查是否含有安全区域，可用来判断iPhoneX
@property (nonatomic, assign, readonly) BOOL hasSafeAreaInsets;
/// 获取安全区域距离
@property (nonatomic, assign, readonly) UIEdgeInsets safeAreaInsets;

/// 状态栏高度，与是否隐藏无关
@property (nonatomic, assign, readonly) CGFloat statusBarHeight;
/// 导航栏高度，与是否隐藏无关
@property (nonatomic, assign, readonly) CGFloat navigationBarHeight;
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
@property (nonatomic, assign, readonly) CGFloat topBarHeight;
/// 标签栏高度，与是否隐藏无关
@property (nonatomic, assign, readonly) CGFloat tabBarHeight;
/// 工具栏高度，与是否隐藏无关
@property (nonatomic, assign, readonly) CGFloat toolBarHeight;

/// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
@property (nonatomic, assign) CGSize referenceSize;
/// 获取当前屏幕宽度缩放比例，宽度常用
@property (nonatomic, assign, readonly) CGFloat relativeScale;
/// 获取当前屏幕高度缩放比例，高度不常用
@property (nonatomic, assign, readonly) CGFloat relativeHeightScale;

/// 获取相对设计图宽度等比例缩放值
- (CGFloat)relativeValue:(CGFloat)value;

/// 获取相对设计图高度等比例缩放值
- (CGFloat)relativeHeight:(CGFloat)value;

/// 基于当前设备的屏幕倍数，对传进来的floatValue进行像素取整
- (CGFloat)flatValue:(CGFloat)value;

/// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
- (CGFloat)flatValue:(CGFloat)value scale:(CGFloat)scale;

@end

#pragma mark - FWViewControllerWrapper+FWAdaptive

@interface FWViewControllerWrapper (FWAdaptive)

/// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat statusBarHeight;

/// 当前导航栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat navigationBarHeight;

/// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat topBarHeight;

/// 当前标签栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat tabBarHeight;

/// 当前工具栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat toolBarHeight;

/// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat bottomBarHeight;

@end

NS_ASSUME_NONNULL_END
