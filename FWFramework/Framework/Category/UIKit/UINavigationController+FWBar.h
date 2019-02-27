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
 @brief 优化导航栏转场动画突兀的问题，默认关闭。全局启用后各个ViewController管理自己的导航栏样式，可在viewWillAppear中覆盖设置
 @discussion 方案1：自己实现UINavigationController管理器；方案2：将原有导航栏设置透明，每个控制器添加一个NavigationBar充当导航栏；方案3：转场开始隐藏原有导航栏并添加假的NavigationBar，转场结束后还原。此处采用方案3。更多介绍：https://tech.meituan.com/2018/10/25/navigation-transition-solution-and-best-practice-in-meituan.html
 
 @see https://github.com/MoZhouqi/KMNavigationBarTransition
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface UINavigationController (FWBar)

// 全局启用NavigationBar转场。启用后各个ViewController管理自己的导航栏样式，可在viewWillAppear中覆盖设置
+ (void)fwEnableNavigationBarTransition;

@end

#pragma mark - FWNavigationBarTransitionDelegate

/*!
 @brief 导航栏转场代理
 */
@protocol FWNavigationBarTransitionDelegate <NSObject>

@optional

// 是否隐藏导航栏。不实现时不处理导航栏显示/隐藏
- (BOOL)fwPrefersNavigationBarHidden;

// 自定义导航栏背景色。为了自动判断转场，请在此方法中设置，不在custom中设置。不实现时不设置
- (nullable UIColor *)fwNavigationBarBarTintColor;

// 自定义导航栏背景图片。为了自动判断转场，请在此方法中设置，不在custom中设置。不实现时不设置
- (nullable UIImage *)fwNavigationBarBackgroundImage;

// 自定义导航栏阴影图片。为了自动判断转场，请在此方法中设置，不在custom中设置。不实现时不设置
- (nullable UIImage *)fwNavigationBarShadowImage;

// 自定义导航栏文字颜色。不实现时不设置
- (nullable UIColor *)fwNavigationBarTintColor;

// 自定义导航栏标题文字属性。不实现时不设置
- (nullable NSDictionary *)fwNavigationBarTitleTextAttributes;

// 自定义导航栏样式，可搭配key方式实现自定义转场。不实现时不设置
- (void)fwCustomNavigationBarStyle;

// 转场动画自定义判断KEY，不相等才会启用转场。不实现时默认根据导航栏样式自动比较判定，建议实现，提高性能
- (nullable id)fwNavigationBarTransitionKey;

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
