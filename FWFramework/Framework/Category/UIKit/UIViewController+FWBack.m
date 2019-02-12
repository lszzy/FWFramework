/*!
 @header     UIViewController+FWBack.m
 @indexgroup FWFramework
 @brief      UIViewController+FWBack
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/12
 */

#import "UIViewController+FWBack.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

@implementation UIViewController (FWBack)

- (BOOL)fwPopBackBarItem
{
    BOOL shouldPop = YES;
    // 是否存在自定义block
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fwPopBackBarItem));
    if (block) {
        shouldPop = block();
    }
    return shouldPop;
}

- (void)fwSetBackBarBlock:(BOOL (^)(void))block
{
    if (block) {
        objc_setAssociatedObject(self, @selector(fwPopBackBarItem), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    } else {
        objc_setAssociatedObject(self, @selector(fwPopBackBarItem), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

@end

/**
 * UINavigationController默认为UINavigationBar的事件代理(UINavigationBarDelegate)。
 * 运行时替换navigationBar:shouldPopItem:方法可以处理全局返回按钮点击事件，也可使用子类重写。
 * 注意：分类重写原方法时，只有最后加载的方法会被调用，如果冲突，可使用swizzle实现
 */
@interface UINavigationController (FWBack)

@end

@implementation UINavigationController (FWBack)

+ (void)load
{
    [self fwSwizzleInstanceMethod:@selector(navigationBar:shouldPopItem:) with:@selector(fwInnerNavigationBar:shouldPopItem:)];
    [self fwSwizzleInstanceMethod:@selector(childViewControllerForStatusBarHidden) with:@selector(fwInnerChildViewControllerForStatusBarHidden)];
    [self fwSwizzleInstanceMethod:@selector(childViewControllerForStatusBarStyle) with:@selector(fwInnerChildViewControllerForStatusBarStyle)];
}

- (BOOL)fwInnerNavigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if (self.viewControllers.count < navigationBar.items.count) {
        return YES;
    }
    
    // 检查返回按钮点击事件钩子
    BOOL shouldPop = YES;
    if ([self.topViewController respondsToSelector:@selector(fwPopBackBarItem)]) {
        // 调用钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
        shouldPop = [self.topViewController fwPopBackBarItem];
    }
    
    if (shouldPop) {
        // 关闭当前页面
        dispatch_async(dispatch_get_main_queue(), ^{
            [self popViewControllerAnimated:YES];
        });
    } else {
        if (@available(iOS 11, *)) {
        } else {
            // 处理iOS7.1导航栏透明度bug
            for (UIView *subview in [navigationBar subviews]) {
                if (0. < subview.alpha && subview.alpha < 1.) {
                    [UIView animateWithDuration:.25 animations:^{
                        subview.alpha = 1.;
                    }];
                }
            }
        }
    }
    return NO;
}

/**
 * 调用setNeedsStatusBarAppearanceUpdate时，系统会调用window的rootViewController的preferredStatusBarStyle方法。
 * 如果root为导航栏，会导致视图控制器的preferredStatusBarStyle不调用。重写此方法使视图控制器的状态栏样式生效
 */
- (UIViewController *)fwInnerChildViewControllerForStatusBarStyle
{
    if (self.topViewController) {
        return self.topViewController;
    } else {
        return [self fwInnerChildViewControllerForStatusBarStyle];
    }
}

- (UIViewController *)fwInnerChildViewControllerForStatusBarHidden
{
    if (self.topViewController) {
        return self.topViewController;
    } else {
        return [self fwInnerChildViewControllerForStatusBarHidden];
    }
}

@end
