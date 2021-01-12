/*!
 @header     BaseViewController.m
 @indexgroup Example
 @brief      BaseViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "BaseViewController.h"

@interface FWViewControllerManager (FWViewController)

@end

@implementation FWViewControllerManager (FWViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [FWViewControllerIntercepter new];
    intercepter.initIntercepter = @selector(viewControllerInit:);
    intercepter.loadViewIntercepter = @selector(viewControllerLoadView:);
    intercepter.viewDidLoadIntercepter = @selector(viewControllerViewDidLoad:);
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWViewController) withIntercepter:intercepter];
    
    FWNavigationBarAppearance *defaultAppearance = [[FWNavigationBarAppearance alloc] init];
    defaultAppearance.foregroundColor = [AppTheme textColor];
    defaultAppearance.appearanceBlock = ^(UINavigationBar * _Nonnull navigationBar) {
        navigationBar.fwThemeBackgroundColor = [AppTheme barColor];
    };
    [FWNavigationBarAppearance setAppearance:defaultAppearance forStyle:FWNavigationBarStyleDefault];
    
    FWNavigationBarAppearance *randomAppearance = [[FWNavigationBarAppearance alloc] init];
    randomAppearance.foregroundColor = [AppTheme textColor];
    randomAppearance.appearanceBlock = ^(UINavigationBar * _Nonnull navigationBar) {
        navigationBar.fwThemeBackgroundColor = [UIColor fwRandomColor];
    };
    [FWNavigationBarAppearance setAppearance:randomAppearance forStyle:FWNavigationBarStyleRandom];
    
    FWNavigationBarAppearance *clearAppearance = [[FWNavigationBarAppearance alloc] init];
    clearAppearance.foregroundColor = [AppTheme textColor];
    clearAppearance.appearanceBlock = ^(UINavigationBar * _Nonnull navigationBar) {
        navigationBar.fwThemeBackgroundColor = [UIColor clearColor];
    };
    [FWNavigationBarAppearance setAppearance:clearAppearance forStyle:FWNavigationBarStyleClear];
}

- (void)viewControllerInit:(UIViewController *)viewController
{
    // 全局控制器初始化
    viewController.edgesForExtendedLayout = UIRectEdgeNone;
    viewController.extendedLayoutIncludesOpaqueBars = YES;
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    viewController.hidesBottomBarWhenPushed = YES;
    
    // 默认导航栏样式
    viewController.fwNavigationBarStyle = FWNavigationBarStyleDefault;
}

- (void)viewControllerLoadView:(UIViewController *)viewController
{
    // 默认背景色
    viewController.view.backgroundColor = [AppTheme backgroundColor];
}

- (void)viewControllerViewDidLoad:(UIViewController *)viewController
{
    // 通用返回按钮
    [viewController fwSetBackBarImage:[UIImage imageNamed:@"public_back"]];
}

@end

#pragma mark - BaseViewController

@implementation BaseViewController

FWDealloc();

@end
