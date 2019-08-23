/*!
 @header     UINavigationController+FWBar.m
 @indexgroup FWFramework
 @brief      UINavigationController+FWBar
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import "UINavigationController+FWBar.h"
#import "UIViewController+FWBar.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UINavigationController+FWBarInternal

@interface UINavigationController (FWBarInternal)

@property (nonatomic, assign) BOOL fwBackgroundViewHidden;
@property (nonatomic, weak) UIViewController *fwTransitionContextToViewController;

@end

#pragma mark - UIViewController+FWBarInternal

@interface UIViewController (FWBarInternal)

@property (nonatomic, strong) UINavigationBar *fwTransitionNavigationBar;

- (void)fwAddTransitionNavigationBarIfNeeded;

@end

#pragma mark - UINavigationBar+FWBarTransition

@interface UINavigationBar (FWBarTransition)

@property (nonatomic, assign) BOOL fwIsFakeBar;

- (void)fwReplaceStyleWithNavigationBar:(UINavigationBar *)navigationBar;

@end

@implementation UINavigationBar (FWBarTransition)

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(layoutSubviews) with:@selector(fwInnerUINavigationBarLayoutSubviews)];
    });
}

- (void)fwInnerUINavigationBarLayoutSubviews
{
    [self fwInnerUINavigationBarLayoutSubviews];
    UIView *backgroundView = self.fwBackgroundView;
    CGRect frame = backgroundView.frame;
    frame.size.height = self.frame.size.height + fabs(frame.origin.y);
    backgroundView.frame = frame;
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
}

@end

#pragma mark - UIView+FWBarTransition

@interface UIView (FWBarTransition)

@end

@implementation UIView (FWBarTransition)

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject fwSwizzleInstanceMethod:@selector(setHidden:) in:objc_getClass("_UIBarBackground") with:@selector(fwInnerUIBarBackgroundSetHidden:) in:[self class]];
        [NSObject fwSwizzleInstanceMethod:@selector(layoutSubviews) in:objc_getClass("_UIParallaxDimmingView") with:@selector(fwInnerUIParallaxDimmingViewLayoutSubviews) in:[self class]];
    });
}

- (void)fwInnerUIBarBackgroundSetHidden:(BOOL)hidden
{
    UIResponder *responder = (UIResponder *)self;
    while (responder) {
        if ([responder isKindOfClass:[UINavigationBar class]] && ((UINavigationBar *)responder).fwIsFakeBar) {
            return;
        }
        if ([responder isKindOfClass:[UINavigationController class]]) {
            [self fwInnerUIBarBackgroundSetHidden:((UINavigationController *)responder).fwBackgroundViewHidden];
            return;
        }
        responder = responder.nextResponder;
    }
    [self fwInnerUIBarBackgroundSetHidden:hidden];
}

- (void)fwInnerUIParallaxDimmingViewLayoutSubviews
{
    [self fwInnerUIParallaxDimmingViewLayoutSubviews];
    // 处理导航栏左侧阴影占不满的问题。兼容iOS13下如果navigationBar是磨砂的，则每个视图内部都会有一个磨砂，而磨砂再包裹了imageView等subview
    if ([self.subviews.firstObject isKindOfClass:[UIImageView class]] ||
        [self.subviews.firstObject isKindOfClass:[UIVisualEffectView class]]) {
        UIView *shadowView = self.subviews.firstObject;
        if (self.frame.origin.y > 0 && shadowView.frame.origin.y == 0) {
            shadowView.frame = CGRectMake(shadowView.frame.origin.x,
                                          shadowView.frame.origin.y - self.frame.origin.y,
                                          shadowView.frame.size.width,
                                          shadowView.frame.size.height + self.frame.origin.y);
        }
    }
}

@end

#pragma mark - UIViewController+FWBarTransition

@implementation UIViewController (FWBarTransition)

#pragma mark - Hook

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(viewDidAppear:) with:@selector(fwInnerTransitionViewDidAppear:)];
        [self fwSwizzleInstanceMethod:@selector(viewWillLayoutSubviews) with:@selector(fwInnerTransitionViewWillLayoutSubviews)];
    });
}

- (void)fwInnerTransitionViewDidAppear:(BOOL)animated
{
    UIViewController *transitionViewController = self.navigationController.fwTransitionContextToViewController;
    if (self.fwTransitionNavigationBar) {
        [self.navigationController.navigationBar fwReplaceStyleWithNavigationBar:self.fwTransitionNavigationBar];
        if (!transitionViewController || [transitionViewController isEqual:self]) {
            [self.fwTransitionNavigationBar removeFromSuperview];
            self.fwTransitionNavigationBar = nil;
        }
    }
    if ([transitionViewController isEqual:self]) {
        self.navigationController.fwTransitionContextToViewController = nil;
    }
    self.navigationController.fwBackgroundViewHidden = NO;
    [self fwInnerTransitionViewDidAppear:animated];
}

- (void)fwInnerTransitionViewWillLayoutSubviews
{
    id<UIViewControllerTransitionCoordinator> tc = self.transitionCoordinator;
    UIViewController *fromViewController = [tc viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [tc viewControllerForKey:UITransitionContextToViewControllerKey];
    if (![self fwShouldCustomTransitionFrom:fromViewController to:toViewController]) {
        [self fwInnerTransitionViewWillLayoutSubviews];
        return;
    }
    
    if ([self isEqual:self.navigationController.viewControllers.lastObject] && [toViewController isEqual:self] && tc.presentationStyle == UIModalPresentationNone) {
        if (self.navigationController.navigationBar.translucent) {
            [tc containerView].backgroundColor = [self.navigationController fwContainerViewBackgroundColor];
        }
        fromViewController.view.clipsToBounds = NO;
        toViewController.view.clipsToBounds = NO;
        if (!self.fwTransitionNavigationBar) {
            [self fwAddTransitionNavigationBarIfNeeded];
            self.navigationController.fwBackgroundViewHidden = YES;
        }
        [self fwResizeTransitionNavigationBarFrame];
    }
    if (self.fwTransitionNavigationBar) {
        [self.view bringSubviewToFront:self.fwTransitionNavigationBar];
    }
    [self fwInnerTransitionViewWillLayoutSubviews];
}

#pragma mark - Accessor

- (id)fwNavigationBarTransitionIdentifier
{
    return objc_getAssociatedObject(self, @selector(fwNavigationBarTransitionIdentifier));
}

- (void)setFwNavigationBarTransitionIdentifier:(id)identifier
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarTransitionIdentifier), identifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    id fromIdentifier = [from fwNavigationBarTransitionIdentifier];
    id toIdentifier = [to fwNavigationBarTransitionIdentifier];
    if (fromIdentifier || toIdentifier) {
        return ![fromIdentifier isEqual:toIdentifier];
    }
    
    return YES;
}

@end

#pragma mark - UINavigationController+FWBar

@implementation UINavigationController (FWBar)

+ (void)fwEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UINavigationBar fwInnerEnableNavigationBarTransition];
        [UIView fwInnerEnableNavigationBarTransition];
        [UIViewController fwInnerEnableNavigationBarTransition];
        [UINavigationController fwInnerEnableNavigationBarTransition];
    });
}

#pragma mark - Hook

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(pushViewController:animated:) with:@selector(fwInnerPushViewController:animated:)];
        [self fwSwizzleInstanceMethod:@selector(popViewControllerAnimated:) with:@selector(fwInnerPopViewControllerAnimated:)];
        [self fwSwizzleInstanceMethod:@selector(popToViewController:animated:) with:@selector(fwInnerPopToViewController:animated:)];
        [self fwSwizzleInstanceMethod:@selector(popToRootViewControllerAnimated:) with:@selector(fwInnerPopToRootViewControllerAnimated:)];
        [self fwSwizzleInstanceMethod:@selector(setViewControllers:animated:) with:@selector(fwInnerSetViewControllers:animated:)];
    });
}

- (void)fwInnerPushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (!disappearingViewController) {
        return [self fwInnerPushViewController:viewController animated:animated];
    }
    if (![self fwShouldCustomTransitionFrom:disappearingViewController to:viewController]) {
        return [self fwInnerPushViewController:viewController animated:animated];
    }
    
    if (!self.fwTransitionContextToViewController || !disappearingViewController.fwTransitionNavigationBar) {
        [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    }
    if (animated) {
        self.fwTransitionContextToViewController = viewController;
        if (disappearingViewController.fwTransitionNavigationBar) {
            disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
        }
    }
    return [self fwInnerPushViewController:viewController animated:animated];
}

- (UIViewController *)fwInnerPopViewControllerAnimated:(BOOL)animated
{
    if (self.viewControllers.count < 2) {
        return [self fwInnerPopViewControllerAnimated:animated];
    }
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *appearingViewController = self.viewControllers[self.viewControllers.count - 2];
    if (![self fwShouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
        return [self fwInnerPopViewControllerAnimated:animated];
    }
    
    [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    if (appearingViewController.fwTransitionNavigationBar) {
        UINavigationBar *appearingNavigationBar = appearingViewController.fwTransitionNavigationBar;
        [self.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
    }
    if (animated) {
        disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
    }
    return [self fwInnerPopViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)fwInnerPopToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (![self.viewControllers containsObject:viewController] || self.viewControllers.count < 2) {
        return [self fwInnerPopToViewController:viewController animated:animated];
    }
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (![self fwShouldCustomTransitionFrom:disappearingViewController to:viewController]) {
        return [self fwInnerPopToViewController:viewController animated:animated];
    }
    
    [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    if (viewController.fwTransitionNavigationBar) {
        UINavigationBar *appearingNavigationBar = viewController.fwTransitionNavigationBar;
        [self.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
    }
    if (animated) {
        disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
    }
    return [self fwInnerPopToViewController:viewController animated:animated];
}

- (NSArray<UIViewController *> *)fwInnerPopToRootViewControllerAnimated:(BOOL)animated
{
    if (self.viewControllers.count < 2) {
        return [self fwInnerPopToRootViewControllerAnimated:animated];
    }
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *rootViewController = self.viewControllers.firstObject;
    if (![self fwShouldCustomTransitionFrom:disappearingViewController to:rootViewController]) {
        return [self fwInnerPopToRootViewControllerAnimated:animated];
    }
    
    [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    if (rootViewController.fwTransitionNavigationBar) {
        UINavigationBar *appearingNavigationBar = rootViewController.fwTransitionNavigationBar;
        [self.navigationBar fwReplaceStyleWithNavigationBar:appearingNavigationBar];
    }
    if (animated) {
        disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
    }
    return [self fwInnerPopToRootViewControllerAnimated:animated];
}

- (void)fwInnerSetViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *appearingViewController = viewControllers.count > 0 ? viewControllers.lastObject : nil;
    if (![self fwShouldCustomTransitionFrom:disappearingViewController to:appearingViewController]) {
        return [self fwInnerSetViewControllers:viewControllers animated:animated];
    }
    
    if (animated && disappearingViewController && ![disappearingViewController isEqual:viewControllers.lastObject]) {
        [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
        if (disappearingViewController.fwTransitionNavigationBar) {
            disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
        }
    }
    return [self fwInnerSetViewControllers:viewControllers animated:animated];
}

#pragma mark - Accessor

- (UIColor *)fwContainerViewBackgroundColor
{
    UIColor *backgroundColor = objc_getAssociatedObject(self, @selector(fwContainerViewBackgroundColor));
    return backgroundColor ?: [UIColor whiteColor];
}

- (void)setFwContainerViewBackgroundColor:(UIColor *)backgroundColor
{
    objc_setAssociatedObject(self, @selector(fwContainerViewBackgroundColor), backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    return objc_getAssociatedObject(self, @selector(fwTransitionContextToViewController));
}

- (void)setFwTransitionContextToViewController:(UIViewController *)viewController
{
    objc_setAssociatedObject(self, @selector(fwTransitionContextToViewController), viewController, OBJC_ASSOCIATION_ASSIGN);
}

@end
