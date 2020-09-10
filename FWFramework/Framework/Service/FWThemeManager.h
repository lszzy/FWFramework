/*!
 @header     FWThemeManager.h
 @indexgroup FWFramework
 @brief      FWThemeManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWThemeManager

/// 主题样式枚举，可扩展
typedef NSInteger FWThemeStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 浅色样式
static const FWThemeStyle FWThemeStyleLight = 1;
/// 深色样式
static const FWThemeStyle FWThemeStyleDark = 2;

/// 主题模式枚举，可扩展
typedef NSInteger FWThemeMode NS_TYPED_EXTENSIBLE_ENUM;
/// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色，默认
static const FWThemeMode FWThemeModeSystem = 0;
/// 固定浅色模式
static const FWThemeMode FWThemeModeLight = FWThemeStyleLight;
/// 固定深色模式
static const FWThemeMode FWThemeModeDark = FWThemeStyleDark;

/// iOS13主题改变通知，object为FWThemeManager时表示手工切换，object为UIScreen时为系统切换
extern NSString *const FWThemeChangedNotification;

/*!
 @brief 主题管理器，iOS13+可跟随系统改变
 @discussion 框架默认只拦截了UIView|UIViewController|UIScreen|UIImageView类，满足条件会自动触发fwThemeChanged；如果不满足条件或者拦截未生效(如UILabel等)，需先设置主题上下文fwThemeContext才能生效
 */
@interface FWThemeManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWThemeManager *sharedInstance;

/// 当前主题模式，默认跟随系统模式
@property (nonatomic, assign) FWThemeMode mode;

/// iOS13切换主题模式时是否覆盖主window样式(立即生效)，默认NO(不会立即生效，需刷新界面)。如果不满足需求，可自定义处理
@property (nonatomic, assign) BOOL overrideWindow;

/// 当前全局主题样式
@property (nonatomic, readonly) FWThemeStyle style;

/// 指定traitCollection的主题样式，传nil时为全局样式
- (FWThemeStyle)style:(nullable UITraitCollection *)traitCollection;

@end

#pragma mark - UIColor+FWTheme

// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/*!
 @brief UIColor主题分类
 */
@interface UIColor (FWTheme)

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

#pragma mark - Theme

/// 动态创建主题色，分别指定浅色和深色
+ (UIColor *)fwThemeLight:(UIColor *)light dark:(UIColor *)dark;

/// 动态创建主题色，指定提供句柄
+ (UIColor *)fwThemeColor:(UIColor * (^)(FWThemeStyle style))provider;

/// 动态创建主题色，指定名称，兼容iOS11+系统方式和手工指定。失败时返回clear防止崩溃
+ (UIColor *)fwThemeNamed:(NSString *)name;

/// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fwSetThemeColor:(nullable UIColor *)color forName:(NSString *)name;

/// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fwSetThemeColors:(NSDictionary<NSString *, UIColor *> *)nameColors;

@end

#pragma mark - UIImage+FWTheme

/*!
 @brief UIImage主题分类
 @discussion 注意UIImage只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化
 */
@interface UIImage (FWTheme)

/// 创建主题模拟动态图像，分别指定浅色和深色，不支持动态切换，需重新赋值才会变化
+ (nullable UIImage *)fwThemeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark;

/// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
+ (nullable UIImage *)fwThemeImage:(UIImage * _Nullable (^)(FWThemeStyle style))provider;

/// 创建主题模拟动态图像，指定名称，兼容系统方式和手工指定，支持动态切换，需配置any和dark
+ (nullable UIImage *)fwThemeNamed:(NSString *)name;

/// 手工单个注册主题图像，未配置主题图像时可使用本方式
+ (void)fwSetThemeImage:(nullable UIImage *)image forName:(NSString *)name;

/// 手工批量注册主题图像，未配置主题图像时可使用本方式
+ (void)fwSetThemeImages:(NSDictionary<NSString *, UIImage *> *)nameImages;

/// 是否是主题模拟动态图像，不支持动态切换，需重新赋值才会变化
@property (nonatomic, readonly) BOOL fwIsDynamic;

/// 获取主题模拟动态图像的当前显示静态图像
@property (nullable, nonatomic, readonly) UIImage *fwStaticImage;

@end

#pragma mark - UIFont+FWTheme

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
@interface UIFont (FWTheme)

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

#pragma mark - NSObject+FWTheme

/*!
 @brief iOS13主题订阅NSObject分类，可参考UIImageView.fwThemeImage方式进行扩展
 */
@interface NSObject (FWTheme)

/// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
@property (nullable, nonatomic, weak) id<UITraitEnvironment> fwThemeContext;

/// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
- (nullable NSString *)fwAddThemeListener:(void (^)(FWThemeStyle style))listener;

/// iOS13根据订阅唯一标志移除主题通知回调
- (void)fwRemoveThemeListener:(nullable NSString *)identifier;

/// iOS13主题改变回调钩子，如果父类有重写，记得调用super，需订阅后才生效
- (void)fwThemeChanged:(FWThemeStyle)style;

@end

/*!
 @brief iOS13主题订阅UIImageView分类
*/
@interface UIImageView (FWTheme)

/// 设置主题图片，自动跟随系统改变
@property (nullable, nonatomic, strong) UIImage *fwThemeImage;

@end

/*!
 @brief iOS13主题订阅CALayer分类
*/
@interface CALayer (FWTheme)

/// 设置主题背景色，启用主题订阅后可跟随系统改变
@property (nullable, nonatomic, strong) UIColor *fwThemeBackgroundColor;

/// 设置主题边框色，启用主题订阅后可跟随系统改变
@property (nullable, nonatomic, strong) UIColor *fwThemeBorderColor;

/// 设置主题阴影色，启用主题订阅后可跟随系统改变
@property (nullable, nonatomic, strong) UIColor *fwThemeShadowColor;

/// 设置主题内容图片，启用主题订阅后可跟随系统改变
@property (nullable, nonatomic, strong) UIImage *fwThemeContents;

@end

/*!
 @brief iOS13主题订阅CALayer分类
*/
@interface CAGradientLayer (FWTheme)

/// 设置主题渐变色，启用主题订阅后可跟随系统改变
@property (nullable, nonatomic, copy) NSArray<UIColor *> *fwThemeColors;

@end

NS_ASSUME_NONNULL_END
