/*!
 @header     UIViewController+FWDelegate.m
 @indexgroup FWFramework
 @brief      UIViewController+FWDelegate
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/11
 */

#import "UIViewController+FWDelegate.h"
#import <objc/runtime.h>

#pragma mark - FWModalTransitionDelegate

@interface FWModalTransitionDelegate ()

@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> transition;

@end

@implementation FWModalTransitionDelegate

+ (instancetype)delegateWithTransition:(id<UIViewControllerAnimatedTransitioning>)transition
{
    FWModalTransitionDelegate *delegate = [[self alloc] init];
    delegate.transition = transition;
    return delegate;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self.transition;
}

@end

#pragma mark - UIViewController+FWDelegate

@implementation UIViewController (FWDelegate)

- (id<UIViewControllerTransitioningDelegate>)fwModalTransitionDelegate
{
    return objc_getAssociatedObject(self, @selector(fwModalTransitionDelegate));
}

// 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
- (void)setFwModalTransitionDelegate:(id<UIViewControllerTransitioningDelegate>)fwModalTransitionDelegate
{
    // 设置delegation动画，nil时清除delegate动画
    self.transitioningDelegate = fwModalTransitionDelegate;
    // 强引用，防止被自动释放，nil时释放引用
    objc_setAssociatedObject(self, @selector(fwModalTransitionDelegate), fwModalTransitionDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<UIViewControllerAnimatedTransitioning>)fwNavigationTransition
{
    return objc_getAssociatedObject(self, @selector(fwNavigationTransition));
}

- (void)setFwNavigationTransition:(id<UIViewControllerAnimatedTransitioning>)fwNavigationTransition
{
    objc_setAssociatedObject(self, @selector(fwNavigationTransition), fwNavigationTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - FWNavigationTransitionDelegate

@interface FWNavigationTransitionDelegate ()

@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> transition;

@end

@implementation FWNavigationTransitionDelegate

+ (instancetype)delegateWithTransition:(id<UIViewControllerAnimatedTransitioning>)transition
{
    FWNavigationTransitionDelegate *delegate = [[self alloc] init];
    delegate.transition = transition;
    return delegate;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        // push时检查toVC的转场代理
        if (toVC.fwNavigationTransition) {
            return toVC.fwNavigationTransition;
        } else {
            return self.transition;
        }
    } else if (operation == UINavigationControllerOperationPop) {
        // pop时检查fromVC的转场代理
        if (fromVC.fwNavigationTransition) {
            return fromVC.fwNavigationTransition;
        } else {
            return self.transition;
        }
    }
    return nil;
}

@end

#pragma mark - UINavigationController+FWDelegate

@implementation UINavigationController (FWDelegate)

- (id<UINavigationControllerDelegate>)fwNavigationTransitionDelegate
{
    return objc_getAssociatedObject(self, @selector(fwNavigationTransitionDelegate));
}

- (void)setFwNavigationTransitionDelegate:(id<UINavigationControllerDelegate>)fwNavigationTransitionDelegate
{
    // 设置delegate动画，nil时清理delegate动画，无需清理CA动画
    self.delegate = fwNavigationTransitionDelegate;
    // 强引用，防止被自动释放，nil时释放引用
    objc_setAssociatedObject(self, @selector(fwNavigationTransitionDelegate), fwNavigationTransitionDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
