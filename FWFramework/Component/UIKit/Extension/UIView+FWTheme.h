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

/// 主题样式枚举
typedef NS_ENUM(NSInteger, FWThemeStyle) {
    /// 浅色
    FWThemeStyleLight,
    /// 深色
    FWThemeStyleDark,
};

/// 主题模式枚举
typedef NS_ENUM(NSInteger, FWThemeMode) {
    /// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色
    FWThemeModeSystem,
    /// 固定浅色模式
    FWThemeModeLight,
    /// 固定深色模式
    FWThemeModeDark,
};

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

/// iOS13切换主题模式时是否覆盖主window样式，默认NO，使用overrideUserInterfaceStyle实现。如果需要自定义处理，请使用通知
@property (nonatomic, assign) BOOL overrideWindow;

/// 当前主题样式
@property (nonatomic, readonly) FWThemeStyle style;

@end

#pragma mark - NSObject+FWTheme

/*!
 @brief iOS13主题订阅NSObject分类
 */
@interface NSObject (FWTheme)

/// 是否订阅iOS13主题通知，如果为UIView|UIViewController|UIScreen时为YES，否则为NO，需订阅后才能响应系统主题
@property (nonatomic, assign) BOOL fwThemeSubscribed;

/// 添加iOS13主题改变通知回调，自动订阅，返回订阅唯一标志。非UIViewUIViewController|UIScreen子类时，订阅主题通知后才生效
- (NSString *)fwAddThemeListener:(void (^)(FWThemeStyle style))listener;

/// iOS13根据订阅唯一标志移除主题通知回调
- (void)fwRemoveThemeListener:(NSString *)identifier;

/// iOS13主题改变回调钩子。非UIView|UIViewController|UIScreen子类时，启用主题监听后才生效
- (void)fwThemeChanged:(FWThemeStyle)style;

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

/// 动态创建主题色，指定名称，兼容iOS11+系统方式和手工指定
+ (nullable UIColor *)fwThemeNamed:(NSString *)name;

/// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fwSetThemeColor:(nullable UIColor *)color forName:(NSString *)name;

/// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
+ (void)fwSetThemeColors:(NSDictionary<NSString *, UIColor *> *)nameColors;

@end

#pragma mark - UIImage+FWTheme

/*!
 @brief UIImage主题分类
 */
@interface UIImage (FWTheme)

/// 动态创建主题图像，分别指定浅色和深色
+ (nullable UIImage *)fwThemeLight:(nullable UIImage *)light dark:(nullable UIImage *)dark;

/// 动态创建主题图像，指定提供句柄
+ (nullable UIImage *)fwThemeImage:(UIImage * _Nullable (^)(FWThemeStyle style))provider;

/// 动态创建主题图像，指定名称，兼容系统方式和手工指定
+ (nullable UIImage *)fwThemeNamed:(NSString *)name;

/// 手工单个注册主题图像，未配置主题图像时可使用本方式
+ (void)fwSetThemeImage:(nullable UIImage *)image forName:(NSString *)name;

/// 手工批量注册主题图像，未配置主题图像时可使用本方式
+ (void)fwSetThemeImages:(NSDictionary<NSString *, UIImage *> *)nameImages;

@end

NS_ASSUME_NONNULL_END
