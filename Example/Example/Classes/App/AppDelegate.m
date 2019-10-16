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

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    [self setupApplication:application options:launchOptions];
    [self setupService];
    [self setupController];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

#pragma mark - Notification

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self setupDeviceToken:deviceToken error:nil];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self setupDeviceToken:nil error:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[FWNotificationManager sharedInstance] handleLocalNotification:notification];
}

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [self handleOpenURL:url options:options];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self handleOpenURL:url options:nil];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [self handleOpenURL:url options:nil];
}

#pragma mark - Protected

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
}

- (void)setupController
{
    // 自动布局适配RTL
    [UIView fwAutoLayoutRTL:YES];
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
