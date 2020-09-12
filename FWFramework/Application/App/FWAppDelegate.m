/*!
 @header     FWAppDelegate.m
 @indexgroup FWFramework
 @brief      FWAppDelegate
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import "FWAppDelegate.h"

@interface FWAppDelegate ()

@end

@implementation FWAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupApplication:application options:launchOptions];
    [self setupService];
    [self setupAppearance];
    [self setupController];
    [self setupComponent];
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

/*
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [[FWNotificationManager sharedInstance] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}
*/

/*
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[FWNotificationManager sharedInstance] handleLocalNotification:notification];
}
*/

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [self handleOpenURL:url options:options];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        if (userActivity.webpageURL != nil) {
            return [self handleUserActivity:userActivity];
        }
    }
    return NO;
}

#pragma mark - Protected

- (void)setupApplication:(UIApplication *)application options:(NSDictionary *)options
{
    // [[FWNotificationManager sharedInstance] clearNotificationBadges];
    // NSDictionary *localNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    // NSDictionary *remoteNotification = (NSDictionary *)[options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
}

- (void)setupService
{
    // [[FWNotificationManager sharedInstance] registerNotificationHandler];
    // [[FWNotificationManager sharedInstance] requestAuthorize:nil];
}

- (void)setupAppearance
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
}

- (void)setupController
{
    // self.window.rootViewController = [TabBarController new];
}

- (void)setupComponent
{
    // 预加载启动广告，检查App更新等
}

- (void)setupDeviceToken:(NSData *)tokenData error:(NSError *)error
{
    // [UIDevice fwSetDeviceTokenData:tokenData];
}

- (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary *)options
{
    // [FWRouter openURL:url.absoluteString];
    return YES;
}

- (BOOL)handleUserActivity:(NSUserActivity *)userActivity
{
    return [self handleOpenURL:userActivity.webpageURL options:nil];
}

@end
