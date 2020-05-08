//
//  UIViewController+FWTransition.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWTransition.h"
#import "UIGestureRecognizer+FWFramework.h"
#import "UIView+FWBorder.h"
#import <objc/runtime.h>

#pragma mark - FWAnimatedTransition

@interface FWAnimatedTransition ()

@property (nonatomic, assign) BOOL isSystem;

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

@property (nonatomic, strong) FWPanGestureRecognizer *gestureRecognizer;

@property (nonatomic, copy) void(^interactBegan)(void);

@end

@implementation FWAnimatedTransition

#pragma mark - Lifecycle

+ (instancetype)systemTransition
{
    static FWAnimatedTransition *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWAnimatedTransition alloc] init];
        instance.isSystem = YES;
    });
    return instance;
}

+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *))block
{
    FWAnimatedTransition *transition = [[self alloc] init];
    transition.transitionBlock = block;
    return transition;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _transitionDuration = 0.35;
        self.completionSpeed = 0.35;
    }
    return self;
}

#pragma mark - Private

- (void)setInteractEnabled:(BOOL)interactEnabled
{
    _interactEnabled = interactEnabled;
    self.gestureRecognizer.enabled = interactEnabled;
}

- (void)interactWith:(UIViewController *)viewController
{
    if (!viewController.view) return;

    for (UIGestureRecognizer *gestureRecognizer in viewController.view.gestureRecognizers) {
        if (gestureRecognizer == self.gestureRecognizer) return;
    }
    [viewController.view addGestureRecognizer:self.gestureRecognizer];
}

- (FWPanGestureRecognizer *)gestureRecognizer
{
    if (!_gestureRecognizer) {
        _gestureRecognizer = [[FWPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerAction:)];
    }
    return _gestureRecognizer;
}

- (void)gestureRecognizerAction:(FWPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _isInteractive = YES;
            
            BOOL interactBegan = self.interactBlock ? self.interactBlock(gestureRecognizer) : YES;
            if (interactBegan && self.interactBegan) {
                self.interactBegan();
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            BOOL interactChanged = self.interactBlock ? self.interactBlock(gestureRecognizer) : YES;
            if (interactChanged) {
                CGFloat percent = [gestureRecognizer fwSwipePercentOfDirection:gestureRecognizer.direction];
                [self updateInteractiveTransition:percent];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            _isInteractive = NO;
            
            BOOL interactEnded = self.interactBlock ? self.interactBlock(gestureRecognizer) : YES;
            if (interactEnded) {
                BOOL finished = NO;
                if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                    finished = NO;
                } else if (self.percentComplete >= 0.5) {
                    finished = YES;
                } else {
                    CGPoint velocity = [gestureRecognizer velocityInView:gestureRecognizer.view];
                    CGPoint transition = [gestureRecognizer translationInView:gestureRecognizer.view];
                    switch (gestureRecognizer.direction) {
                        case UISwipeGestureRecognizerDirectionUp:
                            if (velocity.y <= -100 && fabs(transition.x) < fabs(transition.y)) finished = YES;
                            break;
                        case UISwipeGestureRecognizerDirectionLeft:
                            if (velocity.x <= -100 && fabs(transition.x) > fabs(transition.y)) finished = YES;
                            break;
                        case UISwipeGestureRecognizerDirectionDown:
                            if (velocity.y >= 100 && fabs(transition.x) < fabs(transition.y)) finished = YES;
                            break;
                        case UISwipeGestureRecognizerDirectionRight:
                            if (velocity.x >= 100 && fabs(transition.x) > fabs(transition.y)) finished = YES;
                            break;
                        default:
                            break;
                    }
                }
                
                if (finished) {
                    [self finishInteractiveTransition];
                } else {
                    [self cancelInteractiveTransition];
                }
            }
            break;
        }
        default:
            break;
    }
}

- (BOOL)presentationEnabled
{
    return self.presentationBlock != nil || self.presentationController != nil;
}

- (void)setPresentationEnabled:(BOOL)presentationEnabled
{
    if (presentationEnabled == self.presentationEnabled) return;
    
    if (presentationEnabled) {
        self.presentationBlock = ^UIPresentationController *(UIViewController *presented, UIViewController *presenting) {
            return [[FWPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
        };
    } else {
        self.presentationBlock = nil;
        self.presentationController = nil;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)interactiveTransitionForTransition:(id<UIViewControllerAnimatedTransitioning>)transition
{
    if (self.transitionType == FWAnimatedTransitionTypeDismiss || self.transitionType == FWAnimatedTransitionTypePop) {
        if (!self.isSystem && self.interactEnabled && self.isInteractive) {
            return self;
        }
    }
    return nil;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    self.transitionType = FWAnimatedTransitionTypePresent;
    // 自动设置和绑定dismiss交互转场，在dismiss前设置生效
    if (!self.isSystem && self.interactEnabled && !self.interactBlock) {
        __weak UIViewController *weakPresented = presented;
        self.interactBegan = ^{
            [weakPresented dismissViewControllerAnimated:YES completion:nil];
        };
        [self interactWith:presented];
    }
    return !self.isSystem ? self : nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.transitionType = FWAnimatedTransitionTypeDismiss;
    return !self.isSystem ? self : nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return [self interactiveTransitionForTransition:animator];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return [self interactiveTransitionForTransition:animator];
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    if (self.presentationBlock) {
        self.presentationController = self.presentationBlock(presented, presenting);
    }
    return self.presentationController;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        // push时检查toVC的转场代理
        FWAnimatedTransition *transition = toVC.fwViewTransition ?: self;
        transition.transitionType = FWAnimatedTransitionTypePush;
        // 自动设置和绑定pop交互转场，在pop前设置生效
        if (!transition.isSystem && transition.interactEnabled && !transition.interactBlock) {
            transition.interactBegan = ^{
                [navigationController popViewControllerAnimated:YES];
            };
            [transition interactWith:toVC];
        }
        return !transition.isSystem ? transition : nil;
    } else if (operation == UINavigationControllerOperationPop) {
        // pop时检查fromVC的转场代理
        FWAnimatedTransition *transition = fromVC.fwViewTransition ?: self;
        transition.transitionType = FWAnimatedTransitionTypePop;
        return !transition.isSystem ? transition : nil;
    }
    return nil;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
{
    return [self interactiveTransitionForTransition:animationController];
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return transitionContext.isAnimated ? self.transitionDuration : 0.f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    self.transitionContext = transitionContext;
    
    if (self.transitionBlock) {
        self.transitionBlock(self);
    } else {
        [self animate];
    }
}

#pragma mark - Animate

- (FWAnimatedTransitionType)transitionType
{
    // 如果自定义type，优先使用之
    if (_transitionType != FWAnimatedTransitionTypeNone) {
        return _transitionType;
    }
    
    // 自动根据上下文获取type
    if (!self.transitionContext) {
        return FWAnimatedTransitionTypeNone;
    }
    
    UIViewController *fromViewController = [self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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

- (void)start
{
    UIView *fromView = [self.transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [self.transitionContext viewForKey:UITransitionContextToViewKey];
    switch (self.transitionType) {
        // push时fromView在下，toView在上
        case FWAnimatedTransitionTypePush: {
            [self.transitionContext.containerView addSubview:fromView];
            [self.transitionContext.containerView addSubview:toView];
            break;
        }
        // pop时fromView在上，toView在下
        case FWAnimatedTransitionTypePop: {
            // 此处后添加fromView，方便做pop动画，可自行移动toView到上面
            [self.transitionContext.containerView addSubview:toView];
            [self.transitionContext.containerView addSubview:fromView];
            break;
        }
        // present时使用toView做动画
        case FWAnimatedTransitionTypePresent: {
            [self.transitionContext.containerView addSubview:toView];
            break;
        }
        // dismiss时使用fromView做动画
        case FWAnimatedTransitionTypeDismiss: {
            [self.transitionContext.containerView addSubview:fromView];
            break;
        }
        default: {
            break;
        }
    }
}

- (void)animate
{
    // 子类可重写，默认alpha动画
    FWAnimatedTransitionType transitionType = [self transitionType];
    BOOL transitionIn = (transitionType == FWAnimatedTransitionTypePush || transitionType == FWAnimatedTransitionTypePresent);
    UIView *transitionView = transitionIn ? [self.transitionContext viewForKey:UITransitionContextToViewKey] : [self.transitionContext viewForKey:UITransitionContextFromViewKey];
    
    [self start];
    if (transitionIn) transitionView.alpha = 0;
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext] delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        transitionView.alpha = transitionIn ? 1 : 0;
    } completion:^(BOOL finished) {
        [self complete];
    }];
}

- (void)complete
{
    [self.transitionContext completeTransition:![self.transitionContext transitionWasCancelled]];
}

@end

#pragma mark - FWSwipeAnimatedTransition

@implementation FWSwipeAnimatedTransition

+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection
{
    FWSwipeAnimatedTransition *transition = [[self alloc] init];
    transition.inDirection = inDirection;
    transition.outDirection = outDirection;
    return transition;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inDirection = UISwipeGestureRecognizerDirectionUp;
        _outDirection = UISwipeGestureRecognizerDirectionDown;
    }
    return self;
}

- (void)setOutDirection:(UISwipeGestureRecognizerDirection)outDirection
{
    _outDirection = outDirection;
    self.gestureRecognizer.direction = outDirection;
}

- (void)animate
{
    FWAnimatedTransitionType transitionType = [self transitionType];
    BOOL transitionIn = (transitionType == FWAnimatedTransitionTypePush || transitionType == FWAnimatedTransitionTypePresent);
    UISwipeGestureRecognizerDirection direction = transitionIn ? self.inDirection : self.outDirection;
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
    
    CGRect fromFrame = [self.transitionContext initialFrameForViewController:[self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey]];
    CGRect toFrame = [self.transitionContext finalFrameForViewController:[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey]];
    UIView *fromView = [self.transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [self.transitionContext viewForKey:UITransitionContextToViewKey];
    if (transitionIn) {
        [self.transitionContext.containerView addSubview:toView];
        toView.frame = [self animateFrameWithFrame:toFrame offset:offset initial:YES show:transitionIn];
        fromView.frame = fromFrame;
    } else {
        [self.transitionContext.containerView insertSubview:toView belowSubview:fromView];
        fromView.frame = [self animateFrameWithFrame:fromFrame offset:offset initial:YES show:transitionIn];
        toView.frame = toFrame;
    }
    
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext] animations:^{
        if (transitionIn) {
            toView.frame = [self animateFrameWithFrame:toFrame offset:offset initial:NO show:transitionIn];
        } else {
            fromView.frame = [self animateFrameWithFrame:fromFrame offset:offset initial:NO show:transitionIn];
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

#pragma mark - FWTransformAnimatedTransition

@implementation FWTransformAnimatedTransition

+ (instancetype)transitionWithInTransform:(CGAffineTransform)inTransform
                             outTransform:(CGAffineTransform)outTransform
{
    FWTransformAnimatedTransition *transition = [[self alloc] init];
    transition.inTransform = inTransform;
    transition.outTransform = outTransform;
    return transition;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _inTransform = CGAffineTransformMakeScale(0.01, 0.01);
        _outTransform = CGAffineTransformMakeScale(0.01, 0.01);
    }
    return self;
}

- (void)animate
{
    FWAnimatedTransitionType transitionType = [self transitionType];
    BOOL transitionIn = (transitionType == FWAnimatedTransitionTypePush || transitionType == FWAnimatedTransitionTypePresent);
    UIView *transitionView = transitionIn ? [self.transitionContext viewForKey:UITransitionContextToViewKey] : [self.transitionContext viewForKey:UITransitionContextFromViewKey];
    
    [self start];
    if (transitionIn) {
        transitionView.transform = self.inTransform;
        transitionView.alpha = 0;
    }
    [UIView animateWithDuration:[self transitionDuration:self.transitionContext] delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        transitionView.transform = transitionIn ? CGAffineTransformIdentity : self.outTransform;
        transitionView.alpha = transitionIn ? 1 : 0;
    } completion:^(BOOL finished) {
        [self complete];
    }];
}

@end

#pragma mark - FWPresentationController

@interface FWPresentationController ()

@property (nonatomic, strong) UIView *dimmingView;

@end

@implementation FWPresentationController

#pragma mark - Lifecycle

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self) {
        _showDimming = YES;
        _dimmingClick = YES;
        _dimmingAnimated = YES;
        _dimmingColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        _rectCorner = UIRectCornerTopLeft | UIRectCornerTopRight;
        _cornerRadius = 0;
        _presentedFrame = CGRectZero;
        _presentedSize = CGSizeZero;
        _verticalInset = 0;
    }
    return self;
}

#pragma mark - Accessor

- (UIView *)dimmingView
{
    if (!_dimmingView) {
        _dimmingView = [[UIView alloc] initWithFrame:self.containerView.bounds];
        _dimmingView.backgroundColor = self.dimmingColor;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAction:)];
        [_dimmingView addGestureRecognizer:tapGesture];
    }
    return _dimmingView;
}

- (void)setShowDimming:(BOOL)showDimming
{
    _showDimming = showDimming;
    self.dimmingView.hidden = !showDimming;
}

- (void)setDimmingClick:(BOOL)dimmingClick
{
    _dimmingClick = dimmingClick;
    self.dimmingView.userInteractionEnabled = dimmingClick;
}

- (void)onTapAction:(id)sender
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Protect

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    
    self.presentedView.frame = [self frameOfPresentedViewInContainerView];
    if (self.cornerRadius > 0) {
        self.presentedView.layer.masksToBounds = YES;
        if ((self.rectCorner & UIRectCornerAllCorners) == UIRectCornerAllCorners) {
            self.presentedView.layer.cornerRadius = self.cornerRadius;
        } else {
            [self.presentedView fwSetCornerLayer:self.rectCorner radius:self.cornerRadius];
        }
    }
    self.dimmingView.frame = self.containerView.bounds;
    [self.containerView insertSubview:self.dimmingView atIndex:0];
    
    if (self.dimmingAnimated) {
        self.dimmingView.alpha = 0;
        [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            self.dimmingView.alpha = 1.0;
        } completion:nil];
    }
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    
    if (self.dimmingAnimated) {
        [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            self.dimmingView.alpha = 0;
        } completion:nil];
    }
}

- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    [super dismissalTransitionDidEnd:completed];
    
    if (completed) {
        [self.dimmingView removeFromSuperview];
    }
}

- (CGRect)frameOfPresentedViewInContainerView
{
    if (self.frameBlock) {
        return self.frameBlock(self);
    } else if (!CGRectEqualToRect(self.presentedFrame, CGRectZero)) {
        return self.presentedFrame;
    } else if (!CGSizeEqualToSize(self.presentedSize, CGSizeZero)) {
        CGRect presentedFrame = CGRectMake(0, 0, self.presentedSize.width, self.presentedSize.height);
        presentedFrame.origin.x = (self.containerView.bounds.size.width - self.presentedSize.width) / 2;
        presentedFrame.origin.y = (self.containerView.bounds.size.height - self.presentedSize.height) / 2;
        return presentedFrame;
    } else if (self.verticalInset != 0) {
        CGRect presentedFrame = self.containerView.bounds;
        presentedFrame.origin.y = self.verticalInset;
        presentedFrame.size.height -= self.verticalInset;
        return presentedFrame;
    } else {
        return self.containerView.bounds;
    }
}

@end

#pragma mark - UIViewController+FWTransition

@implementation UIViewController (FWTransition)

- (FWAnimatedTransition *)fwModalTransition
{
    return objc_getAssociatedObject(self, @selector(fwModalTransition));
}

// 注意：App退出后台时如果弹出页面，整个present动画不会执行。如果需要设置遮罩层等，需要在viewDidAppear中处理兼容
- (void)setFwModalTransition:(FWAnimatedTransition *)fwModalTransition
{
    // 设置delegation动画，nil时清除delegate动画
    self.transitioningDelegate = fwModalTransition;
    // 强引用，防止被自动释放，nil时释放引用
    objc_setAssociatedObject(self, @selector(fwModalTransition), fwModalTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAnimatedTransition *)fwViewTransition
{
    return objc_getAssociatedObject(self, @selector(fwViewTransition));
}

- (void)setFwViewTransition:(FWAnimatedTransition *)fwViewTransition
{
    objc_setAssociatedObject(self, @selector(fwViewTransition), fwViewTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UINavigationController+FWTransition

@implementation UINavigationController (FWTransition)

- (FWAnimatedTransition *)fwNavigationTransition
{
    return objc_getAssociatedObject(self, @selector(fwNavigationTransition));
}

- (void)setFwNavigationTransition:(FWAnimatedTransition *)fwNavigationTransition
{
    // 设置delegate动画，nil时清理delegate动画，无需清理CA动画
    self.delegate = fwNavigationTransition;
    // 强引用，防止被自动释放，nil时释放引用
    objc_setAssociatedObject(self, @selector(fwNavigationTransition), fwNavigationTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
