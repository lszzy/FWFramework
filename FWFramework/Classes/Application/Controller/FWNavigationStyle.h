/*!
 @header     FWNavigationStyle.h
 @indexgroup FWFramework
 @brief      FWNavigationStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationBarAppearance

/// 导航栏全局样式可扩展枚举
typedef NSInteger FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 默认样式，不透明
static const FWNavigationBarStyle FWNavigationBarStyleDefault     = 0;
/// 隐藏样式，不显示
static const FWNavigationBarStyle FWNavigationBarStyleHidden      = -1;
/// 透明样式，全透明
static const FWNavigationBarStyle FWNavigationBarStyleTransparent = 1;
/// 磨砂样式，半透明，需edgesForExtendedLayout为Top|All，contentInsetAdjustmentBehavior为Automatic|Always
static const FWNavigationBarStyle FWNavigationBarStyleTranslucent = 2;

/// 导航栏样式配置
@interface FWNavigationBarAppearance : NSObject

@property (nullable, nonatomic, strong) UIColor *foregroundColor;
@property (nullable, nonatomic, strong) UIColor *titleColor;
@property (nullable, nonatomic, strong) UIColor *backgroundColor;
@property (nullable, nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) BOOL isTransparent;
@property (nonatomic, assign) BOOL isTranslucent;
@property (nullable, nonatomic, copy) void (^appearanceBlock)(UINavigationBar *navigationBar);

+ (nullable FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style;
+ (void)setAppearance:(nullable FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style;

@end

#pragma mark - UIViewController+FWStyle

/*!
 @brief 视图控制器样式分类，兼容系统导航栏和自定义导航栏(default和custom样式)
 @discussion 需要设置UIViewControllerBasedStatusBarAppearance为YES，视图控制器修改状态栏样式才会生效
 */
@interface UIViewController (FWStyle)

#pragma mark - Bar

/// 状态栏是否隐藏，默认NO，设置后才会生效
@property (nonatomic, assign) BOOL fwStatusBarHidden;

/// 状态栏样式，默认UIStatusBarStyleDefault，设置后才会生效
@property (nonatomic, assign) UIStatusBarStyle fwStatusBarStyle;

/// 导航栏是否隐藏，默认NO，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) BOOL fwNavigationBarHidden;

/// 当前导航栏样式，默认Default，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) FWNavigationBarStyle fwNavigationBarStyle;

/// 当前导航栏设置，优先级高于style和hidden，设置后会在viewWillAppear:自动应用生效
@property (nullable, nonatomic, strong) FWNavigationBarAppearance *fwNavigationBarAppearance;

/// 标签栏是否隐藏，默认为NO，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
@property (nonatomic, assign) BOOL fwTabBarHidden;

/// 工具栏是否隐藏，默认为YES。需设置toolbarItems，立即生效
@property (nonatomic, assign) BOOL fwToolBarHidden;

/// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，All为全部延伸(全部Bar覆盖视图)
@property (nonatomic, assign) UIRectEdge fwExtendedLayoutEdge;

#pragma mark - Height

/// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwStatusBarHeight;

/// 当前导航栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwNavigationBarHeight;

/// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwTopBarHeight;

/// 当前标签栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwTabBarHeight;

/// 当前工具栏布局高度，隐藏时为0，推荐使用
@property (nonatomic, assign, readonly) CGFloat fwToolBarHeight;

#pragma mark - Item

/// 快捷设置导航栏标题文字或视图
@property (nonatomic, strong, nullable) id fwBarTitle;

/// 设置导航栏左侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
@property (nonatomic, strong, nullable) id fwLeftBarItem;

/// 设置导航栏右侧按钮，支持UIBarButtonItem|UIImage等，默认事件为关闭当前页面，下个页面生效
@property (nonatomic, strong, nullable) id fwRightBarItem;

/// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fwSetLeftBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
- (void)fwSetLeftBarItem:(nullable id)object block:(void (^)(id sender))block;

/// 快捷设置导航栏右侧按钮
- (void)fwSetRightBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷设置导航栏右侧按钮，block事件
- (void)fwSetRightBarItem:(nullable id)object block:(void (^)(id sender))block;

/// 快捷添加导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fwAddLeftBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷添加导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
- (void)fwAddLeftBarItem:(nullable id)object block:(void (^)(id sender))block;

/// 快捷添加导航栏右侧按钮
- (void)fwAddRightBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷添加导航栏右侧按钮，block事件
- (void)fwAddRightBarItem:(nullable id)object block:(void (^)(id sender))block;

#pragma mark - Back

/// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
@property (nonatomic, strong, nullable) id fwBackBarItem;

/// 导航栏返回按钮点击事件(pop不会触发)，当前页面生效。返回YES关闭页面，NO不关闭，子类可重写。默认调用已设置的block事件
- (BOOL)fwPopBackBarItem;

/// 设置导航栏返回按钮点击block事件，默认fwPopBackBarItem自动调用。逻辑同上
@property (nonatomic, copy, nullable) BOOL (^fwBackBarBlock)(void);

@end

#pragma mark - UINavigationBar+FWStyle

/*!
 @brief 导航栏视图分类，全局设置用[UINavigationBar appearance]
 */
@interface UINavigationBar (FWStyle)

/// 是否启用iOS13+样式，iOS15+必须启用。默认Xcode13+为YES，Xcode12及以下为NO
@property (class, nonatomic, assign) BOOL fwAppearanceEnabled;

/// 导航栏iOS13+样式对象，用于自定义样式
@property (nonatomic, strong, readonly) UINavigationBarAppearance *fwAppearance API_AVAILABLE(ios(13.0));

/// 手工更新导航栏样式
- (void)fwUpdateAppearance API_AVAILABLE(ios(13.0));

/// 设置返回按钮图片，包含图片和转场Mask图片
@property (nonatomic, strong, nullable) UIImage *fwBackImage UI_APPEARANCE_SELECTOR;

/// 导航栏是否半透明，需先于背景色设置，默认NO。YES时使用barTintColor，NO时使用backgroundImage
@property (nonatomic, assign) BOOL fwIsTranslucent;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *fwForegroundColor UI_APPEARANCE_SELECTOR;

/// 单独设置标题颜色，nil时显示前景颜色
@property (nonatomic, strong, nullable) UIColor *fwTitleColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色(nil时透明)并隐藏底部线条，兼容主题颜色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor UI_APPEARANCE_SELECTOR;

/// 设置背景图片(nil时透明)并隐藏底部线条，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwBackgroundImage UI_APPEARANCE_SELECTOR;

/// 设置透明背景并隐藏底部线条，自动清空主题背景
- (void)fwSetBackgroundTransparent UI_APPEARANCE_SELECTOR;

#pragma mark - View

/// 导航栏内容视图，iOS11+才存在，显示item和titleView等
@property (nonatomic, readonly, nullable) UIView *fwContentView;

/// 导航栏背景视图，显示背景色和背景图片等
@property (nonatomic, readonly, nullable) UIView *fwBackgroundView;

/// 导航栏大标题视图，显示时才有值。如果要设置背景色，可使用fwBackgroundView.backgroundColor
@property (nonatomic, readonly, nullable) UIView *fwLargeTitleView;

/// 导航栏大标题高度，与是否隐藏无关
@property (class, nonatomic, readonly, assign) CGFloat fwLargeTitleHeight;

@end

#pragma mark - UITabBar+FWStyle

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 */
@interface UITabBar (FWStyle)

/// 是否启用iOS13+样式，iOS15+必须启用。默认Xcode13+为YES，Xcode12及以下为NO
@property (class, nonatomic, assign) BOOL fwAppearanceEnabled;

/// 标签栏iOS13+样式对象，用于自定义样式
@property (nonatomic, strong, readonly) UITabBarAppearance *fwAppearance API_AVAILABLE(ios(13.0));

/// 手工更新标签栏样式
- (void)fwUpdateAppearance API_AVAILABLE(ios(13.0));

/// 标签栏是否半透明，需先于背景色设置，默认NO。YES时使用barTintColor，NO时使用backgroundImage
@property (nonatomic, assign) BOOL fwIsTranslucent;

/// 设置前景颜色，包含文字和按钮等
@property (nonatomic, strong, nullable) UIColor *fwForegroundColor;

/// 设置背景颜色并隐藏顶部线条，兼容主题颜色
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor;

/// 设置背景图片并隐藏顶部线条，兼容主题图片
@property (nonatomic, strong, nullable) UIImage *fwBackgroundImage;

@end

NS_ASSUME_NONNULL_END
