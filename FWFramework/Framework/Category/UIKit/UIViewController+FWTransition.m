//
//  UIViewController+FWTransition.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWTransition.h"
#import <objc/runtime.h>

#pragma mark - FWViewTransition

@interface FWViewTransition ()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, assign) BOOL isPresent;

@end

@implementation FWViewTransition

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    self.isPresent = YES;
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.isPresent = NO;
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval duration;
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwViewDuration:)]) {
        duration = [self.delegate fwViewDuration:self];
    } else {
        duration = self.duration;
    }
    // 默认值0.25秒
    return duration > 0 ? duration : -1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    // 执行present动画
    if (self.isPresent) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(fwPresent:)]) {
            [self.delegate fwPresent:self];
        } else if (self.presentBlock) {
            self.presentBlock(self);
        }
        // 执行dismiss动画
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(fwDismiss:)]) {
            [self.delegate fwDismiss:self];
        } else if (self.dismissBlock) {
            self.dismissBlock(self);
        }
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
    // present时使用toView做动画
    if (self.isPresent) {
        UIView *container = [self.transitionContext containerView];
        [container addSubview:self.toView];
        // dismiss时使用fromView做动画
    } else {
        UIView *container = [self.transitionContext containerView];
        [container addSubview:self.fromView];
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

#pragma mark - UIViewController+FWTransition

@implementation UIViewController (FWTransition)

@dynamic fwViewTransition;

- (id<UIViewControllerTransitioningDelegate>)fwViewTransition
{
    return objc_getAssociatedObject(self, @selector(fwViewTransition));
}

- (void)setFwViewTransition:(id<UIViewControllerTransitioningDelegate>)fwViewTransition
{
    // 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
    if (fwViewTransition) {
        // 设置delegation动画
        self.transitioningDelegate = fwViewTransition;
        // 强引用，防止被自动释放
        objc_setAssociatedObject(self, @selector(fwViewTransition), fwViewTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        // 清除delegate动画
        self.transitioningDelegate = nil;
        // 释放引用
        objc_setAssociatedObject(self, @selector(fwViewTransition), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

@end
