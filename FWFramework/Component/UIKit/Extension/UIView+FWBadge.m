//
//  UIView+FWBadge.m
//  FWFramework
//
//  Created by wuyong on 2017/4/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIView+FWBadge.h"
#import "FWAutoLayout.h"
#import "FWMessage.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - FWBadgeView

@implementation FWBadgeView

- (instancetype)initWithBadgeStyle:(FWBadgeStyle)badgeStyle
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // 根据样式处理
        _badgeStyle = badgeStyle;
        switch (badgeStyle) {
            case FWBadgeStyleSmall: {
                [self setupWithBadgeHeight:18.f badgeOffset:CGPointMake(7.f, 7.f) textInset:5.f fontSize:12.f];
                break;
            }
            case FWBadgeStyleBig: {
                [self setupWithBadgeHeight:24.f badgeOffset:CGPointMake(9.f, 9.f) textInset:6.f fontSize:14.f];
                break;
            }
            case FWBadgeStyleDot:
            default: {
                CGFloat badgeHeight = 10.f;
                _badgeOffset = CGPointMake(3.f, 3.f);
                
                self.userInteractionEnabled = NO;
                self.backgroundColor = [UIColor redColor];
                self.layer.cornerRadius = badgeHeight / 2.0;
                [self fwSetDimensionsToSize:CGSizeMake(badgeHeight, badgeHeight)];
                break;
            }
        }
    }
    return self;
}

- (instancetype)initWithBadgeHeight:(CGFloat)badgeHeight badgeOffset:(CGPoint)badgeOffset textInset:(CGFloat)textInset fontSize:(CGFloat)fontSize
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupWithBadgeHeight:badgeHeight badgeOffset:badgeOffset textInset:textInset fontSize:fontSize];
    }
    return self;
}

- (void)setupWithBadgeHeight:(CGFloat)badgeHeight badgeOffset:(CGPoint)badgeOffset textInset:(CGFloat)textInset fontSize:(CGFloat)fontSize
{
    _badgeOffset = badgeOffset;
    
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor redColor];
    self.layer.cornerRadius = badgeHeight / 2.0;
    [self fwSetDimension:NSLayoutAttributeHeight toSize:badgeHeight];
    [self fwSetDimension:NSLayoutAttributeWidth toSize:badgeHeight relation:NSLayoutRelationGreaterThanOrEqual];
    
    _badgeLabel = [UILabel fwAutoLayoutView];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.font = [UIFont systemFontOfSize:fontSize];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_badgeLabel];
    [_badgeLabel fwAlignCenterToSuperview];
    [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
    [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
}

@end

#pragma mark - UIView+FWBadge

@implementation UIView (FWBadge)

- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fwHideBadgeView];
    
    badgeView.badgeLabel.text = badgeValue;
    badgeView.tag = 2041;
    [self addSubview:badgeView];
    [self bringSubviewToFront:badgeView];
    
    // 默认偏移
    [badgeView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:-badgeView.badgeOffset.y];
    [badgeView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:-badgeView.badgeOffset.x];
}

- (void)fwHideBadgeView
{
    UIView *badgeView = [self viewWithTag:2041];
    if (badgeView) {
        [badgeView removeFromSuperview];
    }
}

@end

#pragma mark - UIBarItem+FWBadge

@implementation UIBarItem (FWBadge)

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

#pragma mark - UIBarButtonItem+FWBadge

@implementation UIBarButtonItem (FWBadge)

- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fwHideBadgeView];
    
    // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
    self.fwViewLoadedBlock = ^(UIBarButtonItem *item, UIView *view) {
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        
        // 自定义视图时默认偏移，否则固定偏移
        [badgeView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.y : 0];
        [badgeView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.x : 0];
    };
}

- (void)fwHideBadgeView
{
    UIView *superview = [self fwView];
    if (superview) {
        UIView *badgeView = [superview viewWithTag:2041];
        if (badgeView) {
            [badgeView removeFromSuperview];
        }
    }
}

@end

#pragma mark - UITabBarItem+FWBadege

@implementation UITabBarItem (FWBadge)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleMethod(objc_getClass("UITabBarButton"), @selector(layoutSubviews), nil, FWSwizzleType(UIView *), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            // 解决因为层级关系变化导致的badgeView被遮挡问题
            for (UIView *subview in selfObject.subviews) {
                if ([subview isKindOfClass:[FWBadgeView class]]) {
                    [selfObject bringSubviewToFront:subview];
                    break;
                }
            }
        }));
    });
}

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

- (void)fwShowBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fwHideBadgeView];
    
    // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
    self.fwViewLoadedBlock = ^(UITabBarItem *item, UIView *view) {
        UIView *imageView = item.fwImageView;
        if (!imageView) return;
        
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        
        // x轴默认偏移，y轴固定偏移，类似系统布局
        [badgeView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:imageView.superview withOffset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.y : 2.f];
        [badgeView fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:imageView withOffset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.x : -badgeView.badgeOffset.x];
    };
}

- (void)fwHideBadgeView
{
    UIView *superview = self.fwView;
    if (superview) {
        UIView *badgeView = [superview viewWithTag:2041];
        if (badgeView) {
            [badgeView removeFromSuperview];
        }
    }
}

@end
