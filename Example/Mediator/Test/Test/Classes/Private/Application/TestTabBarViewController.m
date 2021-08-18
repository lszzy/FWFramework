//
//  TestTabBarViewController.m
//  Example
//
//  Created by wuyong on 2020/12/21.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestTabBarViewController.h"
#import "TestRouterViewController.h"
#import "TestModuleController.h"
#import "TestWebViewController.h"
@import Core;

@interface TestTabBarViewController () <UITabBarControllerDelegate>

@end

@implementation TestTabBarViewController

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
    self.hidesBottomBarWhenPushed = YES;
    self.delegate = self;
    self.tabBar.fwForegroundColor = [Theme textColor];
    self.tabBar.fwBackgroundColor = [Theme barColor];
    self.fwForcePopGesture = YES;
    self.fwNavigationBarHidden = YES;
}

- (void)setupController
{
    UIViewController *firstController = [TestRouterViewController new];
    firstController.hidesBottomBarWhenPushed = NO;
    FWWeakifySelf();
    firstController.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:FWIcon.backImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIViewController *secondController = [TestModuleController new];
    secondController.hidesBottomBarWhenPushed = NO;
    secondController.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:FWIcon.backImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.navigationController popViewControllerAnimated:YES];
    }];
    UIViewController *thirdController = [[TestWebViewController alloc] initWithRequestUrl:@"http://kvm.wuyong.site/test.php"];
    thirdController.hidesBottomBarWhenPushed = NO;
    thirdController.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:FWIcon.backImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    firstController = [[UINavigationController alloc] initWithRootViewController:firstController];
    secondController = [[UINavigationController alloc] initWithRootViewController:secondController];
    thirdController = [[UINavigationController alloc] initWithRootViewController:thirdController];
    [self setViewControllers:@[firstController, secondController, thirdController]];
    
    firstController.tabBarItem.image = [TestBundle imageNamed:@"tabbar_home"];
    firstController.tabBarItem.title = FWLocalizedString(@"homeTitle");
    firstController.tabBarItem.badgeValue = @"99";
    secondController.tabBarItem.image = [TestBundle imageNamed:@"tabbar_test"];
    secondController.tabBarItem.title = FWLocalizedString(@"testTitle");
    thirdController.tabBarItem.image = [TestBundle imageNamed:@"tabbar_settings"];
    thirdController.tabBarItem.title = FWLocalizedString(@"settingTitle");
    FWBadgeView *badgeView = [[FWBadgeView alloc] initWithBadgeStyle:FWBadgeStyleDot];
    [thirdController.tabBarItem fwShowBadgeView:badgeView badgeValue:nil];
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
