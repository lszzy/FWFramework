//
//  FWNavigationController.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UINavigationController+FWBarTransition

/**
 优化导航栏转场动画闪烁的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
 @note 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html
 
 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface UINavigationController (FWBarTransition)

/// 自定义转场过程中containerView的背景色，默认透明
@property (nonatomic, strong) UIColor *fw_containerBackgroundColor NS_REFINED_FOR_SWIFT;

/// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
+ (void)fw_enableBarTransition NS_REFINED_FOR_SWIFT;

@end

/**
 视图控制器导航栏转场分类。可设置部分界面不需要自定义转场
 @note 如果导航栏push/pop存在黑影(tab.nav.push|present.nav.push|nav.push)，可在对应控制器的viewDidLoad设置视图背景色为白色(tab.view|present.nav.view|vc.view)。
 */
@interface UIViewController (FWBarTransition)

/// 转场动画自定义判断标识，不相等才会启用转场。默认nil启用转场。可重写或者push前设置生效
@property (nullable, nonatomic, strong) id fw_barTransitionIdentifier NS_REFINED_FOR_SWIFT;

/// 标记转场导航栏样式需要刷新，如果viewDidAppear之前导航栏样式发生了改变，可调用此方法
- (void)fw_barTransitionNeedsUpdate NS_REFINED_FOR_SWIFT;

@end

@interface UINavigationBar (FWBarTransition)

/// 导航栏背景视图，显示背景色和背景图片等
@property (nonatomic, readonly, nullable) UIView *fw_backgroundView NS_REFINED_FOR_SWIFT;

/// 导航栏内容视图，iOS11+才存在，显示item和titleView等
@property (nonatomic, readonly, nullable) UIView *fw_contentView NS_REFINED_FOR_SWIFT;

/// 导航栏大标题视图，显示时才有值。如果要设置背景色，可使用fwBackgroundView.backgroundColor
@property (nonatomic, readonly, nullable) UIView *fw_largeTitleView NS_REFINED_FOR_SWIFT;

/// 导航栏大标题高度，与是否隐藏无关
@property (class, nonatomic, readonly, assign) CGFloat fw_largeTitleHeight NS_REFINED_FOR_SWIFT;

@end

/**
 present带导航栏webview，如果存在input[type=file]，会dismiss两次，无法选择照片。
 解决方法：1.使用push 2.重写dismiss方法仅当presentedViewController存在时才调用dismiss
 */
@interface UIToolbar (FWBarTransition)

/// 工具栏背景视图，显示背景色和背景图片等。如果标签栏同时显示，背景视图高度也会包含标签栏高度
@property (nonatomic, readonly, nullable) UIView *fw_backgroundView NS_REFINED_FOR_SWIFT;

/// 工具栏内容视图，iOS11+才存在，显示item等
@property (nonatomic, readonly, nullable) UIView *fw_contentView NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UINavigationController+FWFullscreenPopGesture

/**
 导航栏全屏返回手势分类，兼容shouldPopController返回拦截方法
 @see https://github.com/forkingdog/FDFullscreenPopGesture
 */
@interface UINavigationController (FWFullscreenPopGesture)

/// 是否启用导航栏全屏返回手势，默认NO。启用时系统返回手势失效，禁用时还原系统手势。如果只禁用系统手势，设置interactivePopGestureRecognizer.enabled即可
@property (nonatomic, assign) BOOL fw_fullscreenPopGestureEnabled NS_REFINED_FOR_SWIFT;

/// 导航栏全屏返回手势对象
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *fw_fullscreenPopGestureRecognizer NS_REFINED_FOR_SWIFT;

/// 判断手势是否是全局返回手势对象
+ (BOOL)fw_isFullscreenPopGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer NS_REFINED_FOR_SWIFT;

@end

/**
 控制器全屏返回手势分类，兼容shouldPopController返回拦截方法
 */
@interface UIViewController (FWFullscreenPopGesture)

/// 视图控制器是否禁用全屏返回手势，默认NO
@property (nonatomic, assign) BOOL fw_fullscreenPopGestureDisabled NS_REFINED_FOR_SWIFT;

/// 视图控制器全屏手势距离左侧最大距离，默认0，无限制
@property (nonatomic, assign) CGFloat fw_fullscreenPopGestureDistance NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
