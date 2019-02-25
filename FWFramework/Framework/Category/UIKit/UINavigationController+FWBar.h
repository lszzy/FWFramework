/*!
 @header     UINavigationController+FWBar.h
 @indexgroup FWFramework
 @brief      UINavigationController+FWBar
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UINavigationController+FWBar

/*!
 @brief 优化导航栏转场动画突兀的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，在viewWillAppear中设置即可
 @discussion 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html
 
 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface UINavigationController (FWBar)

// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，在viewWillAppear中设置即可
+ (void)fwEnableNavigationBarTransition;

@end

#pragma mark - FWNavigationBarTransitionDelegate

/*!
 @brief 导航栏转场代理
 */
@protocol FWNavigationBarTransitionDelegate <NSObject>

@optional

// 转场动画自定义判断KEY，不相等时才会启用转场。不实现时不启用自定义转场
- (nullable id)fwNavigationBarTransitionKey;

// 是否隐藏导航栏。不实现时不处理导航栏显示/隐藏
- (BOOL)fwPrefersNavigationBarHidden;

// 自定义转场动画样式，viewWillAppear中自动调用。不实现时不处理导航栏样式
- (void)fwCustomNavigationBarTransition;

// 自定义转场过程中containerView的背景色，不实现时默认白色
- (nullable UIColor *)fwContainerViewBackgroundColor;

@end

#pragma mark - UIViewController+FWNavigationBarTransitionDelegate

/*!
 @brief 视图控制器默认可选实现导航栏转场代理
 */
@interface UIViewController (FWNavigationBarTransitionDelegate) <FWNavigationBarTransitionDelegate>

@end

NS_ASSUME_NONNULL_END
