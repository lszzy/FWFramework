//
//  FWTheme.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWThemeManager

/// 主题样式枚举，可扩展
typedef NSInteger FWThemeStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ThemeStyle);
/// 浅色样式
static const FWThemeStyle FWThemeStyleLight = 1;
/// 深色样式
static const FWThemeStyle FWThemeStyleDark = 2;

/// 主题模式枚举，可扩展(扩展值与样式值相同即可)
typedef NSInteger FWThemeMode NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ThemeMode);
/// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色，默认
static const FWThemeMode FWThemeModeSystem = 0;
/// 固定浅色模式
static const FWThemeMode FWThemeModeLight = FWThemeStyleLight;
/// 固定深色模式
static const FWThemeMode FWThemeModeDark = FWThemeStyleDark;

/// iOS13主题改变通知，object为FWThemeManager时表示手工切换，object为UIScreen时为系统切换
extern NSNotificationName const FWThemeChangedNotification NS_SWIFT_NAME(ThemeChanged);

/**
 主题管理器，iOS13+可跟随系统改变
 @note 框架默认只拦截了UIView|UIViewController|UIScreen|UIImageView|UILabel类，满足条件会自动触发fwThemeChanged；如果不满足条件或者拦截未生效，需先设置主题上下文fwThemeContext才能生效
 注意事项：iOS13以下默认不支持主题切换；如需支持，请使用fwColor相关方法
 */
NS_SWIFT_NAME(ThemeManager)
@interface FWThemeManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWThemeManager *sharedInstance NS_SWIFT_NAME(shared);

/// 当前主题模式，默认跟随系统模式
@property (nonatomic, assign) FWThemeMode mode;

/// iOS13切换主题模式时是否覆盖主window样式(立即生效)，默认NO。如果固定主题模式时颜色不正常，可尝试开启本属性
@property (nonatomic, assign) BOOL overrideWindow;

/// 当前全局主题样式
@property (nonatomic, readonly) FWThemeStyle style;

/// 指定traitCollection的实际显示样式，传nil时为全局样式
- (FWThemeStyle)styleForTraitCollection:(nullable UITraitCollection *)traitCollection;

@end

/**
 主题动态对象，可获取当前主题静态对象
 */
NS_SWIFT_NAME(ThemeObject)
@interface FWThemeObject<__covariant ObjectType> : NSObject

/// 创建主题动态对象，分别指定浅色和深色
+ (instancetype)objectWithLight:(nullable ObjectType)light dark:(nullable ObjectType)dark;

/// 创建主题动态对象，指定提供句柄
+ (instancetype)objectWithProvider:(ObjectType _Nullable (^)(FWThemeStyle style))provider;

/// 获取当前主题静态对象，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) ObjectType object;

/// 指定主题样式获取对应静态对象，iOS13+可跟随系统改变
- (nullable ObjectType)objectForStyle:(FWThemeStyle)style;

@end

#pragma mark - UIColor+FWTheme

@interface UIColor (FWTheme)

/// 动态创建主题色，分别指定浅色和深色
+ (UIColor *)fw_themeLight:(UIColor *)light dark:(UIColor *)dark NS_REFINED_FOR_SWIFT;

/// 动态创建主题色，指定提供句柄
+ (UIColor *)fw_themeColor:(UIColor * (^)(FWThemeStyle style))provider NS_REFINED_FOR_SWIFT;

/// 动态创建主题色，指定名称，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
+ (UIColor *)fw_themeNamed:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
+ (UIColor *)fw_themeNamed:(NSString *)name bundle:(nullable NSBundle *)bundle NS_REFINED_FOR_SWIFT;

/// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fw_setThemeColor:(nullable UIColor *)color forName:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fw_setThemeColors:(NSDictionary<NSString *, UIColor *> *)nameColors NS_REFINED_FOR_SWIFT;

/// 获取当前主题样式对应静态颜色，主要用于iOS13以下兼容主题切换
@property (nonatomic, readonly) UIColor *fw_color NS_SWIFT_NAME(__fw_color) NS_REFINED_FOR_SWIFT;

/// 指定主题样式获取对应静态颜色，iOS13+可跟随系统改变
- (UIColor *)fw_colorForStyle:(FWThemeStyle)style NS_REFINED_FOR_SWIFT;

/// 是否是主题颜色，仅支持判断使用fwTheme创建的颜色
@property (nonatomic, assign, readonly) BOOL fw_isThemeColor NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIImage+FWTheme

/**
 UIImage主题分类
 @note 注意UIImage默认只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化。
 为避免内存泄漏，通过fwTheme方式创建的主题图片不能直接用于显示，显示时请调用fwImage方法
 */
@interface UIImage (FWTheme)

/// 创建主题模拟动态图像，分别指定浅色和深色，不支持动态切换，需重新赋值才会变化
+ (UIImage *)fw_themeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark NS_REFINED_FOR_SWIFT;

/// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
+ (UIImage *)fw_themeImage:(UIImage * _Nullable (^)(FWThemeStyle style))provider NS_REFINED_FOR_SWIFT;

/// 创建主题模拟动态图像，指定名称，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
+ (UIImage *)fw_themeNamed:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 创建主题模拟动态图像，指定名称和bundle，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
+ (UIImage *)fw_themeNamed:(NSString *)name bundle:(nullable NSBundle *)bundle NS_REFINED_FOR_SWIFT;

/// 手工单个注册主题图像，未配置主题图像时可使用本方式
+ (void)fw_setThemeImage:(nullable UIImage *)image forName:(NSString *)name NS_REFINED_FOR_SWIFT;

/// 手工批量注册主题图像，未配置主题图像时可使用本方式
+ (void)fw_setThemeImages:(NSDictionary<NSString *, UIImage *> *)nameImages NS_REFINED_FOR_SWIFT;

/// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) UIImage *fw_image NS_SWIFT_NAME(__fw_image) NS_REFINED_FOR_SWIFT;

/// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
- (nullable UIImage *)fw_imageForStyle:(FWThemeStyle)style NS_REFINED_FOR_SWIFT;

/// 是否是主题图片，仅支持判断使用fwTheme创建的图片
@property (nonatomic, assign, readonly) BOOL fw_isThemeImage NS_REFINED_FOR_SWIFT;

#pragma mark - Color

/// 默认主题图片颜色，未设置时为浅色=>黑色，深色=>白色
@property (class, nonatomic, strong, readonly) UIColor *fw_themeImageColor NS_REFINED_FOR_SWIFT;

/// 默认主题图片颜色配置句柄，默认nil
@property (class, nonatomic, copy, nullable) UIColor * (^fw_themeImageColorConfiguration)(void) NS_REFINED_FOR_SWIFT;

/// 快速生成当前图片对应的默认主题图片
@property (nonatomic, strong, readonly) UIImage *fw_themeImage NS_SWIFT_NAME(__fw_themeImage) NS_REFINED_FOR_SWIFT;

/// 指定主题颜色，快速生成当前图片对应的主题图片
- (UIImage *)fw_themeImageWithColor:(UIColor *)themeColor NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIImageAsset+FWTheme

@interface UIImageAsset (FWTheme)

/// 创建主题动态图片资源，分别指定浅色和深色，系统方式，推荐使用
+ (UIImageAsset *)fw_themeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark NS_REFINED_FOR_SWIFT;

/// 创建主题动态图片资源，指定提供句柄，内部使用FWThemeObject实现
+ (UIImageAsset *)fw_themeAsset:(UIImage * _Nullable (^)(FWThemeStyle style))provider NS_REFINED_FOR_SWIFT;

/// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) UIImage *fw_image NS_REFINED_FOR_SWIFT;

/// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
- (nullable UIImage *)fw_imageForStyle:(FWThemeStyle)style NS_REFINED_FOR_SWIFT;

/// 是否是主题图片资源，仅支持判断使用fwTheme创建的图片资源
@property (nonatomic, assign, readonly) BOOL fw_isThemeAsset NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSObject+FWTheme

/// iOS13主题订阅观察者监听协议，主题改变时自动通知
NS_SWIFT_NAME(ThemeObserver)
@protocol FWThemeObserver <NSObject>

@optional

/// iOS13主题改变渲染钩子，如果父类有重写，记得调用super，需订阅后才生效
- (void)renderTheme:(FWThemeStyle)style;

@end

@interface NSObject (FWTheme) <FWThemeObserver>

/// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
@property (nullable, nonatomic, weak) id<UITraitEnvironment> fw_themeContext NS_REFINED_FOR_SWIFT;

/// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
- (nullable NSString *)fw_addThemeListener:(void (^)(FWThemeStyle style))listener NS_REFINED_FOR_SWIFT;

/// iOS13根据订阅唯一标志移除主题通知回调
- (void)fw_removeThemeListener:(nullable NSString *)identifier NS_REFINED_FOR_SWIFT;

/// iOS13移除所有主题通知回调，一般用于cell重用
- (void)fw_removeAllThemeListeners NS_REFINED_FOR_SWIFT;

/// iOS13主题改变包装器钩子，如果父类有重写，记得调用super，需订阅后才生效
- (void)fw_themeChanged:(FWThemeStyle)style NS_REFINED_FOR_SWIFT;

@end

/**
 iOS13主题订阅UIImageView分类
*/
@interface UIImageView (FWTheme)

/// 设置主题图片，自动跟随系统改变，清空时需置为nil，二选一
@property (nullable, nonatomic, strong) UIImage *fw_themeImage NS_REFINED_FOR_SWIFT;

/// 设置主题图片资源，自动跟随系统改变，清空时需置为nil，二选一
@property (nullable, nonatomic, strong) UIImageAsset *fw_themeAsset NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
