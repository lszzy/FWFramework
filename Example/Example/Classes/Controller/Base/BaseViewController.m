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
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWViewController) withIntercepter:intercepter];
}

- (void)viewControllerInit:(UIViewController *)viewController
{
    // 全局控制器初始化
    viewController.edgesForExtendedLayout = UIRectEdgeNone;
    viewController.extendedLayoutIncludesOpaqueBars = YES;
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    viewController.hidesBottomBarWhenPushed = YES;
}

- (void)viewControllerLoadView:(UIViewController *)viewController
{
    // 默认背景色
    viewController.view.backgroundColor = [UIColor whiteColor];
}

@end

#pragma mark - BaseViewController

@implementation BaseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 通用导航栏样式
    [self fwSetBackBarImage:[UIImage imageNamed:@"public_back"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 通用导航栏样式
    [self.navigationController.navigationBar fwSetBackgroundColor:[UIColor fwColorWithHex:0xFFDA00]];
    [self.navigationController.navigationBar fwSetLineHidden:YES];
}

- (void)dealloc
{
    // 自动移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 打印被释放日志，防止内存泄露
    NSLog(@"%@ did dealloc", NSStringFromClass(self.class));
}

@end
