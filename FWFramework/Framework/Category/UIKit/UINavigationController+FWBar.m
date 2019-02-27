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
#import "UIImage+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - UINavigationBar+FWBarTransition

@interface UINavigationBar (FWBarTransition)

@property (nonatomic, strong) UINavigationBar *fwTransitionNavigationBar;

- (void)fwReplaceStyleWithNavigationBar:(UINavigationBar *)navigationBar;

@end

@implementation UINavigationBar (FWBarTransition)

#pragma mark - Hook

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(setShadowImage:) with:@selector(fwInnerSetShadowImage:)];
        [self fwSwizzleInstanceMethod:@selector(setBarTintColor:) with:@selector(fwInnerSetBarTintColor:)];
        [self fwSwizzleInstanceMethod:@selector(setBackgroundImage:forBarMetrics:) with:@selector(fwInnerSetBackgroundImage:forBarMetrics:)];
    });
}

- (void)fwInnerSetShadowImage:(UIImage *)image
{
    [self fwInnerSetShadowImage:image];
    if (self.fwTransitionNavigationBar) {
        self.fwTransitionNavigationBar.shadowImage = image;
    }
}

- (void)fwInnerSetBarTintColor:(UIColor *)tintColor
{
    [self fwInnerSetBarTintColor:tintColor];
    if (self.fwTransitionNavigationBar) {
        self.fwTransitionNavigationBar.barTintColor = self.barTintColor;
    }
}

- (void)fwInnerSetBackgroundImage:(UIImage *)backgroundImage forBarMetrics:(UIBarMetrics)barMetrics
{
    [self fwInnerSetBackgroundImage:backgroundImage forBarMetrics:barMetrics];
    if (self.fwTransitionNavigationBar) {
        [self.fwTransitionNavigationBar setBackgroundImage:backgroundImage forBarMetrics:barMetrics];
    }
}

#pragma mark - Accessor

- (UINavigationBar *)fwTransitionNavigationBar
{
    return objc_getAssociatedObject(self, @selector(fwTransitionNavigationBar));
}

- (void)setFwTransitionNavigationBar:(UINavigationBar *)fwTransitionNavigationBar
{
    objc_setAssociatedObject(self, @selector(fwTransitionNavigationBar), fwTransitionNavigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)fwReplaceStyleWithNavigationBar:(UINavigationBar *)navigationBar
{
    if (self.barStyle != navigationBar.barStyle) {
        self.barStyle = navigationBar.barStyle;
    }
    self.barTintColor = navigationBar.barTintColor;
    [self setBackgroundImage:[navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:navigationBar.shadowImage];
}

@end

#pragma mark - FWTransitionNavigationBar

@interface FWTransitionNavigationBar : UINavigationBar

@end

@implementation FWTransitionNavigationBar

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (@available(iOS 11, *)) {
        // iOS11自己init的navigationBar.backgroundView.height默认一直是44，所以兼容之
        UIView *backgroundView = [self valueForKey:@"_backgroundView"];
        backgroundView.frame = self.bounds;
    }
}

@end

#pragma mark - UIViewController+FWBarTransition

@interface UIViewController (FWBarTransition)

@property (nonatomic, strong) FWTransitionNavigationBar *fwTransitionNavigationBar;

@property (nonatomic, assign) BOOL fwNavigationBarBackgroundViewHidden;

@property (nonatomic, strong) UIColor *fwOriginContainerViewBackgroundColor;

@property (nonatomic, assign) BOOL fwLockTransitionNavigationBar;

- (void)fwAddTransitionNavigationBarIfNeeded;

@end

@implementation UIViewController (FWBarTransition)

#pragma mark - Hook

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(viewWillAppear:) with:@selector(fwInnerViewWillAppear:)];
        [self fwSwizzleInstanceMethod:@selector(viewDidAppear:) with:@selector(fwInnerViewDidAppear:)];
        [self fwSwizzleInstanceMethod:@selector(viewDidDisappear:) with:@selector(fwInnerViewDidDisappear:)];
        [self fwSwizzleInstanceMethod:@selector(viewWillLayoutSubviews) with:@selector(fwInnerViewWillLayoutSubviews)];
    });
}

- (void)fwInnerViewWillAppear:(BOOL)animated
{
    // 放在最前面，允许业务覆盖
    [self fwRenderNavigationStyleAnimated:animated];
    [self fwInnerViewWillAppear:animated];
}

- (void)fwInnerViewDidAppear:(BOOL)animated
{
    self.fwLockTransitionNavigationBar = YES;
    
    if (self.fwTransitionNavigationBar) {
        [self.navigationController.navigationBar fwReplaceStyleWithNavigationBar:self.fwTransitionNavigationBar];
        [self fwRemoveTransitionNavigationBar];
        
        id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
        [transitionCoordinator containerView].backgroundColor = self.fwOriginContainerViewBackgroundColor;
    }
    
    if ([self.navigationController.viewControllers containsObject:self]) {
        // 防止一些childViewController走到这里
        self.fwNavigationBarBackgroundViewHidden = NO;
    }

    [self fwInnerViewDidAppear:animated];
}

- (void)fwInnerViewDidDisappear:(BOOL)animated
{
    self.fwLockTransitionNavigationBar = NO;
    
    [self fwRemoveTransitionNavigationBar];
    
    [self fwInnerViewDidDisappear:animated];
}

- (void)fwInnerViewWillLayoutSubviews
{
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    UIViewController *fromViewController = [transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    
    BOOL isCurrentToViewController = (self == self.navigationController.viewControllers.lastObject && self == toViewController);
    if (isCurrentToViewController && !self.fwLockTransitionNavigationBar) {
        BOOL shouldCustomNavigationBarTransition = NO;
        if (!self.fwTransitionNavigationBar) {
            if ([self fwShouldCustomTransitionWithFirstViewController:fromViewController secondViewController:toViewController]) {
                shouldCustomNavigationBarTransition = YES;
            }
            
            if (shouldCustomNavigationBarTransition) {
                if (self.navigationController.navigationBar.translucent) {
                    // 如果原生bar是半透明的，需要给containerView加个背景色，否则有可能会看到下面的默认黑色背景色
                    toViewController.fwOriginContainerViewBackgroundColor = [transitionCoordinator containerView].backgroundColor;
                    [transitionCoordinator containerView].backgroundColor = [self respondsToSelector:@selector(fwContainerViewBackgroundColor)] ? [self fwContainerViewBackgroundColor] : [UIColor whiteColor];
                }
                [self fwAddTransitionNavigationBarIfNeeded];
                [self fwResizeTransitionNavigationBarFrame];
                self.navigationController.navigationBar.fwTransitionNavigationBar = self.fwTransitionNavigationBar;
                self.fwNavigationBarBackgroundViewHidden = YES;
            }
        }
    }
    
    [self fwInnerViewWillLayoutSubviews];
}

#pragma mark - Accessor

- (UINavigationBar *)fwTransitionNavigationBar
{
    return objc_getAssociatedObject(self, @selector(fwTransitionNavigationBar));
}

- (void)setFwTransitionNavigationBar:(UINavigationBar *)navigationBar
{
    objc_setAssociatedObject(self, @selector(fwTransitionNavigationBar), navigationBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)fwOriginContainerViewBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwOriginContainerViewBackgroundColor));
}

- (void)setFwOriginContainerViewBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwOriginContainerViewBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwLockTransitionNavigationBar
{
    return [objc_getAssociatedObject(self, @selector(fwLockTransitionNavigationBar)) boolValue];
}

- (void)setFwLockTransitionNavigationBar:(BOOL)lock
{
    objc_setAssociatedObject(self, @selector(fwLockTransitionNavigationBar), @(lock), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwNavigationBarBackgroundViewHidden
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationBarBackgroundViewHidden)) boolValue];
}

- (void)setFwNavigationBarBackgroundViewHidden:(BOOL)hidden
{
    UIView *backgroundView = [self.navigationController.navigationBar valueForKey:@"_backgroundView"];
    backgroundView.layer.mask = hidden ? [CALayer layer] : nil;
    objc_setAssociatedObject(self, @selector(fwNavigationBarBackgroundViewHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (void)fwAddTransitionNavigationBarIfNeeded
{
    if (!self.isViewLoaded || !self.view.window ||
        !self.navigationController.navigationBar) {
        return;
    }

    UINavigationBar *originBar = self.navigationController.navigationBar;
    FWTransitionNavigationBar *customBar = [[FWTransitionNavigationBar alloc] init];
    if (customBar.barStyle != originBar.barStyle) {
        customBar.barStyle = originBar.barStyle;
    }
    if (customBar.translucent != originBar.translucent) {
        customBar.translucent = originBar.translucent;
    }
    if (![customBar.barTintColor isEqual:originBar.barTintColor]) {
        customBar.barTintColor = originBar.barTintColor;
    }
    UIImage *backgroundImage = [originBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    if (backgroundImage && backgroundImage.size.width <= 0 && backgroundImage.size.height <= 0) {
        // 假设这里的图片是通过[UIImage new]这种形式创建的，那么会navBar会奇怪地显示为系统默认navBar的样式。而navController设置自己的navBar为[UIImage new]却没事，这里做个保护
        backgroundImage = [UIImage fwImageWithColor:[UIColor clearColor]];
    }
    [customBar setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
    [customBar setShadowImage:originBar.shadowImage];
    
    self.fwTransitionNavigationBar = customBar;
    [self fwResizeTransitionNavigationBarFrame];
    if (!self.navigationController.navigationBarHidden) {
        [self.view addSubview:self.fwTransitionNavigationBar];
    }
    
    CGRect viewRect = [self.navigationController.view convertRect:self.view.frame fromView:self.view.superview];
    if (viewRect.origin.y != 0 && self.view.clipsToBounds) {
        NSLog(@"当前界面 controller.view = %@ 布局并没有从屏幕顶部开始，可能会导致自定义导航栏转场的假 bar 看不到", self);
    }
}

- (void)fwRemoveTransitionNavigationBar
{
    if (self.fwTransitionNavigationBar) {
        [self.fwTransitionNavigationBar removeFromSuperview];
        self.fwTransitionNavigationBar = nil;
    }
}

- (void)fwResizeTransitionNavigationBarFrame
{
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }
    UIView *backgroundView = [self.navigationController.navigationBar valueForKey:@"_backgroundView"];
    CGRect rect = [backgroundView.superview convertRect:backgroundView.frame toView:self.view];
    self.fwTransitionNavigationBar.frame = rect;
}

- (void)fwRenderNavigationStyleAnimated:(BOOL)animated
{
    // 防止一些childViewController走到这里
    if (![self.navigationController.viewControllers containsObject:self]) {
        return;
    }
    
    // 自动切换导航栏显隐
    if ([self respondsToSelector:@selector(fwPrefersNavigationBarHidden)]) {
        BOOL navigationBarHidden = [self fwPrefersNavigationBarHidden];
        if (self.navigationController.navigationBarHidden != navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:navigationBarHidden animated:animated];
        }
    }
    
    // 设置导航栏样式
    if ([self respondsToSelector:@selector(fwNavigationBarBarTintColor)]) {
        self.navigationController.navigationBar.barTintColor = [self fwNavigationBarBarTintColor];
    }
    if ([self respondsToSelector:@selector(fwNavigationBarBackgroundImage)]) {
        [self.navigationController.navigationBar setBackgroundImage:[self fwNavigationBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    }
    if ([self respondsToSelector:@selector(fwNavigationBarShadowImage)]) {
        self.navigationController.navigationBar.shadowImage = [self fwNavigationBarShadowImage];
    }
    if ([self respondsToSelector:@selector(fwNavigationBarTintColor)]) {
        self.navigationController.navigationBar.tintColor = [self fwNavigationBarTintColor];
    }
    if ([self respondsToSelector:@selector(fwNavigationBarTitleTextAttributes)]) {
        self.navigationController.navigationBar.titleTextAttributes = [self fwNavigationBarTitleTextAttributes];
    }
    
    // 自定义导航样式
    if ([self respondsToSelector:@selector(fwCustomNavigationBarStyle)]) {
        [self fwCustomNavigationBarStyle];
    }
}

- (BOOL)fwShouldCustomTransitionWithFirstViewController:(UIViewController *)vc1 secondViewController:(UIViewController *)vc2
{
    // 如果实现自定义转场key，则依据自定义key是否相等来执行自定义转场，不自动比较导航栏样式
    if ([vc1 respondsToSelector:@selector(fwNavigationBarTransitionKey)] ||
        [vc2 respondsToSelector:@selector(fwNavigationBarTransitionKey)]) {
        id key1 = [vc1 respondsToSelector:@selector(fwNavigationBarTransitionKey)] ? [vc1 fwNavigationBarTransitionKey] : nil;
        id key2 = [vc2 respondsToSelector:@selector(fwNavigationBarTransitionKey)] ? [vc2 fwNavigationBarTransitionKey] : nil;
        BOOL result = (key1 || key2) && ![key1 isEqual:key2];
        return result;
    }
    
    // 比较自定义背景图片是否相等，不相等执行自定义转场
    UIImage *bg1 = [vc1 respondsToSelector:@selector(fwNavigationBarBackgroundImage)] ? [vc1 fwNavigationBarBackgroundImage] : [[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsDefault];
    UIImage *bg2 = [vc2 respondsToSelector:@selector(fwNavigationBarBackgroundImage)] ? [vc2 fwNavigationBarBackgroundImage] : [[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsDefault];
    if (bg1 || bg2) {
        if (!bg1 || !bg2 || ![bg1.fwAverageColor isEqual:bg2.fwAverageColor]) {
            return YES;
        }
    }
    
    // 如果存在backgroundImage，则barTintColor就算存在也不会被显示出来，所以这里只判断两个backgroundImage都不存在的时候
    if (!bg1 && !bg2) {
        UIColor *btc1 = [vc1 respondsToSelector:@selector(fwNavigationBarBarTintColor)] ? [vc1 fwNavigationBarBarTintColor] : [UINavigationBar appearance].barTintColor;
        UIColor *btc2 = [vc2 respondsToSelector:@selector(fwNavigationBarBarTintColor)] ? [vc2 fwNavigationBarBarTintColor] : [UINavigationBar appearance].barTintColor;
        if (btc1 || btc2) {
            if (!btc1 || !btc2 || ![btc1 isEqual:btc2]) {
                return YES;
            }
        }
    }
    
    // 比较阴影图片是否相等，不相等执行自定义转场
    UIImage *si1 = [vc1 respondsToSelector:@selector(fwNavigationBarShadowImage)] ? [vc1 fwNavigationBarShadowImage] : [UINavigationBar appearance].shadowImage;
    UIImage *si2 = [vc2 respondsToSelector:@selector(fwNavigationBarShadowImage)] ? [vc2 fwNavigationBarShadowImage] : [UINavigationBar appearance].shadowImage;
    if (si1 || si2) {
        if (!si1 || !si2 || ![si1.fwAverageColor isEqual:si2.fwAverageColor]) {
            return YES;
        }
    }
    
    return NO;
}

@end

#pragma mark - UINavigationController+FWBar

@implementation UINavigationController (FWBar)

#pragma mark - Public

+ (void)fwEnableNavigationBarTransition
{
    [UINavigationBar fwInnerEnableNavigationBarTransition];
    [UIViewController fwInnerEnableNavigationBarTransition];
    [UINavigationController fwInnerEnableNavigationBarTransition];
}

#pragma mark - Hook

+ (void)fwInnerEnableNavigationBarTransition
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(pushViewController:animated:) with:@selector(fwInnerPushViewController:animated:)];
        [self fwSwizzleInstanceMethod:@selector(setViewControllers:animated:) with:@selector(fwInnerSetViewControllers:animated:)];
        [self fwSwizzleInstanceMethod:@selector(popViewControllerAnimated:) with:@selector(fwInnerPopViewControllerAnimated:)];
        [self fwSwizzleInstanceMethod:@selector(popToViewController:animated:) with:@selector(fwInnerPopToViewController:animated:)];
        [self fwSwizzleInstanceMethod:@selector(popToRootViewControllerAnimated:) with:@selector(fwInnerPopToRootViewControllerAnimated:)];
    });
}

- (void)fwInnerPushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (!disappearingViewController) {
        return [self fwInnerPushViewController:viewController animated:animated];
    }
    
    BOOL shouldCustomNavigationBarTransition = [self fwShouldCustomTransitionWithFirstViewController:disappearingViewController secondViewController:viewController];
    if (shouldCustomNavigationBarTransition) {
        [disappearingViewController fwAddTransitionNavigationBarIfNeeded];
        disappearingViewController.fwNavigationBarBackgroundViewHidden = YES;
    }
    
    return [self fwInnerPushViewController:viewController animated:animated];
}

- (void)fwInnerSetViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
    if (viewControllers.count <= 0 || !animated) {
        return [self fwInnerSetViewControllers:viewControllers animated:animated];
    }
    
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *appearingViewController = viewControllers.lastObject;
    if (!disappearingViewController) {
        return [self fwInnerSetViewControllers:viewControllers animated:animated];
    }
    
    [self fwHandleCustomTransitionWithDisappearViewController:disappearingViewController appearViewController:appearingViewController];
    return [self fwInnerSetViewControllers:viewControllers animated:animated];
}

- (UIViewController *)fwInnerPopViewControllerAnimated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *appearingViewController = self.viewControllers.count >= 2 ? self.viewControllers[self.viewControllers.count - 2] : nil;
    if (disappearingViewController && appearingViewController) {
        [self fwHandleCustomTransitionWithDisappearViewController:disappearingViewController appearViewController:appearingViewController];
    }
    return [self fwInnerPopViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)fwInnerPopToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    UIViewController *appearingViewController = viewController;
    NSArray<UIViewController *> *poppedViewControllers = [self fwInnerPopToViewController:viewController animated:animated];
    if (poppedViewControllers) {
        [self fwHandleCustomTransitionWithDisappearViewController:disappearingViewController appearViewController:appearingViewController];
    }
    return poppedViewControllers;
}

- (NSArray<UIViewController *> *)fwInnerPopToRootViewControllerAnimated:(BOOL)animated
{
    NSArray<UIViewController *> *poppedViewControllers = [self fwInnerPopToRootViewControllerAnimated:animated];
    if (self.viewControllers.count > 1) {
        UIViewController *disappearingViewController = self.viewControllers.lastObject;
        UIViewController *appearingViewController = self.viewControllers.firstObject;
        if (poppedViewControllers) {
            [self fwHandleCustomTransitionWithDisappearViewController:disappearingViewController appearViewController:appearingViewController];
        }
    }
    return poppedViewControllers;
}

#pragma mark - Private

- (void)fwHandleCustomTransitionWithDisappearViewController:(UIViewController *)disappearViewController appearViewController:(UIViewController *)appearViewController
{
    BOOL shouldCustomNavigationBarTransition = [self fwShouldCustomTransitionWithFirstViewController:disappearViewController secondViewController:appearViewController];
    if (shouldCustomNavigationBarTransition) {
        [disappearViewController fwAddTransitionNavigationBarIfNeeded];
        if (appearViewController.fwTransitionNavigationBar) {
            // 假设从A→B→C，其中A设置了bar的样式，B跟随A所以B里没有设置bar样式的代码，C又把样式改为另一种，此时从C返回B时，由于B没有设置bar的样式的代码，所以bar的样式依然会保留C的，这就错了，所以每次都要手动改回来才保险
            [self.navigationBar fwReplaceStyleWithNavigationBar:appearViewController.fwTransitionNavigationBar];
        }
        disappearViewController.fwNavigationBarBackgroundViewHidden = YES;
    }
}

@end
