//
//  UIViewController+FWTransition.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWTransition.h"
#import <objc/runtime.h>

#pragma mark - FWAnimatedTransition

@interface FWAnimatedTransition ()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@end

@implementation FWAnimatedTransition

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval duration;
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwAnimatedTransitionDuration:)]) {
        duration = [self.delegate fwAnimatedTransitionDuration:self];
    } else {
        duration = self.duration;
    }
    // 默认值0.25秒
    return duration > 0 ? duration : -1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    // 执行转场动画
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwAnimatedTransition:)]) {
        [self.delegate fwAnimatedTransition:self];
    } else if (self.transitionBlock) {
        self.transitionBlock(self);
    }
}

#pragma mark - Public

- (UIView *)fromView
{
    return [self.transitionContext viewForKey:UITransitionContextFromViewKey];
}

- (UIView *)toView
{
    return [self.transitionContext viewForKey:UITransitionContextToViewKey];
}

- (void)start
{
    switch (self.type) {
        // push时fromView在下，toView在上
        case FWAnimatedTransitionTypePush: {
            UIView *container = [self.transitionContext containerView];
            [container addSubview:self.fromView];
            [container addSubview:self.toView];
            break;
        }
        // pop时fromView在上，toView在下
        case FWAnimatedTransitionTypePop: {
            // 此处后添加fromView，方便做pop动画，可自行移动toView到上面
            UIView *container = [self.transitionContext containerView];
            [container addSubview:self.toView];
            [container addSubview:self.fromView];
            break;
        }
        // present时使用toView做动画
        case FWAnimatedTransitionTypePresent: {
            UIView *container = [self.transitionContext containerView];
            [container addSubview:self.toView];
            break;
        }
        // dismiss时使用fromView做动画
        case FWAnimatedTransitionTypeDismiss: {
            UIView *container = [self.transitionContext containerView];
            [container addSubview:self.fromView];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)complete
{
    [self.transitionContext completeTransition:![self.transitionContext transitionWasCancelled]];
}

- (void)complete:(BOOL)completed
{
    [self.transitionContext completeTransition:completed];
}

@end

#pragma mark - FWViewTransitionDelegate

@implementation FWViewTransitionDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (self.animatedTransition) {
        self.animatedTransition.type = FWAnimatedTransitionTypePresent;
        return self.animatedTransition;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if (self.animatedTransition) {
        self.animatedTransition.type = FWAnimatedTransitionTypeDismiss;
        return self.animatedTransition;
    }
    return nil;
}

@end

@implementation UIViewController (FWTransition)

- (id<UIViewControllerTransitioningDelegate>)fwViewTransitionDelegate
{
    return objc_getAssociatedObject(self, @selector(fwViewTransitionDelegate));
}

// 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
- (void)setFwViewTransitionDelegate:(id<UIViewControllerTransitioningDelegate>)fwViewTransitionDelegate
{
    // 设置delegation动画，nil时清除delegate动画
    self.transitioningDelegate = fwViewTransitionDelegate;
    // 强引用，防止被自动释放，nil时释放引用
    objc_setAssociatedObject(self, @selector(fwViewTransitionDelegate), fwViewTransitionDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAnimatedTransition *)fwNavigationAnimatedTransition
{
    return objc_getAssociatedObject(self, @selector(fwNavigationAnimatedTransition));
}

- (void)setFwNavigationAnimatedTransition:(FWAnimatedTransition *)fwNavigationAnimatedTransition
{
    objc_setAssociatedObject(self, @selector(fwNavigationAnimatedTransition), fwNavigationAnimatedTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - FWNavigationTransitionDelegate

@implementation FWNavigationTransitionDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        // push时检查toVC的转场代理
        if (self.viewControllerTransitionEnabled && toVC.fwNavigationAnimatedTransition) {
            toVC.fwNavigationAnimatedTransition.type = FWAnimatedTransitionTypePush;
            return toVC.fwNavigationAnimatedTransition;
        } else if (self.animatedTransition) {
            self.animatedTransition.type = FWAnimatedTransitionTypePush;
            return self.animatedTransition;
        }
    } else if (operation == UINavigationControllerOperationPop) {
        // pop时检查fromVC的转场代理
        if (self.viewControllerTransitionEnabled && fromVC.fwNavigationAnimatedTransition) {
            fromVC.fwNavigationAnimatedTransition.type = FWAnimatedTransitionTypePop;
            return fromVC.fwNavigationAnimatedTransition;
        } else if (self.animatedTransition) {
            self.animatedTransition.type = FWAnimatedTransitionTypePop;
            return self.animatedTransition;
        }
    }
    return nil;
}

@end

@implementation UINavigationController (FWTransition)

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
