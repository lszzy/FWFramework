//
//  UIView+FWBadge.m
//  FWFramework
//
//  Created by wuyong on 2017/4/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIView+FWBadge.h"
#import "FWMessage.h"
#import "UIView+FWAutoLayout.h"

#pragma mark - FWBadgeView

@interface FWBadgeView ()

// 默认偏移值
@property (nonatomic, readonly) CGPoint badgeOffset;

@end

@implementation FWBadgeView

- (instancetype)initWithStyle:(FWBadgeStyle)style
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // 根据样式处理
        switch (style) {
            case FWBadgeStyleSmall: {
                CGFloat badgeHeight = 18.f;
                CGFloat textInset = 5.f;
                _badgeOffset = CGPointMake(7.f, 7.f);
                
                self.backgroundColor = [UIColor redColor];
                self.layer.cornerRadius = badgeHeight / 2.0;
                [self fwSetDimension:NSLayoutAttributeHeight toSize:badgeHeight];
                [self fwSetDimension:NSLayoutAttributeWidth toSize:badgeHeight relation:NSLayoutRelationGreaterThanOrEqual];
                
                _badgeLabel = [UILabel fwAutoLayoutView];
                _badgeLabel.textColor = [UIColor whiteColor];
                _badgeLabel.font = [UIFont systemFontOfSize:12.f];
                _badgeLabel.textAlignment = NSTextAlignmentCenter;
                [self addSubview:_badgeLabel];
                [_badgeLabel fwAlignCenterToSuperview];
                [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
                [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
                break;
            }
            case FWBadgeStyleBig: {
                CGFloat badgeHeight = 24.f;
                CGFloat textInset = 6.f;
                _badgeOffset = CGPointMake(9.f, 9.f);
                
                self.backgroundColor = [UIColor redColor];
                self.layer.cornerRadius = badgeHeight / 2.0;
                [self fwSetDimension:NSLayoutAttributeHeight toSize:badgeHeight];
                [self fwSetDimension:NSLayoutAttributeWidth toSize:badgeHeight relation:NSLayoutRelationGreaterThanOrEqual];
                
                _badgeLabel = [UILabel fwAutoLayoutView];
                _badgeLabel.textColor = [UIColor whiteColor];
                _badgeLabel.font = [UIFont systemFontOfSize:14.f];
                _badgeLabel.textAlignment = NSTextAlignmentCenter;
                [self addSubview:_badgeLabel];
                [_badgeLabel fwAlignCenterToSuperview];
                [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
                [_badgeLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:textInset relation:NSLayoutRelationGreaterThanOrEqual];
                break;
            }
            case FWBadgeStyleDot:
            default: {
                CGFloat badgeHeight = 10.f;
                _badgeOffset = CGPointMake(3.f, 3.f);
                
                self.backgroundColor = [UIColor redColor];
                self.layer.cornerRadius = badgeHeight / 2.0;
                [self fwSetDimensionsToSize:CGSizeMake(badgeHeight, badgeHeight)];
                break;
            }
        }
    }
    return self;
}

@end

#pragma mark - UIView+FWBadge

@implementation UIView (FWBadge)

- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue
{
    [self fwHideBadge];
    
    FWBadgeView *badgeView = [[FWBadgeView alloc] initWithStyle:style];
    badgeView.badgeLabel.text = badgeValue;
    badgeView.tag = 2041;
    [self addSubview:badgeView];
    [self bringSubviewToFront:badgeView];
    
    // 默认偏移
    [badgeView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:-badgeView.badgeOffset.y];
    [badgeView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:-badgeView.badgeOffset.x];
}

- (void)fwHideBadge
{
    UIView *badgeView = [self viewWithTag:2041];
    if (badgeView) {
        [badgeView removeFromSuperview];
    }
}

@end

#pragma mark - UIBarButtonItem+FWBadge

@implementation UIBarButtonItem (FWBadge)

- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue
{
    [self fwHideBadge];
    
    // 查找内部视图，存在时调用
    [self fwInnerBadgeBlock:^(UIView *view) {
        FWBadgeView *badgeView = [[FWBadgeView alloc] initWithStyle:style];
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        
        // 自定义视图时默认偏移，否则固定偏移
        [badgeView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.customView ? -badgeView.badgeOffset.y : -3.f];
        [badgeView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.customView ? -badgeView.badgeOffset.x : -2.f];
    }];
}

- (void)fwHideBadge
{
    UIView *superview = self.fwInnerBadgeSuperview;
    if (superview) {
        UIView *badgeView = [superview viewWithTag:2041];
        if (badgeView) {
            [badgeView removeFromSuperview];
        }
    }
}

// 查找内部视图，由于view只有显示到页面后才存在，所以使用回调
- (void)fwInnerBadgeBlock:(void (^)(UIView *view))block
{
    UIView *targetView = [self fwInnerBadgeSuperview];
    // 视图已经显示
    if (targetView) {
        block(targetView);
    // 监听视图改变，存在时回调
    } else {
        [self fwObserveProperty:@"view" block:^(UIBarButtonItem *object, NSDictionary *change) {
            if ([change objectForKey:NSKeyValueChangeNewKey]) {
                UIView *innerView = [object fwInnerBadgeSuperview];
                if (innerView) {
                    block(innerView);
                }
            }
        }];
    }
}

- (UIView *)fwInnerBadgeSuperview
{
    // 自定义视图存在
    if (self.customView) {
        return self.customView;
    }
    
    // 获取内部视图：UINavigationButton
    UIView *innerView = nil;
    if ([self respondsToSelector:@selector(view)]) {
        innerView = [(id)self view];
    }
    return innerView;
}

@end

#pragma mark - UITabBarItem+FWBadege

@implementation UITabBarItem (FWBadge)

- (void)fwShowBadgeWithStyle:(FWBadgeStyle)style badgeValue:(NSString *)badgeValue
{
    [self fwHideBadge];
    
    // 查找内部视图，存在时调用
    [self fwInnerBadgeBlock:^(UIView *view) {
        FWBadgeView *badgeView = [[FWBadgeView alloc] initWithStyle:style];
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        
        // x轴默认偏移，y轴固定偏移，类似系统布局
        [badgeView fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view.superview withOffset:2.f];
        [badgeView fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:badgeView.superview withOffset:-badgeView.badgeOffset.x];
    }];
}

- (void)fwHideBadge
{
    UIView *superview = self.fwInnerBadgeSuperview;
    if (superview) {
        UIView *badgeView = [superview viewWithTag:2041];
        if (badgeView) {
            [badgeView removeFromSuperview];
        }
    }
}

// 查找内部视图，由于view只有显示到页面后才存在，所以使用回调
- (void)fwInnerBadgeBlock:(void (^)(UIView *view))block
{
    UIView *targetView = [self fwInnerBadgeSuperview];
    // 视图已经显示
    if (targetView) {
        block(targetView);
    // 监听视图改变，存在时回调
    } else {
        [self fwObserveProperty:@"view" block:^(UITabBarItem *object, NSDictionary *change) {
            if ([change objectForKey:NSKeyValueChangeNewKey]) {
                UIView *innerView = [object fwInnerBadgeSuperview];
                if (innerView) {
                    block(innerView);
                }
            }
        }];
    }
}

- (UIView *)fwInnerBadgeSuperview
{
    // 获取内部视图：UITabBarButton
    UIView *innerView = nil;
    if ([self respondsToSelector:@selector(view)]) {
        innerView = [(id)self view];
    }
    
    // 获取目标视图：UITabBarSwappableImageView
    UIView *targetView = nil;
    if (innerView) {
        Class targetClass = NSClassFromString(@"UITabBarSwappableImageView");
        for (UIView *subview in innerView.subviews) {
            if ([subview isKindOfClass:targetClass]) {
                targetView = subview;
                break;
            }
        }
    }
    return targetView;
}

@end
