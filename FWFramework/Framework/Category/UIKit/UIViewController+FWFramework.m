//
//  UIViewController+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWFramework.h"
#import "UIView+FWAutoLayout.h"

@implementation UIViewController (FWFramework)

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) {
            return NO;
        }
        viewController = self.navigationController;
    }
    BOOL result = viewController.presentingViewController.presentedViewController == viewController;
    return result;
}

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
}

- (void)fwShowPopupView:(UIView *)popupView
{
    UIView *superview = self.tabBarController.view ?: (self.navigationController.view ?: self.view);
    [superview addSubview:popupView];
    [popupView fwPinEdgesToSuperview];
}

- (void)fwHidePopupView:(UIView *)popupView
{
    [popupView removeFromSuperview];
}

#pragma mark - Action

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
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

#pragma mark - Child

- (UIViewController *)fwChildViewController
{
    return [self.childViewControllers firstObject];
}

- (void)fwSetChildViewController:(UIViewController *)viewController
{
    // 移除旧的控制器
    UIViewController *childViewController = [self fwChildViewController];
    if (childViewController) {
        [self fwRemoveChildViewController:childViewController];
    }
    
    // 设置新的控制器
    [self fwAddChildViewController:viewController];
}

- (void)fwRemoveChildViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
}

- (void)fwAddChildViewController:(UIViewController *)viewController
{
    [self fwAddChildViewController:viewController inView:self.view];
}

- (void)fwAddChildViewController:(UIViewController *)viewController inView:(UIView *)view
{
    [self addChildViewController:viewController];
    [view addSubview:viewController.view];
    // viewController.view.frame = view.bounds;
    [viewController.view fwPinEdgesToSuperview];
}

#pragma mark - Previous

- (UIViewController *)fwPreviousViewController
{
    if (self.navigationController.viewControllers &&
        self.navigationController.viewControllers.count > 1 &&
        self.navigationController.topViewController == self) {
        NSUInteger count = self.navigationController.viewControllers.count;
        return (UIViewController *)[self.navigationController.viewControllers objectAtIndex:count - 2];
    }
    return nil;
}

@end
