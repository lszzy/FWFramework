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

@interface UIViewController (FWNavigationView)

/// 自定义导航栏视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) FWNavigationView *fwNavigationView;

/// 自定义容器视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) UIView *fwContainerView;

/// 是否启用自定义导航栏，子类重写，默认NO
- (BOOL)fwNavigationViewEnabled;

@end

NS_ASSUME_NONNULL_END
