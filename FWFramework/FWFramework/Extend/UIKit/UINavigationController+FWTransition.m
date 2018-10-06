//
//  UINavigationController+FWTransition.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UINavigationController+FWTransition.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationTransition

@interface FWNavigationTransition ()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, assign) BOOL isPush;

@end

@implementation FWNavigationTransition

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        self.isPush = YES;
        return self;
    } else if (operation == UINavigationControllerOperationPop) {
        self.isPush = NO;
        return self;
    } else {
        return nil;
    }
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval duration;
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwNavigationDuration:)]) {
        duration = [self.delegate fwNavigationDuration:self];
    } else {
        duration = self.duration;
    }
    // 默认值0.25秒
    return duration > 0 ? duration : -1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    // 执行push动画
    if (self.isPush) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(fwPush:)]) {
            [self.delegate fwPush:self];
        } else if (self.pushBlock) {
            self.pushBlock(self);
        }
        // 执行pop动画
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(fwPop:)]) {
            [self.delegate fwPop:self];
        } else if (self.popBlock) {
            self.popBlock(self);
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
    // push时fromView在下，toView在上
    if (self.isPush) {
        UIView *container = [self.transitionContext containerView];
        [container addSubview:self.fromView];
        [container addSubview:self.toView];
        // pop时fromView在上，toView在下
    } else {
        // 此处后添加fromView，方便做pop动画，可自行移动toView到上面
        UIView *container = [self.transitionContext containerView];
        [container addSubview:self.toView];
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

#pragma mark - UINavigationController+FWTransition

@implementation UINavigationController (FWTransition)

@dynamic fwNavigationTransition;

- (FWNavigationTransition *)fwNavigationTransition
{
    return objc_getAssociatedObject(self, @selector(fwNavigationTransition));
}

- (void)setFwNavigationTransition:(FWNavigationTransition *)fwNavigationTransition
{
    if (fwNavigationTransition) {
        // 设置delegate动画
        self.delegate = fwNavigationTransition;
        // 强引用，防止被自动释放
        objc_setAssociatedObject(self, @selector(fwNavigationTransition), fwNavigationTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        // 清理delegate动画，无需清理CA动画
        self.delegate = nil;
        // 释放引用
        objc_setAssociatedObject(self, @selector(fwNavigationTransition), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

@end
