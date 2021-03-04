/*!
 @header     FWNavigationController.m
 @indexgroup FWFramework
 @brief      FWNavigationController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import "FWNavigationController.h"
#import "FWViewControllerStyle.h"
#import "FWSwizzle.h"
#import "FWProxy.h"
#import <objc/runtime.h>

#pragma mark - UINavigationController+FWBarTransition

@interface UINavigationController (FWBarInternal)

@property (nonatomic, assign) BOOL fwBackgroundViewHidden;
@property (nonatomic, weak) UIViewController *fwTransitionContextToViewController;

@end

@interface UIViewController (FWBarInternal)

@property (nonatomic, strong) UINavigationBar *fwTransitionNavigationBar;

- (void)fwAddTransitionNavigationBarIfNeeded;

@end

@interface UINavigationBar (FWBarTransition)

@property (nonatomic, weak, readonly) UIView *fwBackgroundView;

@property (nonatomic, assign) BOOL fwIsFakeBar;

- (void)fwReplaceStyleWithNavigationBar:(UINavigationBar *)navigationBar;

@end

@implementation UINavigationBar (FWBarTransition)

- (UIView *)fwBackgroundView
{
    return [self fwPerformPropertySelector:@"_backgroundView"];
}

- (BOOL)fwIsFakeBar
{
    return [objc_getAssociatedObject(self, @selector(fwIsFakeBar)) boolValue];
}

- (void)setFwIsFakeBar:(BOOL)fwIsFakeBar
{
    objc_setAssociatedObject(self, @selector(fwIsFakeBar), @(fwIsFakeBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwReplaceStyleWithNavigationBar:(UINavigationBar *)navigationBar
{
    self.barTintColor = navigationBar.barTintColor;
    [self setBackgroundImage:[navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:navigationBar.shadowImage];
    
    self.tintColor = navigationBar.tintColor;
    self.titleTextAttributes = navigationBar.titleTextAttributes;
    if (@available(iOS 11.0, *)) {
        self.largeTitleTextAttributes = navigationBar.largeTitleTextAttributes;
    }
}

@end

@implementation UIViewController (FWBarTransition)

#pragma mark - Accessor

- (id)fwBarTransitionIdentifier
{
    return objc_getAssociatedObject(self, @selector(fwBarTransitionIdentifier));
}

- (void)setFwBarTransitionIdentifier:(id)identifier
{
    objc_setAssociatedObject(self, @selector(fwBarTransitionIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UINavigationBar *)fwTransitionNavigationBar
{
    return objc_getAssociatedObject(self, @selector(fwTransitionNavigationBar));
}

- (void)setFwTransitionNavigationBar:(UINavigationBar *)navigationBar
{
    objc_setAssociatedObject(self, @selector(fwTransitionNavigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)fwResizeTransitionNavigationBarFrame
{
    if (!self.view.window) {
        return;
    }
    UIView *backgroundView = self.navigationController.navigationBar.fwBackgroundView;
    CGRect rect = [backgroundView.superview convertRect:backgroundView.frame toView:self.view];
    self.fwTransitionNavigationBar.frame = rect;
}

- (void)fwAddTransitionNavigationBarIfNeeded
{
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    if (!self.navigationController.navigationBar) {
        return;
    }
    UINavigationBar *bar = [[UINavigationBar alloc] init];
    bar.fwIsFakeBar = YES;
    // 修复iOS14假的NavigationBar不生效问题
    if (@available(iOS 14.0, *)) {
        bar.items = @[[UINavigationItem new]];
    }
    bar.barStyle = self.navigationController.navigationBar.barStyle;
    if (bar.translucent != self.navigationController.navigationBar.translucent) {
        bar.translucent = self.navigationController.navigationBar.translucent;
    }
    [bar fwReplaceStyleWithNavigationBar:self.navigationController.navigationBar];
    [self.fwTransitionNavigationBar removeFromSuperview];
    self.fwTransitionNavigationBar = bar;
    [self fwResizeTransitionNavigationBarFrame];
    if (!self.navigationController.navigationBarHidden && !self.navigationController.navigationBar.hidden) {
        [self.view addSubview:self.fwTransitionNavigationBar];
    }
}

- (BOOL)fwShouldCustomTransitionFrom:(UIViewController *)from to:(UIViewController *)to
{
    if (!from || !to) {
        return YES;
    }
    
    // 如果identifier有值则比较之，不相等才启用转场
    id fromIdentifier = [from fwBarTransitionIdentifier];
    id toIdentifier = [to fwBarTransitionIdentifier];
    if (fromIdentifier || toIdentifier) {
        return ![fromIdentifier isEqual:toIdentifier];
    }
    
    return YES;
}

@end

@implementation UINavigationController (FWBarTransition)

+ (void)fwEnableBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            UIView *backgroundView = selfObject.fwBackgroundView;
            CGRect frame = backgroundView.frame;
            frame.size.height = selfObject.frame.size.height + fabs(frame.origin.y);
            backgroundView.frame = frame;
        }));
        
        FWSwizzleMethod(objc_getClass("_UIBarBackground"), @selector(setHidden:), nil, FWSwizzleType(UIView *), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            UIResponder *responder = (UIResponder *)selfObject;
            while (responder) {
                if ([responder isKindOfClass:[UINavigationBar class]] && ((UINavigationBar *)responder).fwIsFakeBar) {
                    return;
                }
                if ([responder isKindOfClass:[UINavigationController class]]) {
                    FWSwizzleOriginal(((UINavigationController *)responder).fwBackgroundViewHidden);
                    return;
                }
                responder = responder.nextResponder;
            }
            
            FWSwizzleOriginal(hidden);
        }));
        FWSwizzleMethod(objc_getClass("_UIParallaxDimmingView"), @selector(layoutSubviews), nil, FWSwizzleType(UIView *), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            // 处理导航栏左侧阴影占不满的问题。兼容iOS13下如果navigationBar是磨砂的，则每个视图内部都会有一个磨砂，而磨砂再包裹了imageView等subview
            if ([selfObject.subviews.firstObject isKindOfClass:[UIImageView class]] ||
                [selfObject.subviews.firstObject isKindOfClass:[UIVisualEffectView class]]) {
                UIView *shadowView = selfObject.subviews.firstObject;
                if (selfObject.frame.origin.y > 0 && shadowView.frame.origin.y == 0) {
                    shadowView.frame = CGRectMake(shadowView.frame.origin.x,
                                                  shadowView.frame.origin.y - selfObject.frame.origin.y,
                                                  shadowView.frame.size.width,
                                                  shadowView.frame.size.height + selfObject.frame.origin.y);
                }
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            UIViewController *transitionViewController = selfObject.navigationController.fwTransitionContextToViewController;
            if (selfObject.fwTransitionNavigationBar) {
                [selfObject.navigationController.navigationBar fwReplaceStyleWithNavigationBar:selfObject.fwTransitionNavigationBar];
                if (!transitionViewController || [transitionViewController isEqual:selfObject]) {
                    [selfObject.fwTransitionNavigationBar removeFromSuperview];
                    selfObject.fwTransitionNavigationBar = nil;
                }
            }
            if ([transitionViewController isEqual:selfObject]) {
                selfObject.navigationController.fwTransitionContextToViewController = nil;
            }
            selfObject.navigationController.fwBackgroundViewHidden = NO;
            FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UIViewController, @selector(viewWillLayoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            id<UIViewControllerTransitionCoordinator> tc = selfObject.transitionCoordinator;
            UIViewController *fromViewController = [tc viewControllerForKey:UITransitionContextFromViewControllerKey];
            UIViewController *toViewController = [tc viewControllerForKey:UITransitionContextToViewControllerKey];
            if (![selfObject fwShouldCustomTransitionFrom:fromViewController to:toViewController]) {
                FWSwizzleOriginal();
                return;
            }
            
            if ([selfObject isEqual:selfObject.navigationController.viewControllers.lastObject] && [toViewController isEqual:selfObject] && tc.presentationStyle == UIModalPresentationNone) {
                if (selfObject.navigationController.navigationBar.translucent) {
                    [tc containerView].backgroundColor = [selfObject.navigationController fwContainerBackgroundColor];
                }
                fromViewController.view.clipsToBounds = NO;
                toViewController.view.clipsToBounds = NO;
                if (!selfObject.fwTransitionNavigationBar) {
                    [selfObject fwAddTransitionNavigationBarIfNeeded];
                    selfObject.navigationController.fwBackgroundViewHidden = YES;
                }
                [selfObject fwResizeTransitionNavigationBarFrame];
            }
            if (selfObject.fwTransitionNavigationBar) {
                [selfObject.view bringSubviewToFront:selfObject.fwTransitionNavigationBar];
            }
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UINavigationController, @selector(pushViewController:animated:), FWSwizzleReturn(void), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            if (!disappearingViewController) {
                return FWSwizzleOriginal(viewController, animated);
            }
            if (![selfObject fwShouldCustomTransitionFrom:disappearingViewController to:viewController]) {
                return FWSwizzleOriginal(viewController, animated);
            }
            
            if (!selfObject.fwTransitionContextToViewController || !disappearingViewController.fwTransitionNavigationBar) {
                [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
            }
            if (animated) {
                selfObject.fwTransitionContextToViewController = viewController;
                if (disappearingViewController.fwTransitionNavigationBar) {
                    disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
                }
            }
            return FWSwizzleOriginal(viewController, animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(popViewControllerAnimated:), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            if (selfObject.viewControllers.count < 2) {
                return FWSwizzleOriginal(animated);
            }
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            UIViewController *appearingViewController = selfObject.viewControllers[selfObject.viewControllers.count - 2];
            if (![selfObject fwShouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
                return FWSwizzleOriginal(animated);
            }
            
            [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
            if (appearingViewController.fwTransitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = appearingViewController.fwTransitionNavigationBar;
                [selfObject.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(popToViewController:animated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
            if (![selfObject.viewControllers containsObject:viewController] || selfObject.viewControllers.count < 2) {
                return FWSwizzleOriginal(viewController, animated);
            }
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            if (![selfObject fwShouldCustomTransitionFrom:disappearingViewController to:viewController]) {
                return FWSwizzleOriginal(viewController, animated);
            }
            
            [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
            if (viewController.fwTransitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = viewController.fwTransitionNavigationBar;
                [selfObject.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(viewController, animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(popToRootViewControllerAnimated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            if (selfObject.viewControllers.count < 2) {
                return FWSwizzleOriginal(animated);
            }
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            UIViewController *rootViewController = selfObject.viewControllers.firstObject;
            if (![selfObject fwShouldCustomTransitionFrom:disappearingViewController to:rootViewController]) {
                return FWSwizzleOriginal(animated);
            }
            
            [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
            if (rootViewController.fwTransitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = rootViewController.fwTransitionNavigationBar;
                [selfObject.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(setViewControllers:animated:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<UIViewController *> *viewControllers, BOOL animated), FWSwizzleCode({
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            UIViewController *appearingViewController = viewControllers.count > 0 ? viewControllers.lastObject : nil;
            if (![selfObject fwShouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
                return FWSwizzleOriginal(viewControllers, animated);
            }
            
            if (animated && disappearingViewController && ![disappearingViewController isEqual:viewControllers.lastObject]) {
                [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
                if (disappearingViewController.fwTransitionNavigationBar) {
                    disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
                }
            }
            return FWSwizzleOriginal(viewControllers, animated);
        }));
    });
}

#pragma mark - Accessor

- (UIColor *)fwContainerBackgroundColor
{
    UIColor *backgroundColor = objc_getAssociatedObject(self, @selector(fwContainerBackgroundColor));
    return backgroundColor ?: [UIColor whiteColor];
}

- (void)setFwContainerBackgroundColor:(UIColor *)backgroundColor
{
    objc_setAssociatedObject(self, @selector(fwContainerBackgroundColor), backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwBackgroundViewHidden
{
    return [objc_getAssociatedObject(self, @selector(fwBackgroundViewHidden)) boolValue];
}

- (void)setFwBackgroundViewHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fwBackgroundViewHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.navigationBar.fwBackgroundView setHidden:hidden];
}

- (UIViewController *)fwTransitionContextToViewController
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwTransitionContextToViewController));
    return value.object;
}

- (void)setFwTransitionContextToViewController:(UIViewController *)viewController
{
    objc_setAssociatedObject(self, @selector(fwTransitionContextToViewController), [[FWWeakObject alloc] initWithObject:viewController], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UINavigationController+FWPopGesture

@implementation UIViewController (FWPopGesture)

- (BOOL)fwForcePopGesture
{
    return [objc_getAssociatedObject(self, @selector(fwForcePopGesture)) boolValue];
}

- (void)setFwForcePopGesture:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwForcePopGesture), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)issetFwForcePopGesture
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwForcePopGesture));
    return value != nil;
}

- (BOOL)fwFullscreenPopGestureDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwFullscreenPopGestureDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(fwFullscreenPopGestureDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwFullscreenPopGestureDistance
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setFwFullscreenPopGestureDistance:(CGFloat)distance
{
    objc_setAssociatedObject(self, @selector(fwFullscreenPopGestureDistance), @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface FWGestureRecognizerDelegateProxy : FWDelegateProxy <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWGestureRecognizerDelegateProxy

- (BOOL)shouldForceReceive
{
    if (self.navigationController.viewControllers.count <= 1) return NO;
    if (!self.navigationController.interactivePopGestureRecognizer.enabled) return NO;
    if ([self.navigationController.topViewController issetFwForcePopGesture]) {
        return self.navigationController.topViewController.fwForcePopGesture;
    }
    return self.navigationController.fwForcePopGesture;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        BOOL shouldPop = YES;
        if ([self.navigationController.topViewController respondsToSelector:@selector(fwPopBackBarItem)]) {
            // 调用钩子。如果返回NO，则不开始手势；如果返回YES，则使用系统方式
            shouldPop = [self.navigationController.topViewController fwPopBackBarItem];
        }
        if (shouldPop) {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
                return [self.delegate gestureRecognizerShouldBegin:gestureRecognizer];
            }
        }
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
            BOOL shouldReceive = [self.delegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

- (BOOL)_gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveEvent:(UIEvent *)event
{
    // 修复iOS13.4拦截返回失效问题，返回YES才会走后续流程
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(_gestureRecognizer:shouldReceiveEvent:)]) {
            BOOL shouldReceive = [self.delegate _gestureRecognizer:gestureRecognizer shouldReceiveEvent:event];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

@end

@interface FWFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.fwFullscreenPopGestureDisabled) {
        return NO;
    }
    
    if ([topViewController respondsToSelector:@selector(fwPopBackBarItem)] &&
        ![topViewController fwPopBackBarItem]) {
        return NO;
    }
    
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.fwFullscreenPopGestureDistance;
    if (maxAllowedInitialDistance > 0 && beginningLocation.x > maxAllowedInitialDistance) {
        return NO;
    }
    
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    BOOL isLeftToRight = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight;
    CGFloat multiplier = isLeftToRight ? 1 : - 1;
    if ((translation.x * multiplier) <= 0) {
        return NO;
    }
    
    return YES;
}

@end

@implementation UINavigationController (FWPopGesture)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            // 拦截系统返回手势事件代理，加载自定义代理方法
            if (selfObject.interactivePopGestureRecognizer.delegate != selfObject.fwDelegateProxy) {
                selfObject.fwDelegateProxy.delegate = selfObject.interactivePopGestureRecognizer.delegate;
                selfObject.fwDelegateProxy.navigationController = selfObject;
                selfObject.interactivePopGestureRecognizer.delegate = selfObject.fwDelegateProxy;
            }
        }));
        FWSwizzleClass(UINavigationController, @selector(navigationBar:shouldPopItem:), FWSwizzleReturn(BOOL), FWSwizzleArgs(UINavigationBar *navigationBar, UINavigationItem *item), FWSwizzleCode({
            // 检查返回按钮点击事件钩子
            if (selfObject.viewControllers.count >= navigationBar.items.count &&
                [selfObject.topViewController respondsToSelector:@selector(fwPopBackBarItem)]) {
                // 调用钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
                if (![selfObject.topViewController fwPopBackBarItem]) {
                    if (@available(iOS 11, *)) {
                    } else {
                        [navigationBar.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
                            if (subview.alpha < 1.0) {
                                [UIView animateWithDuration:.25 animations:^{
                                    subview.alpha = 1.0;
                                }];
                            }
                        }];
                    }
                    return NO;
                }
            }
            
            return FWSwizzleOriginal(navigationBar, item);
        }));
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarHidden), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarStyle), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
    });
}

- (FWGestureRecognizerDelegateProxy *)fwDelegateProxy
{
    FWGestureRecognizerDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWGestureRecognizerDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

+ (BOOL)fwIsFullscreenPopGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.delegate isKindOfClass:[FWFullscreenPopGestureRecognizerDelegate class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwFullscreenPopGestureEnabled
{
    return self.fwFullscreenPopGestureRecognizer.enabled;
}

- (void)setFwFullscreenPopGestureEnabled:(BOOL)enabled
{
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.fwFullscreenPopGestureRecognizer]) {
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.fwFullscreenPopGestureRecognizer];
        
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        self.fwFullscreenPopGestureRecognizer.delegate = self.fwPopGestureRecognizerDelegate;
        [self.fwFullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
    }
    
    self.fwFullscreenPopGestureRecognizer.enabled = enabled;
    self.interactivePopGestureRecognizer.enabled = !enabled;
}

- (FWFullscreenPopGestureRecognizerDelegate *)fwPopGestureRecognizerDelegate
{
    FWFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[FWFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)fwFullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

@end
