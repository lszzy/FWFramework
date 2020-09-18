/*!
 @header     FWWindow.m
 @indexgroup FWFramework
 @brief      FWWindow
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/18
 */

#import "FWWindow.h"

@implementation UIWindow (FWWindow)

+ (UIWindow *)fwMainWindow
{
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if (window) return window;
    
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) return window;
    }
    return nil;
}

+ (UIWindowScene *)fwMainScene
{
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
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
