//
//  UIViewController+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIViewController+FWFramework.h"
#import "UIView+FWAutoLayout.h"

@implementation UIViewController (FWFramework)

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
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

@end
