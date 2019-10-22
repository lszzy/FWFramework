//
//  AppDelegate.m
//  Example2
//
//  Created by wuyong on 2019/10/17.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "AppDelegate.h"
#import "FlutterViewController.h"
#import "TestViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self setupController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)setupController
{
    FlutterViewController *flutterController = [FlutterViewController sharedInstance];
    // [flutterController setInitialRoute:@"route1"];
    flutterController.hidesBottomBarWhenPushed = NO;
    flutterController.tabBarItem.image = [UIImage imageNamed:@"tabbar_home"];
    flutterController.tabBarItem.title = @"首页";
    
    UIViewController *testController = [TestViewController new];
    testController.hidesBottomBarWhenPushed = NO;
    UINavigationController *testNav = [[UINavigationController alloc] initWithRootViewController:testController];
    testNav.tabBarItem.image = [UIImage imageNamed:@"tabbar_settings"];
    testNav.tabBarItem.title = @"测试";
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[flutterController, testNav];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = tabBarController;
}

@end
