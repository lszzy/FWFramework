//
//  UIView+FWBadge.m
//  FWFramework
//
//  Created by wuyong on 2017/4/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIView+FWBadge.h"
#import "UIView+FWAutoLayout.h"
#import "UIViewController+FWBar.h"
#import "NSObject+FWSwizzle.h"
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
        [NSObject fwSwizzleMethod:objc_getClass("UITabBarButton") selector:@selector(layoutSubviews) withBlock:^id (__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return FWSwizzleBlock(UIView, FWSwizzleReturn(void), FWSwizzleArguments(), FWSwizzleCode({
                FWSwizzleOriginal();
                
                // 解决因为层级关系变化导致的badgeView被遮挡问题
                for (UIView *subview in selfObject.subviews) {
                    if ([subview isKindOfClass:[FWBadgeView class]]) {
                        [selfObject bringSubviewToFront:subview];
                        break;
                    }
                }
            }));
        }];
    });
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
