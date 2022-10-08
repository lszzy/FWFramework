//
//  FWNavigator.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWNavigator.h"
#import <objc/runtime.h>

#pragma mark - FWNavigator

@implementation FWNavigator

+ (UIViewController *)topViewController
{
    return [UIWindow.fw_mainWindow fw_topViewController];
}

+ (UINavigationController *)topNavigationController
{
    return [UIWindow.fw_mainWindow fw_topNavigationController];
}

+ (UIViewController *)topPresentedController
{
    return [UIWindow.fw_mainWindow fw_topPresentedController];
}

+ (BOOL)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    return [UIWindow.fw_mainWindow fw_pushViewController:viewController animated:animated];
}

+ (BOOL)pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated
{
    return [UIWindow.fw_mainWindow fw_pushViewController:viewController pop:count animated:animated];
}

+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [UIWindow.fw_mainWindow fw_presentViewController:viewController animated:animated completion:completion];
}

+ (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    [UIWindow.fw_mainWindow fw_openViewController:viewController animated:animated options:options completion:completion];
}

+ (BOOL)closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    return [UIWindow.fw_mainWindow fw_closeViewControllerAnimated:animated options:options completion:completion];
}

@end

#pragma mark - UIWindow+FWNavigator

@implementation UIWindow (FWNavigator)

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

- (BOOL)fw_pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated
{
    UINavigationController *navigationController = [self fw_topNavigationController];
    if (navigationController) {
        [navigationController fw_pushViewController:viewController pop:count animated:animated completion:nil];
        return YES;
    }
    return NO;
}

- (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self fw_topPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    [[self fw_topViewController] fw_openViewController:viewController animated:animated options:options completion:completion];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    return [[self fw_topViewController] fw_closeViewControllerAnimated:animated options:options completion:completion];
}

@end

#pragma mark - UIViewController+FWNavigator

@implementation UIViewController (FWNavigator)

#pragma mark - Navigator

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self fw_openViewController:viewController animated:animated options:0 completion:nil];
}

- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    BOOL isNavigation = [viewController isKindOfClass:[UINavigationController class]];
    if ((options & FWNavigatorOptionEmbedInNavigation) == FWNavigatorOptionEmbedInNavigation) {
        if (!isNavigation) {
            viewController = [[UINavigationController alloc] initWithRootViewController:viewController];
            isNavigation = YES;
        }
    }
    
    if ((options & FWNavigatorOptionStyleFullScreen) == FWNavigatorOptionStyleFullScreen) {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    } else if ((options & FWNavigatorOptionStylePageSheet) == FWNavigatorOptionStylePageSheet) {
        viewController.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    
    BOOL isPush = NO;
    if ((options & FWNavigatorOptionTransitionPush) == FWNavigatorOptionTransitionPush) {
        isPush = YES;
    } else if ((options & FWNavigatorOptionTransitionPresent) == FWNavigatorOptionTransitionPresent) {
        isPush = NO;
    } else {
        isPush = self.navigationController ? YES : NO;
    }
    if (isNavigation) isPush = NO;
    
    if (isPush) {
        NSUInteger popCount = [self fw_popCountForOptions:options];
        [self.navigationController fw_pushViewController:viewController pop:popCount animated:animated completion:completion];
    } else {
        [self presentViewController:viewController animated:animated completion:completion];
    }
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated
{
    return [self fw_closeViewControllerAnimated:animated options:0 completion:nil];
}

- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(void (^)(void))completion
{
    BOOL isPop = NO;
    BOOL isDismiss = NO;
    if ((options & FWNavigatorOptionTransitionPop) == FWNavigatorOptionTransitionPop) {
        isPop = YES;
    } else if ((options & FWNavigatorOptionTransitionDismiss) == FWNavigatorOptionTransitionDismiss) {
        isDismiss = YES;
    } else {
        if (self.navigationController.viewControllers.count > 1) {
            isPop = YES;
        } else if (self.presentingViewController) {
            isDismiss = YES;
        }
    }
    
    if (isPop) {
        NSUInteger popCount = MAX(1, [self fw_popCountForOptions:options]);
        if ([self.navigationController fw_popViewControllers:popCount animated:animated completion:completion]) return YES;
    } else if (isDismiss) {
        [self dismissViewControllerAnimated:animated completion:completion];
        return YES;
    }
    return NO;
}

- (NSUInteger)fw_popCountForOptions:(FWNavigatorOptions)options {
    NSUInteger popCount = 0;
    // 优先级：7 > 6、5、3 > 4、2、1
    if ((options & FWNavigatorOptionPopToRoot) == FWNavigatorOptionPopToRoot) {
        popCount = NSUIntegerMax;
    } else if ((options & FWNavigatorOptionPopTop6) == FWNavigatorOptionPopTop6) {
        popCount = 6;
    } else if ((options & FWNavigatorOptionPopTop5) == FWNavigatorOptionPopTop5) {
        popCount = 5;
    } else if ((options & FWNavigatorOptionPopTop3) == FWNavigatorOptionPopTop3) {
        popCount = 3;
    } else if ((options & FWNavigatorOptionPopTop4) == FWNavigatorOptionPopTop4) {
        popCount = 4;
    } else if ((options & FWNavigatorOptionPopTop2) == FWNavigatorOptionPopTop2) {
        popCount = 2;
    } else if ((options & FWNavigatorOptionPopTop) == FWNavigatorOptionPopTop) {
        popCount = 1;
    }
    return popCount;
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

#pragma mark - UINavigationController+FWNavigator

@implementation UINavigationController (FWNavigator)

#pragma mark - Navigator

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

- (void)fw_pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (count < 1 || self.viewControllers.count < 2) {
        [self fw_pushViewController:viewController animated:animated completion:completion];
        return;
    }
    
    NSUInteger remainCount = self.viewControllers.count > count ? self.viewControllers.count - count : 1;
    NSMutableArray *viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(0, remainCount)].mutableCopy;
    [viewControllers addObject:viewController];
    [self fw_setViewControllers:viewControllers animated:animated completion:completion];
}

- (NSArray<__kindof UIViewController *> *)fw_popViewControllers:(NSUInteger)count animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (count < 1 || self.viewControllers.count < 2) {
        if (completion) completion();
        return nil;
    }
    
    NSInteger toIndex = MAX(self.viewControllers.count - count - 1, 0);
    UIViewController *toController = [self.viewControllers objectAtIndex:toIndex];
    return [self fw_popToViewController:toController animated:animated completion:completion];
}

#pragma mark - Workflow

- (NSString *)fw_topWorkflowName
{
    return [self.topViewController fw_workflowName];
}

- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_pushViewController:viewController popWorkflows:workflows animated:animated completion:completion];
}

- (void)fw_pushViewController:(UIViewController *)viewController popToWorkflow:(NSString *)workflow animated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:workflow, nil];
    [self fw_pushViewController:viewController popWorkflows:workflows isMatch:NO animated:animated completion:completion];
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

- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self fw_pushViewController:viewController popWorkflows:workflows isMatch:YES animated:animated completion:completion];
}

- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows isMatch:(BOOL)isMatch animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (workflows.count < 1) {
        [self fw_pushViewController:viewController animated:animated completion:completion];
        return;
    }
    
    // 从外到内查找移除的控制器列表
    NSMutableArray *popControllers = [NSMutableArray array];
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = isMatch;
        NSString *workflow = [controller fw_workflowName];
        if (workflow.length > 0) {
            for (NSString *prefix in workflows) {
                if ([workflow hasPrefix:prefix]) {
                    isStop = !isMatch;
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

- (void)fw_popTopWorkflowAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fw_topWorkflowName, nil];
    [self fw_popWorkflows:workflows animated:animated completion:completion];
}

- (void)fw_popToWorkflow:(NSString *)workflow animated:(BOOL)animated completion:(void (^)(void))completion
{
    NSArray *workflows = [NSArray arrayWithObjects:workflow, nil];
    [self fw_popWorkflows:workflows isMatch:NO animated:animated completion:completion];
}

- (void)fw_popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(void (^)(void))completion
{
    [self fw_popWorkflows:workflows isMatch:YES animated:animated completion:completion];
}

- (void)fw_popWorkflows:(NSArray<NSString *> *)workflows isMatch:(BOOL)isMatch animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (workflows.count < 1) {
        if (completion) completion();
        return;
    }
    
    // 从外到内查找停止目标控制器
    __block UIViewController *toController = nil;
    [self.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
        BOOL isStop = isMatch;
        NSString *workflow = [controller fw_workflowName];
        if (workflow.length > 0) {
            for (NSString *prefix in workflows) {
                if ([workflow hasPrefix:prefix]) {
                    isStop = !isMatch;
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
