/**
 @header     FWToolkit.h
 @indexgroup FWFramework
      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MessageUI/MessageUI.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWApplicationClassWrapper+FWToolkit

/**
 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app
 */
@interface FWApplicationClassWrapper (FWToolkit)

/// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
- (BOOL)canOpenURL:(id)url;

/// 打开URL，支持NSString|NSURL，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
- (void)openURL:(id)url;

/// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
- (void)openURL:(id)url completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
- (void)openUniversalLinks:(id)url completionHandler:(nullable void (^)(BOOL success))completion;

/// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
- (BOOL)isSystemURL:(id)url;

/// 判断URL是否HTTP链接，支持NSString|NSURL
- (BOOL)isHttpURL:(id)url;

/// 判断URL是否是AppStore链接，支持NSString|NSURL
- (BOOL)isAppStoreURL:(id)url;

/// 打开AppStore下载页
- (void)openAppStore:(NSString *)appId;

/// 打开AppStore评价页
- (void)openAppStoreReview:(NSString *)appId;

/// 打开应用内评价，有次数限制
- (void)openAppReview;

/// 打开系统应用设置页
- (void)openAppSettings;

/// 打开系统邮件App
- (void)openMailApp:(NSString *)email;

/// 打开系统短信App
- (void)openMessageApp:(NSString *)phone;

/// 打开系统电话App
- (void)openPhoneApp:(NSString *)phone;

/// 打开系统分享
- (void)openActivityItems:(NSArray *)activityItems excludedTypes:(nullable NSArray<UIActivityType> *)excludedTypes;

/// 打开内部浏览器，支持NSString|NSURL
- (void)openSafariController:(id)url;

/// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
- (void)openSafariController:(id)url completionHandler:(nullable void (^)(void))completion;

/// 打开短信控制器，完成时回调
- (void)openMessageController:(MFMessageComposeViewController *)controller completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开邮件控制器，完成时回调
- (void)openMailController:(MFMailComposeViewController *)controller completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开Store控制器，完成时回调
- (void)openStoreController:(NSDictionary<NSString *, id> *)parameters completionHandler:(nullable void (^)(BOOL success))completion;

/// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
- (nullable AVPlayerViewController *)openVideoPlayer:(id)url;

/// 打开音频播放器，支持NSURL|NSString
- (nullable AVAudioPlayer *)openAudioPlayer:(id)url;

@end

#pragma mark - FWColorWrapper+FWToolkit

/// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

/// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

@interface FWColorWrapper (FWToolkit)

/// 获取当前颜色指定透明度的新颜色
- (UIColor *)colorWithAlpha:(CGFloat)alpha;

/// 读取颜色的十六进制值RGB，不含透明度
@property (nonatomic, assign, readonly) long hexValue;

/// 读取颜色的透明度值，范围0~1
@property (nonatomic, assign, readonly) CGFloat alphaValue;

/// 读取颜色的十六进制字符串RGB，不含透明度
@property (nonatomic, copy, readonly) NSString *hexString;

/// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
@property (nonatomic, copy, readonly) NSString *hexStringWithAlpha;

@end

@interface FWColorClassWrapper (FWToolkit)

/// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
@property (nonatomic, assign) BOOL colorStandardARGB;

/// 获取透明度为1.0的RGB随机颜色
@property (nonatomic, readonly) UIColor *randomColor;

/// 从十六进制值初始化，格式：0x20B2AA，透明度为1.0
- (UIColor *)colorWithHex:(long)hex;

/// 从十六进制值初始化，格式：0x20B2AA，自定义透明度
- (UIColor *)colorWithHex:(long)hex alpha:(CGFloat)alpha;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度为1.0，失败时返回clear
- (UIColor *)colorWithHexString:(NSString *)hexString;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，自定义透明度，失败时返回clear
- (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/// 从颜色字符串初始化，支持十六进制和颜色值，透明度为1.0，失败时返回clear
- (UIColor *)colorWithString:(NSString *)string;

/// 从颜色字符串初始化，支持十六进制和颜色值，自定义透明度，失败时返回clear
- (UIColor *)colorWithString:(NSString *)string alpha:(CGFloat)alpha;

@end

#pragma mark - FWFontWrapper+FWToolkit

/// 快速创建系统字体，字重可选，默认Regular
#define FWFontSize( size, ... ) \
    [UIFont.fw fontOfSize:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建Thin字体
FOUNDATION_EXPORT UIFont * FWFontThin(CGFloat size);
/// 快速创建Light字体
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat size);
/// 快速创建Regular字体
FOUNDATION_EXPORT UIFont * FWFontRegular(CGFloat size);
/// 快速创建Medium字体
FOUNDATION_EXPORT UIFont * FWFontMedium(CGFloat size);
/// 快速创建Semibold字体
FOUNDATION_EXPORT UIFont * FWFontSemibold(CGFloat size);
/// 快速创建Bold字体
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat size);

@interface FWFontClassWrapper (FWToolkit)

/// 全局自定义字体句柄，优先调用
@property (nonatomic, copy, nullable) UIFont * (^fontBlock)(CGFloat size, UIFontWeight weight);

/// 返回系统Thin字体
- (UIFont *)thinFontOfSize:(CGFloat)size;
/// 返回系统Light字体
- (UIFont *)lightFontOfSize:(CGFloat)size;
/// 返回系统Regular字体
- (UIFont *)fontOfSize:(CGFloat)size;
/// 返回系统Medium字体
- (UIFont *)mediumFontOfSize:(CGFloat)size;
/// 返回系统Semibold字体
- (UIFont *)semiboldFontOfSize:(CGFloat)size;
/// 返回系统Bold字体
- (UIFont *)boldFontOfSize:(CGFloat)size;

/// 创建指定尺寸和weight的系统字体
- (UIFont *)fontOfSize:(CGFloat)size weight:(UIFontWeight)weight;

@end

#pragma mark - FWImageWrapper+FWToolkit

@interface FWImageWrapper (FWToolkit)

/// 从当前图片创建指定透明度的图片
- (nullable UIImage *)imageWithAlpha:(CGFloat)alpha;

/// 从当前图片混合颜色创建UIImage，默认kCGBlendModeDestinationIn模式，适合透明图标
- (nullable UIImage *)imageWithTintColor:(UIColor *)tintColor;

/// 从当前UIImage混合颜色创建UIImage，自定义模式
- (nullable UIImage *)imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

/// 缩放图片到指定大小
- (nullable UIImage *)imageWithScaleSize:(CGSize)size;

/// 缩放图片到指定大小，指定模式
- (nullable UIImage *)imageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/// 按指定模式绘制图片
- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds;

/// 裁剪指定区域图片
- (nullable UIImage *)imageWithCropRect:(CGRect)rect;

/// 指定颜色填充图片边缘
- (nullable UIImage *)imageWithInsets:(UIEdgeInsets)insets color:(nullable UIColor *)color;

/// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
- (UIImage *)imageWithCapInsets:(UIEdgeInsets)insets;

/// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
- (UIImage *)imageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode;

/// 生成圆角图片
- (nullable UIImage *)imageWithCornerRadius:(CGFloat)radius;

/// 按角度常数(0~360)转动图片，默认图片尺寸适应内容
- (nullable UIImage *)imageWithRotateDegree:(CGFloat)degree;

/// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪
- (nullable UIImage *)imageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize;

/// 生成mark图片
- (nullable UIImage *)imageWithMaskImage:(UIImage *)maskImage;

/// 图片合并，并制定叠加图片的起始位置
- (nullable UIImage *)imageWithMergeImage:(UIImage *)image atPoint:(CGPoint)point;

/// 图片应用CIFilter滤镜处理
- (nullable UIImage *)imageWithFilter:(CIFilter *)filter;

/// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
- (nullable UIImage *)compressImageWithMaxLength:(NSInteger)maxLength;

/// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.1。不保证图片大小一定小于该大小
- (nullable NSData *)compressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio;

/// 长边压缩图片尺寸，获取等比例的图片
- (nullable UIImage *)compressImageWithMaxWidth:(NSInteger)maxWidth;

/// 通过指定图片最长边，获取等比例的图片size
- (CGSize)scaleSizeWithMaxWidth:(CGFloat)maxWidth;

/// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
@property (nonatomic, readonly) UIImage *originalImage;

/// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
@property (nonatomic, readonly) UIImage *templateImage;

/// 判断图片是否有透明通道
@property (nonatomic, assign, readonly) BOOL hasAlpha;

/// 获取当前图片的像素大小，多倍图会放大到一倍
@property (nonatomic, assign, readonly) CGSize pixelSize;

@end

@interface FWImageClassWrapper (FWToolkit)

/// 从视图创建UIImage，生成截图，主线程调用
- (nullable UIImage *)imageWithView:(UIView *)view;

/// 从颜色创建UIImage，默认尺寸1x1
- (nullable UIImage *)imageWithColor:(UIColor *)color;

/// 从颜色创建UIImage，指定尺寸
- (nullable UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

/// 从颜色创建UIImage，指定尺寸和圆角
- (nullable UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius;

/// 从block创建UIImage，指定尺寸
- (nullable UIImage *)imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef context))block;

@end

#pragma mark - FWViewWrapper+FWToolkit

@interface FWViewWrapper (FWToolkit)

/// 顶部纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat top;

/// 底部纵坐标，frame.origin.y + frame.size.height
@property (nonatomic, assign) CGFloat bottom;

/// 左边横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat left;

/// 右边横坐标，frame.origin.x + frame.size.width
@property (nonatomic, assign) CGFloat right;

/// 宽度，frame.size.width
@property (nonatomic, assign) CGFloat width;

/// 高度，frame.size.height
@property (nonatomic, assign) CGFloat height;

/// 中心横坐标，center.x
@property (nonatomic, assign) CGFloat centerX;

/// 中心纵坐标，center.y
@property (nonatomic, assign) CGFloat centerY;

/// 起始横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat x;

/// 起始纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat y;

/// 起始坐标，frame.origin
@property (nonatomic, assign) CGPoint origin;

/// 大小，frame.size
@property (nonatomic, assign) CGSize size;

@end

#pragma mark - FWViewControllerWrapper+FWToolkit

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

@interface FWViewControllerWrapper (FWToolkit)

/// 当前生命周期状态，默认Ready
@property (nonatomic, assign, readonly) FWViewControllerVisibleState visibleState;

/// 生命周期变化时通知句柄，默认nil
@property (nonatomic, copy, nullable) void (^visibleStateChanged)(__kindof UIViewController *viewController, FWViewControllerVisibleState visibleState);

/// 自定义完成结果对象，默认nil
@property (nonatomic, strong, nullable) id completionResult;

/// 自定义完成句柄，默认nil，dealloc时自动调用，参数为fwCompletionResult。支持提前调用，调用后需置为nil
@property (nonatomic, copy, nullable) void (^completionHandler)(id _Nullable result);

/// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
@property (nonatomic, copy, nullable) BOOL (^allowsPopGesture)(void);

/// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
@property (nonatomic, copy, nullable) BOOL (^shouldPopController)(void);

@end

@interface UIViewController (FWToolkit)

/// 自定义侧滑返回手势VC开关，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，自动调用fw.allowsPopGesture，默认YES
@property (nonatomic, assign, readonly) BOOL allowsPopGesture;

/// 自定义控制器返回VC开关，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，自动调用fw.shouldPopController，默认YES
@property (nonatomic, assign, readonly) BOOL shouldPopController;

@end

#pragma mark - FWNavigationControllerWrapper+FWToolkit

@interface FWNavigationControllerWrapper (FWToolkit)

/// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
- (void)enablePopProxy;

@end

/**
 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
 */
@interface FWNavigationControllerClassWrapper (FWToolkit)

/// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
- (void)enablePopProxy;

@end

NS_ASSUME_NONNULL_END
