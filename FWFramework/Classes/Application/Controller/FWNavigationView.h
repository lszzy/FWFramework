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
 * 自定义导航栏视图，高度自动布局，隐藏时自动收起
 */
@interface FWNavigationView : UIView

/// 自定义导航栏，可隐藏，底部对齐
@property (nonatomic, strong, readonly) UINavigationBar *navigationBar;

/// 自定义导航项，可设置标题、按钮等
@property (nonatomic, strong, readonly) UINavigationItem *navigationItem;

/// 自定义总高度，隐藏时自动收起，默认FWTopBarHeight
@property (nonatomic, assign) CGFloat topBarHeight;

/// 自定义导航栏高度，默认FWNavigationBarHeight
@property (nonatomic, assign) CGFloat navigationBarHeight;

@end

#pragma mark - UIViewController+FWNavigationView

/**
 * 控制器自定义导航栏
 *
 * 原则：优先用系统导航栏，不满足时才使用自定义导航栏
 * 注意：启用自定义导航栏后，虽然兼容FWViewControllerStyle方法，但有几点不同，列举如下：
 * 1. fwNavigationView位于VC.view顶部；fwContainerView位于VC.view底部，顶部对齐fwNavigationView.底部
 * 2. VC容器视图为fwContainerView，所有子视图应该添加到fwContainerView；可使用fwView兼容两种方式
 * 3. VC返回按钮会使用自身的backBarButtonItem，兼容系统导航栏动态切换；而系统VC会使用前一个控制器的backBarButtonItem
 * 如果从系统导航栏动态迁移到自定义导航栏，注意检查导航相关功能是否异常
 */
@interface UIViewController (FWNavigationView)

/// 自定义导航栏视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) FWNavigationView *fwNavigationView;

/// 自定义容器视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) UIView *fwContainerView;

/// 是否启用自定义导航栏，需在init中设置或子类重写，默认NO
@property (nonatomic, assign) BOOL fwNavigationViewEnabled;

@end

#pragma mark - FWNavigationButton

/**
 * 自定义导航栏按钮，兼容系统customView方式和自定义方式
 */
@interface FWNavigationButton : UIButton

/// UIBarButtonItem默认都是跟随tintColor的，所以这里声明是否让图片也是用AlwaysTemplate模式，默认YES
@property (nonatomic, assign) BOOL adjustsTintColor;

/// UIBarButtonItem自定义导航栏时最左和最右间距为16，系统导航栏时为8，所以这里声明是否让内容自动偏移，默认YES
@property (nonatomic, assign) BOOL adjustsContentInsets;

/// 初始化标题类型按钮，默认内间距：{8, 8, 8, 8}，可自定义
- (instancetype)initWithTitle:(nullable NSString *)title;

/// 初始化图片类型按钮，默认内间距：{8, 8, 8, 8}，可自定义
- (instancetype)initWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
