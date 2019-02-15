//
//  UIViewController+FWBar.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWBar.h"
#import "UIView+FWBlock.h"
#import "UIScreen+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import "UIImage+FWFramework.h"
#import <objc/runtime.h>

@implementation UIViewController (FWBar)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(prefersStatusBarHidden) with:@selector(fwInnerPrefersStatusBarHidden)];
        [self fwSwizzleInstanceMethod:@selector(preferredStatusBarStyle) with:@selector(fwInnerPreferredStatusBarStyle)];
    });
}

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

- (BOOL)fwInnerPrefersStatusBarHidden
{
    NSNumber *hiddenValue = objc_getAssociatedObject(self, @selector(fwStatusBarHidden));
    if (hiddenValue) {
        return [hiddenValue boolValue];
    } else {
        return [self fwInnerPrefersStatusBarHidden];
    }
}

- (UIStatusBarStyle)fwInnerPreferredStatusBarStyle
{
    NSNumber *styleValue = objc_getAssociatedObject(self, @selector(fwStatusBarStyle));
    if (styleValue) {
        return [styleValue integerValue];
    } else {
        return [self fwInnerPreferredStatusBarStyle];
    }
}

- (BOOL)fwNavigationBarHidden
{
    return self.navigationController.navigationBarHidden;
}

- (void)setFwNavigationBarHidden:(BOOL)fwNavigationBarHidden
{
    self.navigationController.navigationBarHidden = fwNavigationBarHidden;
}

- (void)fwSetNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:hidden animated:animated];
}

- (void)fwSetNavigationBarAlpha:(CGFloat)alpha completion:(void (^)(void))completion
{
    __weak __typeof__(self) self_weak_ = self;
    [self.transitionCoordinator animateAlongsideTransitionInView:self.view animation:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        __typeof__(self) self = self_weak_;
        self.navigationController.navigationBar.alpha = alpha;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (completion) {
            completion();
        }
    }];
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
    UIBarButtonItem *item = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *item = [UIBarButtonItem fwBarItemWithObject:object block:block];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [UIBarButtonItem fwBarItemWithObject:object target:target action:action];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block
{
    UIBarButtonItem *item = [UIBarButtonItem fwBarItemWithObject:object block:block];
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
    // 不使用barTintColor。在iOS8.2或者之前的版本，如果导航栏的translucent值为true时，用barTintColor去设置导航栏的背景样式，然后改变barTintColor的颜色，那么当边缘左滑返回手势取消的时候导航栏的背景色会闪烁。
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

- (UIView *)fwBackgroundView
{
    return [self valueForKey:@"_backgroundView"];
}

- (UIImageView *)fwShadowImageView
{
    return [self.fwBackgroundView valueForKey:@"_shadowView"];
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

- (UIView *)fwBackgroundView
{
    return [self valueForKey:@"_backgroundView"];
}

- (UIImageView *)fwShadowImageView
{
    if (@available(iOS 10, *)) {
        // iOS 10 及以后，在 UITabBar 初始化之后就能获取到 backgroundView 和 shadowView 了
        return [self.fwBackgroundView valueForKey:@"_shadowView"];
    } else {
        // iOS 9 及以前，shadowView 要在 UITabBar 第一次 layoutSubviews 之后才会被创建，直至 UITabBarController viewWillAppear: 时仍未能获取到 shadowView，所以为了省去调用时机的考虑，这里获取不到的时候会主动触发一次 tabBar 的布局
        UIImageView *shadowView = [self valueForKey:@"_shadowView"];
        if (!shadowView) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
            shadowView = [self valueForKey:@"_shadowView"];
        }
        return shadowView;
    }
}

@end
