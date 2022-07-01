/**
 @header     FWNavigation.m
 @indexgroup FWFramework
      FWNavigation
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWNavigation.h"
#import <objc/runtime.h>

#pragma mark - UIWindow+FWNavigation

@implementation UIWindow (FWNavigation)

- (UIViewController *)fw_topViewController
{
    return [self fw_topViewController:[self fw_topPresentedController]];
}

- (UIViewController *)fw_topViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *topController = [(UITabBarController *)viewController selectedViewController];
        if (topController) return [self fw_topViewController:topController];
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topController = [(UINavigationController *)viewController topViewController];
        if (topController) return [self fw_topViewController:topController];
    }
    
    return viewController;
}

- (UINavigationController *)fw_topNavigationController
{
    return [self fw_topViewController].navigationController;
}

- (UIViewController *)fw_topPresentedController
{
    UIViewController *presentedController = self.rootViewController;
    
    while ([presentedController presentedViewController]) {
        presentedController = [presentedController presentedViewController];
    }
    
    return presentedController;
}

- (BOOL)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UINavigationController *navigationController = [self fw_topNavigationController];
    if (navigationController) {
        [navigationController pushViewController:viewController animated:animated];
        return YES;
    }
    return NO;
}

- (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self fw_topPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[self fw_topViewController] fw_openViewController:viewController animated:animated];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [[self fw_topViewController] fw_closeViewControllerAnimated:animated];
}

+ (UIWindow *)fw_mainWindow
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

+ (UIWindowScene *)fw_mainScene
{
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (UIViewController *)fw_topViewController
{
    return [self.fw_mainWindow fw_topViewController];
}

+ (UINavigationController *)fw_topNavigationController
{
    return [self.fw_mainWindow fw_topNavigationController];
}

+ (UIViewController *)fw_topPresentedController
{
    return [self.fw_mainWindow fw_topPresentedController];
}

+ (BOOL)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    return [self.fw_mainWindow fw_pushViewController:viewController animated:animated];
}

+ (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self.fw_mainWindow fw_presentViewController:viewController animated:animated completion:completion];
}

+ (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.fw_mainWindow fw_openViewController:viewController animated:animated];
}

+ (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [self.fw_mainWindow fw_closeViewControllerAnimated:animated];
}

@end

#pragma mark - UIViewController+FWNavigation

@implementation UIViewController (FWNavigation)

#pragma mark - Navigation

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
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

#pragma mark - Workflow

@dynamic fw_workflowName;

- (NSString *)fw_workflowName
{
    NSString *workflowName = objc_getAssociatedObject(self, @selector(fw_workflowName));
    if (!workflowName) {
        workflowName = [[[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""] stringByReplacingOccurrencesOfString:@"Controller" withString:@""] lowercaseString];
        objc_setAssociatedObject(self, @selector(fw_workflowName), workflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return workflowName;
}

- (void)setFw_workflowName:(NSString *)workflowName
{
    if (workflowName != self.fw_workflowName) {
        objc_setAssociatedObject(self, @selector(fw_workflowName), workflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

@end

#pragma mark - UINavigationController+FWNavigation

@implementation UINavigationController (FWNavigation)

#pragma mark - Navigation

- (void)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [CATransaction setCompletionBlock:completion];
    [CATransaction begin];
    [self pushViewController:viewController animated:animated];
    [CATransaction commit];
}

- (UIViewController *)fw_popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIViewController *viewController;
    [CATransaction setCompletionBlock:completion];
    [CATransaction begin];
    viewController = [self popViewControllerAnimated:animated];
    [CATransaction commit];
    return viewController;
}

- (NSArray<__kindof UIViewController *> *)fw_popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray<UIViewController *> *viewControllers;
    [CATransaction setCompletionBlock:completion];
    [CATransaction begin];
    viewControllers = [self popToViewController:viewController animated:animated];
    [CATransaction commit];
    return viewControllers;
}

- (NSArray<__kindof UIViewController *> *)fw_popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray<UIViewController *> *viewControllers;
    [CATransaction setCompletionBlock:completion];
    [CATransaction begin];
    viewControllers = [self popToRootViewControllerAnimated:animated];
    [CATransaction commit];
    return viewControllers;
}

- (void)fw_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated completion:(void (^)(void))completion
{
    [CATransaction setCompletionBlock:completion];
    [CATransaction begin];
    [self setViewControllers:viewControllers animated:animated];
    [CATransaction commit];
}

#pragma mark - Workflow

- (NSString *)fw_topWorkflowName
{
    return [self.topViewController fw_workflowName];
}

- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_pushViewController:viewController popWorkflows:workflows animated:animated];
}

- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated
{
    if (self.viewControllers.count < 2) {
        [self pushViewController:viewController animated:animated];
        return;
    }
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:self.viewControllers.firstObject];
    [viewControllers addObject:viewController];
    [self setViewControllers:viewControllers animated:animated];
}

- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        [self pushViewController:viewController animated:animated];
        return;
    }
    
    // 从外到内查找移除的控制器列表
    NSMutableArray *popControllers = [NSMutableArray array];
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller fw_workflowName];
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

- (void)fw_popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_popWorkflows:workflows animated:animated];
}

- (void)fw_popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        return;
    }
    
    // 从外到内查找停止目标控制器
    __block UIViewController *toController = nil;
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller fw_workflowName];
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
