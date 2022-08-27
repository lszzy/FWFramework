//
//  FWNavigationStyle.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationBarAppearance

/// 导航栏全局样式可扩展枚举
typedef NSInteger FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(NavigationBarStyle);
/// 默认样式，应用可配置并扩展
static const FWNavigationBarStyle FWNavigationBarStyleDefault = 0;

/// 导航栏样式配置
NS_SWIFT_NAME(NavigationBarAppearance)
@interface FWNavigationBarAppearance : NSObject

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
+ (nullable FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style;
/// 设置style对应全局appearance对象
+ (void)setAppearance:(nullable FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style;

@end

#pragma mark - UINavigationBar+FWStyle

/**
 导航栏应用样式配置分类
 */
@interface UINavigationBar (FWStyle)

/// 应用指定导航栏配置
- (void)fw_applyBarAppearance:(FWNavigationBarAppearance *)appearance NS_REFINED_FOR_SWIFT;

/// 应用指定导航栏样式
- (void)fw_applyBarStyle:(FWNavigationBarStyle)style NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWStyle

/**
 视图控制器样式分类，兼容系统导航栏和自定义导航栏(default和custom样式)
 @note 需要设置UIViewControllerBasedStatusBarAppearance为YES，视图控制器修改状态栏样式才会生效
 */
@interface UIViewController (FWStyle)

/// 状态栏样式，默认UIStatusBarStyleDefault，设置后才会生效
@property (nonatomic, assign) UIStatusBarStyle fw_statusBarStyle NS_REFINED_FOR_SWIFT;

/// 状态栏是否隐藏，默认NO，设置后才会生效
@property (nonatomic, assign) BOOL fw_statusBarHidden NS_REFINED_FOR_SWIFT;

/// 当前导航栏设置，优先级高于style，设置后会在viewWillAppear:自动应用生效
@property (nullable, nonatomic, strong) FWNavigationBarAppearance *fw_navigationBarAppearance NS_REFINED_FOR_SWIFT;

/// 当前导航栏样式，默认Default，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) FWNavigationBarStyle fw_navigationBarStyle NS_REFINED_FOR_SWIFT;

/// 导航栏是否隐藏，默认NO，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) BOOL fw_navigationBarHidden NS_REFINED_FOR_SWIFT;

/// 动态隐藏导航栏，如果当前已经viewWillAppear:时立即执行
- (void)fw_setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 是否允许child控制器修改导航栏样式，默认NO
@property (nonatomic, assign) BOOL fw_allowsChildNavigation NS_REFINED_FOR_SWIFT;

/// 标签栏是否隐藏，默认为NO，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
@property (nonatomic, assign) BOOL fw_tabBarHidden NS_REFINED_FOR_SWIFT;

/// 工具栏是否隐藏，默认为YES。需设置toolbarItems，立即生效
@property (nonatomic, assign) BOOL fw_toolBarHidden NS_REFINED_FOR_SWIFT;

/// 动态隐藏工具栏。需设置toolbarItems，立即生效
- (void)fw_setToolBarHidden:(BOOL)hidden animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，Top|Bottom为顶部|底部延伸，All为全部延伸
@property (nonatomic, assign) UIRectEdge fw_extendedLayoutEdge NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
