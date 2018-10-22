//
//  UIWindow+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIWindow+FWFramework.h"

@implementation UIWindow (FWFramework)

+ (BOOL)fwHasSafeAreaInsets
{
    static BOOL hasSafeAreaInsets = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            UIWindow *mainWindow = [self fwMainWindow];
            if (mainWindow.safeAreaInsets.bottom > 0) {
                hasSafeAreaInsets = YES;
            }
        }
    });
    return hasSafeAreaInsets;
}

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

@end
