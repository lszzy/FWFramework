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
