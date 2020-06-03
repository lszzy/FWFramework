//
//  UIViewController+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWFramework.h"
#import "UIView+FWAutoLayout.h"
#import "NSObject+FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWInnerPresentationTarget

@interface FWInnerPresentationTarget : NSObject <UIAdaptivePresentationControllerDelegate>

@end

@implementation FWInnerPresentationTarget

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    if (presentationController.presentedViewController.fwPresentationDidDismiss) {
        presentationController.presentedViewController.fwPresentationDidDismiss();
    }
}

@end

#pragma mark - UIViewController+FWFramework

API_AVAILABLE(ios(13.0))
static UIModalPresentationStyle fwStaticModalPresentationStyle = UIModalPresentationAutomatic;

@implementation UIViewController (FWFramework)

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
}

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

#pragma mark - Present

+ (void)fwDefaultModalPresentationStyle:(UIModalPresentationStyle)style
{
    if (@available(iOS 13.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [UIViewController fwSwizzleInstanceMethod:@selector(setModalPresentationStyle:) with:@selector(fwInnerSetModalPresentationStyle:)];
            [UIViewController fwSwizzleInstanceMethod:@selector(presentViewController:animated:completion:) with:@selector(fwInnerPresentViewController:animated:completion:)];
        });
        fwStaticModalPresentationStyle = style;
    }
}

- (void)fwInnerSetModalPresentationStyle:(UIModalPresentationStyle)style
{
    if (@available(iOS 13.0, *)) {
        objc_setAssociatedObject(self, @selector(fwInnerSetModalPresentationStyle:), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self fwInnerSetModalPresentationStyle:style];
}

- (void)fwInnerPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (@available(iOS 13.0, *)) {
        if (!objc_getAssociatedObject(viewController, @selector(fwInnerSetModalPresentationStyle:)) &&
            fwStaticModalPresentationStyle != UIModalPresentationAutomatic) {
            if (viewController.modalPresentationStyle == UIModalPresentationAutomatic ||
                viewController.modalPresentationStyle == UIModalPresentationPageSheet) {
                [viewController fwInnerSetModalPresentationStyle:fwStaticModalPresentationStyle];
            }
        }
    }
    [self fwInnerPresentViewController:viewController animated:animated completion:completion];
}

- (void (^)(void))fwPresentationDidDismiss
{
    return objc_getAssociatedObject(self, @selector(fwPresentationDidDismiss));
}

- (void)setFwPresentationDidDismiss:(void (^)(void))fwPresentationDidDismiss
{
    objc_setAssociatedObject(self, @selector(fwPresentationDidDismiss), fwPresentationDidDismiss, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (@available(iOS 13.0, *)) {
        self.presentationController.delegate = self.fwInnerPresentationTarget;
    }
}

- (FWInnerPresentationTarget *)fwInnerPresentationTarget
{
    FWInnerPresentationTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerPresentationTarget alloc] init];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(void))fwDismissBlock
{
    return objc_getAssociatedObject(self, @selector(fwDismissBlock));
}

- (void)setFwDismissBlock:(void (^)(void))fwDismissBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController fwSwizzleInstanceMethod:@selector(dismissViewControllerAnimated:completion:) with:@selector(fwInnerDismissViewControllerAnimated:completion:)];
    });
    
    objc_setAssociatedObject(self, @selector(fwDismissBlock), fwDismissBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)fwInnerDismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    UIViewController *viewController = self.presentedViewController ?: self;
    void (^dismissBlock)(void) = viewController.fwDismissBlock ?: viewController.navigationController.fwDismissBlock;
    if (dismissBlock) {
        [self fwInnerDismissViewControllerAnimated:flag completion:^{
            if (completion) completion();
            if (dismissBlock) dismissBlock();
        }];
    } else {
        [self fwInnerDismissViewControllerAnimated:flag completion:completion];
    }
}

#pragma mark - Popup

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
