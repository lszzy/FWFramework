//
//  UIWindow+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIWindow+FWFramework.h"

@implementation UIWindow (FWFramework)

+ (UIWindow *)fwMainWindow
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application.delegate respondsToSelector:@selector(window)]) {
        return [application.delegate window];
    } else {
        return [application keyWindow];
    }
}

- (UIViewController *)fwTopViewController
{
    UIViewController *viewController = [self fwTopPresentedController];
    
    while ([viewController isKindOfClass:[UITabBarController class]] &&
           [(UITabBarController *)viewController selectedViewController]) {
        viewController = [(UITabBarController *)viewController selectedViewController];
    }
    
    while ([viewController isKindOfClass:[UINavigationController class]] &&
           [(UINavigationController *)viewController topViewController]) {
        viewController = [(UINavigationController*)viewController topViewController];
    }
    
    return viewController;
}

- (UINavigationController *)fwTopNavigationController
{
    return [self fwTopViewController].navigationController;
}

- (UIViewController *)fwTopPresentedController
{
    UIViewController *presentedController = self.rootViewController;
    
    while ([presentedController presentedViewController]) {
        presentedController = [presentedController presentedViewController];
    }
    
    return presentedController;
}

- (BOOL)fwPushViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    UINavigationController *navigationController = [self fwTopNavigationController];
    if (navigationController) {
        [navigationController pushViewController:viewController animated:animated];
        return YES;
    }
    return NO;
}

- (void)fwPresentViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(void (^)(void))completion
{
    [[self fwTopPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)fwDismissViewControllers:(void (^)(void))completion
{
    if (self.rootViewController.presentedViewController) {
        [self.rootViewController dismissViewControllerAnimated:YES completion:completion];
    } else {
        if (completion) completion();
    }
}

- (UIViewController *)fwSelectTabBarController:(Class)viewController
{
    if (![self.rootViewController isKindOfClass:[UITabBarController class]]) return nil;
    
    UINavigationController *targetNavigation = nil;
    UITabBarController *tabbarController = (UITabBarController *)self.rootViewController;
    for (UINavigationController *navigationController in tabbarController.viewControllers) {
        if ([navigationController isKindOfClass:viewController] ||
            ([navigationController isKindOfClass:[UINavigationController class]] &&
             [navigationController.viewControllers.firstObject isKindOfClass:viewController])) {
            targetNavigation = navigationController;
            break;
        }
    }
    if (!targetNavigation) return nil;
    
    UINavigationController *currentNavigation = tabbarController.selectedViewController;
    if (currentNavigation != targetNavigation) {
        if ([currentNavigation isKindOfClass:[UINavigationController class]] &&
            currentNavigation.viewControllers.count > 1) {
            [currentNavigation popToRootViewControllerAnimated:NO];
        }
        tabbarController.selectedViewController = targetNavigation;
    }
    
    UIViewController *targetController = targetNavigation;
    if ([targetNavigation isKindOfClass:[UINavigationController class]]) {
        targetController = targetNavigation.viewControllers.firstObject;
        if (targetNavigation.viewControllers.count > 1) {
            [targetNavigation popToRootViewControllerAnimated:NO];
        }
    }
    return targetController;
}

@end
