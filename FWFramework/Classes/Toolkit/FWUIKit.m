/*!
 @header     FWUIKit.m
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWUIKit.h"
#import "FWAutoLayout.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import "FWEncode.h"
#import "FWMessage.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

#pragma mark - UIDevice+FWUIKit

@implementation UIDevice (FWUIKit)

+ (void)fwSetDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[deviceToken copy] forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fwDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

+ (NSString *)fwDeviceModel
{
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

+ (NSString *)fwDeviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fwDeviceIDFA
{
#if FWCOMPONENT_TRACKING_ENABLED
    return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
#else
    return nil;
#endif
}

@end

#pragma mark - UIView+FWUIKit

static void *kUIViewFWBorderLayerTopKey = &kUIViewFWBorderLayerTopKey;
static void *kUIViewFWBorderLayerLeftKey = &kUIViewFWBorderLayerLeftKey;
static void *kUIViewFWBorderLayerBottomKey = &kUIViewFWBorderLayerBottomKey;
static void *kUIViewFWBorderLayerRightKey = &kUIViewFWBorderLayerRightKey;

static void *kUIViewFWBorderLayerCornerKey = &kUIViewFWBorderLayerCornerKey;

static void *kUIViewFWBorderViewTopKey = &kUIViewFWBorderViewTopKey;
static void *kUIViewFWBorderViewLeftKey = &kUIViewFWBorderViewLeftKey;
static void *kUIViewFWBorderViewBottomKey = &kUIViewFWBorderViewBottomKey;
static void *kUIViewFWBorderViewRightKey = &kUIViewFWBorderViewRightKey;

@implementation UIView (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(pointInside:withEvent:), FWSwizzleReturn(BOOL), FWSwizzleArgs(CGPoint point, UIEvent *event), FWSwizzleCode({
            NSValue *insetsValue = objc_getAssociatedObject(selfObject, @selector(fwTouchInsets));
            if (insetsValue) {
                UIEdgeInsets touchInsets = [insetsValue UIEdgeInsetsValue];
                CGRect bounds = selfObject.bounds;
                bounds = CGRectMake(bounds.origin.x - touchInsets.left,
                                    bounds.origin.y - touchInsets.top,
                                    bounds.size.width + touchInsets.left + touchInsets.right,
                                    bounds.size.height + touchInsets.top + touchInsets.bottom);
                return CGRectContainsPoint(bounds, point);
            }
            
            return FWSwizzleOriginal(point, event);
        }));
        
        FWSwizzleClass(UILabel, @selector(drawTextInRect:), FWSwizzleReturn(void), FWSwizzleArgs(CGRect rect), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fwContentInset));
            if (contentInsetValue) {
                rect = UIEdgeInsetsInsetRect(rect, [contentInsetValue UIEdgeInsetsValue]);
            }
            
            UIControlContentVerticalAlignment verticalAlignment = [objc_getAssociatedObject(selfObject, @selector(fwVerticalAlignment)) integerValue];
            if (verticalAlignment == UIControlContentVerticalAlignmentTop) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, fitsSize.height);
            } else if (verticalAlignment == UIControlContentVerticalAlignmentBottom) {
                CGSize fitsSize = [selfObject sizeThatFits:rect.size];
                rect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height - fitsSize.height), rect.size.width, fitsSize.height);
            }
            
            FWSwizzleOriginal(rect);
        }));
        
        FWSwizzleClass(UILabel, @selector(intrinsicContentSize), FWSwizzleReturn(CGSize), FWSwizzleArgs(), FWSwizzleCode({
            CGSize size = FWSwizzleOriginal();
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fwContentInset));
            if (contentInsetValue && !CGSizeEqualToSize(size, CGSizeZero)) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom);
            }
            return size;
        }));
        
        FWSwizzleClass(UILabel, @selector(sizeThatFits:), FWSwizzleReturn(CGSize), FWSwizzleArgs(CGSize size), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(fwContentInset));
            if (contentInsetValue) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width - contentInset.left - contentInset.right, size.height - contentInset.top - contentInset.bottom);
                CGSize fitsSize = FWSwizzleOriginal(size);
                if (!CGSizeEqualToSize(fitsSize, CGSizeZero)) {
                    fitsSize = CGSizeMake(fitsSize.width + contentInset.left + contentInset.right, fitsSize.height + contentInset.top + contentInset.bottom);
                }
                return fitsSize;
            }
            
            return FWSwizzleOriginal(size);
        }));
        
        FWSwizzleClass(UIButton, @selector(setEnabled:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL enabled), FWSwizzleCode({
            FWSwizzleOriginal(enabled);
            
            if (selfObject.fwDisabledAlpha > 0) {
                selfObject.alpha = enabled ? 1 : selfObject.fwDisabledAlpha;
            }
        }));
        
        FWSwizzleClass(UIButton, @selector(setHighlighted:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL highlighted), FWSwizzleCode({
            FWSwizzleOriginal(highlighted);
            
            if (selfObject.enabled && selfObject.fwHighlightedAlpha > 0) {
                selfObject.alpha = highlighted ? selfObject.fwHighlightedAlpha : 1;
            }
        }));
    });
}

- (UIViewController *)fwViewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (UIEdgeInsets)fwTouchInsets
{
    return [objc_getAssociatedObject(self, @selector(fwTouchInsets)) UIEdgeInsetsValue];
}

- (void)setFwTouchInsets:(UIEdgeInsets)fwTouchInsets
{
    objc_setAssociatedObject(self, @selector(fwTouchInsets), [NSValue valueWithUIEdgeInsets:fwTouchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 1.0;
}

- (void)fwSetBorderColor:(UIColor *)color width:(CGFloat)width
{
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
}

- (void)fwSetBorderColor:(UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius
{
    [self fwSetBorderColor:color width:width];
    [self fwSetCornerRadius:radius];
}

- (void)fwSetCornerRadius:(CGFloat)radius
{
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
}

- (void)fwSetBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self fwSetBorderLayer:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)fwSetBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    CALayer *borderLayer;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderLayer = [self fwInnerBorderLayer:kUIViewFWBorderLayerTopKey edge:UIRectEdgeTop];
        borderLayer.frame = CGRectMake(leftInset, 0, self.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderLayer = [self fwInnerBorderLayer:kUIViewFWBorderLayerLeftKey edge:UIRectEdgeLeft];
        borderLayer.frame = CGRectMake(0, leftInset, width, self.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderLayer = [self fwInnerBorderLayer:kUIViewFWBorderLayerBottomKey edge:UIRectEdgeBottom];
        borderLayer.frame = CGRectMake(leftInset, self.bounds.size.height - width, self.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderLayer = [self fwInnerBorderLayer:kUIViewFWBorderLayerRightKey edge:UIRectEdgeRight];
        borderLayer.frame = CGRectMake(self.bounds.size.width - width, leftInset, width, self.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
}

- (CALayer *)fwInnerBorderLayer:(const void *)edgeKey edge:(UIRectEdge)edge
{
    CALayer *borderLayer = objc_getAssociatedObject(self, edgeKey);
    if (!borderLayer) {
        borderLayer = [CALayer layer];
        [self.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self, edgeKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return borderLayer;
}

- (void)fwSetCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius
{
    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    cornerLayer.frame = self.bounds;
    cornerLayer.path = path.CGPath;
    self.layer.mask = cornerLayer;
}

- (void)fwSetCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(UIColor *)color width:(CGFloat)width
{
    [self fwSetCornerLayer:corner radius:radius];
    
    CAShapeLayer *borderLayer = objc_getAssociatedObject(self, kUIViewFWBorderLayerCornerKey);
    if (!borderLayer) {
        borderLayer = [CAShapeLayer layer];
        [self.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self, kUIViewFWBorderLayerCornerKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    borderLayer.frame = self.bounds;
    borderLayer.path = path.CGPath;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.lineWidth = width * 2;
    borderLayer.fillColor = nil;
}

- (void)fwSetBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self fwSetBorderView:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)fwSetBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    UIView *borderView;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderView = [self fwInnerBorderView:kUIViewFWBorderViewTopKey edge:UIRectEdgeTop];
        [borderView fwConstraintForKey:@(NSLayoutAttributeHeight)].constant = width;
        [borderView fwConstraintForKey:@(NSLayoutAttributeLeft)].constant = leftInset;
        [borderView fwConstraintForKey:@(NSLayoutAttributeRight)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderView = [self fwInnerBorderView:kUIViewFWBorderViewLeftKey edge:UIRectEdgeLeft];
        [borderView fwConstraintForKey:@(NSLayoutAttributeWidth)].constant = width;
        [borderView fwConstraintForKey:@(NSLayoutAttributeTop)].constant = leftInset;
        [borderView fwConstraintForKey:@(NSLayoutAttributeBottom)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderView = [self fwInnerBorderView:kUIViewFWBorderViewBottomKey edge:UIRectEdgeBottom];
        [borderView fwConstraintForKey:@(NSLayoutAttributeHeight)].constant = width;
        [borderView fwConstraintForKey:@(NSLayoutAttributeLeft)].constant = leftInset;
        [borderView fwConstraintForKey:@(NSLayoutAttributeRight)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderView = [self fwInnerBorderView:kUIViewFWBorderViewRightKey edge:UIRectEdgeRight];
        [borderView fwConstraintForKey:@(NSLayoutAttributeWidth)].constant = width;
        [borderView fwConstraintForKey:@(NSLayoutAttributeTop)].constant = leftInset;
        [borderView fwConstraintForKey:@(NSLayoutAttributeBottom)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
}

- (UIView *)fwInnerBorderView:(const void *)edgeKey edge:(UIRectEdge)edge
{
    UIView *borderView = objc_getAssociatedObject(self, edgeKey);
    if (!borderView) {
        borderView = [UIView fwAutoLayoutView];
        [self addSubview:borderView];
        objc_setAssociatedObject(self, edgeKey, borderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (edge == UIRectEdgeTop || edge == UIRectEdgeBottom) {
            [borderView fwPinEdgeToSuperview:(edge == UIRectEdgeTop ? NSLayoutAttributeTop : NSLayoutAttributeBottom)];
            [borderView fwSetConstraint:[borderView fwSetDimension:NSLayoutAttributeHeight toSize:0] forKey:@(NSLayoutAttributeHeight)];
            [borderView fwSetConstraint:[borderView fwPinEdgeToSuperview:NSLayoutAttributeLeft] forKey:@(NSLayoutAttributeLeft)];
            [borderView fwSetConstraint:[borderView fwPinEdgeToSuperview:NSLayoutAttributeRight] forKey:@(NSLayoutAttributeRight)];
        } else {
            [borderView fwPinEdgeToSuperview:(edge == UIRectEdgeLeft ? NSLayoutAttributeLeft : NSLayoutAttributeRight)];
            [borderView fwSetConstraint:[borderView fwSetDimension:NSLayoutAttributeWidth toSize:0] forKey:@(NSLayoutAttributeWidth)];
            [borderView fwSetConstraint:[borderView fwPinEdgeToSuperview:NSLayoutAttributeTop] forKey:@(NSLayoutAttributeTop)];
            [borderView fwSetConstraint:[borderView fwPinEdgeToSuperview:NSLayoutAttributeBottom] forKey:@(NSLayoutAttributeBottom)];
        }
    }
    return borderView;
}

@end

#pragma mark - CAAnimation+FWUIKit

@interface FWInnerAnimationTarget : NSObject <CAAnimationDelegate>

@property (nonatomic, copy) void (^startBlock)(CAAnimation *animation);

@property (nonatomic, copy) void (^stopBlock)(CAAnimation *animation, BOOL finished);

@end

@implementation FWInnerAnimationTarget

- (void)animationDidStart:(CAAnimation *)anim
{
    if (self.startBlock) self.startBlock(anim);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.stopBlock) self.stopBlock(anim, flag);
}

@end

@implementation CAAnimation (FWUIKit)

- (FWInnerAnimationTarget *)fwInnerAnimationTarget:(BOOL)lazyload
{
    FWInnerAnimationTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerAnimationTarget alloc] init];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(CAAnimation * _Nonnull))fwStartBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.startBlock;
}

- (void)setFwStartBlock:(void (^)(CAAnimation * _Nonnull))startBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.startBlock = startBlock;
    self.delegate = target;
}

- (void (^)(CAAnimation * _Nonnull, BOOL))fwStopBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.stopBlock;
}

- (void)setFwStopBlock:(void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.stopBlock = stopBlock;
    self.delegate = target;
}

@end

#pragma mark - UILabel+FWUIKit

@implementation UILabel (FWUIKit)

- (UIEdgeInsets)fwContentInset
{
    return [objc_getAssociatedObject(self, @selector(fwContentInset)) UIEdgeInsetsValue];
}

- (void)setFwContentInset:(UIEdgeInsets)fwContentInset
{
    objc_setAssociatedObject(self, @selector(fwContentInset), [NSValue valueWithUIEdgeInsets:fwContentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

- (UIControlContentVerticalAlignment)fwVerticalAlignment
{
    return [objc_getAssociatedObject(self, @selector(fwVerticalAlignment)) integerValue];
}

- (void)setFwVerticalAlignment:(UIControlContentVerticalAlignment)fwVerticalAlignment
{
    objc_setAssociatedObject(self, @selector(fwVerticalAlignment), @(fwVerticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setNeedsDisplay];
}

+ (instancetype)fwLabelWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor
{
    UILabel *label = [[self alloc] init];
    [label fwSetText:text font:font textColor:textColor];
    return label;
}

+ (instancetype)fwLabelWithFont:(UIFont *)font textColor:(UIColor *)textColor
{
    return [self fwLabelWithText:nil font:font textColor:textColor];
}

- (void)fwSetText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor
{
    if (text) self.text = text;
    if (font) self.font = font;
    if (textColor) self.textColor = textColor;
}

- (void)fwSetFont:(UIFont *)font textColor:(UIColor *)textColor
{
    [self fwSetText:nil font:font textColor:textColor];
}

@end

#pragma mark - UIButton+FWUIKit

@implementation UIButton (FWUIKit)

- (CGFloat)fwDisabledAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwDisabledAlpha)) doubleValue];
}

- (void)setFwDisabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwDisabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (alpha > 0) {
        self.alpha = self.isEnabled ? 1 : alpha;
    }
}

- (CGFloat)fwHighlightedAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwHighlightedAlpha)) doubleValue];
}

- (void)setFwHighlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwHighlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.enabled && alpha > 0) {
        self.alpha = self.isHighlighted ? alpha : 1;
    }
}

+ (instancetype)fwButtonWithTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button fwSetTitle:title font:font titleColor:titleColor];
    return button;
}

- (void)fwSetTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    if (title) [self setTitle:title forState:UIControlStateNormal];
    if (font) self.titleLabel.font = font;
    if (titleColor) [self setTitleColor:titleColor forState:UIControlStateNormal];
}

+ (instancetype)fwButtonWithImage:(UIImage *)image
{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button fwSetImage:image];
    return button;
}

- (void)fwSetImage:(UIImage *)image
{
    [self setImage:image forState:UIControlStateNormal];
}

- (void)fwSetImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing
{
    CGSize imageSize = self.imageView.image.size;
    CGSize labelSize = self.titleLabel.intrinsicContentSize;
    switch (edge) {
        case UIRectEdgeLeft:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
            break;
        case UIRectEdgeRight:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, labelSize.width + spacing, 0, -labelSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width - spacing, 0, imageSize.width);
            break;
        case UIRectEdgeTop:
            self.imageEdgeInsets = UIEdgeInsetsMake(-labelSize.height - spacing, 0, 0, -labelSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -imageSize.height - spacing, 0);
            break;
        case UIRectEdgeBottom:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, -labelSize.height - spacing, -labelSize.width);
            self.titleEdgeInsets = UIEdgeInsetsMake(-imageSize.height - spacing, -imageSize.width, 0, 0);
            break;
        default:
            break;
    }
}

@end

#pragma mark - UIScrollView+FWUIKit

@implementation UIScrollView (FWUIKit)

- (BOOL)fwCanScroll
{
    return [self fwCanScrollVertical] || [self fwCanScrollHorizontal];
}

- (BOOL)fwCanScrollHorizontal
{
    if (self.bounds.size.width <= 0) return NO;
    return self.contentSize.width + self.adjustedContentInset.left + self.adjustedContentInset.right > CGRectGetWidth(self.bounds);
}

- (BOOL)fwCanScrollVertical
{
    if (self.bounds.size.height <= 0) return NO;
    return self.contentSize.height + self.adjustedContentInset.top + self.adjustedContentInset.bottom > CGRectGetHeight(self.bounds);
}

- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint contentOffset = [self fwContentOffsetOfEdge:edge];
    [self setContentOffset:contentOffset animated:animated];
}

- (BOOL)fwIsScrollToEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = [self fwContentOffsetOfEdge:edge];
    switch (edge) {
        case UIRectEdgeTop:
            return self.contentOffset.y <= contentOffset.y;
        case UIRectEdgeLeft:
            return self.contentOffset.x <= contentOffset.x;
        case UIRectEdgeBottom:
            return self.contentOffset.y >= contentOffset.y;
        case UIRectEdgeRight:
            return self.contentOffset.x >= contentOffset.x;
        default:
            return NO;
    }
}

- (CGPoint)fwContentOffsetOfEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = self.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            contentOffset.y = -self.adjustedContentInset.top;
            break;
        case UIRectEdgeLeft:
            contentOffset.x = -self.adjustedContentInset.left;
            break;
        case UIRectEdgeBottom:
            contentOffset.y = self.contentSize.height - self.bounds.size.height + self.adjustedContentInset.bottom;
            break;
        case UIRectEdgeRight:
            contentOffset.x = self.contentSize.width - self.bounds.size.width + self.adjustedContentInset.right;
            break;
        default:
            break;
    }
    return contentOffset;
}

- (NSInteger)fwTotalPage
{
    if ([self fwCanScrollVertical]) {
        return (NSInteger)ceil((self.contentSize.height / self.frame.size.height));
    } else {
        return (NSInteger)ceil((self.contentSize.width / self.frame.size.width));
    }
}

- (NSInteger)fwCurrentPage
{
    if ([self fwCanScrollVertical]) {
        CGFloat pageHeight = self.frame.size.height;
        return (NSInteger)floor((self.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
    } else {
        CGFloat pageWidth = self.frame.size.width;
        return (NSInteger)floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    }
}

- (void)setFwCurrentPage:(NSInteger)page
{
    if ([self fwCanScrollVertical]) {
        CGFloat offset = (self.frame.size.height * page);
        self.contentOffset = CGPointMake(0.f, offset);
    } else {
        CGFloat offset = (self.frame.size.width * page);
        self.contentOffset = CGPointMake(offset, 0.f);
    }
}

- (void)fwSetCurrentPage:(NSInteger)page animated:(BOOL)animated
{
    if ([self fwCanScrollVertical]) {
        CGFloat offset = (self.frame.size.height * page);
        [self setContentOffset:CGPointMake(0.f, offset) animated:animated];
    } else {
        CGFloat offset = (self.frame.size.width * page);
        [self setContentOffset:CGPointMake(offset, 0.f) animated:animated];
    }
}

- (BOOL)fwIsLastPage
{
    return (self.fwCurrentPage == (self.fwTotalPage - 1));
}

@end

#pragma mark - UIPageControl+FWUIKit

@implementation UIPageControl (FWUIKit)

- (CGSize)fwPreferredSize
{
    CGSize size = self.bounds.size;
    if (size.height <= 0) {
        size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(10, 10);
    }
    return size;
}

- (void)setFwPreferredSize:(CGSize)size
{
    CGFloat height = [self fwPreferredSize].height;
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - UISlider+FWUIKit

@implementation UISlider (FWUIKit)

- (CGSize)fwThumbSize
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fwThumbSize));
    return value ? [value CGSizeValue] : CGSizeZero;
}

- (void)setFwThumbSize:(CGSize)fwThumbSize
{
    objc_setAssociatedObject(self, @selector(fwThumbSize), [NSValue valueWithCGSize:fwThumbSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateThumbImage];
}

- (UIColor *)fwThumbColor
{
    return objc_getAssociatedObject(self, @selector(fwThumbColor));
}

- (void)setFwThumbColor:(UIColor *)fwThumbColor
{
    objc_setAssociatedObject(self, @selector(fwThumbColor), fwThumbColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwUpdateThumbImage];
}

- (void)fwUpdateThumbImage
{
    CGSize thumbSize = self.fwThumbSize;
    if (thumbSize.width <= 0 || thumbSize.height <= 0) return;
    UIColor *thumbColor = self.fwThumbColor ?: (self.tintColor ?: [UIColor whiteColor]);
    UIImage *thumbImage = [UIImage fwImageWithSize:thumbSize block:^(CGContextRef  _Nonnull context) {
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
        CGContextSetFillColorWithColor(context, thumbColor.CGColor);
        [path fill];
    }];
    
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

@end

#pragma mark - UISwitch+FWUIKit

@implementation UISwitch (FWUIKit)

- (CGSize)fwPreferredSize
{
    CGSize size = self.bounds.size;
    if (size.height <= 0) {
        size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(51, 31);
    }
    return size;
}

- (void)setFwPreferredSize:(CGSize)size
{
    CGFloat height = [self fwPreferredSize].height;
    CGFloat scale = size.height / height;
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - UITextField+FWUIKit

@implementation UITextField (FWUIKit)

- (NSInteger)fwMaxLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxLength)) integerValue];
}

- (void)setFwMaxLength:(NSInteger)fwMaxLength
{
    objc_setAssociatedObject(self, @selector(fwMaxLength), @(fwMaxLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSInteger)fwMaxUnicodeLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxUnicodeLength)) integerValue];
}

- (void)setFwMaxUnicodeLength:(NSInteger)fwMaxUnicodeLength
{
    objc_setAssociatedObject(self, @selector(fwMaxUnicodeLength), @(fwMaxUnicodeLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (void)fwTextLengthChanged
{
    if (self.fwMaxLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if (self.text.length > self.fwMaxLength) {
                    // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                    self.text = [self.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.text = [self.text substringToIndex:self.fwMaxLength];
                }
            }
        } else {
            if (self.text.length > self.fwMaxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                self.text = [self.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.text = [self.text substringToIndex:self.fwMaxLength];
            }
        }
    }
    
    if (self.fwMaxUnicodeLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                    self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
                }
            }
        } else {
            if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
            }
        }
    }
}

- (NSTimeInterval)fwAutoCompleteInterval
{
    NSTimeInterval interval = [objc_getAssociatedObject(self, @selector(fwAutoCompleteInterval)) doubleValue];
    return interval > 0 ? interval : 1.0;
}

- (void)setFwAutoCompleteInterval:(NSTimeInterval)fwAutoCompleteInterval
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteInterval), @(fwAutoCompleteInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(NSString *))fwAutoCompleteBlock
{
    return objc_getAssociatedObject(self, @selector(fwAutoCompleteBlock));
}

- (void)setFwAutoCompleteBlock:(void (^)(NSString *))fwAutoCompleteBlock
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteBlock), fwAutoCompleteBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSTimeInterval)fwAutoCompleteTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fwAutoCompleteTimestamp)) doubleValue];
}

- (void)setFwAutoCompleteTimestamp:(NSTimeInterval)fwAutoCompleteTimestamp
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteTimestamp), @(fwAutoCompleteTimestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwInnerLengthEvent
{
    id object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        [self addTarget:self action:@selector(fwInnerLengthAction) forControlEvents:UIControlEventEditingChanged];
        objc_setAssociatedObject(self, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)fwInnerLengthAction
{
    [self fwTextLengthChanged];
    
    if (self.fwAutoCompleteBlock) {
        self.fwAutoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = self.text;
        if (inputText.fwTrimString.length < 1) {
            self.fwAutoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.fwAutoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.fwAutoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.fwAutoCompleteTimestamp) {
                    self.fwAutoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end

#pragma mark - UITextView+FWUIKit

@implementation UITextView (FWUIKit)

- (NSInteger)fwMaxLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxLength)) integerValue];
}

- (void)setFwMaxLength:(NSInteger)fwMaxLength
{
    objc_setAssociatedObject(self, @selector(fwMaxLength), @(fwMaxLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSInteger)fwMaxUnicodeLength
{
    return [objc_getAssociatedObject(self, @selector(fwMaxUnicodeLength)) integerValue];
}

- (void)setFwMaxUnicodeLength:(NSInteger)fwMaxUnicodeLength
{
    objc_setAssociatedObject(self, @selector(fwMaxUnicodeLength), @(fwMaxUnicodeLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (void)fwTextLengthChanged
{
    if (self.fwMaxLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if (self.text.length > self.fwMaxLength) {
                    // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                    self.text = [self.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.text = [self.text substringToIndex:self.fwMaxLength];
                }
            }
        } else {
            if (self.text.length > self.fwMaxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.text rangeOfComposedCharacterSequenceAtIndex:self.fwMaxLength];
                self.text = [self.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.text = [self.text substringToIndex:self.fwMaxLength];
            }
        }
    }
    
    if (self.fwMaxUnicodeLength > 0) {
        if (self.markedTextRange) {
            if (![self positionFromPosition:self.markedTextRange.start offset:0]) {
                if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                    self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
                }
            }
        } else {
            if ([self.text fwUnicodeLength] > self.fwMaxUnicodeLength) {
                self.text = [self.text fwUnicodeSubstring:self.fwMaxUnicodeLength];
            }
        }
    }
}

- (NSTimeInterval)fwAutoCompleteInterval
{
    NSTimeInterval interval = [objc_getAssociatedObject(self, @selector(fwAutoCompleteInterval)) doubleValue];
    return interval > 0 ? interval : 1.0;
}

- (void)setFwAutoCompleteInterval:(NSTimeInterval)fwAutoCompleteInterval
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteInterval), @(fwAutoCompleteInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(NSString *))fwAutoCompleteBlock
{
    return objc_getAssociatedObject(self, @selector(fwAutoCompleteBlock));
}

- (void)setFwAutoCompleteBlock:(void (^)(NSString *))fwAutoCompleteBlock
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteBlock), fwAutoCompleteBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self fwInnerLengthEvent];
}

- (NSTimeInterval)fwAutoCompleteTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fwAutoCompleteTimestamp)) doubleValue];
}

- (void)setFwAutoCompleteTimestamp:(NSTimeInterval)fwAutoCompleteTimestamp
{
    objc_setAssociatedObject(self, @selector(fwAutoCompleteTimestamp), @(fwAutoCompleteTimestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwInnerLengthEvent
{
    id object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwInnerLengthAction)];
        objc_setAssociatedObject(self, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)fwInnerLengthAction
{
    [self fwTextLengthChanged];
    
    if (self.fwAutoCompleteBlock) {
        self.fwAutoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = self.text;
        if (inputText.fwTrimString.length < 1) {
            self.fwAutoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.fwAutoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.fwAutoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.fwAutoCompleteTimestamp) {
                    self.fwAutoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end

#pragma mark - UIViewController+FWUIKit

@implementation UIViewController (FWUIKit)

- (BOOL)fwIsRoot
{
    return !self.navigationController || self.navigationController.viewControllers.firstObject == self;
}

- (BOOL)fwIsChild
{
    UIViewController *parentController = self.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)fwIsPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.navigationController ?: self;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
}

- (BOOL)fwIsLoaded
{
    return [objc_getAssociatedObject(self, @selector(fwIsLoaded)) boolValue];
}

- (void)setFwIsLoaded:(BOOL)fwIsLoaded
{
    objc_setAssociatedObject(self, @selector(fwIsLoaded), @(fwIsLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
