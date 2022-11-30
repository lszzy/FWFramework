//
//  FWToolkit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

/// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/// 快速创建系统字体，字重可选，默认Regular
#define FWFontSize( size, ... ) \
    [UIFont fw_fontOfSize:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建Thin字体
FOUNDATION_EXPORT UIFont * FWFontThin(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Light字体
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Regular字体
FOUNDATION_EXPORT UIFont * FWFontRegular(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Medium字体
FOUNDATION_EXPORT UIFont * FWFontMedium(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Semibold字体
FOUNDATION_EXPORT UIFont * FWFontSemibold(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Bold字体
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat size) NS_SWIFT_UNAVAILABLE("");

#pragma mark - UIImage+FWToolkit

@interface UIImage (FWToolkit)

/// 保存图片到相册，保存成功时error为nil
- (void)fw_saveImageWithCompletion:(nullable void (^)(NSError * _Nullable error))completion NS_SWIFT_NAME(__fw_saveImage(completion:)) NS_REFINED_FOR_SWIFT;

/// 保存视频到相册，保存成功时error为nil。如果视频地址为NSURL，需使用NSURL.path
+ (void)fw_saveVideo:(NSString *)videoPath withCompletion:(nullable void (^)(NSError * _Nullable error))completion NS_REFINED_FOR_SWIFT;

/// 获取灰度图
@property (nonatomic, readonly, nullable) UIImage *fw_grayImage NS_REFINED_FOR_SWIFT;

/// 获取图片的平均颜色
@property (nonatomic, readonly) UIColor *fw_averageColor NS_REFINED_FOR_SWIFT;

/// 倒影图片
- (nullable UIImage *)fw_imageWithReflectScale:(CGFloat)scale NS_REFINED_FOR_SWIFT;

/// 倒影图片
- (nullable UIImage *)fw_imageWithReflectScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha NS_REFINED_FOR_SWIFT;

/// 阴影图片
- (nullable UIImage *)fw_imageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur NS_REFINED_FOR_SWIFT;

/// 获取装饰图片
@property (nonatomic, readonly) UIImage *fw_maskImage NS_REFINED_FOR_SWIFT;

/// 高斯模糊图片，默认模糊半径为10，饱和度为1。注意CGContextDrawImage如果图片尺寸太大会导致内存不足闪退，建议先压缩再调用
- (nullable UIImage *)fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage NS_REFINED_FOR_SWIFT;

/// 如果没有透明通道，增加透明通道
@property (nonatomic, readonly) UIImage *fw_alphaImage NS_REFINED_FOR_SWIFT;

/// 截取View所有视图，包括旋转缩放效果
+ (nullable UIImage *)fw_imageWithView:(UIView *)view limitWidth:(CGFloat)limitWidth NS_REFINED_FOR_SWIFT;

/// 获取AppIcon图片
+ (nullable UIImage *)fw_appIconImage NS_REFINED_FOR_SWIFT;

/// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
+ (nullable UIImage *)fw_appIconImage:(CGSize)size NS_REFINED_FOR_SWIFT;

/// 从Pdf数据或者路径创建UIImage
+ (nullable UIImage *)fw_imageWithPdf:(id)path NS_REFINED_FOR_SWIFT;

/// 从Pdf数据或者路径创建指定大小UIImage
+ (nullable UIImage *)fw_imageWithPdf:(id)path size:(CGSize)size NS_REFINED_FOR_SWIFT;

/**
 创建渐变颜色UIImage，支持四个方向，默认向下Down
 
 @param size 图片大小
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
 @return 渐变颜色UIImage
 */
+ (nullable UIImage *)fw_gradientImageWithSize:(CGSize)size
                                       colors:(NSArray *)colors
                                    locations:(nullable const CGFloat *)locations
                                    direction:(UISwipeGestureRecognizerDirection)direction NS_REFINED_FOR_SWIFT;

/**
 创建渐变颜色UIImage
 
 @param size 图片大小
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param startPoint 渐变开始点，需要根据rect计算
 @param endPoint 渐变结束点，需要根据rect计算
 @return 渐变颜色UIImage
 */
+ (nullable UIImage *)fw_gradientImageWithSize:(CGSize)size
                                       colors:(NSArray *)colors
                                    locations:(nullable const CGFloat *)locations
                                   startPoint:(CGPoint)startPoint
                                     endPoint:(CGPoint)endPoint NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWToolkit

@interface UIView (FWToolkit)

/// 顶部纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat fw_top NS_REFINED_FOR_SWIFT;

/// 底部纵坐标，frame.origin.y + frame.size.height
@property (nonatomic, assign) CGFloat fw_bottom NS_REFINED_FOR_SWIFT;

/// 左边横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat fw_left NS_REFINED_FOR_SWIFT;

/// 右边横坐标，frame.origin.x + frame.size.width
@property (nonatomic, assign) CGFloat fw_right NS_REFINED_FOR_SWIFT;

/// 宽度，frame.size.width
@property (nonatomic, assign) CGFloat fw_width NS_REFINED_FOR_SWIFT;

/// 高度，frame.size.height
@property (nonatomic, assign) CGFloat fw_height NS_REFINED_FOR_SWIFT;

/// 中心横坐标，center.x
@property (nonatomic, assign) CGFloat fw_centerX NS_REFINED_FOR_SWIFT;

/// 中心纵坐标，center.y
@property (nonatomic, assign) CGFloat fw_centerY NS_REFINED_FOR_SWIFT;

/// 起始横坐标，frame.origin.x
@property (nonatomic, assign) CGFloat fw_x NS_REFINED_FOR_SWIFT;

/// 起始纵坐标，frame.origin.y
@property (nonatomic, assign) CGFloat fw_y NS_REFINED_FOR_SWIFT;

/// 起始坐标，frame.origin
@property (nonatomic, assign) CGPoint fw_origin NS_REFINED_FOR_SWIFT;

/// 大小，frame.size
@property (nonatomic, assign) CGSize fw_size NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWToolkit

/// 视图控制器生命周期状态枚举
typedef NS_OPTIONS(NSUInteger, FWViewControllerVisibleState) {
    /// 未触发ViewDidLoad
    FWViewControllerVisibleStateReady = 0,
    /// 已触发ViewDidLoad
    FWViewControllerVisibleStateDidLoad = 1 << 0,
    /// 已触发ViewWillAppear
    FWViewControllerVisibleStateWillAppear = 1 << 1,
    /// 已触发ViewDidAppear
    FWViewControllerVisibleStateDidAppear = 1 << 2,
    /// 已触发ViewWillDisappear
    FWViewControllerVisibleStateWillDisappear = 1 << 3,
    /// 已触发ViewDidDisappear
    FWViewControllerVisibleStateDidDisappear = 1 << 4,
} NS_SWIFT_NAME(ViewControllerVisibleState);

@interface UIViewController (FWToolkit)

/// 当前生命周期状态，默认Ready
@property (nonatomic, assign, readonly) FWViewControllerVisibleState fw_visibleState NS_REFINED_FOR_SWIFT;

/// 生命周期变化时通知句柄，默认nil
@property (nonatomic, copy, nullable) void (^fw_visibleStateChanged)(__kindof UIViewController *viewController, FWViewControllerVisibleState visibleState) NS_REFINED_FOR_SWIFT;

/// 自定义完成结果对象，默认nil
@property (nonatomic, strong, nullable) id fw_completionResult NS_REFINED_FOR_SWIFT NS_REFINED_FOR_SWIFT;

/// 自定义完成句柄，默认nil，dealloc时自动调用，参数为fwCompletionResult。支持提前调用，调用后需置为nil
@property (nonatomic, copy, nullable) void (^fw_completionHandler)(id _Nullable result) NS_REFINED_FOR_SWIFT;

/// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
@property (nonatomic, copy, nullable) BOOL (^fw_allowsPopGesture)(void) NS_REFINED_FOR_SWIFT;

/// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
@property (nonatomic, copy, nullable) BOOL (^fw_shouldPopController)(void) NS_REFINED_FOR_SWIFT;

/// 自定义侧滑返回手势VC开关，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，自动调用fw.allowsPopGesture，默认YES
@property (nonatomic, assign, readonly) BOOL allowsPopGesture;

/// 自定义控制器返回VC开关，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，自动调用fw.shouldPopController，默认YES
@property (nonatomic, assign, readonly) BOOL shouldPopController;

@end

NS_ASSUME_NONNULL_END
