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
    [self fw_openViewController:viewController animated:animated completion:nil];
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self fw_topViewController] fw_openViewController:viewController animated:animated completion:completion];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [self fw_closeViewControllerAnimated:animated completion:nil];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    return [[self fw_topViewController] fw_closeViewControllerAnimated:animated completion:completion];
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
    [self fw_openViewController:viewController animated:animated completion:nil];
}

+ (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self.fw_mainWindow fw_openViewController:viewController animated:animated completion:completion];
}

+ (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [self fw_closeViewControllerAnimated:animated completion:nil];
}

+ (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    return [self.fw_mainWindow fw_closeViewControllerAnimated:animated completion:completion];
}

@end

#pragma mark - UIViewController+FWNavigation

@implementation UIViewController (FWNavigation)

#pragma mark - Navigation

- (FWNavigationOptions)fw_navigationOptions
{
    return [objc_getAssociatedObject(self, @selector(fw_navigationOptions)) unsignedIntegerValue];
}

- (void)setFw_navigationOptions:(FWNavigationOptions)navigationOptions
{
    objc_setAssociatedObject(self, @selector(fw_navigationOptions), @(navigationOptions), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self fw_openViewController:viewController animated:animated completion:nil];
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    FWNavigationOptions options = self.fw_navigationOptions;
    BOOL isNavigation = [viewController isKindOfClass:[UINavigationController class]];
    if ((options & FWNavigationOptionNavigation) == FWNavigationOptionNavigation) {
        if (!isNavigation) {
            viewController = [[UINavigationController alloc] initWithRootViewController:viewController];
            isNavigation = YES;
        }
    }
    
    if ((options & FWNavigationOptionFullScreen) == FWNavigationOptionFullScreen) {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    } else if ((options & FWNavigationOptionPageSheet) == FWNavigationOptionPageSheet) {
        viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    
    BOOL isPush = NO;
    if ((options & FWNavigationOptionPush) == FWNavigationOptionPush) {
        isPush = YES;
    } else if ((options & FWNavigationOptionPresent) == FWNavigationOptionPresent) {
        isPush = NO;
    } else {
        isPush = self.navigationController ? YES : NO;
    }
    if (isNavigation) isPush = NO;
    
    if (isPush) {
        if ((options & FWNavigationOptionPopToRoot) == FWNavigationOptionPopToRoot) {
            NSMutableArray *viewControllers = [NSMutableArray arrayWithObjects:self.navigationController.viewControllers.firstObject, nil];
            [viewControllers addObject:viewController];
            [self.navigationController fw_setViewControllers:viewControllers animated:animated completion:completion];
        } else if ((options & FWNavigationOptionPopTop) == FWNavigationOptionPopTop) {
            NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
            [viewControllers removeLastObject];
            [viewControllers addObject:viewController];
            [self.navigationController fw_setViewControllers:viewControllers animated:animated completion:completion];
        } else {
            [self.navigationController fw_pushViewController:viewController animated:animated completion:completion];
        }
    } else {
        [self presentViewController:viewController animated:animated completion:completion];
    }
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [self fw_closeViewControllerAnimated:animated completion:nil];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.navigationController) {
        if ([self.navigationController fw_popViewControllerAnimated:animated completion:completion]) return YES;
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:animated completion:completion];
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
    if (completion) {
        [CATransaction setCompletionBlock:completion];
        [CATransaction begin];
        [self pushViewController:viewController animated:animated];
        [CATransaction commit];
    } else {
        [self pushViewController:viewController animated:animated];
    }
}

- (UIViewController *)fw_popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    UIViewController *viewController;
    if (completion) {
        [CATransaction setCompletionBlock:completion];
        [CATransaction begin];
        viewController = [self popViewControllerAnimated:animated];
        [CATransaction commit];
    } else {
        viewController = [self popViewControllerAnimated:animated];
    }
    return viewController;
}

- (NSArray<__kindof UIViewController *> *)fw_popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray<UIViewController *> *viewControllers;
    if (completion) {
        [CATransaction setCompletionBlock:completion];
        [CATransaction begin];
        viewControllers = [self popToViewController:viewController animated:animated];
        [CATransaction commit];
    } else {
        viewControllers = [self popToViewController:viewController animated:animated];
    }
    return viewControllers;
}

- (NSArray<__kindof UIViewController *> *)fw_popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray<UIViewController *> *viewControllers;
    if (completion) {
        [CATransaction setCompletionBlock:completion];
        [CATransaction begin];
        viewControllers = [self popToRootViewControllerAnimated:animated];
        [CATransaction commit];
    } else {
        viewControllers = [self popToRootViewControllerAnimated:animated];
    }
    return viewControllers;
}

- (void)fw_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (completion) {
        [CATransaction setCompletionBlock:completion];
        [CATransaction begin];
        [self setViewControllers:viewControllers animated:animated];
        [CATransaction commit];
    } else {
        [self setViewControllers:viewControllers animated:animated];
    }
}

#pragma mark - Workflow

- (NSString *)fw_topWorkflowName
{
    return [self.topViewController fw_workflowName];
}

- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated
{
    [self fw_pushViewController:viewController popTopWorkflowAnimated:animated completion:nil];
}

- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_pushViewController:viewController popWorkflows:workflows animated:animated];
}

- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated
{
    [self fw_pushViewController:viewController popToRootWorkflowAnimated:animated completion:nil];
}

- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.viewControllers.count < 2) {
        [self fw_pushViewController:viewController animated:animated completion:completion];
        return;
    }
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithObject:self.viewControllers.firstObject];
    [viewControllers addObject:viewController];
    [self fw_setViewControllers:viewControllers animated:animated completion:completion];
}

- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    [self fw_pushViewController:viewController popWorkflows:workflows animated:animated completion:nil];
}

- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (workflows.count < 1) {
        [self fw_pushViewController:viewController animated:animated completion:completion];
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
        [self fw_pushViewController:viewController animated:animated completion:completion];
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
        [viewControllers removeObjectsInArray:popControllers];
        [viewControllers addObject:viewController];
        [self fw_setViewControllers:viewControllers animated:animated completion:completion];
    }
}

- (void)fw_popTopWorkflowAnimated:(BOOL)animated
{
    [self fw_popTopWorkflowAnimated:animated completion:nil];
}

- (void)fw_popTopWorkflowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_popWorkflows:workflows animated:animated];
}

- (void)fw_popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    [self fw_popWorkflows:workflows animated:animated completion:nil];
}

- (void)fw_popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(void (^)(void))completion
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
        [self fw_popToViewController:toController animated:animated completion:completion];
    } else {
        // 至少保留一个根控制器
        [self fw_popToRootViewControllerAnimated:animated completion:completion];
    }
}

@end
