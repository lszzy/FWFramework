//
//  FWNavigationStyle.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWNavigationStyle.h"
#import "FWSwizzle.h"
#import "FWUIKit.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWNavigationBarAppearance

@implementation FWNavigationBarAppearance

+ (NSMutableDictionary *)styleAppearances
{
    static NSMutableDictionary *appearances = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appearances = [[NSMutableDictionary alloc] init];
    });
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

#pragma mark - UINavigationBar+FWStyle

@implementation UINavigationBar (FWStyle)

- (void)fw_applyBarAppearance:(FWNavigationBarAppearance *)appearance
{
    if (appearance.isTranslucent != self.fw_isTranslucent) {
        self.fw_isTranslucent = appearance.isTranslucent;
    }
    if (appearance.backgroundTransparent) {
        self.fw_backgroundTransparent = appearance.backgroundTransparent;
    } else if (appearance.backgroundImage) {
        self.fw_backgroundImage = appearance.backgroundImage;
    } else if (appearance.backgroundColor) {
        self.fw_backgroundColor = appearance.backgroundColor;
    }
    if (appearance.shadowImage) {
        self.fw_shadowImage = appearance.shadowImage;
    } else if (appearance.shadowColor) {
        self.fw_shadowColor = appearance.shadowColor;
    } else {
        self.fw_shadowColor = nil;
    }
    if (appearance.foregroundColor) self.fw_foregroundColor = appearance.foregroundColor;
    if (appearance.titleAttributes) self.fw_titleAttributes = appearance.titleAttributes;
    if (appearance.buttonAttributes) self.fw_buttonAttributes = appearance.buttonAttributes;
    if (appearance.backImage) self.fw_backImage = appearance.backImage;
    if (appearance.appearanceBlock) appearance.appearanceBlock(self);
}

- (void)fw_applyBarStyle:(FWNavigationBarStyle)style
{
    FWNavigationBarAppearance *appearance = [FWNavigationBarAppearance appearanceForStyle:style];
    if (appearance) [self fw_applyBarAppearance:appearance];
}

@end

#pragma mark - UIViewController+FWStyle

@implementation UIViewController (FWStyle)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(prefersStatusBarHidden), FWSwizzleReturn(BOOL), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *hiddenValue = objc_getAssociatedObject(selfObject, @selector(fw_statusBarHidden));
            if (hiddenValue) {
                return [hiddenValue boolValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(preferredStatusBarStyle), FWSwizzleReturn(UIStatusBarStyle), FWSwizzleArgs(), FWSwizzleCode({
            NSNumber *styleValue = objc_getAssociatedObject(selfObject, @selector(fw_statusBarStyle));
            if (styleValue) {
                return [styleValue integerValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            [selfObject fw_updateNavigationBarStyle:animated];
        }));
    });
}

- (UIStatusBarStyle)fw_statusBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fw_statusBarStyle)) integerValue];
}

- (void)setFw_statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    objc_setAssociatedObject(self, @selector(fw_statusBarStyle), @(statusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)fw_statusBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fw_statusBarHidden)) boolValue];
}

- (void)setFw_statusBarHidden:(BOOL)statusBarHidden
{
    objc_setAssociatedObject(self, @selector(fw_statusBarHidden), @(statusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsStatusBarAppearanceUpdate];
}

- (FWNavigationBarAppearance *)fw_navigationBarAppearance
{
    return objc_getAssociatedObject(self, @selector(fw_navigationBarAppearance));
}

- (void)setFw_navigationBarAppearance:(FWNavigationBarAppearance *)navigationBarAppearance
{
    objc_setAssociatedObject(self, @selector(fw_navigationBarAppearance), navigationBarAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded && self.view.window) {
        [self fw_updateNavigationBarStyle:NO];
    }
}

- (FWNavigationBarStyle)fw_navigationBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fw_navigationBarStyle)) integerValue];
}

- (void)setFw_navigationBarStyle:(FWNavigationBarStyle)navigationBarStyle
{
    objc_setAssociatedObject(self, @selector(fw_navigationBarStyle), @(navigationBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded && self.view.window) {
        [self fw_updateNavigationBarStyle:NO];
    }
}

- (BOOL)fw_navigationBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fw_navigationBarHidden)) boolValue];
}

- (void)setFw_navigationBarHidden:(BOOL)hidden
{
    [self fw_setNavigationBarHidden:hidden animated:NO];
    // 直接设置navigtionBar.isHidden不会影响右滑关闭手势
    // self.navigationController.navigationBar.isHidden = YES;
}

- (void)fw_setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    objc_setAssociatedObject(self, @selector(fw_navigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded && self.view.window) {
        [self fw_updateNavigationBarStyle:animated];
    }
}

- (BOOL)fw_allowsChildNavigation
{
    return [objc_getAssociatedObject(self, @selector(fw_allowsChildNavigation)) boolValue];
}

- (void)setFw_allowsChildNavigation:(BOOL)allowsChildNavigation
{
    objc_setAssociatedObject(self, @selector(fw_allowsChildNavigation), @(allowsChildNavigation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWNavigationBarAppearance *)fw_currentNavigationBarAppearance
{
    // 1. 检查VC是否自定义appearance
    FWNavigationBarAppearance *appearance = self.fw_navigationBarAppearance;
    if (appearance) return appearance;
    // 2. 检查VC是否自定义style
    NSNumber *style = objc_getAssociatedObject(self, @selector(fw_navigationBarStyle));
    if (style) {
        appearance = [FWNavigationBarAppearance appearanceForStyle:style.integerValue];
        return appearance;
    }
    // 3. 检查NAV是否自定义appearance
    appearance = self.navigationController.fw_navigationBarAppearance;
    if (appearance) return appearance;
    // 4. 检查NAV是否自定义style
    style = objc_getAssociatedObject(self.navigationController, @selector(fw_navigationBarStyle));
    if (style) {
        appearance = [FWNavigationBarAppearance appearanceForStyle:style.integerValue];
    }
    return appearance;
}

- (void)fw_updateNavigationBarStyle:(BOOL)animated
{
    // 含有导航栏且不是导航栏控制器，如果是child控制器且允许修改时才处理
    if (!self.navigationController || [self isKindOfClass:[UINavigationController class]]) return;
    if (self.fw_isChild && !self.fw_allowsChildNavigation) return;
    
    // fwNavigationBarHidden设置即生效，动态切换导航栏不突兀，一般在viewWillAppear:中调用
    NSNumber *hidden = objc_getAssociatedObject(self, @selector(fw_navigationBarHidden));
    if (hidden && self.navigationController.navigationBarHidden != hidden.boolValue) {
        [self.navigationController setNavigationBarHidden:hidden.boolValue animated:animated];
    }
    
    // 获取当前用于显示的appearance，未设置时不处理
    FWNavigationBarAppearance *appearance = [self fw_currentNavigationBarAppearance];
    if (!appearance) return;
    
    // 配合导航栏appearance初始化返回按钮或左侧按钮
    if (appearance.backImage) self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    if (appearance.leftBackImage && objc_getAssociatedObject(self, _cmd) == nil) {
        objc_setAssociatedObject(self, _cmd, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (self.navigationController.childViewControllers.count > 1 &&
            self.navigationItem.leftBarButtonItem == nil) {
            self.fw_leftBarItem = appearance.leftBackImage;
        }
    }
    
    // 应用当前导航栏appearance
    [self.navigationController.navigationBar fw_applyBarAppearance:appearance];
}

- (BOOL)fw_tabBarHidden
{
    return self.tabBarController.tabBar.hidden;
}

- (void)setFw_tabBarHidden:(BOOL)tabBarHidden
{
    self.tabBarController.tabBar.hidden = tabBarHidden;
}

- (BOOL)fw_toolBarHidden
{
    return self.navigationController.toolbarHidden;
}

- (void)setFw_toolBarHidden:(BOOL)toolBarHidden
{
    self.navigationController.toolbarHidden = toolBarHidden;
}

- (void)fw_setToolBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self.navigationController setToolbarHidden:hidden animated:animated];
}

- (UIRectEdge)fw_extendedLayoutEdge
{
    return self.edgesForExtendedLayout;
}

- (void)setFw_extendedLayoutEdge:(UIRectEdge)edge
{
    self.edgesForExtendedLayout = edge;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

@end
