//
//  UIWindow+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIWindow+FWFramework.h"

@implementation UIWindow (FWFramework)

- (UIViewController *)fwViewController
{
    UIViewController *currentViewController = [self fwTopMostController];
    
    while ([currentViewController isKindOfClass:[UITabBarController class]] &&
           [(UITabBarController *)currentViewController selectedViewController]) {
        currentViewController = [(UITabBarController *)currentViewController selectedViewController];
    }
    
    while ([currentViewController isKindOfClass:[UINavigationController class]] &&
           [(UINavigationController *)currentViewController topViewController]) {
        currentViewController = [(UINavigationController*)currentViewController topViewController];
    }
    
    return currentViewController;
}

- (UIViewController *)fwTopMostController
{
    UIViewController *topController = self.rootViewController;
    
    while ([topController presentedViewController]) {
        topController = [topController presentedViewController];
    }
    
    return topController;
}

@end
