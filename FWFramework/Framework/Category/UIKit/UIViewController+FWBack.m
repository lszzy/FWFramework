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
#import "FWProxy.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWBack

@implementation UIViewController (FWBack)

- (BOOL)fwForcePopGesture
{
    return [objc_getAssociatedObject(self, @selector(fwForcePopGesture)) boolValue];
}

- (void)setFwForcePopGesture:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwForcePopGesture), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

#pragma mark - UINavigationController+FWBack

@interface UINavigationController (FWBack)

@property (nonatomic, weak) UIViewController *fwTmpTopViewController;

@end

#pragma mark - FWGestureRecognizerDelegateProxy

@interface FWGestureRecognizerDelegateProxy : FWDelegateProxy <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWGestureRecognizerDelegateProxy

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        self.navigationController.fwTmpTopViewController = self.navigationController.topViewController;
        BOOL shouldPop = YES;
        if ([self.navigationController.fwTmpTopViewController respondsToSelector:@selector(fwPopBackBarItem)]) {
            // 调用钩子。如果返回NO，则不开始手势；如果返回YES，则使用系统方式
            shouldPop = [self.navigationController.fwTmpTopViewController fwPopBackBarItem];
        }
        BOOL forcePop = self.navigationController.viewControllers.count > 1 &&
            self.navigationController.interactivePopGestureRecognizer.enabled &&
            self.navigationController.topViewController.fwForcePopGesture;
        if (forcePop) {
            self.navigationController.fwTmpTopViewController = nil;
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
            if (!shouldReceive) {
                BOOL forcePop = self.navigationController.viewControllers.count > 1 && self.navigationController.interactivePopGestureRecognizer.enabled && self.navigationController.topViewController.fwForcePopGesture;
                if (forcePop) {
                    return YES;
                }
            }
            return shouldReceive;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
            return [self.delegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        return YES;
    }
    return NO;
}

@end

#pragma mark - UINavigationController+FWBack

/**
 * UINavigationController默认为UINavigationBar的事件代理(UINavigationBarDelegate)。
 * 运行时替换navigationBar:shouldPopItem:方法可以处理全局返回按钮点击事件，也可使用子类重写。
 * 注意：分类重写原方法时，只有最后加载的方法会被调用，如果冲突，可使用swizzle实现
 */
@implementation UINavigationController (FWBack)

+ (void)load
{
    [self fwSwizzleInstanceMethod:@selector(viewDidLoad) with:@selector(fwInnerNavigationViewDidLoad)];
    [self fwSwizzleInstanceMethod:@selector(navigationBar:shouldPopItem:) with:@selector(fwInnerNavigationBar:shouldPopItem:)];
    [self fwSwizzleInstanceMethod:@selector(childViewControllerForStatusBarHidden) with:@selector(fwInnerChildViewControllerForStatusBarHidden)];
    [self fwSwizzleInstanceMethod:@selector(childViewControllerForStatusBarStyle) with:@selector(fwInnerChildViewControllerForStatusBarStyle)];
}

#pragma mark - Swizzle

- (void)fwInnerNavigationViewDidLoad
{
    [self fwInnerNavigationViewDidLoad];
    
    // 拦截系统返回手势事件代理，加载自定义代理方法
    if (self.interactivePopGestureRecognizer.delegate != self.fwDelegateProxy) {
        self.fwDelegateProxy.delegate = self.interactivePopGestureRecognizer.delegate;
        self.fwDelegateProxy.navigationController = self;
        self.interactivePopGestureRecognizer.delegate = self.fwDelegateProxy;
    }
}

- (BOOL)fwInnerNavigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    // 判断是否是代码pop，代码pop时顶层vc为root
    BOOL isCodePop = (item != self.topViewController.navigationItem);
    
    // 检查返回按钮点击事件钩子
    BOOL shouldPop = !isCodePop;
    if (!isCodePop) {
        UIViewController *topViewController = self.fwTmpTopViewController ?: self.topViewController;
        if ([topViewController respondsToSelector:@selector(fwPopBackBarItem)]) {
            // 调用钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
            shouldPop = [topViewController fwPopBackBarItem];
        }
    }
    
    if (shouldPop || isCodePop) {
        self.fwTmpTopViewController = nil;
        // 调用原始方法
        return [self fwInnerNavigationBar:navigationBar shouldPopItem:item];
    } else {
        self.fwTmpTopViewController = nil;
        // 处理iOS7.1导航栏透明度bug
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

#pragma mark - Private

- (FWGestureRecognizerDelegateProxy *)fwDelegateProxy
{
    FWGestureRecognizerDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWGestureRecognizerDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

- (UIViewController *)fwTmpTopViewController
{
    return objc_getAssociatedObject(self, @selector(fwTmpTopViewController));
}

- (void)setFwTmpTopViewController:(UIViewController *)fwTmpTopViewController
{
    objc_setAssociatedObject(self, @selector(fwTmpTopViewController), fwTmpTopViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end
