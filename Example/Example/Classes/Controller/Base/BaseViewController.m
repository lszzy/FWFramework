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
    viewController.view.backgroundColor = [UIColor whiteColor];
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
