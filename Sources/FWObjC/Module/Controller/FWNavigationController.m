//
//  FWNavigationController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWNavigationController.h"
#import "FWNavigationStyle.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - UINavigationController+FWBarTransition

@interface UINavigationController (FWBarInternal)

@property (nonatomic, assign) BOOL fw_backgroundViewHidden;
@property (nonatomic, weak) UIViewController *fw_transitionContextToViewController;

@end

@interface UIViewController (FWBarInternal)

@property (nonatomic, strong) UINavigationBar *fw_transitionNavigationBar;

- (void)fw_addTransitionNavigationBarIfNeeded;

@end

@implementation UINavigationBar (FWBarTransition)

- (UIView *)fw_backgroundView
{
    return [self fw_invokeGetter:@"_backgroundView"];
}

- (UIView *)fw_contentView
{
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"ContentView"]) return subview;
    }
    return nil;
}

- (UIView *)fw_largeTitleView
{
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"LargeTitleView"]) return subview;
    }
    return nil;
}

+ (CGFloat)fw_largeTitleHeight
{
    return 52;
}

- (BOOL)fw_isFakeBar
{
    return [objc_getAssociatedObject(self, @selector(fw_isFakeBar)) boolValue];
}

- (void)setFw_isFakeBar:(BOOL)isFakeBar
{
    objc_setAssociatedObject(self, @selector(fw_isFakeBar), @(isFakeBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_replaceStyleWithNavigationBar:(UINavigationBar *)navigationBar
{
    self.barTintColor = navigationBar.barTintColor;
    [self setBackgroundImage:[navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:navigationBar.shadowImage];
    
    self.tintColor = navigationBar.tintColor;
    self.titleTextAttributes = navigationBar.titleTextAttributes;
    self.largeTitleTextAttributes = navigationBar.largeTitleTextAttributes;
    
    if (UINavigationBar.fw_appearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.standardAppearance = navigationBar.standardAppearance;
        self.compactAppearance = navigationBar.compactAppearance;
        self.scrollEdgeAppearance = navigationBar.scrollEdgeAppearance;
        if (@available(iOS 15.0, *)) {
            self.compactScrollEdgeAppearance = navigationBar.compactScrollEdgeAppearance;
        }
    }}
}

@end

@implementation UIToolbar (FWBarTransition)

- (UIView *)fw_backgroundView
{
    return [self fw_invokeGetter:@"_backgroundView"];
}

- (UIView *)fw_contentView
{
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"ContentView"]) return subview;
    }
    return nil;
}

@end

@implementation UIViewController (FWBarTransition)

#pragma mark - Accessor

- (id)fw_barTransitionIdentifier
{
    return objc_getAssociatedObject(self, @selector(fw_barTransitionIdentifier));
}

- (void)setFw_barTransitionIdentifier:(id)identifier
{
    objc_setAssociatedObject(self, @selector(fw_barTransitionIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UINavigationBar *)fw_transitionNavigationBar
{
    return objc_getAssociatedObject(self, @selector(fw_transitionNavigationBar));
}

- (void)setFw_transitionNavigationBar:(UINavigationBar *)navigationBar
{
    objc_setAssociatedObject(self, @selector(fw_transitionNavigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)fw_resizeTransitionNavigationBarFrame
{
    if (!self.view.window) {
        return;
    }
    UIView *backgroundView = self.navigationController.navigationBar.fw_backgroundView;
    CGRect rect = [backgroundView.superview convertRect:backgroundView.frame toView:self.view];
    self.fw_transitionNavigationBar.frame = rect;
}

- (void)fw_addTransitionNavigationBarIfNeeded
{
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    if (!self.navigationController.navigationBar) {
        return;
    }
    UINavigationBar *bar = [[UINavigationBar alloc] init];
    bar.fw_isFakeBar = YES;
    // 修复iOS14假的NavigationBar不生效问题
    if (@available(iOS 14.0, *)) {
        bar.items = @[[UINavigationItem new]];
    }
    bar.barStyle = self.navigationController.navigationBar.barStyle;
    if (bar.translucent != self.navigationController.navigationBar.translucent) {
        bar.translucent = self.navigationController.navigationBar.translucent;
    }
    [bar fw_replaceStyleWithNavigationBar:self.navigationController.navigationBar];
    [self.fw_transitionNavigationBar removeFromSuperview];
    self.fw_transitionNavigationBar = bar;
    [self fw_resizeTransitionNavigationBarFrame];
    if (!self.navigationController.navigationBarHidden && !self.navigationController.navigationBar.hidden) {
        [self.view addSubview:self.fw_transitionNavigationBar];
    }
}

- (BOOL)fw_shouldCustomTransitionFrom:(UIViewController *)from to:(UIViewController *)to
{
    if (!from || !to) {
        return YES;
    }
    
    // 如果identifier有值则比较之，不相等才启用转场
    id fromIdentifier = [from fw_barTransitionIdentifier];
    id toIdentifier = [to fw_barTransitionIdentifier];
    if (fromIdentifier || toIdentifier) {
        return ![fromIdentifier isEqual:toIdentifier];
    }
    
    return YES;
}

@end

@implementation UINavigationController (FWBarTransition)

#pragma mark - Accessor

- (UIColor *)fw_containerBackgroundColor
{
    UIColor *backgroundColor = objc_getAssociatedObject(self, @selector(fw_containerBackgroundColor));
    return backgroundColor ?: [UIColor clearColor];
}

- (void)setFw_containerBackgroundColor:(UIColor *)backgroundColor
{
    objc_setAssociatedObject(self, @selector(fw_containerBackgroundColor), backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_backgroundViewHidden
{
    return [objc_getAssociatedObject(self, @selector(fw_backgroundViewHidden)) boolValue];
}

- (void)setFw_backgroundViewHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fw_backgroundViewHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.navigationBar.fw_backgroundView setHidden:hidden];
}

- (UIViewController *)fw_transitionContextToViewController
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fw_transitionContextToViewController));
    return value.object;
}

- (void)setFw_transitionContextToViewController:(UIViewController *)viewController
{
    objc_setAssociatedObject(self, @selector(fw_transitionContextToViewController), [[FWWeakObject alloc] initWithObject:viewController], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)fw_enableBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationBar, @selector(layoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            UIView *backgroundView = selfObject.fw_backgroundView;
            CGRect frame = backgroundView.frame;
            frame.size.height = selfObject.frame.size.height + fabs(frame.origin.y);
            backgroundView.frame = frame;
        }));
        
        FWSwizzleMethod(objc_getClass("_UIBarBackground"), @selector(setHidden:), nil, FWSwizzleType(UIView *), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            UIResponder *responder = (UIResponder *)selfObject;
            while (responder) {
                if ([responder isKindOfClass:[UINavigationBar class]] && ((UINavigationBar *)responder).fw_isFakeBar) {
                    return;
                }
                if ([responder isKindOfClass:[UINavigationController class]]) {
                    FWSwizzleOriginal(((UINavigationController *)responder).fw_backgroundViewHidden);
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
            UIViewController *transitionViewController = selfObject.navigationController.fw_transitionContextToViewController;
            if (selfObject.fw_transitionNavigationBar) {
                [selfObject.navigationController.navigationBar fw_replaceStyleWithNavigationBar:selfObject.fw_transitionNavigationBar];
                if (!transitionViewController || [transitionViewController isEqual:selfObject]) {
                    [selfObject.fw_transitionNavigationBar removeFromSuperview];
                    selfObject.fw_transitionNavigationBar = nil;
                }
            }
            if ([transitionViewController isEqual:selfObject]) {
                selfObject.navigationController.fw_transitionContextToViewController = nil;
            }
            selfObject.navigationController.fw_backgroundViewHidden = NO;
            FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UIViewController, @selector(viewWillLayoutSubviews), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            id<UIViewControllerTransitionCoordinator> tc = selfObject.transitionCoordinator;
            UIViewController *fromViewController = [tc viewControllerForKey:UITransitionContextFromViewControllerKey];
            UIViewController *toViewController = [tc viewControllerForKey:UITransitionContextToViewControllerKey];
            if (![selfObject fw_shouldCustomTransitionFrom:fromViewController to:toViewController]) {
                FWSwizzleOriginal();
                return;
            }
            
            if ([selfObject isEqual:selfObject.navigationController.viewControllers.lastObject] && [toViewController isEqual:selfObject] && tc.presentationStyle == UIModalPresentationNone) {
                if (selfObject.navigationController.navigationBar.translucent) {
                    [tc containerView].backgroundColor = [selfObject.navigationController fw_containerBackgroundColor];
                }
                fromViewController.view.clipsToBounds = NO;
                toViewController.view.clipsToBounds = NO;
                if (!selfObject.fw_transitionNavigationBar) {
                    [selfObject fw_addTransitionNavigationBarIfNeeded];
                    selfObject.navigationController.fw_backgroundViewHidden = YES;
                }
                [selfObject fw_resizeTransitionNavigationBarFrame];
            }
            if (selfObject.fw_transitionNavigationBar) {
                [selfObject.view bringSubviewToFront:selfObject.fw_transitionNavigationBar];
            }
            FWSwizzleOriginal();
        }));
        
        FWSwizzleClass(UINavigationController, @selector(pushViewController:animated:), FWSwizzleReturn(void), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            if (!disappearingViewController) {
                return FWSwizzleOriginal(viewController, animated);
            }
            if (![selfObject fw_shouldCustomTransitionFrom:disappearingViewController to:viewController]) {
                return FWSwizzleOriginal(viewController, animated);
            }
            
            if (viewController && [selfObject.viewControllers containsObject:viewController]) return;
            if (!selfObject.fw_transitionContextToViewController || !disappearingViewController.fw_transitionNavigationBar) {
                [disappearingViewController fw_addTransitionNavigationBarIfNeeded];
            }
            if (animated) {
                selfObject.fw_transitionContextToViewController = viewController;
                if (disappearingViewController.fw_transitionNavigationBar) {
                    disappearingViewController.navigationController.fw_backgroundViewHidden = YES;
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
            if (![selfObject fw_shouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
                return FWSwizzleOriginal(animated);
            }
            
            [disappearingViewController fw_addTransitionNavigationBarIfNeeded];
            if (appearingViewController.fw_transitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = appearingViewController.fw_transitionNavigationBar;
                [selfObject.navigationBar fw_replaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fw_backgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(popToViewController:animated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
            if (![selfObject.viewControllers containsObject:viewController] || selfObject.viewControllers.count < 2) {
                return FWSwizzleOriginal(viewController, animated);
            }
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            if (![selfObject fw_shouldCustomTransitionFrom:disappearingViewController to:viewController]) {
                return FWSwizzleOriginal(viewController, animated);
            }
            
            [disappearingViewController fw_addTransitionNavigationBarIfNeeded];
            if (viewController.fw_transitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = viewController.fw_transitionNavigationBar;
                [selfObject.navigationBar fw_replaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fw_backgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(viewController, animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(popToRootViewControllerAnimated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            if (selfObject.viewControllers.count < 2) {
                return FWSwizzleOriginal(animated);
            }
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            UIViewController *rootViewController = selfObject.viewControllers.firstObject;
            if (![selfObject fw_shouldCustomTransitionFrom:disappearingViewController to:rootViewController]) {
                return FWSwizzleOriginal(animated);
            }
            
            [disappearingViewController fw_addTransitionNavigationBarIfNeeded];
            if (rootViewController.fw_transitionNavigationBar) {
                UINavigationBar *appearingNavigationBar = rootViewController.fw_transitionNavigationBar;
                [selfObject.navigationBar fw_replaceStyleWithNavigationBar:appearingNavigationBar];
            }
            if (animated) {
                disappearingViewController.navigationController.fw_backgroundViewHidden = YES;
            }
            return FWSwizzleOriginal(animated);
        }));
        FWSwizzleClass(UINavigationController, @selector(setViewControllers:animated:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<UIViewController *> *viewControllers, BOOL animated), FWSwizzleCode({
            UIViewController *disappearingViewController = selfObject.viewControllers.lastObject;
            UIViewController *appearingViewController = viewControllers.count > 0 ? viewControllers.lastObject : nil;
            if (![selfObject fw_shouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
                return FWSwizzleOriginal(viewControllers, animated);
            }
            
            if (animated && disappearingViewController && ![disappearingViewController isEqual:viewControllers.lastObject]) {
                [disappearingViewController fw_addTransitionNavigationBarIfNeeded];
                if (disappearingViewController.fw_transitionNavigationBar) {
                    disappearingViewController.navigationController.fw_backgroundViewHidden = YES;
                }
            }
            return FWSwizzleOriginal(viewControllers, animated);
        }));
    });
}

#pragma mark - Fixed

- (BOOL)fw_shouldBottomBarBeHidden
{
    return [objc_getAssociatedObject(self, @selector(fw_shouldBottomBarBeHidden)) boolValue];
}

- (void)setFw_shouldBottomBarBeHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fw_shouldBottomBarBeHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 修复iOS14.0如果pop到一个hidesBottomBarWhenPushed=NO的vc，tabBar无法正确显示出来的bug；iOS14.2已修复该问题
        if (@available(iOS 14.2, *)) {} else if (@available(iOS 14.0, *)) {
            FWSwizzleClass(UINavigationController, @selector(popToViewController:animated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
                if (animated && selfObject.tabBarController && !viewController.hidesBottomBarWhenPushed) {
                    BOOL systemShouldHideTabBar = NO;
                    NSUInteger index = [selfObject.viewControllers indexOfObject:viewController];
                    if (index != NSNotFound) {
                        NSArray<UIViewController *> *viewControllers = [selfObject.viewControllers subarrayWithRange:NSMakeRange(0, index + 1)];
                        for (UIViewController *vc in viewControllers) {
                            if (vc.hidesBottomBarWhenPushed) {
                                systemShouldHideTabBar = YES;
                            }
                        }
                        if (!systemShouldHideTabBar) {
                            selfObject.fw_shouldBottomBarBeHidden = YES;
                        }
                    }
                }
                
                NSArray<UIViewController *> *result = FWSwizzleOriginal(viewController, animated);
                selfObject.fw_shouldBottomBarBeHidden = NO;
                return result;
            }));
            FWSwizzleClass(UINavigationController, @selector(popToRootViewControllerAnimated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
                if (animated && selfObject.tabBarController && !selfObject.viewControllers.firstObject.hidesBottomBarWhenPushed && selfObject.viewControllers.count > 2) {
                    selfObject.fw_shouldBottomBarBeHidden = YES;
                }
                
                NSArray<UIViewController *> *result = FWSwizzleOriginal(animated);
                selfObject.fw_shouldBottomBarBeHidden = NO;
                return result;
            }));
            FWSwizzleClass(UINavigationController, @selector(setViewControllers:animated:), FWSwizzleReturn(void), FWSwizzleArgs(NSArray<UIViewController *> *viewControllers, BOOL animated), FWSwizzleCode({
                UIViewController *viewController = viewControllers.lastObject;
                if (animated && selfObject.tabBarController && !viewController.hidesBottomBarWhenPushed) {
                    BOOL systemShouldHideTabBar = NO;
                    for (UIViewController *vc in viewControllers) {
                        if (vc.hidesBottomBarWhenPushed) {
                            systemShouldHideTabBar = YES;
                        }
                    }
                    if (!systemShouldHideTabBar) {
                        selfObject.fw_shouldBottomBarBeHidden = YES;
                    }
                }
                
                FWSwizzleOriginal(viewControllers, animated);
                selfObject.fw_shouldBottomBarBeHidden = NO;
            }));
            FWSwizzleClass(UINavigationController, NSSelectorFromString(@"_shouldBottomBarBeHidden"), FWSwizzleReturn(BOOL), FWSwizzleArgs(), FWSwizzleCode({
                BOOL result = FWSwizzleOriginal();
                if (selfObject.fw_shouldBottomBarBeHidden) {
                    result = NO;
                }
                return result;
            }));
        }
    });
}

@end

#pragma mark - UINavigationController+FWFullscreenPopGesture

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
    if (topViewController.fw_fullscreenPopGestureDisabled) {
        return NO;
    }
    
    if ([topViewController respondsToSelector:@selector(shouldPopController)] &&
        ![topViewController shouldPopController]) {
        return NO;
    }
    
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.fw_fullscreenPopGestureDistance;
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

@implementation UIViewController (FWFullscreenPopGesture)

- (BOOL)fw_fullscreenPopGestureDisabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_fullscreenPopGestureDisabled:(BOOL)disabled
{
    objc_setAssociatedObject(self, @selector(fw_fullscreenPopGestureDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_fullscreenPopGestureDistance
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setFw_fullscreenPopGestureDistance:(CGFloat)distance
{
    objc_setAssociatedObject(self, @selector(fw_fullscreenPopGestureDistance), @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UINavigationController (FWFullscreenPopGesture)

- (BOOL)fw_fullscreenPopGestureEnabled
{
    return self.fw_fullscreenPopGestureRecognizer.enabled;
}

- (void)setFw_fullscreenPopGestureEnabled:(BOOL)enabled
{
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.fw_fullscreenPopGestureRecognizer]) {
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.fw_fullscreenPopGestureRecognizer];
        
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        self.fw_fullscreenPopGestureRecognizer.delegate = self.fw_popGestureRecognizerDelegate;
        [self.fw_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
    }
    
    self.fw_fullscreenPopGestureRecognizer.enabled = enabled;
    self.interactivePopGestureRecognizer.enabled = !enabled;
}

- (FWFullscreenPopGestureRecognizerDelegate *)fw_popGestureRecognizerDelegate
{
    FWFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[FWFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)fw_fullscreenPopGestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

+ (BOOL)fw_isFullscreenPopGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer.delegate isKindOfClass:[FWFullscreenPopGestureRecognizerDelegate class]]) {
        return YES;
    }
    return NO;
}

@end
