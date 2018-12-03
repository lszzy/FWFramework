//
//  UIViewController+FWBar.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIViewController+FWBar.h"
#import "UIView+FWBlock.h"
#import "UIScreen+FWFramework.h"
#import "UIImage+FWFramework.h"
#import <objc/runtime.h>

@implementation UIViewController (FWBar)

#pragma mark - Bar

- (BOOL)fwStatusBarHidden
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarHidden)) boolValue];
}

- (void)setFwStatusBarHidden:(BOOL)fwStatusBarHidden
{
    if (fwStatusBarHidden != self.fwStatusBarHidden) {
        [self willChangeValueForKey:@"fwStatusBarHidden"];
        objc_setAssociatedObject(self, @selector(fwStatusBarHidden), @(fwStatusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwStatusBarHidden"];
        
        // 视图控制器生效
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (UIStatusBarStyle)fwStatusBarStyle
{
    return [objc_getAssociatedObject(self, @selector(fwStatusBarStyle)) integerValue];
}

- (void)setFwStatusBarStyle:(UIStatusBarStyle)fwStatusBarStyle
{
    if (fwStatusBarStyle != self.fwStatusBarStyle) {
        [self willChangeValueForKey:@"fwStatusBarStyle"];
        objc_setAssociatedObject(self, @selector(fwStatusBarStyle), @(fwStatusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwStatusBarStyle"];
        
        // 视图控制器生效
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return self.fwStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.fwStatusBarStyle;
}

- (BOOL)fwNavigationBarHidden
{
    return self.navigationController.navigationBarHidden;
}

- (void)setFwNavigationBarHidden:(BOOL)fwNavigationBarHidden
{
    self.navigationController.navigationBarHidden = fwNavigationBarHidden;
}

- (BOOL)fwTabBarHidden
{
    return self.tabBarController.tabBar.hidden;
}

- (void)setFwTabBarHidden:(BOOL)fwTabBarHidden
{
    self.tabBarController.tabBar.hidden = fwTabBarHidden;
}

- (void)fwSetBarExtendEdge:(UIRectEdge)edge
{
    self.edgesForExtendedLayout = edge;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.modalPresentationCapturesStatusBarAppearance = NO;
}

#pragma mark - Item

- (void)fwSetBarTitle:(id)title
{
    if ([title isKindOfClass:[UIView class]]) {
        self.navigationItem.titleView = title;
    } else {
        self.navigationItem.title = title;
    }
}

- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithFWObject:object target:target action:action];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithFWObject:object block:block];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithFWObject:object target:target action:action];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithFWObject:object block:block];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - Back

- (void)fwSetBackBarTitle:(NSString *)title
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = item;
    
    // 清除自定义图片
    [self.navigationController.navigationBar fwSetIndicatorImage:nil];
}

- (void)fwSetBackBarImage:(UIImage *)image
{
    // 设置返回按钮为空白图片
    [self fwSetBackBarClear];
    
    // 设置箭头图片为指定图片
    [self.navigationController.navigationBar fwSetIndicatorImage:image];
}

- (void)fwSetBackBarClear
{
    // 设置按钮图片为空白图片
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage new] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = item;
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

#pragma mark - UINavigationBar+FWBar

@implementation UINavigationBar (FWBar)

+ (void)fwSetButtonTitleAttributes:(NSDictionary *)attributes
{
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateDisabled];
}

- (void)fwSetTextColor:(UIColor *)color
{
    // 按钮颜色
    self.tintColor = color;
    // 标题颜色
    [self setTitleTextAttributes:@{NSForegroundColorAttributeName: color}];
}

- (void)fwSetTitleAttributes:(NSDictionary *)attributes
{
    [self setTitleTextAttributes:attributes];
}

- (void)fwSetBackgroundColor:(UIColor *)color
{
    // barTintColor在iOS10以下无法隐藏底部线条
    // self.barTintColor = color;
    [self setBackgroundImage:[UIImage fwImageWithColor:color] forBarMetrics:UIBarMetricsDefault];
}

- (void)fwSetBackgroundImage:(UIImage *)image
{
    [self setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
}

- (void)fwSetBackgroundClear
{
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
}

- (void)fwSetLineHidden:(BOOL)hidden
{
    // 设置线条颜色，传入UIColor创建的UIImage对象即可
    [self setShadowImage:hidden ? [UIImage new] : nil];
}

- (UIView *)fwOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (!overlayView) {
        // 设置背景透明
        [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
        
        overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + FWStatusBarHeight)];
        overlayView.userInteractionEnabled = NO;
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.subviews.firstObject insertSubview:overlayView atIndex:0];
        objc_setAssociatedObject(self, @selector(fwOverlayView), overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return overlayView;
}

- (void)fwResetBackground
{
    [self setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:nil];
    
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (overlayView) {
        [overlayView removeFromSuperview];
        objc_setAssociatedObject(self, @selector(fwOverlayView), nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)fwSetIndicatorImage:(UIImage *)image
{
    // 默认左侧偏移8个像素，模拟左侧按钮
    [self fwSetIndicatorImage:image insets:UIEdgeInsetsMake(0, -8, 0, 0)];
}

- (void)fwSetIndicatorImage:(UIImage *)image insets:(UIEdgeInsets)insets
{
    // 自定义图片
    if (image) {
        // 图片是否需要偏移
        if (!UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero)) {
            image = [self fwInnerIndicatorImage:image insets:insets];
        }
        
        self.backIndicatorImage = image;
        self.backIndicatorTransitionMaskImage = image;
    // 系统图片
    } else {
        self.backIndicatorImage = nil;
        self.backIndicatorTransitionMaskImage = nil;
    }
}

- (UIImage *)fwInnerIndicatorImage:(UIImage *)image insets:(UIEdgeInsets)insets
{
    CGSize size = image.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    if (size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(-insets.left, -insets.top, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

#pragma mark - UITabBar+FWBar

@implementation UITabBar (FWBar)

- (void)fwSetTextColor:(UIColor *)color
{
    self.tintColor = color;
}

- (void)fwSetBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
}

- (void)fwSetBackgroundImage:(UIImage *)image
{
    self.backgroundImage = image;
}

- (void)fwSetLineHidden:(BOOL)hidden
{
    // 方案一，不影响背景图片，影响barStyle
    self.barStyle = hidden ? UIBarStyleBlack : UIBarStyleDefault;
    
    // 方案二，不影响barStyle，影响backgroundImage，同时设置才生效
    // self.backgroundImage = hidden ? [UIImage new] : nil;
    // self.shadowImage = hidden ? [UIImage new] : nil;
}

- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    // 去掉横线
    self.barStyle = UIBarStyleBlack;
    // 设置不透明
    self.translucent = NO;
    // 设置阴影色
    self.layer.shadowColor = color.CGColor;
    // 默认阴影配置，可覆盖
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 1.0;
}

@end

#pragma mark - UINavigationController+FWBar

/**
 * UINavigationController默认为UINavigationBar的事件代理(UINavigationBarDelegate)。
 * 运行时替换navigationBar:shouldPopItem:方法可以处理全局返回按钮点击事件，也可使用子类重写。
 * 注意：分类重写原方法时，只有最后加载的方法会被调用，如果冲突，可使用swizzle实现
 */
@interface UINavigationController (FWBar)

@end

@implementation UINavigationController (FWBar)

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
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
        // 处理iOS7.1导航栏透明度bug
        for (UIView *subview in [navigationBar subviews]) {
            if (0. < subview.alpha && subview.alpha < 1.) {
                [UIView animateWithDuration:.25 animations:^{
                    subview.alpha = 1.;
                }];
            }
        }
    }
    
    return NO;
}

/**
 * 调用setNeedsStatusBarAppearanceUpdate时，系统会调用window的rootViewController的preferredStatusBarStyle方法。
 * 如果root为导航栏，会导致视图控制器的preferredStatusBarStyle不调用。重写此方法使视图控制器的状态栏样式生效
 */
- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.topViewController;
}

@end
