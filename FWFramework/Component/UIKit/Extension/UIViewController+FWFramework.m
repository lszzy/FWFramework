//
//  UIViewController+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWFramework.h"
#import "FWAutoLayout.h"
#import "FWSwizzle.h"
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

- (BOOL)fwIsLoaded
{
    return [objc_getAssociatedObject(self, @selector(fwIsLoaded)) boolValue];
}

- (void)setFwIsLoaded:(BOOL)fwIsLoaded
{
    objc_setAssociatedObject(self, @selector(fwIsLoaded), @(fwIsLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Present

+ (void)fwDefaultModalPresentationStyle:(UIModalPresentationStyle)style
{
    if (@available(iOS 13.0, *)) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            FWSwizzleClass(UIViewController, @selector(setModalPresentationStyle:), FWSwizzleReturn(void), FWSwizzleArgs(UIModalPresentationStyle style), FWSwizzleCode({
                objc_setAssociatedObject(selfObject, @selector(fwDefaultModalPresentationStyle:), @(style), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                FWSwizzleOriginal(style);
            }));
            FWSwizzleClass(UIViewController, @selector(presentViewController:animated:completion:), FWSwizzleReturn(void), FWSwizzleArgs(UIViewController *viewController, BOOL animated, void (^completion)(void)), FWSwizzleCode({
                if (!objc_getAssociatedObject(viewController, @selector(fwDefaultModalPresentationStyle:)) &&
                    fwStaticModalPresentationStyle != UIModalPresentationAutomatic) {
                    if (viewController.modalPresentationStyle == UIModalPresentationAutomatic ||
                        viewController.modalPresentationStyle == UIModalPresentationPageSheet) {
                        viewController.modalPresentationStyle = fwStaticModalPresentationStyle;
                    }
                }
                FWSwizzleOriginal(viewController, animated, completion);
            }));
        });
        fwStaticModalPresentationStyle = style;
    }
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
        FWSwizzleClass(UIViewController, @selector(dismissViewControllerAnimated:completion:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated, void (^completion)(void)), FWSwizzleCode({
            UIViewController *viewController = selfObject.presentedViewController ?: selfObject;
            void (^dismissBlock)(void) = viewController.fwDismissBlock ?: viewController.navigationController.fwDismissBlock;
            if (dismissBlock) {
                FWSwizzleOriginal(animated, ^{
                    if (completion) completion();
                    if (dismissBlock) dismissBlock();
                });
            } else {
                FWSwizzleOriginal(animated, completion);
            }
        }));
    });
    
    objc_setAssociatedObject(self, @selector(fwDismissBlock), fwDismissBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
