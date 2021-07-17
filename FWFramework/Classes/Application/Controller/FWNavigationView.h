/*!
 @header     FWNavigationView.h
 @indexgroup FWFramework
 @brief      FWNavigationView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationView

/**
 * 自定义导航栏视图
 */
@interface FWNavigationView : UIView

/// 自定义导航栏
@property (nonatomic, strong, readonly) UINavigationBar *navigationBar;

/// 自定义导航项
@property (nonatomic, strong, readonly) UINavigationItem *navigationItem;

@end

#pragma mark - UIViewController+FWNavigationView

/**
 * 控制器自定义导航栏
 *
 * 注意，启用自定义导航栏后，虽然兼容FWViewControllerStyle方法，但有几点不同，列举如下：
 * 1. fwNavigationView位于VC.view顶部；fwContainerView位于VC.view底部，顶部对齐fwNavigationView.底部
 * 2. VC容器视图为fwContainerView，所有子视图应该添加到fwContainerView；可使用fwView兼容两种方式
 * 3. VC返回按钮会使用自身的backBarButtonItem，方便使用；而系统VC返会使用前一个控制器的backBarButtonItem
 * 如果从系统导航栏动态迁移到自定义导航栏，注意检查导航相关功能是否异常
 */
@interface UIViewController (FWNavigationView)

/// 自定义导航栏视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) FWNavigationView *fwNavigationView;

/// 自定义容器视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) UIView *fwContainerView;

/// 是否启用自定义导航栏，子类重写，默认NO
- (BOOL)fwNavigationViewEnabled;

@end

NS_ASSUME_NONNULL_END
