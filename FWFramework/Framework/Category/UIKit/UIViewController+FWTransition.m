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

#pragma mark - Factory

+ (instancetype)transitionWithDelegate:(id<FWAnimatedTransitionDelegate>)delegate
{
    FWAnimatedTransition *transition = [[self alloc] init];
    transition.delegate = delegate;
    return transition;
}

+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *))block
{
    FWAnimatedTransition *transition = [[self alloc] init];
    transition.block = block;
    return transition;
}

+ (instancetype)transition
{
    return [[self alloc] init];
}

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _duration = -1;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    if (!transitionContext.isAnimated) {
        return 0.f;
    }
    
    NSTimeInterval duration = self.duration;
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwAnimatedTransitionDuration:)]) {
        duration = [self.delegate fwAnimatedTransitionDuration:self];
    }
    return duration > 0 ? duration : -1;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    // 1. delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(fwAnimatedTransition:)]) {
        [self.delegate fwAnimatedTransition:self];
    // 2. block
    } else if (self.block) {
        self.block(self);
    // 3. inherit
    } else {
        [self transition];
    }
}

#pragma mark - Public

- (FWAnimatedTransitionType)type
{
    if (!self.transitionContext) {
        return FWAnimatedTransitionTypeNone;
    }
    
    UIViewController *fromViewController = self.fromViewController;
    UIViewController *toViewController = self.toViewController;
    // 导航栏为同一个时为push|pop
    if (fromViewController.navigationController && toViewController.navigationController &&
        fromViewController.navigationController == toViewController.navigationController) {
        NSInteger toIndex = [toViewController.navigationController.viewControllers indexOfObject:toViewController];
        NSInteger fromIndex = [fromViewController.navigationController.viewControllers indexOfObject:fromViewController];
        if (toIndex > fromIndex) {
            return FWAnimatedTransitionTypePush;
        } else {
            return FWAnimatedTransitionTypePop;
        }
    } else {
        if (toViewController.presentingViewController == fromViewController) {
            return FWAnimatedTransitionTypePresent;
        } else {
            return FWAnimatedTransitionTypeDismiss;
        }
    }
}

- (UIViewController *)fromViewController
{
    return [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
}

- (UIViewController *)toViewController
{
    return [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
}

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
            [self.transitionContext.containerView addSubview:self.fromView];
            [self.transitionContext.containerView addSubview:self.toView];
            break;
        }
        // pop时fromView在上，toView在下
        case FWAnimatedTransitionTypePop: {
            // 此处后添加fromView，方便做pop动画，可自行移动toView到上面
            [self.transitionContext.containerView addSubview:self.toView];
            [self.transitionContext.containerView addSubview:self.fromView];
            break;
        }
        // present时使用toView做动画
        case FWAnimatedTransitionTypePresent: {
            [self.transitionContext.containerView addSubview:self.toView];
            break;
        }
        // dismiss时使用fromView做动画
        case FWAnimatedTransitionTypeDismiss: {
            [self.transitionContext.containerView addSubview:self.fromView];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)transition
{
    // 子类重写
}

- (void)complete
{
    [self.transitionContext completeTransition:![self.transitionContext transitionWasCancelled]];
}

@end

#pragma mark - FWSwipeAnimationTransition

@implementation FWSwipeAnimationTransition

+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection outDirection:(UISwipeGestureRecognizerDirection)outDirection
{
    FWSwipeAnimationTransition *transition = [[self alloc] init];
    transition.inDirection = inDirection;
    transition.outDirection = outDirection;
    return transition;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inDirection = UISwipeGestureRecognizerDirectionLeft;
        _outDirection = UISwipeGestureRecognizerDirectionRight;
    }
    return self;
}

- (void)transition
{
    FWAnimatedTransitionType type = [self type];
    BOOL swipeIn = (type == FWAnimatedTransitionTypePush || type == FWAnimatedTransitionTypePresent);
    UISwipeGestureRecognizerDirection direction = swipeIn ? self.inDirection : self.outDirection;
    CGVector offset;
    switch (direction) {
        case UISwipeGestureRecognizerDirectionLeft: {
            offset = CGVectorMake(-1.f, 0.f);
            break;
        }
        case UISwipeGestureRecognizerDirectionRight: {
            offset = CGVectorMake(1.f, 0.f);
            break;
        }
        case UISwipeGestureRecognizerDirectionUp: {
            offset = CGVectorMake(0.f, -1.f);
            break;
        }
        case UISwipeGestureRecognizerDirectionDown:
        default: {
            offset = CGVectorMake(0.f, 1.f);
            break;
        }
    }
    
    CGRect fromFrame = [self.transitionContext initialFrameForViewController:self.fromViewController];
    CGRect toFrame = [self.transitionContext finalFrameForViewController:self.toViewController];
    UIView *fromView = self.fromView;
    UIView *toView = self.toView;
    if (swipeIn) {
        [self.transitionContext.containerView addSubview:toView];
        toView.frame = [self animateFrameWithFrame:toFrame offset:offset initial:YES show:swipeIn];
        fromView.frame = fromFrame;
    } else {
        [self.transitionContext.containerView insertSubview:toView belowSubview:fromView];
        fromView.frame = [self animateFrameWithFrame:fromFrame offset:offset initial:YES show:swipeIn];
        toView.frame = toFrame;
    }
    
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext] animations:^{
        if (swipeIn) {
            toView.frame = [self animateFrameWithFrame:toFrame offset:offset initial:NO show:swipeIn];
        } else {
            fromView.frame = [self animateFrameWithFrame:fromFrame offset:offset initial:NO show:swipeIn];
        }
    } completion:^(BOOL finished) {
        BOOL cancelled = [self.transitionContext transitionWasCancelled];
        if (cancelled) {
            [toView removeFromSuperview];
        }
        [self.transitionContext completeTransition:!cancelled];
    }];
}

- (CGRect)animateFrameWithFrame:(CGRect)frame offset:(CGVector)offset initial:(BOOL)initial show:(BOOL)show
{
    NSInteger vectorValue = offset.dx == 0 ? offset.dy : offset.dx;
    NSInteger flag = 0;
    if (initial) {
        vectorValue = vectorValue > 0 ? -vectorValue : vectorValue;
        flag = show ? vectorValue : 0;
    } else {
        vectorValue = vectorValue > 0 ? vectorValue : -vectorValue;
        flag = show ? 0 : vectorValue;
    }
    
    CGFloat offsetX = frame.size.width * offset.dx * flag;
    CGFloat offsetY = frame.size.height * offset.dy * flag;
    return CGRectOffset(frame, offsetX, offsetY);
}

@end
