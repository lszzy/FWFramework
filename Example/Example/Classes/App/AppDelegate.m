//
//  AppDelegate.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "AppDelegate.h"
#import "ObjcController.h"
#import "TestViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.window.rootViewController = [self tabBarController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

- (UITabBarController *)tabBarController
{
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:[ObjcController new]];
    homeNav.tabBarItem.title = @"首页";
    
    UINavigationController *testNav = [[UINavigationController alloc] initWithRootViewController:[TestViewController new]];
    testNav.tabBarItem.title = @"测试";
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[homeNav, testNav];
    return tabBarController;
}

@end
