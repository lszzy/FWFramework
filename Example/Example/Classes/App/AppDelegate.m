//
//  AppDelegate.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "AppDelegate.h"
#import "ObjcController.h"
#import "TestViewController.h"

@interface AppDelegate () <UITabBarControllerDelegate>

@end

@implementation AppDelegate

#pragma mark - Protected

- (void)setupApplication:(UIApplication *)application options:(NSDictionary *)options
{
    [[FWNotificationManager sharedInstance] clearNotificationBadges];
}

- (void)setupService
{
    [[FWNotificationManager sharedInstance] registerNotificationHandler];
    [[FWNotificationManager sharedInstance] requestAuthorize:nil];
}

- (void)setupController
{
    // 统一设置导航栏样式
    [[UINavigationBar appearance] fwSetTextColor:[UIColor fwColorWithHex:0x111111]];
    
    // 初始化tabBar控制器
    UIViewController *homeController = [ObjcController new];
    homeController.hidesBottomBarWhenPushed = NO;
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeController];
    homeNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_home"];
    homeNav.tabBarItem.title = @"首页";
    [homeNav.tabBarItem fwShowBadgeView:[[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall] badgeValue:@"1"];
    
    UIViewController *testController = [TestViewController new];
    testController.hidesBottomBarWhenPushed = NO;
    UINavigationController *testNav = [[UINavigationController alloc] initWithRootViewController:testController];
    testNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_settings"];
    testNav.tabBarItem.title = @"测试";
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.delegate = self;
    // present时隐藏tabBar
    tabBarController.definesPresentationContext = YES;
    tabBarController.viewControllers = @[homeNav, testNav];
    
    // 设置主控制器
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = tabBarController;
}

- (void)setupDeviceToken:(NSData *)deviceToken error:(NSError *)error
{
    [UIDevice fwSetDeviceToken:deviceToken];
}

- (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary *)options
{
    [FWRouter openURL:url.absoluteString];
    return YES;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    UIImageView *imageView = viewController.tabBarItem.fwImageView;
    CABasicAnimation *animation = [imageView fwAddAnimationWithKeyPath:@"transform.scale" fromValue:@(0.7) toValue:@(1.3) duration:0.08 completion:nil];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.repeatCount = 1;
    animation.autoreverses = YES;
}

@end
