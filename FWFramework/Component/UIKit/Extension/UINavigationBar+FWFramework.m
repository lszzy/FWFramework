//
//  UINavigationBar+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UINavigationBar+FWFramework.h"
#import "FWImage.h"
#import "FWMessage.h"
#import "FWAdaptive.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - UINavigationBar+FWFramework

@implementation UINavigationBar (FWFramework)

+ (void)fwSetButtonTitleAttributes:(NSDictionary *)attributes
{
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateDisabled];
}

- (void)fwSetTextColor:(UIColor *)color
{
    self.tintColor = color;
    self.titleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    if (@available(iOS 11.0, *)) {
        self.largeTitleTextAttributes = color ? @{NSForegroundColorAttributeName: color} : nil;
    }
}

- (void)fwSetBackgroundColor:(UIColor *)color
{
    // 不使用barTintColor。默认Default样式下barTintColor在iOS10以下无法隐藏底部线条；在iOS8.2或者之前的版本，如果导航栏的translucent值为true时，用barTintColor去设置导航栏的背景样式，然后改变barTintColor的颜色，那么当边缘左滑返回手势取消的时候导航栏的背景色会闪烁。
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

- (UIView *)fwBackgroundView
{
    return [self fwPerformPropertySelector:@"_backgroundView"];
}

- (UIImageView *)fwShadowImageView
{
    if (@available(iOS 13, *)) {
        return [self.fwBackgroundView fwPerformPropertySelector:@"_shadowView1"];
    }
    return [self.fwBackgroundView fwPerformPropertySelector:@"_shadowView"];
}

@end

#pragma mark - UITabBar+FWFramework

@implementation UITabBar (FWFramework)

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

- (void)fwSetShadowColor:(UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius
{
    self.barStyle = UIBarStyleBlack;
    self.translucent = NO;
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 1.0;
}

- (UIView *)fwBackgroundView
{
    return [self fwPerformPropertySelector:@"_backgroundView"];
}

- (UIImageView *)fwShadowImageView
{
    if (@available(iOS 13, *)) {
        return [self.fwBackgroundView fwPerformPropertySelector:@"_shadowView1"];
    } else if (@available(iOS 10, *)) {
        // iOS 10 及以后，在 UITabBar 初始化之后就能获取到 backgroundView 和 shadowView 了
        return [self.fwBackgroundView fwPerformPropertySelector:@"_shadowView"];
    } else {
        // iOS 9 及以前，shadowView 要在 UITabBar 第一次 layoutSubviews 之后才会被创建，直至 UITabBarController viewWillAppear: 时仍未能获取到 shadowView，所以为了省去调用时机的考虑，这里获取不到的时候会主动触发一次 tabBar 的布局
        UIImageView *shadowView = [self fwPerformPropertySelector:@"_shadowView"];
        if (!shadowView) {
            [self setNeedsLayout];
            [self layoutIfNeeded];
            shadowView = [self fwPerformPropertySelector:@"_shadowView"];
        }
        return shadowView;
    }
}

@end

#pragma mark - UIBarItem+FWFramework

@implementation UIBarItem (FWFramework)

- (UIView *)fwView
{
    if ([self isKindOfClass:[UIBarButtonItem class]]) {
        if (((UIBarButtonItem *)self).customView != nil) {
            return ((UIBarButtonItem *)self).customView;
        }
    }
    
    if ([self respondsToSelector:@selector(view)]) {
        return [self fwPerformPropertySelector:@"view"];
    }
    return nil;
}

- (void (^)(__kindof UIBarItem *, UIView *))fwViewLoadedBlock
{
    return objc_getAssociatedObject(self, @selector(fwViewLoadedBlock));
}

- (void)setFwViewLoadedBlock:(void (^)(__kindof UIBarItem *, UIView *))block
{
    objc_setAssociatedObject(self, @selector(fwViewLoadedBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UIView *view = [self fwView];
    if (view) {
        block(self, view);
    } else {
        [self fwObserveProperty:@"view" target:self action:@selector(fwViewLoaded:change:)];
    }
}

- (void)fwViewLoaded:(UIBarItem *)object change:(NSDictionary *)change
{
    if (![change objectForKey:NSKeyValueChangeNewKey]) return;
    [object fwUnobserveProperty:@"view" target:self action:@selector(fwViewLoaded:change:)];
    
    UIView *view = [object fwView];
    if (view && self.fwViewLoadedBlock) {
        self.fwViewLoadedBlock(self, view);
    }
}

@end

#pragma mark - UITabBarItem+FWFramework

@implementation UITabBarItem (FWFramework)

- (UIImageView *)fwImageView
{
    UIView *tabBarButton = [self fwView];
    if (!tabBarButton) return nil;
    
    UIView *superview = tabBarButton;
    if (@available(iOS 13.0, *)) {
        // iOS 13 下如果 tabBar 是磨砂的，则每个 button 内部都会有一个磨砂，而磨砂再包裹了 imageView、label 等 subview，但某些时机后系统又会把 imageView、label 挪出来放到 button 上，所以这里做个保护
        if ([tabBarButton.subviews.firstObject isKindOfClass:[UIVisualEffectView class]] && ((UIVisualEffectView *)tabBarButton.subviews.firstObject).contentView.subviews.count) {
            superview = ((UIVisualEffectView *)tabBarButton.subviews.firstObject).contentView;
        }
    }
    
    for (UIView *subview in superview.subviews) {
        if (@available(iOS 10.0, *)) {
            // iOS10及以后，imageView都是用UITabBarSwappableImageView实现的，所以遇到这个class就直接拿
            if ([NSStringFromClass([subview class]) isEqualToString:@"UITabBarSwappableImageView"]) {
                return (UIImageView *)subview;
            }
        }
        
        // iOS10以前，选中的item的高亮是用UITabBarSelectionIndicatorView实现的，所以要屏蔽掉
        if ([subview isKindOfClass:[UIImageView class]] && ![NSStringFromClass([subview class]) isEqualToString:@"UITabBarSelectionIndicatorView"]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

@end
