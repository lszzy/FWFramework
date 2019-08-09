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

@property (nonatomic, assign) BOOL isSystem;

@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;

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

#pragma mark - Private

- (id<UIViewControllerInteractiveTransitioning>)interactiveTransitionForTransition:(id<UIViewControllerAnimatedTransitioning>)transition
{
    if ([transition isKindOfClass:[FWAnimatedTransition class]]) {
        FWAnimatedTransition *animatedTransition = (FWAnimatedTransition *)transition;
        BOOL transitionIn = (animatedTransition.type == FWAnimatedTransitionTypePresent || animatedTransition.type == FWAnimatedTransitionTypePush);
        id<UIViewControllerInteractiveTransitioning> interactiveTransition = transitionIn ? animatedTransition.inInteractiveTransition : animatedTransition.outInteractiveTransition;
        if ([interactiveTransition isKindOfClass:[FWPercentInteractiveTransition class]]) {
            FWPercentInteractiveTransition *percentTransition = (FWPercentInteractiveTransition *)interactiveTransition;
            if (percentTransition.transitionBlock) {
                percentTransition.transitionBlock(animatedTransition);
            }
            return percentTransition.isInteractive ? percentTransition : nil;
        }
        return interactiveTransition;
    }
    return nil;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    self.type = FWAnimatedTransitionTypePresent;
    // 自动设置和绑定out交互转场，在dismiss前设置生效。in交互转场需要在present之前设置才能生效
    if (!self.isSystem && [self.outInteractiveTransition isKindOfClass:[FWPercentInteractiveTransition class]]) {
        FWPercentInteractiveTransition *interactiveTransition = (FWPercentInteractiveTransition *)self.outInteractiveTransition;
        interactiveTransition.interactiveBlock = ^{
            [presented dismissViewControllerAnimated:YES completion:nil];
        };
        [interactiveTransition interactWithViewController:presented];
    }
    return !self.isSystem ? self : nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.type = FWAnimatedTransitionTypeDismiss;
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

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        // push时检查toVC的转场代理
        FWAnimatedTransition *transition = toVC.fwViewTransition ?: self;
        transition.type = FWAnimatedTransitionTypePush;
        // 自动设置和绑定in交互转场，在pop前设置生效。out交互转场需要在push之前设置才能生效
        if (!transition.isSystem && [transition.outInteractiveTransition isKindOfClass:[FWPercentInteractiveTransition class]]) {
            FWPercentInteractiveTransition *interactiveTransition = (FWPercentInteractiveTransition *)transition.outInteractiveTransition;
            interactiveTransition.interactiveBlock = ^{
                [navigationController popViewControllerAnimated:YES];
            };
            [interactiveTransition interactWithViewController:toVC];
        }
        return !transition.isSystem ? transition : nil;
    } else if (operation == UINavigationControllerOperationPop) {
        // pop时检查fromVC的转场代理
        FWAnimatedTransition *transition = fromVC.fwViewTransition ?: self;
        transition.type = FWAnimatedTransitionTypePop;
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

#pragma mark - FWPercentInteractiveTransition

@interface FWPercentInteractiveTransition ()

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CGFloat percent;

@end

@implementation FWPercentInteractiveTransition

- (instancetype)init
{
    self = [super init];
    if (self) {
        _direction = UISwipeGestureRecognizerDirectionDown;
        _completionPercent = 0.3;
    }
    return self;
}

- (void)interactWithViewController:(UIViewController *)viewController
{
    if (!viewController.view) {
        return;
    }
    
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeAction:)];
    [viewController.view addGestureRecognizer:gestureRecognizer];
}

- (void)gestureRecognizeAction:(UIPanGestureRecognizer *)gestureRecognizer
{
    // 自定义percent计算规则
    if (self.percentBlock) {
        _percent = self.percentBlock(gestureRecognizer);
    // 默认计算当前方向上的进度
    } else {
        CGPoint transition = [gestureRecognizer translationInView:gestureRecognizer.view];
        switch (self.direction) {
            case UISwipeGestureRecognizerDirectionLeft:
                _percent = -transition.x / gestureRecognizer.view.bounds.size.width;
                break;
            case UISwipeGestureRecognizerDirectionRight:
                _percent = transition.x / gestureRecognizer.view.bounds.size.width;
                break;
            case UISwipeGestureRecognizerDirectionUp:
                _percent = -transition.y / gestureRecognizer.view.bounds.size.height;
                break;
            case UISwipeGestureRecognizerDirectionDown:
            default:
                _percent = transition.y / gestureRecognizer.view.bounds.size.height;
                break;
        }
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            _isInteractive = YES;
            // 计算实际交互方向，如果多个方向交互，取绝对值较大的一方
            CGPoint transition = [gestureRecognizer translationInView:gestureRecognizer.view];
            if (fabs(transition.x) > fabs(transition.y)) {
                if (transition.x < 0.0f) {
                    _interactiveDirection = UISwipeGestureRecognizerDirectionLeft;
                } else if (transition.x > 0.0f) {
                    _interactiveDirection = UISwipeGestureRecognizerDirectionRight;
                }
            } else {
                if (transition.y > 0.0f) {
                    _interactiveDirection = UISwipeGestureRecognizerDirectionDown;
                } else if (transition.y < 0.0f) {
                    _interactiveDirection = UISwipeGestureRecognizerDirectionUp;
                }
            }
            
            if (self.interactiveBlock) {
                self.interactiveBlock();
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self updateInteractiveTransition:_percent];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            _isInteractive = NO;
            _interactiveDirection = 0;

            if (!_displayLink) {
                // displayLink强引用self，会循环引用，所以action中需要invalidate
                _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
                [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            }
            break;
        }
        default:
            break;
    }
}

- (void)displayLinkAction
{
    CGFloat timePercent = 2.0 / 60;
    _percent = (_percent > _completionPercent) ? (_percent + timePercent) : (_percent - timePercent);
    [self updateInteractiveTransition:_percent];
    
    if (_percent >= 1.0) {
        [_displayLink invalidate];
        _displayLink = nil;
        [self finishInteractiveTransition];
    }
    
    if (_percent <= 0.0) {
        [_displayLink invalidate];
        _displayLink = nil;
        [self cancelInteractiveTransition];
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
