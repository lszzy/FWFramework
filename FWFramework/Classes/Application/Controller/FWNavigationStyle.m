/*!
 @header     FWNavigationStyle.m
 @indexgroup FWFramework
 @brief      FWNavigationStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import "FWNavigationStyle.h"
#import "FWNavigationView.h"
#import "FWAdaptive.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWImage.h"
#import "FWTheme.h"
#import "FWBlock.h"
#import "FWNavigation.h"
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
    
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        self.fwNavigationView.topHidden = fwStatusBarHidden;
    }
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
    if (!self.navigationController || self.fwIsChild) return;
    FWNavigationBarAppearance *appearance = self.fwNavigationBarAppearance;
    NSNumber *styleNum = objc_getAssociatedObject(self, @selector(fwNavigationBarStyle));
    NSNumber *hiddenNum = objc_getAssociatedObject(self, @selector(fwNavigationBarHidden));
    if (!appearance && !styleNum && !hiddenNum) return;

    if (!appearance) appearance = [FWNavigationBarAppearance appearanceForStyle:styleNum.integerValue];
    BOOL isHidden = (styleNum.integerValue == FWNavigationBarStyleHidden) || hiddenNum.boolValue || appearance.isHidden;
    BOOL isTransparent = (styleNum.integerValue == FWNavigationBarStyleTransparent) || appearance.isTransparent;
    
    // 自定义导航栏，隐藏系统默认导航栏，切换自定义导航栏显示状态
    if ([self fwNavigationViewEnabled]) {
        if (self.navigationController.navigationBarHidden != YES) {
            [self.navigationController setNavigationBarHidden:YES animated:animated];
        }
        self.fwNavigationView.hidden = isHidden;
    // 系统导航栏，动态切换动画不突兀，一般在viewWillAppear:中调用，立即生效
    } else {
        if (self.navigationController.navigationBarHidden != isHidden) {
            [self.navigationController setNavigationBarHidden:isHidden animated:animated];
        }
    }
    
    if (isTransparent) {
        [self.fwNavigationBar fwSetBackgroundTransparent];
    }
    if (appearance.backgroundColor) {
        self.fwNavigationBar.fwBackgroundColor = appearance.backgroundColor;
    }
    if (appearance.backgroundImage) {
        self.fwNavigationBar.fwBackgroundImage = appearance.backgroundImage;
    }
    if (appearance.foregroundColor) {
        self.fwNavigationBar.fwForegroundColor = appearance.foregroundColor;
    }
    if (appearance.titleColor) {
        self.fwNavigationBar.fwTitleColor = appearance.titleColor;
    }
    if (appearance.appearanceBlock) {
        appearance.appearanceBlock(self.fwNavigationBar);
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

#pragma mark - Height

- (CGFloat)fwStatusBarHeight
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        return self.fwNavigationView.topHeight;
    }
    
    // 1. 导航栏隐藏时不占用布局高度始终为0
    if (!self.navigationController || self.navigationController.navigationBarHidden) return 0.0;
    
    // 2. 竖屏且为iOS13+弹出pageSheet样式时布局高度为0
    BOOL isPortrait = ![UIDevice fwIsLandscape];
    if (isPortrait && self.fwIsPageSheet) return 0.0;
    
    // 3. 竖屏且异形屏，导航栏显示时布局高度固定
    if (isPortrait && [UIScreen fwIsNotchedScreen]) {
        // 也可以这样计算：CGRectGetMinY(self.navigationController.navigationBar.frame)
        return [UIScreen fwStatusBarHeight];
    }
    
    // 4. 其他情况状态栏显示时布局高度固定，隐藏时布局高度为0
    if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
    return [UIApplication sharedApplication].statusBarFrame.size.height;
    
    /*
     // 系统状态栏可见高度算法：
     // 1. 竖屏且为iOS13+弹出pageSheet样式时安全高度为0
     if (![UIDevice fwIsLandscape] && self.fwIsPageSheet) return 0.0;
     
     // 2. 其他情况状态栏显示时安全高度固定，隐藏时安全高度为0
     if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
     return [UIApplication sharedApplication].statusBarFrame.size.height;
     */
}

- (CGFloat)fwNavigationBarHeight
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        return self.fwNavigationView.middleHeight;
    }
    
    // 系统导航栏
    if (!self.navigationController || self.navigationController.navigationBarHidden) return 0.0;
    return self.navigationController.navigationBar.frame.size.height;
}

- (CGFloat)fwTopBarHeight
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        return self.fwNavigationView.height;
    }
    
    // 通常情况下导航栏显示时可以这样计算：CGRectGetMaxY(self.navigationController.navigationBar.frame)
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
    
    /*
     // 系统顶部栏可见高度算法：
     // 1. 导航栏隐藏时和状态栏安全高度相同
     if (!self.navigationController || self.navigationController.navigationBarHidden) {
         return [self fwSafeStatusBarHeight];
     }
     
     // 2. 导航栏显示时和顶部栏布局高度相同
     return [self fwTopBarHeight];
     */
}

- (CGFloat)fwTabBarHeight
{
    if (!self.tabBarController || self.tabBarController.tabBar.hidden) return 0.0;
    return self.tabBarController.tabBar.frame.size.height;
}

- (CGFloat)fwToolBarHeight
{
    if (!self.navigationController || self.navigationController.toolbarHidden) return 0.0;
    return self.navigationController.toolbar.frame.size.height + [UIScreen fwSafeAreaInsets].bottom;
}

#pragma mark - Item

- (id)fwBarTitle
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        return self.fwNavigationView.titleView ?: self.fwNavigationItem.title;
    }
    
    // 系统导航栏
    return self.fwNavigationItem.titleView ?: self.fwNavigationItem.title;
}

- (void)setFwBarTitle:(id)title
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        if ([title isKindOfClass:[UIView class]]) {
            self.fwNavigationView.titleView = title;
        } else {
            self.fwNavigationItem.title = title;
        }
        return;
    }
    
    if ([title isKindOfClass:[UIView class]]) {
        self.fwNavigationItem.titleView = title;
    } else {
        self.fwNavigationItem.title = title;
    }
}

- (id)fwLeftBarItem
{
    return self.fwNavigationItem.leftBarButtonItem;
}

- (void)setFwLeftBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.fwNavigationItem.leftBarButtonItem = object;
    } else {
        __weak __typeof__(self) self_weak_ = self;
        self.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:^(id  _Nonnull sender) {
            __typeof__(self) self = self_weak_;
            if (![self fwPopBackBarItem]) return;
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
}

- (id)fwRightBarItem
{
    return self.fwNavigationItem.rightBarButtonItem;
}

- (void)setFwRightBarItem:(id)object
{
    if (!object || [object isKindOfClass:[UIBarButtonItem class]]) {
        self.fwNavigationItem.rightBarButtonItem = object;
    } else {
        __weak __typeof__(self) self_weak_ = self;
        self.fwNavigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:^(id  _Nonnull sender) {
            __typeof__(self) self = self_weak_;
            if (![self fwPopBackBarItem]) return;
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
}

- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    self.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block
{
    self.fwNavigationItem.leftBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action
{
    self.fwNavigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
}

- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block
{
    self.fwNavigationItem.rightBarButtonItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
}

- (void)fwAddLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
    NSMutableArray *items = self.fwNavigationItem.leftBarButtonItems ? [self.fwNavigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.fwNavigationItem.leftBarButtonItems = [items copy];
}

- (void)fwAddLeftBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
    NSMutableArray *items = self.fwNavigationItem.leftBarButtonItems ? [self.fwNavigationItem.leftBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.fwNavigationItem.leftBarButtonItems = [items copy];
}

- (void)fwAddRightBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *barItem = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
    NSMutableArray *items = self.fwNavigationItem.rightBarButtonItems ? [self.fwNavigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.fwNavigationItem.rightBarButtonItems = [items copy];
}

- (void)fwAddRightBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *barItem = [UIBarButtonItem fwBarItemWithObject:object block:block];
    NSMutableArray *items = self.fwNavigationItem.rightBarButtonItems ? [self.fwNavigationItem.rightBarButtonItems mutableCopy] : [NSMutableArray new];
    [items addObject:barItem];
    self.fwNavigationItem.rightBarButtonItems = [items copy];
}

#pragma mark - Back

- (id)fwBackBarItem
{
    return self.fwNavigationItem.backBarButtonItem;
}

- (void)setFwBackBarItem:(id)object
{
    // 自定义导航栏
    if (self.fwNavigationViewEnabled) {
        UIBarButtonItem *backItem;
        if ([object isKindOfClass:[UIBarButtonItem class]]) {
            backItem = (UIBarButtonItem *)object;
        } else {
            backItem = [UIBarButtonItem fwBarItemWithObject:(object ?: [UIImage new]) target:nil action:nil];
        }
        self.fwNavigationItem.backBarButtonItem = backItem;
        self.fwNavigationBar.fwBackImage = nil;
        return;
    }
    
    // 系统导航栏
    if (![object isKindOfClass:[UIImage class]]) {
        UIBarButtonItem *backItem;
        if (!object) {
            backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
        } else if ([object isKindOfClass:[UIBarButtonItem class]]) {
            backItem = (UIBarButtonItem *)object;
        } else {
            backItem = [UIBarButtonItem fwBarItemWithObject:object target:nil action:nil];
        }
        self.fwNavigationItem.backBarButtonItem = backItem;
        self.fwNavigationBar.fwBackImage = nil;
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
    
    self.fwNavigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.fwNavigationBar.fwBackImage = indicatorImage;
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

#if __IPHONE_15_0
static BOOL fwStaticNavigationBarAppearanceEnabled = YES;
#else
static BOOL fwStaticNavigationBarAppearanceEnabled = NO;
#endif

@implementation UINavigationBar (FWStyle)

+ (BOOL)fwAppearanceEnabled
{
    return fwStaticNavigationBarAppearanceEnabled;
}

+ (void)setFwAppearanceEnabled:(BOOL)enabled
{
    fwStaticNavigationBarAppearanceEnabled = enabled;
}

- (UINavigationBarAppearance *)fwAppearance
{
    UINavigationBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fwUpdateAppearance
{
    self.standardAppearance = self.fwAppearance;
    self.compactAppearance = self.fwAppearance;
    self.scrollEdgeAppearance = self.fwAppearance;
}

- (UIImage *)fwBackImage
{
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        return self.fwAppearance.backIndicatorImage;
    }}
    
    return self.backIndicatorImage;
}

- (void)setFwBackImage:(UIImage *)image
{
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        [self.fwAppearance setBackIndicatorImage:image transitionMaskImage:image];
        [self fwUpdateAppearance];
        return;
    }}
    
    self.backIndicatorImage = image;
    self.backIndicatorTransitionMaskImage = image;
}

- (UIColor *)fwForegroundColor
{
    return self.tintColor;
}

- (void)setFwForegroundColor:(UIColor *)color
{
    self.tintColor = color;
    [self fwUpdateTitleColor];
}

- (UIColor *)fwTitleColor
{
    return objc_getAssociatedObject(self, @selector(fwTitleColor));
}

- (void)setFwTitleColor:(UIColor *)fwTitleColor
{
    objc_setAssociatedObject(self, @selector(fwTitleColor), fwTitleColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateTitleColor];
}

- (void)fwUpdateTitleColor
{
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        UIColor *titleColor = self.fwTitleColor ?: self.tintColor;
        NSMutableDictionary *titleAttrs = self.fwAppearance.titleTextAttributes ? [self.fwAppearance.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
        titleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.fwAppearance.titleTextAttributes = [titleAttrs copy];
        
        NSMutableDictionary *largeTitleAttrs = self.fwAppearance.largeTitleTextAttributes ? [self.fwAppearance.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.fwAppearance.largeTitleTextAttributes = [largeTitleAttrs copy];
        [self fwUpdateAppearance];
        return;
    }}
    
    UIColor *titleColor = self.fwTitleColor ?: self.tintColor;
    NSMutableDictionary *titleAttrs = self.titleTextAttributes ? [self.titleTextAttributes mutableCopy] : [NSMutableDictionary new];
    titleAttrs[NSForegroundColorAttributeName] = titleColor;
    self.titleTextAttributes = [titleAttrs copy];
    
    if (@available(iOS 11.0, *)) {
        NSMutableDictionary *largeTitleAttrs = self.largeTitleTextAttributes ? [self.largeTitleTextAttributes mutableCopy] : [NSMutableDictionary new];
        largeTitleAttrs[NSForegroundColorAttributeName] = titleColor;
        self.largeTitleTextAttributes = [largeTitleAttrs copy];
    }
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = [UIImage fwImageWithColor:color] ?: [UIImage new];
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fwAppearance.backgroundImage = image;
        self.fwAppearance.shadowImage = [UIImage new];
        [self fwUpdateAppearance];
        return;
    }}
    
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (UIImage *)fwBackgroundImage
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundImage));
}

- (void)setFwBackgroundImage:(UIImage *)backgroundImage
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), backgroundImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIImage *image = backgroundImage.fwImage ?: [UIImage new];
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fwAppearance.backgroundImage = image;
        self.fwAppearance.shadowImage = [UIImage new];
        [self fwUpdateAppearance];
        return;
    }}
    
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (void)fwSetBackgroundTransparent
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fwAppearance.backgroundImage = [UIImage new];
        self.fwAppearance.shadowImage = [UIImage new];
        [self fwUpdateAppearance];
        return;
    }}
    
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwBackgroundColor && self.fwBackgroundColor.fwIsThemeColor) {
        UIImage *image = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor] ?: [UIImage new];
        if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fwAppearance.backgroundImage = image;
            self.fwAppearance.shadowImage = [UIImage new];
            [self fwUpdateAppearance];
            return;
        }}
        
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
        return;
    }
    
    if (self.fwBackgroundImage && self.fwBackgroundImage.fwIsThemeImage) {
        UIImage *image = self.fwBackgroundImage.fwImage ?: [UIImage new];
        if (UINavigationBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fwAppearance.backgroundImage = image;
            self.fwAppearance.shadowImage = [UIImage new];
            [self fwUpdateAppearance];
            return;
        }}
        
        [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
        return;
    }
}

#pragma mark - View

- (UIView *)fwContentView
{
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"ContentView"]) return subview;
    }
    return nil;
}

- (UIView *)fwBackgroundView
{
    return [self fwPerformGetter:@"_backgroundView"];
}

- (UIView *)fwLargeTitleView
{
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) hasSuffix:@"LargeTitleView"]) return subview;
    }
    return nil;
}

+ (CGFloat)fwLargeTitleHeight
{
    return 52;
}

@end

#pragma mark - UITabBar+FWStyle

#if __IPHONE_15_0
static BOOL fwStaticTabBarAppearanceEnabled = YES;
#else
static BOOL fwStaticTabBarAppearanceEnabled = NO;
#endif

@implementation UITabBar (FWStyle)

+ (BOOL)fwAppearanceEnabled
{
    return fwStaticTabBarAppearanceEnabled;
}

+ (void)setFwAppearanceEnabled:(BOOL)enabled
{
    fwStaticTabBarAppearanceEnabled = enabled;
}

- (UITabBarAppearance *)fwAppearance
{
    UITabBarAppearance *appearance = objc_getAssociatedObject(self, _cmd);
    if (!appearance) {
        appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithTransparentBackground];
        objc_setAssociatedObject(self, _cmd, appearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appearance;
}

- (void)fwUpdateAppearance
{
    self.standardAppearance = self.fwAppearance;
#if __IPHONE_15_0
    if (@available(iOS 15.0, *)) {
        self.scrollEdgeAppearance = self.fwAppearance;
    }
#endif
}

- (UIColor *)fwForegroundColor
{
    return self.tintColor;
}

- (void)setFwForegroundColor:(UIColor *)color
{
    self.tintColor = color;
}

- (UIColor *)fwBackgroundColor
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundColor));
}

- (void)setFwBackgroundColor:(UIColor *)color
{
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UITabBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:color];
        self.fwAppearance.shadowImage = [UIImage new];
        [self fwUpdateAppearance];
        return;
    }}
    
    self.backgroundImage = [UIImage fwImageWithColor:color];
    self.shadowImage = [UIImage new];
}

- (UIImage *)fwBackgroundImage
{
    return objc_getAssociatedObject(self, @selector(fwBackgroundImage));
}

- (void)setFwBackgroundImage:(UIImage *)image
{
    objc_setAssociatedObject(self, @selector(fwBackgroundColor), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, @selector(fwBackgroundImage), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (UITabBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
        self.fwAppearance.backgroundImage = image.fwImage;
        self.fwAppearance.shadowImage = [UIImage new];
        [self fwUpdateAppearance];
        return;
    }}
    
    self.backgroundImage = image.fwImage;
    self.shadowImage = [UIImage new];
}

- (void)fwThemeChanged:(FWThemeStyle)style
{
    [super fwThemeChanged:style];
    
    if (self.fwBackgroundColor && self.fwBackgroundColor.fwIsThemeColor) {
        if (UITabBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fwAppearance.backgroundImage = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor];
            self.fwAppearance.shadowImage = [UIImage new];
            [self fwUpdateAppearance];
            return;
        }}
        
        self.backgroundImage = [UIImage fwImageWithColor:self.fwBackgroundColor.fwColor];
        self.shadowImage = [UIImage new];
        return;
    }
    
    if (self.fwBackgroundImage && self.fwBackgroundImage.fwIsThemeImage) {
        if (UITabBar.fwAppearanceEnabled) { if (@available(iOS 13.0, *)) {
            self.fwAppearance.backgroundImage = self.fwBackgroundImage.fwImage;
            self.fwAppearance.shadowImage = [UIImage new];
            [self fwUpdateAppearance];
            return;
        }}
        
        self.backgroundImage = self.fwBackgroundImage.fwImage;
        self.shadowImage = [UIImage new];
        return;
    }
}

@end
