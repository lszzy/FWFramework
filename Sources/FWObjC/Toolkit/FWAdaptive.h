//
//  FWAdaptive.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIApplication+FWAdaptive

/// 是否是调试模式
#ifdef DEBUG
    #define FWIsDebug YES
#else
    #define FWIsDebug NO
#endif

@interface UIApplication (FWAdaptive)

/// 是否是调试模式
@property (class, nonatomic, assign, readonly) BOOL fw_isDebug NS_REFINED_FOR_SWIFT;

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
#define FWIsMac [UIDevice fw_isMac]

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

@interface UIDevice (FWAdaptive)

/// 是否是模拟器
@property (class, nonatomic, assign, readonly) BOOL fw_isSimulator NS_REFINED_FOR_SWIFT;

/// 是否是iPhone
@property (class, nonatomic, assign, readonly) BOOL fw_isIphone NS_REFINED_FOR_SWIFT;
/// 是否是iPad
@property (class, nonatomic, assign, readonly) BOOL fw_isIpad NS_REFINED_FOR_SWIFT;
/// 是否是Mac
@property (class, nonatomic, assign, readonly) BOOL fw_isMac NS_REFINED_FOR_SWIFT;

/// 界面是否横屏
@property (class, nonatomic, assign, readonly) BOOL fw_isLandscape NS_REFINED_FOR_SWIFT;
/// 设备是否横屏，无论支不支持横屏
@property (class, nonatomic, assign, readonly) BOOL fw_isDeviceLandscape NS_REFINED_FOR_SWIFT;
/// 设置界面方向，支持旋转方向时生效
+ (BOOL)fw_setDeviceOrientation:(UIDeviceOrientation)orientation NS_REFINED_FOR_SWIFT;

/// iOS系统版本
@property (class, nonatomic, assign, readonly) double fw_iosVersion NS_REFINED_FOR_SWIFT;
/// 是否是指定iOS主版本
+ (BOOL)fw_isIos:(NSInteger)version NS_REFINED_FOR_SWIFT;
/// 是否是大于等于指定iOS主版本
+ (BOOL)fw_isIosLater:(NSInteger)version NS_REFINED_FOR_SWIFT;

/// 设备尺寸，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGSize fw_deviceSize NS_REFINED_FOR_SWIFT;
/// 设备宽度，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_deviceWidth NS_REFINED_FOR_SWIFT;
/// 设备高度，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_deviceHeight NS_REFINED_FOR_SWIFT;
/// 设备分辨率，跟横竖屏无关
@property (class, nonatomic, assign, readonly) CGSize fw_deviceResolution NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIScreen+FWAdaptive

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
#define FWIsScreenInch( inch ) [UIScreen fw_isScreenInch:inch]
/// 是否是全面屏屏幕
#define FWIsNotchedScreen [UIScreen fw_isNotchedScreen]
/// 屏幕一像素的大小
#define FWPixelOne [UIScreen fw_pixelOne]
/// 屏幕安全区域距离
#define FWSafeAreaInsets [UIScreen fw_safeAreaInsets]

/// 状态栏高度，与是否隐藏无关
#define FWStatusBarHeight [UIScreen fw_statusBarHeight]
/// 导航栏高度，与是否隐藏无关
#define FWNavigationBarHeight [UIScreen fw_navigationBarHeight]
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
#define FWTopBarHeight [UIScreen fw_topBarHeight]
/// 标签栏高度，与是否隐藏无关
#define FWTabBarHeight [UIScreen fw_tabBarHeight]
/// 工具栏高度，与是否隐藏无关
#define FWToolBarHeight [UIScreen fw_toolBarHeight]

/// 当前等比例缩放参考设计图宽度，默认375
#define FWReferenceWidth [UIScreen fw_referenceSize].width
/// 当前等比例缩放参考设计图高度，默认812
#define FWReferenceHeight [UIScreen fw_referenceSize].height
/// 当前屏幕宽度缩放比例
#define FWRelativeScale [UIScreen fw_relativeScale]
/// 当前屏幕高度缩放比例
#define FWRelativeHeightScale [UIScreen fw_relativeHeightScale]

/// 获取相对设计图宽度等比例缩放值
FOUNDATION_EXPORT CGFloat FWRelativeValue(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图高度等比例缩放值
FOUNDATION_EXPORT CGFloat FWRelativeHeight(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图宽度等比例缩放时的固定宽度值
FOUNDATION_EXPORT CGFloat FWFixedValue(CGFloat value) NS_SWIFT_UNAVAILABLE("");
/// 获取相对设计图高度等比例缩放时的固定高度值
FOUNDATION_EXPORT CGFloat FWFixedHeight(CGFloat value) NS_SWIFT_UNAVAILABLE("");
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

@interface UIScreen (FWAdaptive)

/// 屏幕尺寸
@property (class, nonatomic, assign, readonly) CGSize fw_screenSize NS_REFINED_FOR_SWIFT;
/// 屏幕宽度
@property (class, nonatomic, assign, readonly) CGFloat fw_screenWidth NS_REFINED_FOR_SWIFT;
/// 屏幕高度
@property (class, nonatomic, assign, readonly) CGFloat fw_screenHeight NS_REFINED_FOR_SWIFT;
/// 屏幕像素比例
@property (class, nonatomic, assign, readonly) CGFloat fw_screenScale NS_REFINED_FOR_SWIFT;
/// 是否是指定英寸屏幕
+ (BOOL)fw_isScreenInch:(FWScreenInch)inch NS_REFINED_FOR_SWIFT;
/// 是否是全面屏屏幕
@property (class, nonatomic, assign, readonly) BOOL fw_isNotchedScreen NS_REFINED_FOR_SWIFT;

/// 获取一像素的大小
@property (class, nonatomic, assign, readonly) CGFloat fw_pixelOne NS_REFINED_FOR_SWIFT;
/// 检查是否含有安全区域，可用来判断iPhoneX
@property (class, nonatomic, assign, readonly) BOOL fw_hasSafeAreaInsets NS_REFINED_FOR_SWIFT;
/// 获取安全区域距离
@property (class, nonatomic, assign, readonly) UIEdgeInsets fw_safeAreaInsets NS_REFINED_FOR_SWIFT;

/// 状态栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_statusBarHeight NS_REFINED_FOR_SWIFT;
/// 导航栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_navigationBarHeight NS_REFINED_FOR_SWIFT;
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_topBarHeight NS_REFINED_FOR_SWIFT;
/// 标签栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_tabBarHeight NS_REFINED_FOR_SWIFT;
/// 工具栏高度，与是否隐藏无关
@property (class, nonatomic, assign, readonly) CGFloat fw_toolBarHeight NS_REFINED_FOR_SWIFT;

/// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
@property (class, nonatomic, assign) CGSize fw_referenceSize NS_REFINED_FOR_SWIFT;
/// 配置是否全局自动对相对值像素取整(仅影响relative|fixed相关方法)，默认NO
@property (class, nonatomic, assign) BOOL fw_autoFlat NS_REFINED_FOR_SWIFT;
/// 获取当前屏幕宽度缩放比例，宽度常用
@property (class, nonatomic, assign, readonly) CGFloat fw_relativeScale NS_REFINED_FOR_SWIFT;
/// 获取当前屏幕高度缩放比例，高度不常用
@property (class, nonatomic, assign, readonly) CGFloat fw_relativeHeightScale NS_REFINED_FOR_SWIFT;

/// 获取相对设计图宽度等比例缩放值
+ (CGFloat)fw_relativeValue:(CGFloat)value NS_REFINED_FOR_SWIFT;

/// 获取相对设计图高度等比例缩放值
+ (CGFloat)fw_relativeHeight:(CGFloat)value NS_REFINED_FOR_SWIFT;

/// 获取相对设计图宽度等比例缩放时的固定宽度值
+ (CGFloat)fw_fixedValue:(CGFloat)value NS_REFINED_FOR_SWIFT;

/// 获取相对设计图高度等比例缩放时的固定高度值
+ (CGFloat)fw_fixedHeight:(CGFloat)value NS_REFINED_FOR_SWIFT;

/// 基于当前设备的屏幕倍数，对传进来的floatValue进行像素取整
+ (CGFloat)fw_flatValue:(CGFloat)value NS_REFINED_FOR_SWIFT;

/// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
+ (CGFloat)fw_flatValue:(CGFloat)value scale:(CGFloat)scale NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWAdaptive

@interface UIView (FWAdaptive)

/// 是否自动等比例缩放方式设置transform，默认NO
@property (nonatomic, assign) BOOL fw_autoScaleTransform NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWAdaptive

@interface UIViewController (FWAdaptive)

/// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_statusBarHeight NS_REFINED_FOR_SWIFT;

/// 当前导航栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_navigationBarHeight NS_REFINED_FOR_SWIFT;

/// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_topBarHeight NS_REFINED_FOR_SWIFT;

/// 当前标签栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_tabBarHeight NS_REFINED_FOR_SWIFT;

/// 当前工具栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_toolBarHeight NS_REFINED_FOR_SWIFT;

/// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fw_bottomBarHeight NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
