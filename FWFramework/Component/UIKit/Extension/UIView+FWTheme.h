/*!
 @header     UIView+FWTheme.h
 @indexgroup FWFramework
 @brief      UIView+FWTheme
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
 @brief 主题管理器
 @discussion iOS13跟随系统模式时，如果为UIView|UIViewController|UIScreen子类，会自动触发fwThemeChanged回调；否则需要先启用fwThemeSubscribed才会触发fwThemeChanged回调
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

/*!
 @brief UIColor主题分类
 */
@interface UIColor (FWTheme)

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

#pragma mark - NSObject+FWTheme

/*!
 @brief iOS13主题订阅NSObject分类，可参考UIImageView.fwThemeImage方式进行扩展
 */
@interface NSObject (FWTheme)

/// 是否启用iOS13主题订阅，如果为UIView|UIViewController|UIScreen时始终为YES，否则默认为NO，需订阅后才能响应系统主题
@property (nonatomic, readonly) BOOL fwThemeEnabled;

/// 订阅主题通知并指定主题上下文(如vc|view)。非UIViewUIViewController|UIScreen子类时，需订阅后才能响应系统主题
@property (nullable, nonatomic, weak) id<UITraitEnvironment> fwThemeContext;

/// 添加iOS13主题改变通知回调，返回订阅唯一标志。非UIViewUIViewController|UIScreen子类时，需订阅后才生效
- (nullable NSString *)fwAddThemeListener:(void (^)(FWThemeStyle style))listener;

/// iOS13根据订阅唯一标志移除主题通知回调
- (void)fwRemoveThemeListener:(nullable NSString *)identifier;

/// iOS13主题改变回调钩子，如果父类有重写，记得调用super。非UIView|UIViewController|UIScreen子类时，需订阅后才生效
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
