//
//  AppDelegate.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "AppDelegate.h"
#import "TabBarController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark - UISceneSession

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options API_AVAILABLE(ios(13.0)){
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions API_AVAILABLE(ios(13.0)){
    
}

#pragma mark - Notification

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[FWNotificationManager sharedInstance] handleLocalNotification:notification];
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
        if (@available(iOS 10.0, *)) {
            if ([notification isKindOfClass:[UNNotificationResponse class]]) {
                title = ((UNNotificationResponse *)notification).notification.request.content.title;
            }
        }
        [UIWindow.fwMainWindow fwShowMessageWithText:[NSString stringWithFormat:@"收到远程通知：%@\n%@", FWSafeString(title), userInfo]];
    };
    [FWNotificationManager sharedInstance].localNotificationHandler = ^(NSDictionary * userInfo, id notification) {
        NSString *title = nil;
        if (@available(iOS 10.0, *)) {
            if ([notification isKindOfClass:[UNNotificationResponse class]]) {
                title = ((UNNotificationResponse *)notification).notification.request.content.title;
            }
        } else {
            if ([notification isKindOfClass:[UILocalNotification class]]) {
                title = ((UILocalNotification *)notification).alertTitle ?: ((UILocalNotification *)notification).alertBody;
            }
        }
        [UIWindow.fwMainWindow fwShowMessageWithText:[NSString stringWithFormat:@"收到本地通知：%@\n%@", FWSafeString(title), userInfo]];
    };
}

- (void)setupAppearance
{
    // 导航栏样式
    FWNavigationBarConfig *config = [[FWNavigationBarConfig alloc] initWithBackgroundColor:[UIColor fwColorWithHex:0xFFDA00] foregroundColor:[UIColor fwColorWithHex:0x111111] configBlock:nil];
    [FWNavigationBarConfig setConfig:config forStyle:FWNavigationBarStyleDefault];
    
    // 优先查找非cancel按钮，找不到则默认cancel
    FWAlertAppearance.appearance.preferredActionBlock = ^UIAlertAction *(UIAlertController *alertController) {
        return alertController.actions.firstObject;
    };
    
    FWAlertAppearance.appearance.titleFont = [UIFont appFontSemiBoldSize:16];
    FWAlertAppearance.appearance.titleColor = [UIColor appColorHex:0x111111];
    FWAlertAppearance.appearance.messageFont = [UIFont appFontSize:13];
    FWAlertAppearance.appearance.messageColor = [UIColor appColorHex:0x111111];
    
    FWAlertAppearance.appearance.actionColor = [UIColor appColorHex:0xBFA300];
    FWAlertAppearance.appearance.preferredActionColor = [UIColor appColorHex:0xC69B00];
    FWAlertAppearance.appearance.cancelActionColor = [UIColor appColorHex:0x111111];
    FWAlertAppearance.appearance.destructiveActionColor = [UIColor redColor];
    FWAlertAppearance.appearance.disabledActionColor = [UIColor lightGrayColor];
    
    FWAlertStyle.appearance.lineColor = [UIColor appColorHex:0xDDDDDD];
    FWAlertStyle.appearance.contentInsets = UIEdgeInsetsMake(32, 16, 24, 16);
    FWAlertStyle.appearance.actionFont = [UIFont appFontSize:16];
    FWAlertStyle.appearance.actionBoldFont = [UIFont appFontSemiBoldSize:16];
}

- (void)setupController
{
    // iOS13以前使用旧的方式
    if (@available(iOS 13.0, *)) { } else {
        if (!self.window) {
            self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [self.window makeKeyAndVisible];
        }
        
        self.window.backgroundColor = [UIColor whiteColor];
        self.window.rootViewController = [TabBarController new];
    }
}

- (void)setupComponent
{
    // 预加载启动广告，检查App更新等
}

- (void)setupDeviceToken:(NSData *)tokenData error:(NSError *)error
{
    [UIDevice fwSetDeviceTokenData:tokenData];
}

- (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary *)options
{
    [FWRouter openURL:url.absoluteString];
    return YES;
}

@end
