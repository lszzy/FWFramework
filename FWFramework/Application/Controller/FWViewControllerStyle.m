/*!
 @header     FWViewControllerStyle.m
 @indexgroup FWFramework
 @brief      FWViewControllerStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import "FWViewControllerStyle.h"
#import "FWSwizzle.h"
#import "FWImage.h"
#import "FWTheme.h"
#import "FWBlock.h"
#import "FWRouter.h"
#import <objc/runtime.h>

#pragma mark - FWNavigationBarAppearance

@implementation FWNavigationBarAppearance

+ (NSMutableDictionary *)styleAppearances
{
    static NSMutableDictionary *appearances = nil;
    if (!appearances) {
        appearances = [[NSMutableDictionary alloc] init];
    }
    return appearances;
}

+ (FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style
{
    return [[self styleAppearances] objectForKey:@(style)];
}

+ (void)setAppearance:(FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style
{
    if (appearance) {
        [[self styleAppearances] setObject:appearance forKey:@(style)];
    } else {
        [[self styleAppearances] removeObjectForKey:@(style)];
    }
}

@end

#pragma mark - UIViewController+FWStyle

@implementation UIViewController (FWStyle)

#pragma mark - Bar

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(prefersStatusBarHidden), FWSwizzleReturn(BOOL), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *hiddenValue = objc_getAssociatedObject(selfObject, @selector(fwStatusBarHidden));
            if (hiddenValue) {
                return [hiddenValue boolValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(preferredStatusBarStyle), FWSwizzleReturn(UIStatusBarStyle), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *styleValue = objc_getAssociatedObject(selfObject, @selector(fwStatusBarStyle));
            if (styleValue) {
                return [styleValue integerValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            selfObject.fwVisibleState = FWViewControllerVisibleStateWillAppear;
            [selfObject fwUpdateNavigationBarStyle:animated];
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            selfObject.fwVisibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidDisappear;
        }));
    });
}

- (BOOL)fwStatusBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarHidden)) boolValue];
}

- (void)setFwStatusBarHidden:(BOOL)fwStatusBarHidden
{
    objc_setAssociatedObject(self, @selector(fwStatusBarHidden), @(fwStatusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)fwStatusBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarStyle)) integerValue];
}

- (void)setFwStatusBarStyle:(UIStatusBarStyle)fwStatusBarStyle
{
    objc_setAssociatedObject(self, @selector(fwStatusBarStyle), @(fwStatusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)fwNavigationBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationBarHidden)) boolValue];
}

- (void)setFwNavigationBarHidden:(BOOL)fwNavigationBarHidden
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarHidden), @(fwNavigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 动态切换导航栏显示隐藏，切换动画不突兀，一般在viewWillAppear:中调用，立即生效
    // [self.navigationController setNavigationBarHidden:hidden animated:animated];
    if (self.isViewLoaded && self.view.window) {
        [self fwUpdateNavigationBarStyle:NO];
    }
}

- (FWNavigationBarStyle)fwNavigationBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwNavigationBarStyle)) integerValue];
}

- (void)setFwNavigationBarStyle:(FWNavigationBarStyle)fwNavigationBarStyle
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarStyle), @(fwNavigationBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded && self.view.window) {
        [self fwUpdateNavigationBarStyle:NO];
    }
}

- (FWNavigationBarAppearance *)fwNavigationBarAppearance
{
    return objc_getAssociatedObject(self, @selector(fwNavigationBarAppearance));
}

- (void)setFwNavigationBarAppearance:(FWNavigationBarAppearance *)fwNavigationBarAppearance
{
    objc_setAssociatedObject(self, @selector(fwNavigationBarAppearance), fwNavigationBarAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded && self.view.window) {
        [self fwUpdateNavigationBarStyle:NO];
    }
}

- (void)fwUpdateNavigationBarStyle:(BOOL)animated
{
    if (!self.navigationController) return;
    FWNavigationBarAppearance *appearance = self.fwNavigationBarAppearance;
    NSNumber *style = objc_getAssociatedObject(self, @selector(fwNavigationBarStyle));
    NSNumber *hidden = objc_getAssociatedObject(self, @selector(fwNavigationBarHidden));
    if (!appearance && !style && !hidden) return;

    BOOL isHidden = appearance.isHidden;
    BOOL isTransparent = appearance.isTransparent;
    if (!appearance) {
        appearance = [FWNavigationBarAppearance appearanceForStyle:style.integerValue];
        isHidden = (style.integerValue == FWNavigationBarStyleHidden) || hidden.boolValue || appearance.isHidden;
        isTransparent = (style.integerValue == FWNavigationBarStyleTransparent) || appearance.isTransparent;
    }
    
    if (self.navigationController.navigationBarHidden != isHidden) {
        [self.navigationController setNavigationBarHidden:isHidden animated:animated];
    }
    if (isTransparent) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }
    
    if (appearance.backgroundColor) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage fwImageWithColor:appearance.backgroundColor] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }
    if (appearance.foregroundColor) {
        [self.navigationController.navigationBar setTintColor:appearance.foregroundColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: appearance.foregroundColor}];
        if (@available(iOS 11.0, *)) {
            [self.navigationController.navigationBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: appearance.foregroundColor}];
        }
    }
    if (appearance.appearanceBlock) {
        appearance.appearanceBlock(self.navigationController.navigationBar);
    }
}

- (BOOL)fwTabBarHidden
{
    return self.tabBarController.tabBar.hidden;
}

- (void)setFwTabBarHidden:(BOOL)fwTabBarHidden
{
    self.tabBarController.tabBar.hidden = fwTabBarHidden;
}

- (BOOL)fwToolBarHidden
{
    return self.navigationController.toolbarHidden;
}

- (void)setFwToolBarHidden:(BOOL)fwToolBarHidden
{
    // 动态切换工具栏显示隐藏，切换动画不突兀，立即生效
    // [self.navigationController setToolbarHidden:hidden animated:animated];
    self.navigationController.toolbarHidden = fwToolBarHidden;
}

- (UIRectEdge)fwExtendedLayoutEdge
{
    return self.edgesForExtendedLayout;
}

- (void)setFwExtendedLayoutEdge:(UIRectEdge)edge
{
    self.edgesForExtendedLayout = edge;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

#pragma mark - Item

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (id)fwBarTitle
{
    return self.navigationItem.titleView ?: self.navigationItem.title;
}

- (void)setFwBarTitle:(id)title
{
    if ([title isKindOfClass:[UIView class]]) {
        self.navigationItem.titleView = title;
    } else {
        self.navigationItem.title = title;
    }
}

- (id)fwLeftBarItem
{
    return self.navigationItem.leftBarButtonItem;
}

- (void)setFwLeftBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.navigationItem.leftBarButtonItem = object;
    } else {
        __weak __typeof__(self) self_weak_ = self;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:^(id  _Nonnull sender) {
            __typeof__(self) self = self_weak_;
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
}

- (id)fwRightBarItem
{
    return self.navigationItem.rightBarButtonItem;
}

- (void)setFwRightBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.navigationItem.rightBarButtonItem = object;
    } else {
        __weak __typeof__(self) self_weak_ = self;
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:^(id  _Nonnull sender) {
            __typeof__(self) self = self_weak_;
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
}

- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block
{
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

#pragma mark - Back

- (id)fwBackBarItem
{
    return self.navigationItem.backBarButtonItem;
}

- (void)setFwBackBarItem:(id)object
{
    if (![object isKindOfClass:[UIImage class]]) {
        UIBarButtonItem *backItem;
        if (!object) {
            backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        } else if ([object isKindOfClass:[UIBarButtonItem class]]) {
            backItem = (UIBarButtonItem *)object;
        } else {
            backItem = [UIBarButtonItem fwBarItemWithObject:object target:nil action:nil];
        }
        self.navigationItem.backBarButtonItem = backItem;
        self.navigationController.navigationBar.backIndicatorImage = nil;
        self.navigationController.navigationBar.backIndicatorTransitionMaskImage = nil;
        return;
    }
    
    UIImage *indicatorImage = nil;
    UIImage *image = (UIImage *)object;
    if (image.size.width > 0 && image.size.height > 0) {
        // 左侧偏移8个像素，和左侧按钮位置一致
        UIEdgeInsets insets = UIEdgeInsetsMake(0, -8, 0, 0);
        CGSize size = image.size;
        size.width -= insets.left + insets.right;
        size.height -= insets.top + insets.bottom;
        CGRect rect = CGRectMake(-insets.left, -insets.top, image.size.width, image.size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        [image drawInRect:rect];
        indicatorImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.backIndicatorImage = indicatorImage;
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = indicatorImage;
}

- (BOOL)fwPopBackBarItem
{
    BOOL shouldPop = YES;
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fwPopBackBarItem));
    if (block) {
        shouldPop = block();
    }
    return shouldPop;
}

- (BOOL (^)(void))fwBackBarBlock
{
    return objc_getAssociatedObject(self, @selector(fwPopBackBarItem));
}

- (void)setFwBackBarBlock:(BOOL (^)(void))block
{
    if (block) {
        objc_setAssociatedObject(self, @selector(fwPopBackBarItem), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    } else {
        objc_setAssociatedObject(self, @selector(fwPopBackBarItem), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

#pragma mark - State

- (FWViewControllerVisibleState)fwVisibleState
{
    return [objc_getAssociatedObject(self, @selector(fwVisibleState)) unsignedIntegerValue];
}

- (void)setFwVisibleState:(FWViewControllerVisibleState)fwVisibleState
{
    BOOL valueChanged = self.fwVisibleState != fwVisibleState;
    objc_setAssociatedObject(self, @selector(fwVisibleState), @(fwVisibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.fwVisibleStateChanged) {
        self.fwVisibleStateChanged(self, fwVisibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fwVisibleStateChanged
{
    return objc_getAssociatedObject(self, @selector(fwVisibleStateChanged));
}

- (void)setFwVisibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fwVisibleStateChanged
{
    objc_setAssociatedObject(self, @selector(fwVisibleStateChanged), fwVisibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

#pragma mark - UINavigationBar+FWStyle

@implementation UINavigationBar (FWStyle)

- (UIColor *)fwTextColor
{
    return self.tintColor;
}

- (void)setFwTextColor:(UIColor *)color
{
    self.tintColor = color;
    self.titleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    if (@available(iOS 11.0, *)) {
        self.largeTitleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    }
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        UIImage *image = [UIImage fwImageWithColor:self.fwThemeBackgroundColor] ?: [UIImage new];
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
    }
}

- (void)fwSetBackgroundTransparent
{
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

@end

#pragma mark - UITabBar+FWStyle

@implementation UITabBar (FWStyle)

- (UIColor *)fwTextColor
{
    return self.tintColor;
}

- (void)setFwTextColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundImage = [UIImage fwImageWithColor:color];
    self.shadowImage = [UIImage new];
}

- (UIColor *)fwThemeBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwThemeBackgroundColor));
}

- (void)setFwThemeBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwThemeBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.backgroundImage = [UIImage fwImageWithColor:color];
    self.shadowImage = [UIImage new];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwThemeBackgroundColor != nil) {
        self.backgroundImage = [UIImage fwImageWithColor:self.fwThemeBackgroundColor];
        self.shadowImage = [UIImage new];
    }
}

@end
