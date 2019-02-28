/*!
 @header     UINavigationController+FWBar.h
 @indexgroup FWFramework
 @brief      UINavigationController+FWBar
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import <UIKit/UIKit.h>

/*!
 @brief 优化导航栏转场动画闪烁的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
 @discussion 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html
 
 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 */
@interface UINavigationController (FWBar)

// 全局启用转场NavigationBar。启用后各个ViewController管理自己的导航栏样式，在viewDidLoad或viewViewAppear中设置即可
+ (void)fwEnableTransitionNavigationBar;

// 自定义转场过程中containerView的背景色，默认白色
@property (nonatomic, strong) UIColor *fwContainerViewBackgroundColor;

@end

/*!
 @brief UIViewController+FWBarTransition
 */
@interface UIViewController (FWBarTransition)

// 如果iOS11+有滚动视图时转场动画不正常，可指定此视图；也可设置滚动视图的contentInsetAdjustmentBehavior为Never
@property (nonatomic, weak) UIScrollView *fwTransitionScrollView;

@end
