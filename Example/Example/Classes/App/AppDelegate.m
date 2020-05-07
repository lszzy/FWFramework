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
#import "SettingsViewController.h"

@interface AppDelegate () <UITabBarControllerDelegate>

@end

@implementation AppDelegate

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[FWNotificationManager sharedInstance] handleLocalNotification:notification];
}

#pragma mark - Protect

- (void)setupApplication:(UIApplication *)application options:(NSDictionary *)options
{
    [[FWNotificationManager sharedInstance] clearNotificationBadges];
    
    NSDictionary *remoteNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [[FWNotificationManager sharedInstance] handleRemoteNotification:remoteNotification];
    }
    NSDictionary *localNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [[FWNotificationManager sharedInstance] handleLocalNotification:localNotification];
    }
}

- (void)setupService
{
    [[FWNotificationManager sharedInstance] registerNotificationHandler];
    [[FWNotificationManager sharedInstance] requestAuthorize:nil];
    [FWNotificationManager sharedInstance].remoteNotificationHandler = ^(NSDictionary * userInfo, id notification) {
        NSString *title = nil;
        if ([notification isKindOfClass:[UNNotificationResponse class]]) {
            title = ((UNNotificationResponse *)notification).notification.request.content.title;
        }
        [[UIWindow fwMainWindow] fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"收到远程通知：%@\n%@", FWSafeString(title), userInfo]]];
        [[UIWindow fwMainWindow] fwHideToastAfterDelay:2.0 completion:nil];
    };
    [FWNotificationManager sharedInstance].localNotificationHandler = ^(NSDictionary * userInfo, id notification) {
        NSString *title = nil;
        if ([notification isKindOfClass:[UNNotificationResponse class]]) {
            title = ((UNNotificationResponse *)notification).notification.request.content.title;
        } else if ([notification isKindOfClass:[UILocalNotification class]]) {
            title = ((UILocalNotification *)notification).alertTitle ?: ((UILocalNotification *)notification).alertBody;
        }
        [[UIWindow fwMainWindow] fwShowToastWithAttributedText:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"收到本地通知：%@\n%@", FWSafeString(title), userInfo]]];
        [[UIWindow fwMainWindow] fwHideToastAfterDelay:2.0 completion:nil];
    };
    
    [[FWTabAnimated sharedAnimated] initWithOnlySkeleton];
    [FWTabAnimated sharedAnimated].closeCache = NO;
    [FWTabAnimated sharedAnimated].openLog = FWIsSimulator;
    [FWTabAnimated sharedAnimated].openAnimationTag = FWIsSimulator;
}

- (void)setupController
{
    [UIView fwAutoLayoutRTL:YES];
    [[UINavigationBar appearance] fwSetTextColor:[UIColor fwColorWithHex:0x111111]];
    
    // 优先查找非cancel按钮，找不到则默认cancel
    FWAlertAppearance.appearance.preferredActionBlock = ^UIAlertAction *(UIAlertController *alertController) {
        if (alertController.preferredStyle == UIAlertControllerStyleAlert) {
            for (UIAlertAction *alertAction in alertController.actions) {
                if (alertAction.style != UIAlertActionStyleCancel) {
                    return alertAction;
                }
            }
        }
        return alertController.actions.firstObject;
    };
    
    FWAlertAppearance.appearance.titleFont = [UIFont appFontSemiBoldSize:16];
    FWAlertAppearance.appearance.titleColor = [UIColor appColorHex:0x111111];
    FWAlertAppearance.appearance.messageFont = [UIFont appFontSize:13];
    FWAlertAppearance.appearance.messageColor = [UIColor appColorHex:0x111111];
    
    FWAlertAppearance.appearance.actionColor = [UIColor appColorHex:0xBFA300];
    FWAlertAppearance.appearance.actionFont = [UIFont appFontSize:16];
    FWAlertAppearance.appearance.preferredActionColor = [UIColor appColorHex:0xC69B00];
    FWAlertAppearance.appearance.preferredActionFont = [UIFont appFontSemiBoldSize:16];
    FWAlertAppearance.appearance.cancelActionColor = [UIColor appColorHex:0x111111];
    FWAlertAppearance.appearance.destructiveActionColor = [UIColor redColor];
    FWAlertAppearance.appearance.disabledActionColor = [UIColor lightGrayColor];
    
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
    
    UIViewController *settingsController = [SettingsViewController new];
    settingsController.hidesBottomBarWhenPushed = NO;
    settingsController.tabBarItem.image = [UIImage imageNamed:@"tabbar_settings"];
    settingsController.tabBarItem.title = @"设置";
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.delegate = self;
    tabBarController.definesPresentationContext = YES;
    tabBarController.viewControllers = @[homeNav, testNav, settingsController];
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
