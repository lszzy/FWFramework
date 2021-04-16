/*!
 @header     FWViewControllerStyle.h
 @indexgroup FWFramework
 @brief      FWViewControllerStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationBarAppearance

/// 导航栏全局样式可扩展枚举
typedef NSInteger FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM;
static const FWNavigationBarStyle FWNavigationBarStyleDefault     = 0;
static const FWNavigationBarStyle FWNavigationBarStyleHidden      = -1;
static const FWNavigationBarStyle FWNavigationBarStyleTransparent = 1;

/// 导航栏样式配置
@interface FWNavigationBarAppearance : NSObject

@property (nullable, nonatomic, strong) UIColor *backgroundColor;
@property (nullable, nonatomic, strong) UIColor *foregroundColor;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) BOOL isTransparent;
@property (nullable, nonatomic, copy) void (^appearanceBlock)(UINavigationBar *navigationBar);

+ (nullable FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style;
+ (void)setAppearance:(nullable FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style;

@end

#pragma mark - FWViewControllerVisibleState

/// 视图控制器生命周期状态枚举
typedef NS_OPTIONS(NSUInteger, FWViewControllerVisibleState) {
    /// 未触发ViewDidLoad
    FWViewControllerVisibleStateDefault = 0,
    /// 已触发ViewDidLoad
    FWViewControllerVisibleStateDidLoad,
    /// 已触发ViewWillAppear
    FWViewControllerVisibleStateWillAppear,
    /// 已触发ViewDidAppear
    FWViewControllerVisibleStateDidAppear,
    /// 已触发ViewWillDisappear
    FWViewControllerVisibleStateWillDisappear,
    /// 已触发ViewDidDisappear
    FWViewControllerVisibleStateDidDisappear,
};

#pragma mark - UIViewController+FWStyle

/*!
 @brief 视图控制器样式分类
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

#pragma mark - Item

/// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES，方便添加左上角关闭按钮
@property (nonatomic, assign, readonly) BOOL fwIsPresented;

/// 快捷设置导航栏标题文字或试图
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

#pragma mark - Back

/// 设置导航栏返回按钮，支持UIBarButtonItem|NSString|UIImage等，nil时显示系统箭头，下个页面生效
@property (nonatomic, strong, nullable) id fwBackBarItem;

/// 导航栏返回按钮点击事件(pop不会触发)，当前页面生效。返回YES关闭页面，NO不关闭，子类可重写。默认调用已设置的block事件
- (BOOL)fwPopBackBarItem;

/// 设置导航栏返回按钮点击block事件，默认fwPopBackBarItem自动调用。逻辑同上
@property (nonatomic, copy, nullable) BOOL (^fwBackBarBlock)(void);

#pragma mark - State

/// 当前生命周期状态，默认Default
@property (nonatomic, assign, readonly) FWViewControllerVisibleState fwVisibleState;

/// 生命周期变化时通知句柄，默认nil
@property (nonatomic, copy, nullable) void (^fwVisibleStateChanged)(__kindof UIViewController *viewController, FWViewControllerVisibleState visibleState);

@end

#pragma mark - UINavigationBar+FWStyle

/*!
 @brief 导航栏视图分类，全局设置用[UINavigationBar appearance]
 */
@interface UINavigationBar (FWStyle)

/// 设置文字和按钮颜色
@property (nonatomic, strong, nullable) UIColor *fwTextColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色(nil时透明)并隐藏底部线条
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor UI_APPEARANCE_SELECTOR;

/// 设置主题背景色(nil时透明)并隐藏底部线条，自动跟随系统改变
@property (nonatomic, strong, nullable) UIColor *fwThemeBackgroundColor;

/// 设置透明背景并隐藏底部线条
- (void)fwSetBackgroundTransparent UI_APPEARANCE_SELECTOR;

@end

#pragma mark - UITabBar+FWStyle

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 */
@interface UITabBar (FWStyle)

/// 设置文字和按钮颜色
@property (nonatomic, strong, nullable) UIColor *fwTextColor;

/// 设置背景颜色并隐藏顶部线条
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor;

/// 设置主题背景色并隐藏顶部线条，自动跟随系统改变
@property (nonatomic, strong, nullable) UIColor *fwThemeBackgroundColor;

@end

NS_ASSUME_NONNULL_END
