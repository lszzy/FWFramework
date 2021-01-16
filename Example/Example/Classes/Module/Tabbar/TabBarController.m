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

@interface TabBarController () <UITabBarControllerDelegate>

@end

@implementation TabBarController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupAppearance];
        [self setupController];
    }
    return self;
}

- (void)setupAppearance
{
    self.delegate = self;
    [self.tabBar fwSetTextColor:[Theme textColor]];
    self.tabBar.fwThemeBackgroundColor = [Theme barColor];
}

- (void)setupController
{
    UIViewController *homeController = [HomeViewController new];
    homeController.hidesBottomBarWhenPushed = NO;
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeController];
    homeNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_home"];
    homeNav.tabBarItem.title = FWLocalizedString(@"homeTitle");
    [homeNav.tabBarItem fwShowBadgeView:[[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleSmall] badgeValue:@"1"];
    
    UIViewController *testController = [Mediator.testModule testViewController];
    testController.hidesBottomBarWhenPushed = NO;
    UINavigationController *testNav = [[UINavigationController alloc] initWithRootViewController:testController];
    testNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_test"];
    testNav.tabBarItem.title = FWLocalizedString(@"testTitle");
    
    UIViewController *settingsController = [SettingsViewController new];
    settingsController.hidesBottomBarWhenPushed = NO;
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    settingsNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_settings"];
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
    CABasicAnimation *animation = [imageView fwAddAnimationWithKeyPath:@"transform.scale" fromValue:@(0.7) toValue:@(1.3) duration:0.08 completion:nil];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.repeatCount = 1;
    animation.autoreverses = YES;
}

#pragma mark - Public

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
