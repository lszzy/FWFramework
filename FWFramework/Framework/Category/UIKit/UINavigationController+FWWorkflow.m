/*!
 @header     UINavigationController+FWWorkflow.m
 @indexgroup FWFramework
 @brief      导航栏控制器工作流分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import "UINavigationController+FWWorkflow.h"
#import <objc/runtime.h>

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
        objc_setAssociatedObject(self, @selector(fwWorkflowName), fwWorkflowName, fwWorkflowName ? OBJC_ASSOCIATION_COPY_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwWorkflowName"];
    }
}

- (void)fwOpenViewController:(UIViewController *)viewController
{
    [self fwOpenViewController:viewController animated:YES];
}

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

- (void)fwCloseViewController
{
    [self fwCloseViewControllerAnimated:YES];
}

- (void)fwCloseViewControllerAnimated:(BOOL)animated
{
    if (self.navigationController) {
        UIViewController *viewController = [self.navigationController popViewControllerAnimated:animated];
        // 如果已经是导航栏底部，则尝试dismiss当前控制器
        if (!viewController && self.presentingViewController) {
            [self dismissViewControllerAnimated:animated completion:nil];
        }
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

@end

@implementation UINavigationController (FWWorkflow)

- (NSString *)fwTopWorkflowName
{
    return [self.topViewController fwWorkflowName];
}

- (NSArray<UIViewController *> *)fwPushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fwTopWorkflowName, nil];
    return [self fwPushViewController:viewController popWorkflows:workflows animated:animated];
}

- (NSArray<UIViewController *> *)fwPushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        [self pushViewController:viewController animated:animated];
        return nil;
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
        return nil;
    } else {
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
        [viewControllers removeObjectsInArray:popControllers];
        [viewControllers addObject:viewController];
        [self setViewControllers:viewControllers animated:animated];
        return popControllers;
    }
}

- (NSArray<UIViewController *> *)fwPopTopWorkflowAnimated:(BOOL)animated
{
    NSArray *workflows = [NSArray arrayWithObjects:self.fwTopWorkflowName, nil];
    return [self fwPopWorkflows:workflows animated:animated];
}

- (NSArray<UIViewController *> *)fwPopWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated
{
    if (workflows.count < 1) {
        return nil;
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
        return [self popToViewController:toController animated:animated];
    } else {
        // 至少保留一个根控制器
        return [self popToRootViewControllerAnimated:animated];
    }
}

@end
