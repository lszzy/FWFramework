//
//  FWToolkit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVKit/AVKit.h>
#import <MessageUI/MessageUI.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIApplication+FWToolkit

/**
 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app
 */
@interface UIApplication (FWToolkit)

/// 读取应用名称
@property (class, nonatomic, copy, readonly) NSString *fw_appName NS_REFINED_FOR_SWIFT;

/// 读取应用显示名称，未配置时读取名称
@property (class, nonatomic, copy, readonly) NSString *fw_appDisplayName NS_REFINED_FOR_SWIFT;

/// 读取应用主版本号，示例：1.0.0
@property (class, nonatomic, copy, readonly) NSString *fw_appVersion NS_REFINED_FOR_SWIFT;

/// 读取应用构建版本号，示例：1.0.0.1
@property (class, nonatomic, copy, readonly) NSString *fw_appBuildVersion NS_REFINED_FOR_SWIFT;

/// 读取应用唯一标识
@property (class, nonatomic, copy, readonly) NSString *fw_appIdentifier NS_REFINED_FOR_SWIFT;

/// 读取应用可执行程序名称
@property (class, nonatomic, copy, readonly) NSString *fw_appExecutable NS_REFINED_FOR_SWIFT;

/// 读取应用信息字典
+ (nullable id)fw_appInfo:(NSString *)key NS_REFINED_FOR_SWIFT;

/// 读取应用启动URL
+ (nullable NSURL *)fw_appLaunchURL:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)options NS_REFINED_FOR_SWIFT;

/// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
+ (BOOL)fw_canOpenURL:(id)url NS_REFINED_FOR_SWIFT;

/// 打开URL，支持NSString|NSURL，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fw_openURL:(id)url NS_REFINED_FOR_SWIFT;

/// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
+ (void)fw_openURL:(id)url completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
+ (void)fw_openUniversalLinks:(id)url completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
+ (BOOL)fw_isSystemURL:(id)url NS_REFINED_FOR_SWIFT;

/// 判断URL是否是Scheme链接(非http|https|file链接)，支持NSString|NSURL
+ (BOOL)fw_isSchemeURL:(id)url NS_REFINED_FOR_SWIFT;

/// 判断URL是否HTTP链接，支持NSString|NSURL
+ (BOOL)fw_isHttpURL:(id)url NS_REFINED_FOR_SWIFT;

/// 判断URL是否是AppStore链接，支持NSString|NSURL
+ (BOOL)fw_isAppStoreURL:(id)url NS_REFINED_FOR_SWIFT;

/// 打开AppStore下载页
+ (void)fw_openAppStore:(NSString *)appId completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开AppStore评价页
+ (void)fw_openAppStoreReview:(NSString *)appId completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开应用内评价，有次数限制
+ (void)fw_openAppReview NS_REFINED_FOR_SWIFT;

/// 打开系统应用设置页
+ (void)fw_openAppSettings:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开系统邮件App
+ (void)fw_openMailApp:(NSString *)email completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开系统短信App
+ (void)fw_openMessageApp:(NSString *)phone completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开系统电话App
+ (void)fw_openPhoneApp:(NSString *)phone completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开系统分享
+ (void)fw_openActivityItems:(NSArray *)activityItems excludedTypes:(nullable NSArray<UIActivityType> *)excludedTypes customBlock:(nullable void(^)(UIActivityViewController *activityController))customBlock NS_REFINED_FOR_SWIFT;

/// 打开内部浏览器，支持NSString|NSURL
+ (void)fw_openSafariController:(id)url NS_REFINED_FOR_SWIFT;

/// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
+ (void)fw_openSafariController:(id)url completionHandler:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 打开短信控制器，完成时回调
+ (void)fw_openMessageController:(MFMessageComposeViewController *)controller completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开邮件控制器，完成时回调
+ (void)fw_openMailController:(MFMailComposeViewController *)controller completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开Store控制器，完成时回调
+ (void)fw_openStoreController:(NSDictionary<NSString *, id> *)parameters completionHandler:(nullable void (^)(BOOL success))completion NS_REFINED_FOR_SWIFT;

/// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
+ (nullable AVPlayerViewController *)fw_openVideoPlayer:(id)url NS_REFINED_FOR_SWIFT;

/// 打开音频播放器，支持NSURL|NSString
+ (nullable AVAudioPlayer *)fw_openAudioPlayer:(id)url NS_REFINED_FOR_SWIFT;

/// 播放内置声音文件，完成后回调
+ (SystemSoundID)fw_playSystemSound:(NSString *)file completionHandler:(nullable void (^)(void))completionHandler NS_REFINED_FOR_SWIFT;

/// 停止播放内置声音文件
+ (void)fw_stopSystemSound:(SystemSoundID)soundId NS_REFINED_FOR_SWIFT;

/// 播放内置震动，完成后回调
+ (void)fw_playSystemVibrate:(nullable void (^)(void))completionHandler NS_REFINED_FOR_SWIFT;

/// 播放触控反馈
+ (void)fw_playImpactFeedback:(UIImpactFeedbackStyle)style NS_REFINED_FOR_SWIFT;

/// 语音朗读文字，可指定语言(如zh-CN)
+ (void)fw_playSpeechUtterance:(NSString *)string language:(nullable NSString *)languageCode NS_REFINED_FOR_SWIFT;

/// 是否是盗版(不是从AppStore安装)
@property (class, nonatomic, assign, readonly) BOOL fw_isPirated NS_REFINED_FOR_SWIFT;

/// 是否是Testflight版本
@property (class, nonatomic, assign, readonly) BOOL fw_isTestflight NS_REFINED_FOR_SWIFT;

/// 开始后台任务，task必须调用completionHandler
+ (void)fw_beginBackgroundTask:(void (NS_NOESCAPE ^)(void (^completionHandler)(void)))task expirationHandler:(nullable void (^)(void))expirationHandler NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIColor+FWToolkit

/// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

/// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

@interface UIColor (FWToolkit)

/// 获取当前颜色指定透明度的新颜色
- (UIColor *)fw_colorWithAlpha:(CGFloat)alpha NS_REFINED_FOR_SWIFT;

/// 读取颜色的十六进制值RGB，不含透明度
@property (nonatomic, assign, readonly) long fw_hexValue NS_REFINED_FOR_SWIFT;

/// 读取颜色的透明度值，范围0~1
@property (nonatomic, assign, readonly) CGFloat fw_alphaValue NS_REFINED_FOR_SWIFT;

/// 读取颜色的十六进制字符串RGB，不含透明度
@property (nonatomic, copy, readonly) NSString *fw_hexString NS_REFINED_FOR_SWIFT;

/// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
@property (nonatomic, copy, readonly) NSString *fw_hexAlphaString NS_REFINED_FOR_SWIFT;

/// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
@property (class, nonatomic, assign) BOOL fw_colorStandardARGB NS_REFINED_FOR_SWIFT;

/// 获取透明度为1.0的RGB随机颜色
@property (class, nonatomic, readonly) UIColor *fw_randomColor NS_REFINED_FOR_SWIFT;

/// 从十六进制值初始化，格式：0x20B2AA，透明度为1.0
+ (UIColor *)fw_colorWithHex:(long)hex NS_REFINED_FOR_SWIFT;

/// 从十六进制值初始化，格式：0x20B2AA，自定义透明度
+ (UIColor *)fw_colorWithHex:(long)hex alpha:(CGFloat)alpha NS_REFINED_FOR_SWIFT;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度为1.0，失败时返回clear
+ (UIColor *)fw_colorWithHexString:(NSString *)hexString NS_REFINED_FOR_SWIFT;

/// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，自定义透明度，失败时返回clear
+ (UIColor *)fw_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha NS_REFINED_FOR_SWIFT;

/// 以指定模式添加混合颜色
- (UIColor *)fw_addColor:(UIColor *)color blendMode:(CGBlendMode)blendMode NS_REFINED_FOR_SWIFT;

/// 当前颜色修改亮度比率的颜色
- (UIColor *)fw_brightnessColor:(CGFloat)ratio NS_REFINED_FOR_SWIFT;

/// 判断当前颜色是否为深色
@property (nonatomic, assign, readonly) BOOL fw_isDarkColor NS_REFINED_FOR_SWIFT;

/**
 创建渐变颜色，支持四个方向，默认向下Down
 
 @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
 @return 渐变色
 */
+ (UIColor *)fw_gradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(nullable const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction NS_REFINED_FOR_SWIFT;

/**
 创建渐变颜色
 
 @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param startPoint 渐变开始点，需要根据rect计算
 @param endPoint 渐变结束点，需要根据rect计算
 @return 渐变色
 */
+ (UIColor *)fw_gradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(nullable const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIFont+FWToolkit

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

@interface UIFont (FWToolkit)

/// 全局自定义字体句柄，优先调用，返回nil时使用系统字体
@property (class, nonatomic, copy, nullable) UIFont * _Nullable (^fw_fontBlock)(CGFloat size, UIFontWeight weight) NS_REFINED_FOR_SWIFT;

/// 是否自动等比例缩放字体，默认NO。启用后所有fw字体size都会自动*relativeScale
@property (class, nonatomic, assign) BOOL fw_autoScale NS_REFINED_FOR_SWIFT;
/// 是否自动等比例缩放后像素取整，默认NO
@property (class, nonatomic, assign) BOOL fw_autoFlat NS_REFINED_FOR_SWIFT;

/// 返回系统Thin字体，自动等比例缩放
+ (UIFont *)fw_thinFontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;
/// 返回系统Light字体，自动等比例缩放
+ (UIFont *)fw_lightFontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;
/// 返回系统Regular字体，自动等比例缩放
+ (UIFont *)fw_fontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;
/// 返回系统Medium字体，自动等比例缩放
+ (UIFont *)fw_mediumFontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;
/// 返回系统Semibold字体，自动等比例缩放
+ (UIFont *)fw_semiboldFontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;
/// 返回系统Bold字体，自动等比例缩放
+ (UIFont *)fw_boldFontOfSize:(CGFloat)size NS_REFINED_FOR_SWIFT;

/// 创建指定尺寸和weight的系统字体，自动等比例缩放
+ (UIFont *)fw_fontOfSize:(CGFloat)size weight:(UIFontWeight)weight NS_REFINED_FOR_SWIFT;

/// 获取指定名称、字重、斜体字体的完整规范名称
+ (NSString *)fw_fontName:(NSString *)name weight:(UIFontWeight)weight italic:(BOOL)italic NS_REFINED_FOR_SWIFT;

/// 是否是粗体
@property (nonatomic, assign, readonly) BOOL fw_isBold NS_REFINED_FOR_SWIFT;

/// 是否是斜体
@property (nonatomic, assign, readonly) BOOL fw_isItalic NS_REFINED_FOR_SWIFT;

/// 当前字体的粗体字体
@property (nonatomic, strong, readonly) UIFont *fw_boldFont NS_REFINED_FOR_SWIFT;

/// 当前字体的非粗体字体
@property (nonatomic, strong, readonly) UIFont *fw_nonBoldFont NS_REFINED_FOR_SWIFT;

/// 当前字体的斜体字体
@property (nonatomic, strong, readonly) UIFont *fw_italicFont NS_REFINED_FOR_SWIFT;

/// 当前字体的非斜体字体
@property (nonatomic, strong, readonly) UIFont *fw_nonItalicFont NS_REFINED_FOR_SWIFT;

/// 字体空白高度(上下之和)
@property (nonatomic, assign, readonly) CGFloat fw_spaceHeight NS_REFINED_FOR_SWIFT;

/// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
- (CGFloat)fw_lineSpacingWithMultiplier:(CGFloat)multiplier NS_REFINED_FOR_SWIFT;

/// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
- (CGFloat)fw_lineHeightWithMultiplier:(CGFloat)multiplier NS_REFINED_FOR_SWIFT;

/// 计算指定期望高度下字体的实际行高值，取期望值和行高值的较大值
- (CGFloat)fw_lineHeightWithExpected:(CGFloat)expected NS_REFINED_FOR_SWIFT;
    
/// 计算指定期望高度下字体的实际高度值，取期望值和高度值的较大值
- (CGFloat)fw_pointHeightWithExpected:(CGFloat)expected NS_REFINED_FOR_SWIFT;

/// 计算当前字体与指定字体居中对齐的偏移值
- (CGFloat)fw_baselineOffset:(UIFont *)font NS_REFINED_FOR_SWIFT;

/// 计算当前字体与指定行高居中对齐的偏移值
- (CGFloat)fw_baselineOffsetWithLineHeight:(CGFloat)lineHeight NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIImage+FWToolkit

@interface UIImage (FWToolkit)

/// 从当前图片创建指定透明度的图片
- (nullable UIImage *)fw_imageWithAlpha:(CGFloat)alpha NS_REFINED_FOR_SWIFT;

/// 从当前图片混合颜色创建UIImage，默认kCGBlendModeDestinationIn模式，适合透明图标
- (nullable UIImage *)fw_imageWithTintColor:(UIColor *)tintColor NS_REFINED_FOR_SWIFT;

/// 从当前UIImage混合颜色创建UIImage，自定义模式
- (nullable UIImage *)fw_imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode NS_REFINED_FOR_SWIFT;

/// 缩放图片到指定大小
- (nullable UIImage *)fw_imageWithScaleSize:(CGSize)size NS_REFINED_FOR_SWIFT;

/// 缩放图片到指定大小，指定模式
- (nullable UIImage *)fw_imageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode NS_REFINED_FOR_SWIFT;

/// 按指定模式绘制图片
- (void)fw_drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds NS_REFINED_FOR_SWIFT;

/// 裁剪指定区域图片
- (nullable UIImage *)fw_imageWithCropRect:(CGRect)rect NS_REFINED_FOR_SWIFT;

/// 指定颜色填充图片边缘
- (nullable UIImage *)fw_imageWithInsets:(UIEdgeInsets)insets color:(nullable UIColor *)color NS_REFINED_FOR_SWIFT;

/// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets NS_REFINED_FOR_SWIFT;

/// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode NS_REFINED_FOR_SWIFT;

/// 生成圆角图片
- (nullable UIImage *)fw_imageWithCornerRadius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 按角度常数(0~360)转动图片，默认图片尺寸适应内容
- (nullable UIImage *)fw_imageWithRotateDegree:(CGFloat)degree NS_REFINED_FOR_SWIFT;

/// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪
- (nullable UIImage *)fw_imageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize NS_REFINED_FOR_SWIFT;

/// 生成mark图片
- (nullable UIImage *)fw_imageWithMaskImage:(UIImage *)maskImage NS_REFINED_FOR_SWIFT;

/// 图片合并，并制定叠加图片的起始位置
- (nullable UIImage *)fw_imageWithMergeImage:(UIImage *)image atPoint:(CGPoint)point NS_REFINED_FOR_SWIFT;

/// 图片应用CIFilter滤镜处理
- (nullable UIImage *)fw_imageWithFilter:(CIFilter *)filter NS_REFINED_FOR_SWIFT;

/// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
- (nullable UIImage *)fw_compressImageWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio NS_REFINED_FOR_SWIFT;

/// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.3。不保证图片大小一定小于该大小
- (nullable NSData *)fw_compressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio NS_REFINED_FOR_SWIFT;

/// 长边压缩图片尺寸，获取等比例的图片
- (nullable UIImage *)fw_compressImageWithMaxWidth:(NSInteger)maxWidth NS_REFINED_FOR_SWIFT;

/// 通过指定图片最长边，获取等比例的图片size
- (CGSize)fw_scaleSizeWithMaxWidth:(CGFloat)maxWidth NS_REFINED_FOR_SWIFT;

/// 后台线程压缩图片，完成后主线程回调
+ (void)fw_compressImages:(NSArray<UIImage *> *)images maxWidth:(CGFloat)maxWidth maxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio completion:(void (^)(NSArray<UIImage *> *images))completion NS_REFINED_FOR_SWIFT;

/// 后台线程压缩图片数据，完成后主线程回调
+ (void)fw_compressDatas:(NSArray<UIImage *> *)images maxWidth:(CGFloat)maxWidth maxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio completion:(void (^)(NSArray<NSData *> *datas))completion NS_REFINED_FOR_SWIFT;

/// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fw_originalImage NS_REFINED_FOR_SWIFT;

/// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fw_templateImage NS_REFINED_FOR_SWIFT;

/// 判断图片是否有透明通道
@property (nonatomic, assign, readonly) BOOL fw_hasAlpha NS_REFINED_FOR_SWIFT;

/// 获取当前图片的像素大小，多倍图会放大到一倍
@property (nonatomic, assign, readonly) CGSize fw_pixelSize NS_REFINED_FOR_SWIFT;

/// 从视图创建UIImage，生成截图，主线程调用
+ (nullable UIImage *)fw_imageWithView:(UIView *)view NS_REFINED_FOR_SWIFT;

/// 从颜色创建UIImage，默认尺寸1x1
+ (nullable UIImage *)fw_imageWithColor:(UIColor *)color NS_REFINED_FOR_SWIFT;

/// 从颜色创建UIImage，指定尺寸
+ (nullable UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size NS_REFINED_FOR_SWIFT;

/// 从颜色创建UIImage，指定尺寸和圆角
+ (nullable UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius NS_REFINED_FOR_SWIFT;

/// 从block创建UIImage，指定尺寸
+ (nullable UIImage *)fw_imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef context))block NS_REFINED_FOR_SWIFT;

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

#pragma mark - UINavigationController+FWToolkit

/**
 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
 */
@interface UINavigationController (FWToolkit)

/// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
+ (void)fw_enablePopProxy NS_REFINED_FOR_SWIFT;

/// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
- (void)fw_enablePopProxy NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
