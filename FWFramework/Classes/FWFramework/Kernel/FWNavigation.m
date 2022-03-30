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

#pragma mark - FWWindowWrapper+FWNavigation

@implementation FWWindowWrapper (FWNavigation)

- (UIViewController *)topViewController
{
    return [self topViewController:[self topPresentedController]];
}

- (UIViewController *)topViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *topController = [(UITabBarController *)viewController selectedViewController];
        if (topController) return [self topViewController:topController];
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topController = [(UINavigationController *)viewController topViewController];
        if (topController) return [self topViewController:topController];
    }
    
    return viewController;
}

- (UINavigationController *)topNavigationController
{
    return [self topViewController].navigationController;
}

- (UIViewController *)topPresentedController
{
    UIViewController *presentedController = self.base.rootViewController;
    
    while ([presentedController presentedViewController]) {
        presentedController = [presentedController presentedViewController];
    }
    
    return presentedController;
}

- (BOOL)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UINavigationController *navigationController = [self topNavigationController];
    if (navigationController) {
        [navigationController pushViewController:viewController animated:animated];
        return YES;
    }
    return NO;
}

- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self topPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[self topViewController].fw openViewController:viewController animated:animated];
}

- (BOOL)closeViewControllerAnimated:(BOOL)animated
{
    return [[self topViewController].fw closeViewControllerAnimated:animated];
}

@end

#pragma mark - FWWindowClassWrapper+FWNavigation

@implementation FWWindowClassWrapper (FWNavigation)

- (UIWindow *)mainWindow
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

- (UIWindowScene *)mainScene
{
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.mainWindow.fw pushViewController:viewController animated:animated];
}

- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self.mainWindow.fw presentViewController:viewController animated:animated completion:completion];
}

- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.mainWindow.fw openViewController:viewController animated:animated];
}

- (BOOL)closeViewControllerAnimated:(BOOL)animated
{
    return [self.mainWindow.fw closeViewControllerAnimated:animated];
}

@end

#pragma mark - FWViewControllerWrapper+FWNavigation

@implementation FWViewControllerWrapper (FWNavigation)

- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.base.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self.base presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.base.navigationController pushViewController:viewController animated:animated];
    }
}

- (BOOL)closeViewControllerAnimated:(BOOL)animated
{
    if (self.base.navigationController) {
        if ([self.base.navigationController popViewControllerAnimated:animated]) return YES;
    }
    if (self.base.presentingViewController) {
        [self.base dismissViewControllerAnimated:animated completion:nil];
        return YES;
    }
    return NO;
}

@end

#pragma mark - FWViewControllerWrapper+FWWorkflow

@implementation FWViewControllerWrapper (FWWorkflow)

@dynamic workflowName;

- (NSString *)workflowName
{
    NSString *workflowName = objc_getAssociatedObject(self.base, @selector(workflowName));
    if (!workflowName) {
        workflowName = [[[NSStringFromClass([self.base class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""] stringByReplacingOccurrencesOfString:@"Controller" withString:@""] lowercaseString];
        objc_setAssociatedObject(self.base, @selector(workflowName), workflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return workflowName;
}

- (void)setWorkflowName:(NSString *)workflowName
{
    if (workflowName != self.workflowName) {
        objc_setAssociatedObject(self.base, @selector(workflowName), workflowName, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

@end

#pragma mark - FWNavigationControllerWrapper+FWWorkflow

@implementation FWNavigationControllerWrapper (FWWorkflow)

- (NSString *)topWorkflowName
{
    return [self.base.topViewController.fw workflowName];
}

- (void)pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.topWorkflowName, nil];
    [self pushViewController:viewController popWorkflows:workflows animated:animated];
}

- (void)pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated
{
    if (self.base.viewControllers.count < 2) {
        [self.base pushViewController:viewController animated:animated];
        return;
    }
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:self.base.viewControllers.firstObject];
    [viewControllers addObject:viewController];
    [self.base setViewControllers:viewControllers animated:animated];
}

- (void)pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        [self.base pushViewController:viewController animated:animated];
        return;
    }
    
    // 从外到内查找移除的控制器列表
    NSMutableArray *popControllers = [NSMutableArray array];
    [self.base.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller.fw workflowName];
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
        [self.base pushViewController:viewController animated:animated];
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.base.viewControllers];
        [viewControllers removeObjectsInArray:popControllers];
        [viewControllers addObject:viewController];
        [self.base setViewControllers:viewControllers animated:animated];
    }
}

- (void)popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.topWorkflowName, nil];
    [self popWorkflows:workflows animated:animated];
}

- (void)popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        return;
    }
    
    // 从外到内查找停止目标控制器
    __block UIViewController *toController = nil;
    [self.base.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = YES;
        
        NSString *workflow = [controller.fw workflowName];
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
        [self.base popToViewController:toController animated:animated];
    } else {
        // 至少保留一个根控制器
        [self.base popToRootViewControllerAnimated:animated];
    }
}

@end
