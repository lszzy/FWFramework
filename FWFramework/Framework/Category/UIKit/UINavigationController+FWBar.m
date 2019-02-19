/*!
 @header     UINavigationController+FWBar.m
 @indexgroup FWFramework
 @brief      UINavigationController+FWBar
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import "UINavigationController+FWBar.h"
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

+ (void)fwInnerEnableTransitionNavigationBar
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(layoutSubviews) with:@selector(fwInnerUINavigationBarLayoutSubviews)];
    });
}

- (void)fwInnerUINavigationBarLayoutSubviews
{
    [self fwInnerUINavigationBarLayoutSubviews];
    UIView *backgroundView = [self valueForKey:@"_backgroundView"];
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

#pragma mark - NSObject+FWBarTransition

@interface NSObject (FWBarTransition)

@end

@implementation NSObject (FWBarTransition)

+ (void)fwInnerEnableTransitionNavigationBar
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class originalCls = objc_getClass("_UIBarBackground");
        if (originalCls) {
            SEL originalSelector = @selector(setHidden:);
            Class swizzledCls = [self class];
            SEL swizzledSelector = @selector(fwInnerUIBarBackgroundSetHidden:);
            
            Method originalMethod = class_getInstanceMethod(originalCls, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(swizzledCls, swizzledSelector);
            BOOL isAddMethod = class_addMethod(originalCls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
            if (isAddMethod) {
                class_replaceMethod(originalCls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
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

@end

#pragma mark - UIScrollView+FWBarTransition

@interface UIScrollView (FWBarTransition)

@property (nonatomic, assign) UIScrollViewContentInsetAdjustmentBehavior fwOriginalContentInsetAdjustmentBehavior NS_AVAILABLE_IOS(11_0);
@property (nonatomic, assign) BOOL fwShouldRestoreContentInsetAdjustmentBehavior NS_AVAILABLE_IOS(11_0);

@end

@implementation UIScrollView (FWBarTransition)

- (UIScrollViewContentInsetAdjustmentBehavior)fwOriginalContentInsetAdjustmentBehavior
{
    return [objc_getAssociatedObject(self, @selector(fwOriginalContentInsetAdjustmentBehavior)) integerValue];
}

- (void)setFwOriginalContentInsetAdjustmentBehavior:(UIScrollViewContentInsetAdjustmentBehavior)contentInsetAdjustmentBehavior
{
    objc_setAssociatedObject(self, @selector(fwOriginalContentInsetAdjustmentBehavior), @(contentInsetAdjustmentBehavior), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwShouldRestoreContentInsetAdjustmentBehavior
{
    return [objc_getAssociatedObject(self, @selector(fwShouldRestoreContentInsetAdjustmentBehavior)) boolValue];
}

- (void)setFwShouldRestoreContentInsetAdjustmentBehavior:(BOOL)should
{
    objc_setAssociatedObject(self, @selector(fwShouldRestoreContentInsetAdjustmentBehavior), @(should), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIViewController+FWBarTransition

@implementation UIViewController (FWBarTransition)

+ (void)fwInnerEnableTransitionNavigationBar
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(viewWillLayoutSubviews) with:@selector(fwInnerViewWillLayoutSubviews)];
        [self fwSwizzleInstanceMethod:@selector(viewWillAppear:) with:@selector(fwInnerViewWillAppear:)];
        [self fwSwizzleInstanceMethod:@selector(viewDidAppear:) with:@selector(fwInnerViewDidAppear:)];
    });
}

- (void)fwInnerViewWillAppear:(BOOL)animated
{
    [self fwInnerViewWillAppear:animated];
    id<UIViewControllerTransitionCoordinator> tc = self.transitionCoordinator;
    UIViewController *toViewController = [tc viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([self isEqual:self.navigationController.viewControllers.lastObject] && [toViewController isEqual:self]  && tc.presentationStyle == UIModalPresentationNone) {
        [self fwAdjustScrollViewContentInsetAdjustmentBehavior];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.navigationController.navigationBarHidden) {
                [self fwRestoreScrollViewContentInsetAdjustmentBehaviorIfNeeded];
            }
        });
    }
}

- (void)fwInnerViewDidAppear:(BOOL)animated
{
    [self fwRestoreScrollViewContentInsetAdjustmentBehaviorIfNeeded];
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
    [self fwInnerViewDidAppear:animated];
}

- (void)fwInnerViewWillLayoutSubviews
{
    id<UIViewControllerTransitionCoordinator> tc = self.transitionCoordinator;
    UIViewController *fromViewController = [tc viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [tc viewControllerForKey:UITransitionContextToViewControllerKey];
    
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
    [self fwInnerViewWillLayoutSubviews];
}

- (void)fwResizeTransitionNavigationBarFrame
{
    if (!self.view.window) {
        return;
    }
    UIView *backgroundView = [self.navigationController.navigationBar valueForKey:@"_backgroundView"];
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
    [self fwAdjustScrollViewContentOffsetIfNeeded];
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

- (void)fwAdjustScrollViewContentOffsetIfNeeded
{
    UIScrollView *scrollView = self.fwInnerVisibleScrollView;
    if (scrollView) {
        UIEdgeInsets contentInset;
        if (@available(iOS 11.0, *)) {
            contentInset = scrollView.adjustedContentInset;
        } else {
            contentInset = scrollView.contentInset;
        }
        const CGFloat topContentOffsetY = -contentInset.top;
        const CGFloat bottomContentOffsetY = scrollView.contentSize.height - (CGRectGetHeight(scrollView.bounds) - contentInset.bottom);
        
        CGPoint adjustedContentOffset = scrollView.contentOffset;
        if (adjustedContentOffset.y > bottomContentOffsetY) {
            adjustedContentOffset.y = bottomContentOffsetY;
        }
        if (adjustedContentOffset.y < topContentOffsetY) {
            adjustedContentOffset.y = topContentOffsetY;
        }
        [scrollView setContentOffset:adjustedContentOffset animated:NO];
    }
}

- (void)fwAdjustScrollViewContentInsetAdjustmentBehavior
{
    if (self.navigationController.navigationBar.translucent) {
        return;
    }
    if (@available(iOS 11.0, *)) {
        UIScrollView *scrollView = self.fwInnerVisibleScrollView;
        if (scrollView) {
            UIScrollViewContentInsetAdjustmentBehavior contentInsetAdjustmentBehavior = scrollView.contentInsetAdjustmentBehavior;
            if (contentInsetAdjustmentBehavior != UIScrollViewContentInsetAdjustmentNever) {
                scrollView.fwOriginalContentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior;
                scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                scrollView.fwShouldRestoreContentInsetAdjustmentBehavior = YES;
            }
        }
    }
}

- (void)fwRestoreScrollViewContentInsetAdjustmentBehaviorIfNeeded
{
    if (@available(iOS 11.0, *)) {
        UIScrollView *scrollView = self.fwInnerVisibleScrollView;
        if (scrollView) {
            if (scrollView.fwShouldRestoreContentInsetAdjustmentBehavior) {
                scrollView.contentInsetAdjustmentBehavior = scrollView.fwOriginalContentInsetAdjustmentBehavior;
                scrollView.fwShouldRestoreContentInsetAdjustmentBehavior = NO;
            }
        }
    }
}

- (UINavigationBar *)fwTransitionNavigationBar
{
    return objc_getAssociatedObject(self, @selector(fwTransitionNavigationBar));
}

- (void)setFwTransitionNavigationBar:(UINavigationBar *)navigationBar
{
    objc_setAssociatedObject(self, @selector(fwTransitionNavigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIScrollView *)fwTransitionScrollView {
    return objc_getAssociatedObject(self, @selector(fwTransitionScrollView));
}

- (void)setFwTransitionScrollView:(UIScrollView *)scrollView
{
    objc_setAssociatedObject(self, @selector(fwTransitionScrollView), scrollView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIScrollView *)fwInnerVisibleScrollView
{
    UIScrollView *scrollView = self.fwTransitionScrollView;
    if (!scrollView && [self.view isKindOfClass:[UIScrollView class]]) {
        scrollView = (UIScrollView *)self.view;
    }
    return scrollView;
}

@end

#pragma mark - UINavigationController+FWBar

@implementation UINavigationController (FWBar)

+ (void)fwInnerEnableTransitionNavigationBar
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

+ (void)fwEnableTransitionNavigationBar
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UINavigationBar fwInnerEnableTransitionNavigationBar];
        [NSObject fwInnerEnableTransitionNavigationBar];
        [UIViewController fwInnerEnableTransitionNavigationBar];
        [UINavigationController fwInnerEnableTransitionNavigationBar];
    });
}

- (UIColor *)fwContainerViewBackgroundColor
{
    return [UIColor whiteColor];
}

- (void)fwInnerPushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (!disappearingViewController) {
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
    [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    UIViewController *appearingViewController = self.viewControllers[self.viewControllers.count - 2];
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
    [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
    UIViewController *rootViewController = self.viewControllers.firstObject;
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
    if (animated && disappearingViewController && ![disappearingViewController isEqual:viewControllers.lastObject]) {
        [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
        if (disappearingViewController.fwTransitionNavigationBar) {
            disappearingViewController.navigationController.fwBackgroundViewHidden = YES;
        }
    }
    return [self fwInnerSetViewControllers:viewControllers animated:animated];
}

- (BOOL)fwBackgroundViewHidden
{
    return [objc_getAssociatedObject(self, @selector(fwBackgroundViewHidden)) boolValue];
}

- (void)setFwBackgroundViewHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fwBackgroundViewHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[self.navigationBar valueForKey:@"_backgroundView"] setHidden:hidden];
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
