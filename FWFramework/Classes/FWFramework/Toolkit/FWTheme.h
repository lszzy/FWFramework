/**
 @header     FWTheme.h
 @indexgroup FWFramework
      FWTheme
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import <UIKit/UIKit.h>
#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWThemeManager

/// 主题样式枚举，可扩展
typedef NSInteger FWThemeStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 浅色样式
static const FWThemeStyle FWThemeStyleLight = 1;
/// 深色样式
static const FWThemeStyle FWThemeStyleDark = 2;

/// 主题模式枚举，可扩展(扩展值与样式值相同即可)
typedef NSInteger FWThemeMode NS_TYPED_EXTENSIBLE_ENUM;
/// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色，默认
static const FWThemeMode FWThemeModeSystem = 0;
/// 固定浅色模式
static const FWThemeMode FWThemeModeLight = FWThemeStyleLight;
/// 固定深色模式
static const FWThemeMode FWThemeModeDark = FWThemeStyleDark;

/// iOS13主题改变通知，object为FWThemeManager时表示手工切换，object为UIScreen时为系统切换
extern NSNotificationName const FWThemeChangedNotification;

/**
 主题管理器，iOS13+可跟随系统改变
 @note 框架默认只拦截了UIView|UIViewController|UIScreen|UIImageView|UILabel类，满足条件会自动触发fwThemeChanged；如果不满足条件或者拦截未生效，需先设置主题上下文fwThemeContext才能生效
 注意事项：iOS13以下默认不支持主题切换；如需支持，请使用fwColor相关方法
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

/// 指定traitCollection的实际显示样式，传nil时为全局样式
- (FWThemeStyle)styleForTraitCollection:(nullable UITraitCollection *)traitCollection;

@end

/**
 主题动态对象，可获取当前主题静态对象
 */
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

#pragma mark - FWColorWrapper+FWTheme

@interface FWColorWrapper (FWTheme)

/// 获取当前主题样式对应静态颜色，主要用于iOS13以下兼容主题切换
@property (nonatomic, readonly) UIColor *color;

/// 指定主题样式获取对应静态颜色，iOS13+可跟随系统改变
- (UIColor *)colorForStyle:(FWThemeStyle)style;

/// 是否是主题颜色，仅支持判断使用fwTheme创建的颜色
@property (nonatomic, assign, readonly) BOOL isThemeColor;

@end

@interface FWColorClassWrapper (FWTheme)

/// 动态创建主题色，分别指定浅色和深色
- (UIColor *)themeLight:(UIColor *)light dark:(UIColor *)dark;

/// 动态创建主题色，指定提供句柄
- (UIColor *)themeColor:(UIColor * (^)(FWThemeStyle style))provider;

/// 动态创建主题色，指定名称，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
- (UIColor *)themeNamed:(NSString *)name;

/// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
- (UIColor *)themeNamed:(NSString *)name bundle:(nullable NSBundle *)bundle;

/// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
- (void)setThemeColor:(nullable UIColor *)color forName:(NSString *)name;

/// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
- (void)setThemeColors:(NSDictionary<NSString *, UIColor *> *)nameColors;

@end

#pragma mark - FWImageWrapper+FWTheme

/**
 UIImage主题分类
 @note 注意UIImage默认只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化。
 为避免内存泄漏，通过fwTheme方式创建的主题图片不能直接用于显示，显示时请调用fwImage方法
 */
@interface FWImageWrapper (FWTheme)

/// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) UIImage *image;

/// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
- (nullable UIImage *)imageForStyle:(FWThemeStyle)style;

/// 是否是主题图片，仅支持判断使用fwTheme创建的图片
@property (nonatomic, assign, readonly) BOOL isThemeImage;

#pragma mark - Color

/// 快速生成当前图片对应的默认主题图片
@property (nonatomic, strong, readonly) UIImage *themeImage;

/// 指定主题颜色，快速生成当前图片对应的主题图片
- (UIImage *)themeImageWithColor:(UIColor *)themeColor;

@end

@interface FWImageClassWrapper (FWTheme)

/// 创建主题模拟动态图像，分别指定浅色和深色，不支持动态切换，需重新赋值才会变化
- (UIImage *)themeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark;

/// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
- (UIImage *)themeImage:(UIImage * _Nullable (^)(FWThemeStyle style))provider;

/// 创建主题模拟动态图像，指定名称，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
- (UIImage *)themeNamed:(NSString *)name;

/// 创建主题模拟动态图像，指定名称和bundle，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
- (UIImage *)themeNamed:(NSString *)name bundle:(nullable NSBundle *)bundle;

/// 手工单个注册主题图像，未配置主题图像时可使用本方式
- (void)setThemeImage:(nullable UIImage *)image forName:(NSString *)name;

/// 手工批量注册主题图像，未配置主题图像时可使用本方式
- (void)setThemeImages:(NSDictionary<NSString *, UIImage *> *)nameImages;

#pragma mark - Color

/// 默认主题图片颜色，未设置时为浅色=>黑色，深色=>白色
@property (nonatomic, strong) UIColor *themeImageColor;

@end

#pragma mark - FWImageAssetWrapper+FWTheme

@interface FWImageAssetWrapper (FWTheme)

/// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) UIImage *image;

/// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
- (nullable UIImage *)imageForStyle:(FWThemeStyle)style;

/// 是否是主题图片资源，仅支持判断使用fwTheme创建的图片资源
@property (nonatomic, assign, readonly) BOOL isThemeAsset;

@end

@interface FWImageAssetClassWrapper (FWTheme)

/// 创建主题动态图片资源，分别指定浅色和深色，系统方式，推荐使用
- (UIImageAsset *)themeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark;

/// 创建主题动态图片资源，指定提供句柄，内部使用FWThemeObject实现
- (UIImageAsset *)themeAsset:(UIImage * _Nullable (^)(FWThemeStyle style))provider;

@end

#pragma mark - FWObjectWrapper+FWTheme

/**
 iOS13主题订阅NSObject分类，可参考UIImageView.fwThemeImage方式进行扩展
 */
@interface FWObjectWrapper (FWTheme)

/// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
@property (nullable, nonatomic, weak) id<UITraitEnvironment> themeContext;

/// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
- (nullable NSString *)addThemeListener:(void (^)(FWThemeStyle style))listener;

/// iOS13根据订阅唯一标志移除主题通知回调
- (void)removeThemeListener:(nullable NSString *)identifier;

/// iOS13移除所有主题通知回调，一般用于cell重用
- (void)removeAllThemeListeners;

/// iOS13主题改变回调钩子，如果父类有重写，记得调用super，需订阅后才生效
- (void)themeChanged:(FWThemeStyle)style;

@end

/**
 iOS13主题订阅UIImageView分类
*/
@interface FWImageViewWrapper (FWTheme)

/// 设置主题图片，自动跟随系统改变，清空时需置为nil，二选一
@property (nullable, nonatomic, strong) UIImage *themeImage;

/// 设置主题图片资源，自动跟随系统改变，清空时需置为nil，二选一
@property (nullable, nonatomic, strong) UIImageAsset *themeAsset;

@end

NS_ASSUME_NONNULL_END
