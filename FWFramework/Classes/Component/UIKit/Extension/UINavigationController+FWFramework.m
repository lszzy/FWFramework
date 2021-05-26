/*!
 @header     UINavigationController+FWFramework.m
 @indexgroup FWFramework
 @brief      UINavigationController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UINavigationController+FWFramework.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation UINavigationController (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 修复iOS14.0如果pop到一个hidesBottomBarWhenPushed=NO的vc，tabBar无法正确显示出来的bug
        if (@available(iOS 14.0, *)) {
            FWSwizzleClass(UINavigationController, @selector(popToViewController:animated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(UIViewController *viewController, BOOL animated), FWSwizzleCode({
                if (animated && selfObject.tabBarController && !viewController.hidesBottomBarWhenPushed) {
                    BOOL systemShouldHideTabBar = NO;
                    NSArray<UIViewController *> *viewControllers = [selfObject.viewControllers subarrayWithRange:NSMakeRange(0, [selfObject.viewControllers indexOfObject:viewController] + 1)];
                    for (UIViewController *vc in viewControllers) {
                        if (vc.hidesBottomBarWhenPushed) {
                            systemShouldHideTabBar = YES;
                        }
                    }
                    if (!systemShouldHideTabBar) {
                        selfObject.fwShouldBottomBarBeHidden = YES;
                    }
                }
                
                NSArray<UIViewController *> *result = FWSwizzleOriginal(viewController, animated);
                selfObject.fwShouldBottomBarBeHidden = NO;
                return result;
            }));
            FWSwizzleClass(UINavigationController, @selector(popToRootViewControllerAnimated:), FWSwizzleReturn(NSArray<UIViewController *> *), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
                if (animated && selfObject.tabBarController && !selfObject.viewControllers.firstObject.hidesBottomBarWhenPushed && selfObject.viewControllers.count > 2) {
                    selfObject.fwShouldBottomBarBeHidden = YES;
                }
                
                NSArray<UIViewController *> *result = FWSwizzleOriginal(animated);
                selfObject.fwShouldBottomBarBeHidden = NO;
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
                        selfObject.fwShouldBottomBarBeHidden = YES;
                    }
                }
                
                FWSwizzleOriginal(viewControllers, animated);
                selfObject.fwShouldBottomBarBeHidden = NO;
            }));
            FWSwizzleClass(UINavigationController, NSSelectorFromString(@"_shouldBottomBarBeHidden"), FWSwizzleReturn(BOOL), FWSwizzleArgs(), FWSwizzleCode({
                BOOL result = FWSwizzleOriginal();
                if (selfObject.fwShouldBottomBarBeHidden) {
                    result = NO;
                }
                return result;
            }));
        }
    });
}

- (BOOL)fwShouldBottomBarBeHidden
{
    return [objc_getAssociatedObject(self, @selector(fwShouldBottomBarBeHidden)) boolValue];
}

- (void)setFwShouldBottomBarBeHidden:(BOOL)hidden
{
    objc_setAssociatedObject(self, @selector(fwShouldBottomBarBeHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
