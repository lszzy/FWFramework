//
//  FWBadgeView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWBadgeView.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

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
                [self fw_setDimensions:CGSizeMake(badgeHeight, badgeHeight)];
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
    [self fw_setDimension:NSLayoutAttributeHeight size:badgeHeight relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [self fw_setDimension:NSLayoutAttributeWidth size:badgeHeight relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
    
    _badgeLabel = [[UILabel alloc] init];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.font = [UIFont systemFontOfSize:fontSize];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_badgeLabel];
    [_badgeLabel fw_alignCenterToSuperview:CGPointZero];
    [_badgeLabel fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:textInset relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
    [_badgeLabel fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:textInset relation:NSLayoutRelationGreaterThanOrEqual priority:UILayoutPriorityRequired];
}

@end

#pragma mark - UIView+FWBadge

@implementation UIView (FWBadge)

- (void)fw_showBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fw_hideBadgeView];
    
    badgeView.badgeLabel.text = badgeValue;
    badgeView.tag = 2041;
    [self addSubview:badgeView];
    [self bringSubviewToFront:badgeView];
    
    // 默认偏移
    [badgeView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:-badgeView.badgeOffset.y relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    [badgeView fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:-badgeView.badgeOffset.x relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (void)fw_hideBadgeView
{
    UIView *badgeView = [self viewWithTag:2041];
    if (badgeView) {
        [badgeView removeFromSuperview];
    }
}

@end

#pragma mark - UIBarItem+FWBadge

@implementation UIBarItem (FWBadge)

- (UIView *)fw_view
{
    if ([self isKindOfClass:[UIBarButtonItem class]]) {
        if (((UIBarButtonItem *)self).customView != nil) {
            return ((UIBarButtonItem *)self).customView;
        }
    }
    
    if ([self respondsToSelector:@selector(view)]) {
        return [self fw_invokeGetter:@"view"];
    }
    return nil;
}

- (void (^)(__kindof UIBarItem *, UIView *))fw_viewLoadedBlock
{
    return objc_getAssociatedObject(self, @selector(fw_viewLoadedBlock));
}

- (void)setFw_viewLoadedBlock:(void (^)(__kindof UIBarItem *, UIView *))block
{
    objc_setAssociatedObject(self, @selector(fw_viewLoadedBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UIView *view = [self fw_view];
    if (view) {
        block(self, view);
    } else {
        [self fw_observeProperty:@"view" block:^(UIBarItem *object, NSDictionary *change) {
            if (![change objectForKey:NSKeyValueChangeNewKey]) return;
            [object fw_unobserveProperty:@"view"];
            
            UIView *view = [object fw_view];
            if (view && object.fw_viewLoadedBlock) {
                object.fw_viewLoadedBlock(object, view);
            }
        }];
    }
}

@end

#pragma mark - UIBarButtonItem+FWBadge

@implementation UIBarButtonItem (FWBadge)

- (void)fw_showBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fw_hideBadgeView];
    
    // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
    self.fw_viewLoadedBlock = ^(UIBarButtonItem *item, UIView *view) {
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        
        // 自定义视图时默认偏移，否则固定偏移
        [badgeView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.y : 0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        [badgeView fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.x : 0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    };
}

- (void)fw_hideBadgeView
{
    UIView *superview = [self fw_view];
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
                    FWBadgeView *badgeView = (FWBadgeView *)subview;
                    [selfObject bringSubviewToFront:badgeView];
                    
                    // 解决iOS13因为磨砂层切换导致的badgeView位置不对问题
                    if (@available(iOS 13.0, *)) {
                        UIView *imageView = [UITabBarItem fw_imageView:selfObject];
                        if (imageView) [badgeView fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:imageView offset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.x : -badgeView.badgeOffset.x relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
                    }
                    break;
                }
            }
        }));
    });
}

+ (UIImageView *)fw_imageView:(UIView *)tabBarButton
{
    if (!tabBarButton) return nil;
    
    UIView *superview = tabBarButton;
    if (@available(iOS 13.0, *)) {
        // iOS 13 下如果 tabBar 是磨砂的，则每个 button 内部都会有一个磨砂，而磨砂再包裹了 imageView、label 等 subview，但某些时机后系统又会把 imageView、label 挪出来放到 button 上，所以这里做个保护
        if ([tabBarButton.subviews.firstObject isKindOfClass:[UIVisualEffectView class]] && ((UIVisualEffectView *)tabBarButton.subviews.firstObject).contentView.subviews.count) {
            superview = ((UIVisualEffectView *)tabBarButton.subviews.firstObject).contentView;
        }
    }
    
    for (UIView *subview in superview.subviews) {
        // iOS10及以后，imageView都是用UITabBarSwappableImageView实现的，所以遇到这个class就直接拿
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITabBarSwappableImageView"]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

- (UIImageView *)fw_imageView
{
    UIView *tabBarButton = [self fw_view];
    return [UITabBarItem fw_imageView:tabBarButton];
}

- (void)fw_showBadgeView:(FWBadgeView *)badgeView badgeValue:(NSString *)badgeValue
{
    [self fw_hideBadgeView];
    
    // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
    self.fw_viewLoadedBlock = ^(UITabBarItem *item, UIView *view) {
        UIView *imageView = item.fw_imageView;
        if (!imageView) return;
        
        badgeView.badgeLabel.text = badgeValue;
        badgeView.tag = 2041;
        [view addSubview:badgeView];
        [view bringSubviewToFront:badgeView];
        [badgeView fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.y : 2.f relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        [badgeView fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:imageView offset:badgeView.badgeStyle == 0 ? -badgeView.badgeOffset.x : -badgeView.badgeOffset.x relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
    };
}

- (void)fw_hideBadgeView
{
    UIView *superview = [self fw_view];
    if (superview) {
        UIView *badgeView = [superview viewWithTag:2041];
        if (badgeView) {
            [badgeView removeFromSuperview];
        }
    }
}

@end
