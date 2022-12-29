//
//  NavigationStyle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWNavigationBarAppearance

/// 导航栏全局样式可扩展枚举
typedef NSInteger __FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(NavigationBarStyle);
/// 默认样式，应用可配置并扩展
static const __FWNavigationBarStyle __FWNavigationBarStyleDefault = 0;

/// 导航栏样式配置
NS_SWIFT_NAME(NavigationBarAppearance)
@interface __FWNavigationBarAppearance : NSObject

/// 是否半透明(磨砂)，需edgesForExtendedLayout为Top|All，默认NO
@property (nonatomic, assign) BOOL isTranslucent;
/// 前景色，包含标题和按钮，默认nil
@property (nullable, nonatomic, strong) UIColor *foregroundColor;
/// 标题属性，默认nil使用前景色
@property (nullable, nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *titleAttributes;
/// 按钮属性，默认nil。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
@property (nullable, nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *buttonAttributes;
/// 背景色，后设置生效，默认nil
@property (nullable, nonatomic, strong) UIColor *backgroundColor;
/// 背景图片，后设置生效，默认nil
@property (nullable, nonatomic, strong) UIImage *backgroundImage;
/// 背景透明，需edgesForExtendedLayout为Top|All，后设置生效，默认NO
@property (nonatomic, assign) BOOL backgroundTransparent;
/// 阴影颜色，后设置生效，默认nil
@property (nullable, nonatomic, strong) UIColor *shadowColor;
/// 阴影图片，后设置生效，默认nil
@property (nullable, nonatomic, strong) UIImage *shadowImage;
/// 返回按钮图片，自动配合VC导航栏样式生效，默认nil
@property (nullable, nonatomic, strong) UIImage *backImage;
/// 左侧返回按钮图片，自动配合VC导航栏样式生效，默认nil
@property (nullable, nonatomic, strong) UIImage *leftBackImage;

/// 自定义句柄，最后调用，可自定义样式，默认nil
@property (nullable, nonatomic, copy) void (^appearanceBlock)(UINavigationBar *navigationBar);

/// 根据style获取全局appearance对象
+ (nullable __FWNavigationBarAppearance *)appearanceForStyle:(__FWNavigationBarStyle)style;
/// 设置style对应全局appearance对象
+ (void)setAppearance:(nullable __FWNavigationBarAppearance *)appearance forStyle:(__FWNavigationBarStyle)style;

@end

NS_ASSUME_NONNULL_END
