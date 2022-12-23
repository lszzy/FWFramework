//
//  Theme.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWThemeManager

/// 主题样式枚举，可扩展
typedef NSInteger __FWThemeStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ThemeStyle);
/// 浅色样式
static const __FWThemeStyle __FWThemeStyleLight = 1;
/// 深色样式
static const __FWThemeStyle __FWThemeStyleDark = 2;

/// 主题模式枚举，可扩展(扩展值与样式值相同即可)
typedef NSInteger __FWThemeMode NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ThemeMode);
/// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色，默认
static const __FWThemeMode __FWThemeModeSystem = 0;
/// 固定浅色模式
static const __FWThemeMode __FWThemeModeLight = __FWThemeStyleLight;
/// 固定深色模式
static const __FWThemeMode __FWThemeModeDark = __FWThemeStyleDark;

/// iOS13主题改变通知，object为__FWThemeManager时表示手工切换，object为UIScreen时为系统切换
extern NSNotificationName const __FWThemeChangedNotification NS_SWIFT_NAME(ThemeChanged);

/**
 主题管理器，iOS13+可跟随系统改变
 @note 框架默认只拦截了UIView|UIViewController|UIScreen|UIImageView|UILabel类，满足条件会自动触发fwThemeChanged；如果不满足条件或者拦截未生效，需先设置主题上下文fwThemeContext才能生效
 注意事项：iOS13以下默认不支持主题切换；如需支持，请使用fwColor相关方法
 */
NS_SWIFT_NAME(ThemeManager)
@interface __FWThemeManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) __FWThemeManager *sharedInstance NS_SWIFT_NAME(shared);

/// 当前主题模式，默认跟随系统模式
@property (nonatomic, assign) __FWThemeMode mode;

/// iOS13切换主题模式时是否覆盖主window样式(立即生效)，默认NO。如果固定主题模式时颜色不正常，可尝试开启本属性
@property (nonatomic, assign) BOOL overrideWindow;

/// 当前全局主题样式
@property (nonatomic, readonly) __FWThemeStyle style;

/// 指定traitCollection的实际显示样式，传nil时为全局样式
- (__FWThemeStyle)styleForTraitCollection:(nullable UITraitCollection *)traitCollection;

@end

/**
 主题动态对象，可获取当前主题静态对象
 */
NS_SWIFT_NAME(ThemeObject)
@interface __FWThemeObject<__covariant ObjectType> : NSObject

/// 创建主题动态对象，分别指定浅色和深色
+ (instancetype)objectWithLight:(nullable ObjectType)light dark:(nullable ObjectType)dark;

/// 创建主题动态对象，指定提供句柄
+ (instancetype)objectWithProvider:(ObjectType _Nullable (^)(__FWThemeStyle style))provider;

/// 获取当前主题静态对象，iOS13+可跟随系统改变
@property (nullable, nonatomic, readonly) ObjectType object;

/// 指定主题样式获取对应静态对象，iOS13+可跟随系统改变
- (nullable ObjectType)objectForStyle:(__FWThemeStyle)style;

@end

/**
 iOS13主题订阅观察者监听协议，主题改变时自动通知
 */
NS_SWIFT_NAME(ThemeObserver)
@protocol __FWThemeObserver <NSObject>

@optional
/// iOS13主题改变渲染钩子，如果父类有重写，记得调用super，需订阅后才生效
- (void)renderTheme:(__FWThemeStyle)style;

@end

@interface NSObject (__FWTheme) <__FWThemeObserver>

@end

NS_ASSUME_NONNULL_END
