/*!
 @header     FWNavigation.m
 @indexgroup FWFramework
 @brief      FWNavigation
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWNavigation.h"
#import <objc/runtime.h>

#pragma mark - UIWindow+FWNavigation

@implementation UIWindow (FWNavigation)

+ (UIWindow *)fwMainWindow
{
    UIWindow *mainWindow = UIApplication.sharedApplication.keyWindow;
    if (!mainWindow) {
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (window.isKeyWindow) { mainWindow = window; break; }
        }
    }
    
#ifdef DEBUG
    // DEBUG模式时兼容FLEX、FWDebug等组件
    if ([mainWindow isKindOfClass:NSClassFromString(@"FLEXWindow")] &&
        [mainWindow respondsToSelector:NSSelectorFromString(@"previousKeyWindow")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        mainWindow = [mainWindow performSelector:NSSelectorFromString(@"previousKeyWindow")];
#pragma clang diagnostic pop
    }
#endif
    return mainWindow;
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

+ (UIViewController *)fwTopViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *topController = [(UITabBarController *)viewController selectedViewController];
        if (topController) return [self fwTopViewController:topController];
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topController = [(UINavigationController *)viewController topViewController];
        if (topController) return [self fwTopViewController:topController];
    }
    
    return viewController;
}

- (UIViewController *)fwTopViewController
{
    return [UIWindow fwTopViewController:[self fwTopPresentedController]];
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

- (BOOL)fwPushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UINavigationController *navigationController = [self fwTopNavigationController];
    if (navigationController) {
        [navigationController pushViewController:viewController animated:animated];
        return YES;
    }
    return NO;
}

- (void)fwPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self fwTopPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[self fwTopViewController] fwOpenViewController:viewController animated:animated];
}

- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated
{
    return [[self fwTopViewController] fwCloseViewControllerAnimated:animated];
}

@end

#pragma mark - UIViewController+FWNavigation

@implementation UIViewController (FWNavigation)

- (BOOL)fwIsRoot
{
    return !self.navigationController || self.navigationController.viewControllers.firstObject == self;
}

- (BOOL)fwIsChild
{
    UIViewController *parentController = self.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)fwIsPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.navigationController ?: self;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated
{
    if (self.navigationController) {
        if ([self.navigationController popViewControllerAnimated:animated]) return YES;
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:animated completion:nil];
        return YES;
    }
    return NO;
}

@end

#pragma mark - UINavigationController+FWWorkflow

@implementation UIViewController (FWWorkflow)

@dynamic fwWorkflowName;

- (NSString *)fwWorkflowName
{
    NSString *workflowName = objc_getAssociatedObject(self, @selector(fwWorkflowName));
    if (!workflowName) {
        workflowName = [[[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""] stringByReplacingOccurrencesOfString:@"Controller" withString:@""] lowercaseString];
        objc_setAssociatedObject(self, @selector(fwWorkflowName), workflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return workflowName;
}

- (void)setFwWorkflowName:(NSString *)fwWorkflowName
{
    if (fwWorkflowName != self.fwWorkflowName) {
        [self willChangeValueForKey:@"fwWorkflowName"];
        objc_setAssociatedObject(self, @selector(fwWorkflowName), fwWorkflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [self didChangeValueForKey:@"fwWorkflowName"];
    }
}

@end

@implementation UINavigationController (FWWorkflow)

- (NSString *)fwTopWorkflowName
{
    return [self.topViewController fwWorkflowName];
}

- (void)fwPushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fwTopWorkflowName, nil];
    [self fwPushViewController:viewController popWorkflows:workflows animated:animated];
}

- (void)fwPushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated
{
    if (self.viewControllers.count < 2) {
        [self pushViewController:viewController animated:animated];
        return;
    }
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:self.viewControllers.firstObject];
    [viewControllers addObject:viewController];
    [self setViewControllers:viewControllers animated:animated];
}

- (void)fwPushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        [self pushViewController:viewController animated:animated];
        return;
    }
    
    // 从外到内查找移除的控制器列表
    NSMutableArray *popControllers = [NSMutableArray array];
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller fwWorkflowName];
        if (workflow.length > 0) {
            for (NSString *prefix in workflows) {
                if ([workflow hasPrefix:prefix]) {
                    isStop = NO;
                    break;
                }
            }
        }
        
        if (isStop) {
            *stop = YES;
        } else {
            [popControllers addObject:controller];
        }
    }];
    
    if (popControllers.count < 1) {
        [self pushViewController:viewController animated:animated];
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
        [viewControllers removeObjectsInArray:popControllers];
        [viewControllers addObject:viewController];
        [self setViewControllers:viewControllers animated:animated];
    }
}

- (void)fwPopTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fwTopWorkflowName, nil];
    [self fwPopWorkflows:workflows animated:animated];
}

- (void)fwPopWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        return;
    }
    
    // 从外到内查找停止目标控制器
    __block UIViewController *toController = nil;
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller fwWorkflowName];
        if (workflow.length > 0) {
            for (NSString *prefix in workflows) {
                if ([workflow hasPrefix:prefix]) {
                    isStop = NO;
                    break;
                }
            }
        }
        
        if (isStop) {
            toController = controller;
            *stop = YES;
        }
    }];
    
    if (toController) {
        [self popToViewController:toController animated:animated];
    } else {
        // 至少保留一个根控制器
        [self popToRootViewControllerAnimated:animated];
    }
}

@end
