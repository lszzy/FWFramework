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

#pragma mark - Lifecycle

+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *))block
{
    FWAnimatedTransition *transition = [[self alloc] init];
    transition.block = block;
    return transition;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _duration = 0.35;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return transitionContext.isAnimated ? self.duration : 0.f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    if (self.block) {
        self.block(self);
    } else {
        [self animate];
    }
}

#pragma mark - Animate

- (FWAnimatedTransitionType)type
{
    // 如果自定义type，优先使用之
    if (_type != FWAnimatedTransitionTypeNone) {
        return _type;
    }
    
    // 自动根据上下文获取type
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

- (void)animate
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

+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection
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

- (void)animate
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

#pragma mark - FWInteractiveTransition

@interface FWInteractiveTransition ()

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@end

@implementation FWInteractiveTransition

- (instancetype)init
{
    self = [super init];
    if (self) {
        _interactiveEdge = UIRectEdgeTop;
        _percentOfInteractive = 0.5;
    }
    return self;
}

- (void)interactWithViewController:(UIViewController *)viewController
{
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeAction:)];
    [viewController.view addGestureRecognizer:gestureRecognizer];
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    [super startInteractiveTransition:transitionContext];
}

- (CGFloat)percentForGesture:(UIPanGestureRecognizer *)gesture
{
    // 因为视图控制器将作为动画的一部分在屏幕上或从屏幕上滑动，因此我们希望将计算建立在不移动视图的坐标空间：transitionContext.containerView
    UIView *containerView = self.transitionContext.containerView;
    // 根据移动距离计算
    // CGPoint panPoint = [gesture translationInView:containerView];
    // 根据坐标位置计算
    CGPoint panPoint = [gesture locationInView:containerView];
    CGFloat width = CGRectGetWidth(containerView.bounds);
    CGFloat height = CGRectGetHeight(containerView.bounds);
    
    CGFloat percent = 0.f;
    if (self.interactiveEdge == UIRectEdgeRight) {
        percent = (width - panPoint.x) / width;
    } else if (self.interactiveEdge == UIRectEdgeLeft) {
        percent = panPoint.x / width;
    } else if (self.interactiveEdge == UIRectEdgeBottom) {
        percent = (height - panPoint.y) / height;
    } else if (self.interactiveEdge == UIRectEdgeTop) {
        percent = panPoint.y / height;
    }
    
    percent = fminf(fmaxf(percent, 0.0), 1.0);
    if (_speedOfPercent > 0.f) {
        percent *= _speedOfPercent;
    }
    return percent;
}

- (void)gestureRecognizeAction:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // 开始状态由视图控制器处理，可触发dismiss等。一般began初始化transition，cancelled|ended清空transition
            _isInteractive = YES;
            if (self.interactiveBlock) {
                self.interactiveBlock();
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (_percentOfFinished > 0 && [self percentForGesture:gestureRecognizer] >= _percentOfFinished) {
                _isInteractive = NO;
                [self finishInteractiveTransition];
            } else {
                // 拖动中,更新百分比
                [self updateInteractiveTransition:[self percentForGesture:gestureRecognizer]];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            // 根据拖动比例决定是否转场
            if ([self percentForGesture:gestureRecognizer] >= _percentOfInteractive) {
                _isInteractive = NO;
                [self finishInteractiveTransition];
            } else {
                _isInteractive = NO;
                [self cancelInteractiveTransition];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            // 手势被打断，取消转场
            _isInteractive = NO;
            [self cancelInteractiveTransition];
            break;
        }
        default: {
            break;
        }
    }
}

@end

#pragma mark - FWTransitionDelegate

@interface FWTransitionDelegate ()

@end

@implementation FWTransitionDelegate

+ (instancetype)delegateWithTransition:(FWAnimatedTransition *)transition
{
    FWTransitionDelegate *delegate = [[self alloc] init];
    delegate.transition = transition;
    return delegate;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    self.transition.type = FWAnimatedTransitionTypePresent;
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.transition.type = FWAnimatedTransitionTypeDismiss;
    return self.transition;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return nil;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        // push时检查toVC的转场代理
        if (toVC.fwViewTransitionDelegate.transition) {
            toVC.fwViewTransitionDelegate.transition.type = FWAnimatedTransitionTypePush;
            return toVC.fwViewTransitionDelegate.transition;
        } else {
            self.transition.type = FWAnimatedTransitionTypePush;
            return self.transition;
        }
    } else if (operation == UINavigationControllerOperationPop) {
        // pop时检查fromVC的转场代理
        if (fromVC.fwViewTransitionDelegate.transition) {
            fromVC.fwViewTransitionDelegate.transition.type = FWAnimatedTransitionTypePop;
            return fromVC.fwViewTransitionDelegate.transition;
        } else {
            self.transition.type = FWAnimatedTransitionTypePop;
            return self.transition;
        }
    }
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    return nil;
}

@end

#pragma mark - UIViewController+FWTransition

@implementation UIViewController (FWTransition)

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

- (FWTransitionDelegate *)fwViewTransitionDelegate
{
    return objc_getAssociatedObject(self, @selector(fwViewTransitionDelegate));
}

- (void)setFwViewTransitionDelegate:(FWTransitionDelegate *)fwViewTransitionDelegate
{
    objc_setAssociatedObject(self, @selector(fwViewTransitionDelegate), fwViewTransitionDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UINavigationController+FWTransition

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
