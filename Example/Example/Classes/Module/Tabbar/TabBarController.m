//
//  TabBarController.m
//  Example
//
//  Created by wuyong on 2020/9/12.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TabBarController.h"
#import "HomeViewController.h"
#import "SettingsViewController.h"

@implementation UITabBarController (AppTabBar)

- (void)setupController
{
    self.delegate = self;
    [self.tabBar fwSetTextColor:[Theme textColor]];
    self.tabBar.fwThemeBackgroundColor = [Theme barColor];
    if (AppConfig.isRootNavigation) {
        self.fwNavigationBarStyle = FWNavigationBarStyleHidden;
    }
    
    UIViewController *homeController = [HomeViewController new];
    homeController.hidesBottomBarWhenPushed = NO;
    UINavigationController *homeNav;
    if (AppConfig.isRootCustom) {
        homeNav = [[FWContainerNavigationController alloc] initWithRootViewController:homeController];
    } else {
        homeNav = [[UINavigationController alloc] initWithRootViewController:homeController];
    }
    homeNav.tabBarItem.image = [UIImage imageNamed:@"tabbarHome"];
    homeNav.tabBarItem.title = FWLocalizedString(@"homeTitle");
    [homeNav.tabBarItem fwShowBadgeView:[[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall] badgeValue:@"1"];
    
    UIViewController *testController = [Mediator.testModule testViewController];
    testController.hidesBottomBarWhenPushed = NO;
    UINavigationController *testNav;
    if (AppConfig.isRootCustom) {
        testNav = [[FWContainerNavigationController alloc] initWithRootViewController:testController];
    } else {
        testNav = [[UINavigationController alloc] initWithRootViewController:testController];
    }
    testNav.tabBarItem.image = [UIImage imageNamed:@"tabbarTest"];
    testNav.tabBarItem.title = FWLocalizedString(@"testTitle");
    
    UIViewController *settingsController = [SettingsViewController new];
    settingsController.hidesBottomBarWhenPushed = NO;
    UINavigationController *settingsNav;
    if (AppConfig.isRootCustom) {
        settingsNav = [[FWContainerNavigationController alloc] initWithRootViewController:settingsController];
    } else {
        settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    }
    settingsNav.tabBarItem.image = [UIImage imageNamed:@"tabbarSettings"];
    settingsNav.tabBarItem.title = FWLocalizedString(@"settingTitle");
    self.viewControllers = @[homeNav, testNav, settingsNav];
    
    [self fwObserveNotification:FWLanguageChangedNotification block:^(NSNotification * _Nonnull notification) {
        homeNav.tabBarItem.title = FWLocalizedString(@"homeTitle");
        testNav.tabBarItem.title = FWLocalizedString(@"testTitle");
        settingsNav.tabBarItem.title = FWLocalizedString(@"settingTitle");
    }];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    UIImageView *imageView = viewController.tabBarItem.fwImageView;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = @[@(1.0), @(1.4), @(0.9), @(1.15), @(0.95), @(1.02), @(1.0)];
    animation.duration = 0.3 * 2;
    animation.calculationMode = kCAAnimationCubic;
    [imageView.layer addAnimation:animation forKey:nil];
}

#pragma mark - Public

+ (UIViewController *)setupController
{
    UITabBarController *tabBarController;
    if (AppConfig.isRootCustom) {
        tabBarController = [FWTabBarController new];
    } else {
        tabBarController = [UITabBarController new];
    }
    [tabBarController setupController];
    
    if (!AppConfig.isRootNavigation) {
        return tabBarController;
    } else if (AppConfig.isRootCustom) {
        return [[FWRootNavigationController alloc] initWithRootViewController:tabBarController];
    } else {
        return [[UINavigationController alloc] initWithRootViewController:tabBarController];
    }
}

+ (void)refreshController
{
    if (@available(iOS 13.0, *)) {
        FWSceneDelegate *sceneDelegete = (FWSceneDelegate *)UIWindow.fwMainScene.delegate;
        [sceneDelegete setupController];
    } else {
        FWAppDelegate *appDelegate = (FWAppDelegate *)UIApplication.sharedApplication.delegate;
        [appDelegate setupController];
    }
}

@end
