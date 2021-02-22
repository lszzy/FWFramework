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

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [FWRouter openURL:url.absoluteString];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] &&
        userActivity.webpageURL != nil) {
        [FWRouter openURL:userActivity.webpageURL.absoluteString];
        return YES;
    }
    return NO;
}

#pragma mark - Protected

- (void)setupController
{
    // iOS13以前使用旧的方式
    if (@available(iOS 13.0, *)) { return; }
    
    if (!self.window) {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.backgroundColor = [Theme backgroundColor];
        [self.window makeKeyAndVisible];
    }
    self.window.rootViewController = [UITabBarController setupController];
}

@end
