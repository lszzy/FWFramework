/**
 @header     FWUIKit.m
 @indexgroup FWFramework
      FWUIKit
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

#pragma mark - FWDeviceClassWrapper+FWUIKit

@implementation FWDeviceClassWrapper (FWUIKit)

- (void)setDeviceTokenData:(NSData *)tokenData
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

- (NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

- (NSString *)deviceModel
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

- (NSString *)deviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

@end

#pragma mark - FWViewWrapper+FWUIKit

static void *kUIViewFWBorderLayerTopKey = &kUIViewFWBorderLayerTopKey;
static void *kUIViewFWBorderLayerLeftKey = &kUIViewFWBorderLayerLeftKey;
static void *kUIViewFWBorderLayerBottomKey = &kUIViewFWBorderLayerBottomKey;
static void *kUIViewFWBorderLayerRightKey = &kUIViewFWBorderLayerRightKey;

static void *kUIViewFWBorderLayerCornerKey = &kUIViewFWBorderLayerCornerKey;

static void *kUIViewFWBorderViewTopKey = &kUIViewFWBorderViewTopKey;
static void *kUIViewFWBorderViewLeftKey = &kUIViewFWBorderViewLeftKey;
static void *kUIViewFWBorderViewBottomKey = &kUIViewFWBorderViewBottomKey;
static void *kUIViewFWBorderViewRightKey = &kUIViewFWBorderViewRightKey;

@implementation FWViewWrapper (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(pointInside:withEvent:), FWSwizzleReturn(BOOL), FWSwizzleArgs(CGPoint point, UIEvent *event), FWSwizzleCode({
            NSValue *insetsValue = objc_getAssociatedObject(selfObject, @selector(touchInsets));
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
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(contentInset));
            if (contentInsetValue) {
                rect = UIEdgeInsetsInsetRect(rect, [contentInsetValue UIEdgeInsetsValue]);
            }
            
            UIControlContentVerticalAlignment verticalAlignment = [objc_getAssociatedObject(selfObject, @selector(verticalAlignment)) integerValue];
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
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(contentInset));
            if (contentInsetValue && !CGSizeEqualToSize(size, CGSizeZero)) {
                UIEdgeInsets contentInset = [contentInsetValue UIEdgeInsetsValue];
                size = CGSizeMake(size.width + contentInset.left + contentInset.right, size.height + contentInset.top + contentInset.bottom);
            }
            return size;
        }));
        
        FWSwizzleClass(UILabel, @selector(sizeThatFits:), FWSwizzleReturn(CGSize), FWSwizzleArgs(CGSize size), FWSwizzleCode({
            NSValue *contentInsetValue = objc_getAssociatedObject(selfObject, @selector(contentInset));
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
            
            if (selfObject.fw.disabledAlpha > 0) {
                selfObject.alpha = enabled ? 1 : selfObject.fw.disabledAlpha;
            }
        }));
        
        FWSwizzleClass(UIButton, @selector(setHighlighted:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL highlighted), FWSwizzleCode({
            FWSwizzleOriginal(highlighted);
            
            if (selfObject.enabled && selfObject.fw.highlightedAlpha > 0) {
                selfObject.alpha = highlighted ? selfObject.fw.highlightedAlpha : 1;
            }
        }));
    });
}

- (BOOL)isViewVisible
{
    if (self.base.hidden || self.base.alpha <= 0.01 || !self.base.window) return NO;
    if (self.base.bounds.size.width == 0 || self.base.bounds.size.height == 0) return NO;
    return YES;
}

- (UIViewController *)viewController
{
    UIResponder *responder = [self.base nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (UIEdgeInsets)touchInsets
{
    return [objc_getAssociatedObject(self.base, @selector(touchInsets)) UIEdgeInsetsValue];
}

- (void)setTouchInsets:(UIEdgeInsets)touchInsets
{
    objc_setAssociatedObject(self.base, @selector(touchInsets), [NSValue valueWithUIEdgeInsets:touchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    self.base.layer.shadowColor = color.CGColor;
    self.base.layer.shadowOffset = offset;
    self.base.layer.shadowRadius = radius;
    self.base.layer.shadowOpacity = 1.0;
}

- (void)setBorderColor:(UIColor *)color width:(CGFloat)width
{
    self.base.layer.borderColor = color.CGColor;
    self.base.layer.borderWidth = width;
}

- (void)setBorderColor:(UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius
{
    [self setBorderColor:color width:width];
    [self setCornerRadius:radius];
}

- (void)setCornerRadius:(CGFloat)radius
{
    self.base.layer.cornerRadius = radius;
    self.base.layer.masksToBounds = YES;
}

- (void)setBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self setBorderLayer:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)setBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    CALayer *borderLayer;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderLayer = [self innerBorderLayer:kUIViewFWBorderLayerTopKey edge:UIRectEdgeTop];
        borderLayer.frame = CGRectMake(leftInset, 0, self.base.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderLayer = [self innerBorderLayer:kUIViewFWBorderLayerLeftKey edge:UIRectEdgeLeft];
        borderLayer.frame = CGRectMake(0, leftInset, width, self.base.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderLayer = [self innerBorderLayer:kUIViewFWBorderLayerBottomKey edge:UIRectEdgeBottom];
        borderLayer.frame = CGRectMake(leftInset, self.base.bounds.size.height - width, self.base.bounds.size.width - leftInset - rightInset, width);
        borderLayer.backgroundColor = color.CGColor;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderLayer = [self innerBorderLayer:kUIViewFWBorderLayerRightKey edge:UIRectEdgeRight];
        borderLayer.frame = CGRectMake(self.base.bounds.size.width - width, leftInset, width, self.base.bounds.size.height - leftInset - rightInset);
        borderLayer.backgroundColor = color.CGColor;
    }
}

- (CALayer *)innerBorderLayer:(const void *)edgeKey edge:(UIRectEdge)edge
{
    CALayer *borderLayer = objc_getAssociatedObject(self.base, edgeKey);
    if (!borderLayer) {
        borderLayer = [CALayer layer];
        [self.base.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self.base, edgeKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return borderLayer;
}

- (void)setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius
{
    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.base.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    cornerLayer.frame = self.base.bounds;
    cornerLayer.path = path.CGPath;
    self.base.layer.mask = cornerLayer;
}

- (void)setCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(UIColor *)color width:(CGFloat)width
{
    [self setCornerLayer:corner radius:radius];
    
    CAShapeLayer *borderLayer = objc_getAssociatedObject(self.base, kUIViewFWBorderLayerCornerKey);
    if (!borderLayer) {
        borderLayer = [CAShapeLayer layer];
        [self.base.layer addSublayer:borderLayer];
        objc_setAssociatedObject(self.base, kUIViewFWBorderLayerCornerKey, borderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.base.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
    borderLayer.frame = self.base.bounds;
    borderLayer.path = path.CGPath;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.lineWidth = width * 2;
    borderLayer.fillColor = nil;
}

- (void)setBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width
{
    [self setBorderView:edge color:color width:width leftInset:0 rightInset:0];
}

- (void)setBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset
{
    UIView *borderView;
    
    if ((edge & UIRectEdgeTop) == UIRectEdgeTop) {
        borderView = [self innerBorderView:kUIViewFWBorderViewTopKey edge:UIRectEdgeTop];
        [borderView.fw constraintForKey:@(NSLayoutAttributeHeight)].constant = width;
        [borderView.fw constraintForKey:@(NSLayoutAttributeLeft)].constant = leftInset;
        [borderView.fw constraintForKey:@(NSLayoutAttributeRight)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeLeft) == UIRectEdgeLeft) {
        borderView = [self innerBorderView:kUIViewFWBorderViewLeftKey edge:UIRectEdgeLeft];
        [borderView.fw constraintForKey:@(NSLayoutAttributeWidth)].constant = width;
        [borderView.fw constraintForKey:@(NSLayoutAttributeTop)].constant = leftInset;
        [borderView.fw constraintForKey:@(NSLayoutAttributeBottom)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeBottom) == UIRectEdgeBottom) {
        borderView = [self innerBorderView:kUIViewFWBorderViewBottomKey edge:UIRectEdgeBottom];
        [borderView.fw constraintForKey:@(NSLayoutAttributeHeight)].constant = width;
        [borderView.fw constraintForKey:@(NSLayoutAttributeLeft)].constant = leftInset;
        [borderView.fw constraintForKey:@(NSLayoutAttributeRight)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
    
    if ((edge & UIRectEdgeRight) == UIRectEdgeRight) {
        borderView = [self innerBorderView:kUIViewFWBorderViewRightKey edge:UIRectEdgeRight];
        [borderView.fw constraintForKey:@(NSLayoutAttributeWidth)].constant = width;
        [borderView.fw constraintForKey:@(NSLayoutAttributeTop)].constant = leftInset;
        [borderView.fw constraintForKey:@(NSLayoutAttributeBottom)].constant = -rightInset;
        borderView.backgroundColor = color;
    }
}

- (UIView *)innerBorderView:(const void *)edgeKey edge:(UIRectEdge)edge
{
    UIView *borderView = objc_getAssociatedObject(self.base, edgeKey);
    if (!borderView) {
        borderView = [[UIView alloc] init];
        [self.base addSubview:borderView];
        objc_setAssociatedObject(self.base, edgeKey, borderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        if (edge == UIRectEdgeTop || edge == UIRectEdgeBottom) {
            [borderView.fw pinEdgeToSuperview:(edge == UIRectEdgeTop ? NSLayoutAttributeTop : NSLayoutAttributeBottom)];
            [borderView.fw setConstraint:[borderView.fw setDimension:NSLayoutAttributeHeight toSize:0] forKey:@(NSLayoutAttributeHeight)];
            [borderView.fw setConstraint:[borderView.fw pinEdgeToSuperview:NSLayoutAttributeLeft] forKey:@(NSLayoutAttributeLeft)];
            [borderView.fw setConstraint:[borderView.fw pinEdgeToSuperview:NSLayoutAttributeRight] forKey:@(NSLayoutAttributeRight)];
        } else {
            [borderView.fw pinEdgeToSuperview:(edge == UIRectEdgeLeft ? NSLayoutAttributeLeft : NSLayoutAttributeRight)];
            [borderView.fw setConstraint:[borderView.fw setDimension:NSLayoutAttributeWidth toSize:0] forKey:@(NSLayoutAttributeWidth)];
            [borderView.fw setConstraint:[borderView.fw pinEdgeToSuperview:NSLayoutAttributeTop] forKey:@(NSLayoutAttributeTop)];
            [borderView.fw setConstraint:[borderView.fw pinEdgeToSuperview:NSLayoutAttributeBottom] forKey:@(NSLayoutAttributeBottom)];
        }
    }
    return borderView;
}

@end

#pragma mark - FWLabelWrapper+FWUIKit

@interface UILabel (FWUIKit)

- (void)innerSetText:(NSString *)text;

- (void)innerSetAttributedText:(NSAttributedString *)text;

- (void)innerSetLineBreakMode:(NSLineBreakMode)lineBreakMode;

- (void)innerSetTextAlignment:(NSTextAlignment)textAlignment;

@end

@implementation FWLabelWrapper (FWUIKit)

- (void)setTextAttributes:(NSDictionary<NSAttributedStringKey,id> *)textAttributes
{
    NSDictionary *prevTextAttributes = self.textAttributes;
    if ([prevTextAttributes isEqualToDictionary:textAttributes]) {
        return;
    }
    
    objc_setAssociatedObject(self.base, @selector(textAttributes), textAttributes, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if (!self.base.text.length) {
        return;
    }
    NSMutableAttributedString *string = [self.base.attributedText mutableCopy];
    NSRange fullRange = NSMakeRange(0, string.length);
    
    if (prevTextAttributes) {
        NSMutableArray *willRemovedAttributes = [NSMutableArray array];
        [string enumerateAttributesInRange:NSMakeRange(0, string.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            if (NSEqualRanges(range, NSMakeRange(0, string.length - 1)) && [attrs[NSKernAttributeName] isEqualToNumber:prevTextAttributes[NSKernAttributeName]]) {
                [string removeAttribute:NSKernAttributeName range:NSMakeRange(0, string.length - 1)];
            }
            if (!NSEqualRanges(range, fullRange)) {
                return;
            }
            [attrs enumerateKeysAndObjectsUsingBlock:^(NSAttributedStringKey _Nonnull attr, id  _Nonnull value, BOOL * _Nonnull stop) {
                if (prevTextAttributes[attr] == value) {
                    [willRemovedAttributes addObject:attr];
                }
            }];
        }];
        [willRemovedAttributes enumerateObjectsUsingBlock:^(id  _Nonnull attr, NSUInteger idx, BOOL * _Nonnull stop) {
            [string removeAttribute:attr range:fullRange];
        }];
    }
    
    if (textAttributes) {
        [string addAttributes:textAttributes range:fullRange];
    }
    [self.base innerSetAttributedText:[self adjustedAttributedString:string]];
}

- (NSDictionary<NSAttributedStringKey, id> *)textAttributes
{
    return (NSDictionary<NSAttributedStringKey, id> *)objc_getAssociatedObject(self.base, @selector(textAttributes));
}

- (NSAttributedString *)adjustedAttributedString:(NSAttributedString *)string
{
    if (!string.length) {
        return string;
    }
    NSMutableAttributedString *attributedString = nil;
    if ([string isKindOfClass:[NSMutableAttributedString class]]) {
        attributedString = (NSMutableAttributedString *)string;
    } else {
        attributedString = [string mutableCopy];
    }
    
    if (self.textAttributes[NSKernAttributeName]) {
        [attributedString removeAttribute:NSKernAttributeName range:NSMakeRange(string.length - 1, 1)];
    }
    
    __block BOOL shouldAdjustLineHeight = [self issetLineHeight];
    [attributedString enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
        if (NSEqualRanges(range, NSMakeRange(0, attributedString.length))) {
            if (style && (style.maximumLineHeight || style.minimumLineHeight)) {
                shouldAdjustLineHeight = NO;
                *stop = YES;
            }
        }
    }];
    if (shouldAdjustLineHeight) {
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.minimumLineHeight = self.lineHeight;
        paraStyle.maximumLineHeight = self.lineHeight;
        paraStyle.lineBreakMode = self.base.lineBreakMode;
        paraStyle.alignment = self.base.textAlignment;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, attributedString.length)];
        
        CGFloat baselineOffset = (self.lineHeight - self.base.font.lineHeight) / 4;
        [attributedString addAttribute:NSBaselineOffsetAttributeName value:@(baselineOffset) range:NSMakeRange(0, attributedString.length)];
    }
    return attributedString;
}

- (void)setLineHeight:(CGFloat)lineHeight
{
    if (lineHeight < 0) {
        objc_setAssociatedObject(self.base, @selector(lineHeight), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        objc_setAssociatedObject(self.base, @selector(lineHeight), @(lineHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!self.base.attributedText.string) return;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.base.attributedText.string attributes:self.textAttributes];
    attributedString = [[self adjustedAttributedString:attributedString] mutableCopy];
    [self.base setAttributedText:attributedString];
}

- (CGFloat)lineHeight
{
    if ([self issetLineHeight]) {
        return [(NSNumber *)objc_getAssociatedObject(self.base, @selector(lineHeight)) doubleValue];
    } else if (self.base.attributedText.length) {
        __block NSMutableAttributedString *string = [self.base.attributedText mutableCopy];
        __block CGFloat result = 0;
        [string enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, string.length) options:0 usingBlock:^(NSParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
            if (NSEqualRanges(range, NSMakeRange(0, string.length))) {
                if (style && (style.maximumLineHeight || style.minimumLineHeight)) {
                    result = style.maximumLineHeight;
                    *stop = YES;
                }
            }
        }];
        return result == 0 ? self.base.font.lineHeight : result;
    } else if (self.base.text.length) {
        return self.base.font.lineHeight;
    }
    return 0;
}

- (BOOL)issetLineHeight
{
    return !!objc_getAssociatedObject(self.base, @selector(lineHeight));
}

- (UIEdgeInsets)contentInset
{
    return [objc_getAssociatedObject(self.base, @selector(contentInset)) UIEdgeInsetsValue];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    objc_setAssociatedObject(self.base, @selector(contentInset), [NSValue valueWithUIEdgeInsets:contentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.base setNeedsDisplay];
}

- (UIControlContentVerticalAlignment)verticalAlignment
{
    return [objc_getAssociatedObject(self.base, @selector(verticalAlignment)) integerValue];
}

- (void)setVerticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
{
    objc_setAssociatedObject(self.base, @selector(verticalAlignment), @(verticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.base setNeedsDisplay];
}

- (void)setFont:(UIFont *)font textColor:(UIColor *)textColor
{
    [self setFont:font textColor:textColor text:nil];
}

- (void)setFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    if (font) self.base.font = font;
    if (textColor) self.base.textColor = textColor;
    if (text) self.base.text = text;
}

@end

@implementation FWLabelClassWrapper (FWUIKit)

- (__kindof UILabel *)labelWithFont:(UIFont *)font textColor:(UIColor *)textColor
{
    return [self labelWithFont:font textColor:textColor text:nil];
}

- (__kindof UILabel *)labelWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text
{
    UILabel *label = [[self.base alloc] init];
    [label.fw setFont:font textColor:textColor text:text];
    return label;
}

@end

@implementation UILabel (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // https://github.com/Tencent/QMUI_iOS
        [UILabel.fw exchangeInstanceMethod:@selector(setText:) swizzleMethod:@selector(innerSetText:)];
        [UILabel.fw exchangeInstanceMethod:@selector(setAttributedText:) swizzleMethod:@selector(innerSetAttributedText:)];
        [UILabel.fw exchangeInstanceMethod:@selector(setLineBreakMode:) swizzleMethod:@selector(innerSetLineBreakMode:)];
        [UILabel.fw exchangeInstanceMethod:@selector(setTextAlignment:) swizzleMethod:@selector(innerSetTextAlignment:)];
    });
}

- (void)innerSetText:(NSString *)text
{
    if (!text) {
        [self innerSetText:text];
        return;
    }
    if (!self.fw.textAttributes.count && ![self.fw issetLineHeight]) {
        [self innerSetText:text];
        return;
    }
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:self.fw.textAttributes];
    [self innerSetAttributedText:[self.fw adjustedAttributedString:attributedString]];
}

- (void)innerSetAttributedText:(NSAttributedString *)text
{
    if (!text || (!self.fw.textAttributes.count && ![self.fw issetLineHeight])) {
        [self innerSetAttributedText:text];
        return;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text.string attributes:self.fw.textAttributes];
    attributedString = [[self.fw adjustedAttributedString:attributedString] mutableCopy];
    [text enumerateAttributesInRange:NSMakeRange(0, text.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        [attributedString addAttributes:attrs range:range];
    }];
    [self innerSetAttributedText:attributedString];
}

- (void)innerSetLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    [self innerSetLineBreakMode:lineBreakMode];
    if (!self.fw.textAttributes) return;
    if (self.fw.textAttributes[NSParagraphStyleAttributeName]) {
        NSMutableParagraphStyle *p = ((NSParagraphStyle *)self.fw.textAttributes[NSParagraphStyleAttributeName]).mutableCopy;
        p.lineBreakMode = lineBreakMode;
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = self.fw.textAttributes.mutableCopy;
        attrs[NSParagraphStyleAttributeName] = p.copy;
        self.fw.textAttributes = attrs.copy;
    }
}

- (void)innerSetTextAlignment:(NSTextAlignment)textAlignment
{
    [self innerSetTextAlignment:textAlignment];
    if (!self.fw.textAttributes) return;
    if (self.fw.textAttributes[NSParagraphStyleAttributeName]) {
        NSMutableParagraphStyle *p = ((NSParagraphStyle *)self.fw.textAttributes[NSParagraphStyleAttributeName]).mutableCopy;
        p.alignment = textAlignment;
        NSMutableDictionary<NSAttributedStringKey, id> *attrs = self.fw.textAttributes.mutableCopy;
        attrs[NSParagraphStyleAttributeName] = p.copy;
        self.fw.textAttributes = attrs.copy;
    }
}

@end

#pragma mark - FWButtonWrapper+FWUIKit

@implementation FWButtonWrapper (FWUIKit)

- (CGFloat)disabledAlpha
{
    return [objc_getAssociatedObject(self.base, @selector(disabledAlpha)) doubleValue];
}

- (void)setDisabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self.base, @selector(disabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (alpha > 0) {
        self.base.alpha = self.base.isEnabled ? 1 : alpha;
    }
}

- (CGFloat)highlightedAlpha
{
    return [objc_getAssociatedObject(self.base, @selector(highlightedAlpha)) doubleValue];
}

- (void)setHighlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self.base, @selector(highlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.base.enabled && alpha > 0) {
        self.base.alpha = self.base.isHighlighted ? alpha : 1;
    }
}

- (void)setTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    if (title) [self.base setTitle:title forState:UIControlStateNormal];
    if (font) self.base.titleLabel.font = font;
    if (titleColor) [self.base setTitleColor:titleColor forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title
{
    [self.base setTitle:title forState:UIControlStateNormal];
}

- (void)setImage:(UIImage *)image
{
    [self.base setImage:image forState:UIControlStateNormal];
}

- (void)setImageEdge:(UIRectEdge)edge spacing:(CGFloat)spacing
{
    CGSize imageSize = self.base.imageView.image.size;
    CGSize labelSize = self.base.titleLabel.intrinsicContentSize;
    switch (edge) {
        case UIRectEdgeLeft:
            self.base.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, spacing);
            self.base.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
            break;
        case UIRectEdgeRight:
            self.base.imageEdgeInsets = UIEdgeInsetsMake(0, labelSize.width + spacing, 0, -labelSize.width);
            self.base.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width - spacing, 0, imageSize.width);
            break;
        case UIRectEdgeTop:
            self.base.imageEdgeInsets = UIEdgeInsetsMake(-labelSize.height - spacing, 0, 0, -labelSize.width);
            self.base.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -imageSize.height - spacing, 0);
            break;
        case UIRectEdgeBottom:
            self.base.imageEdgeInsets = UIEdgeInsetsMake(0, 0, -labelSize.height - spacing, -labelSize.width);
            self.base.titleEdgeInsets = UIEdgeInsetsMake(-imageSize.height - spacing, -imageSize.width, 0, 0);
            break;
        default:
            break;
    }
}

@end

@implementation FWButtonClassWrapper (FWUIKit)

- (__kindof UIButton *)buttonWithTitle:(NSString *)title font:(UIFont *)font titleColor:(UIColor *)titleColor
{
    UIButton *button = [self.base buttonWithType:UIButtonTypeCustom];
    [button.fw setTitle:title font:font titleColor:titleColor];
    return button;
}

- (__kindof UIButton *)buttonWithImage:(UIImage *)image
{
    UIButton *button = [self.base buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    return button;
}

@end

#pragma mark - FWScrollViewWrapper+FWUIKit

@implementation FWScrollViewWrapper (FWUIKit)

- (BOOL)canScroll
{
    return [self canScrollVertical] || [self canScrollHorizontal];
}

- (BOOL)canScrollHorizontal
{
    if (self.base.bounds.size.width <= 0) return NO;
    return self.base.contentSize.width + self.base.adjustedContentInset.left + self.base.adjustedContentInset.right > CGRectGetWidth(self.base.bounds);
}

- (BOOL)canScrollVertical
{
    if (self.base.bounds.size.height <= 0) return NO;
    return self.base.contentSize.height + self.base.adjustedContentInset.top + self.base.adjustedContentInset.bottom > CGRectGetHeight(self.base.bounds);
}

- (void)scrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint contentOffset = [self contentOffsetOfEdge:edge];
    [self.base setContentOffset:contentOffset animated:animated];
}

- (BOOL)isScrollToEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = [self contentOffsetOfEdge:edge];
    switch (edge) {
        case UIRectEdgeTop:
            return self.base.contentOffset.y <= contentOffset.y;
        case UIRectEdgeLeft:
            return self.base.contentOffset.x <= contentOffset.x;
        case UIRectEdgeBottom:
            return self.base.contentOffset.y >= contentOffset.y;
        case UIRectEdgeRight:
            return self.base.contentOffset.x >= contentOffset.x;
        default:
            return NO;
    }
}

- (CGPoint)contentOffsetOfEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = self.base.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            contentOffset.y = -self.base.adjustedContentInset.top;
            break;
        case UIRectEdgeLeft:
            contentOffset.x = -self.base.adjustedContentInset.left;
            break;
        case UIRectEdgeBottom:
            contentOffset.y = self.base.contentSize.height - self.base.bounds.size.height + self.base.adjustedContentInset.bottom;
            break;
        case UIRectEdgeRight:
            contentOffset.x = self.base.contentSize.width - self.base.bounds.size.width + self.base.adjustedContentInset.right;
            break;
        default:
            break;
    }
    return contentOffset;
}

- (NSInteger)totalPage
{
    if ([self canScrollVertical]) {
        return (NSInteger)ceil((self.base.contentSize.height / self.base.frame.size.height));
    } else {
        return (NSInteger)ceil((self.base.contentSize.width / self.base.frame.size.width));
    }
}

- (NSInteger)currentPage
{
    if ([self canScrollVertical]) {
        CGFloat pageHeight = self.base.frame.size.height;
        return (NSInteger)floor((self.base.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
    } else {
        CGFloat pageWidth = self.base.frame.size.width;
        return (NSInteger)floor((self.base.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    }
}

- (void)setCurrentPage:(NSInteger)page
{
    if ([self canScrollVertical]) {
        CGFloat offset = (self.base.frame.size.height * page);
        self.base.contentOffset = CGPointMake(0.f, offset);
    } else {
        CGFloat offset = (self.base.frame.size.width * page);
        self.base.contentOffset = CGPointMake(offset, 0.f);
    }
}

- (void)setCurrentPage:(NSInteger)page animated:(BOOL)animated
{
    if ([self canScrollVertical]) {
        CGFloat offset = (self.base.frame.size.height * page);
        [self.base setContentOffset:CGPointMake(0.f, offset) animated:animated];
    } else {
        CGFloat offset = (self.base.frame.size.width * page);
        [self.base setContentOffset:CGPointMake(offset, 0.f) animated:animated];
    }
}

- (BOOL)isLastPage
{
    return (self.currentPage == (self.totalPage - 1));
}

@end

#pragma mark - FWPageControlWrapper+FWUIKit

@implementation FWPageControlWrapper (FWUIKit)

- (CGSize)preferredSize
{
    CGSize size = self.base.bounds.size;
    if (size.height <= 0) {
        size = [self.base sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(10, 10);
    }
    return size;
}

- (void)setPreferredSize:(CGSize)size
{
    CGFloat height = [self preferredSize].height;
    CGFloat scale = size.height / height;
    self.base.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - FWSliderWrapper+FWUIKit

@implementation FWSliderWrapper (FWUIKit)

- (CGSize)thumbSize
{
    NSValue *value = objc_getAssociatedObject(self.base, @selector(thumbSize));
    return value ? [value CGSizeValue] : CGSizeZero;
}

- (void)setThumbSize:(CGSize)thumbSize
{
    objc_setAssociatedObject(self.base, @selector(thumbSize), [NSValue valueWithCGSize:thumbSize], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateThumbImage];
}

- (UIColor *)thumbColor
{
    return objc_getAssociatedObject(self.base, @selector(thumbColor));
}

- (void)setThumbColor:(UIColor *)thumbColor
{
    objc_setAssociatedObject(self.base, @selector(thumbColor), thumbColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updateThumbImage];
}

- (void)updateThumbImage
{
    CGSize thumbSize = self.thumbSize;
    if (thumbSize.width <= 0 || thumbSize.height <= 0) return;
    UIColor *thumbColor = self.thumbColor ?: (self.base.tintColor ?: [UIColor whiteColor]);
    UIImage *thumbImage = [UIImage.fw imageWithSize:thumbSize block:^(CGContextRef  _Nonnull context) {
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, thumbSize.width, thumbSize.height)];
        CGContextSetFillColorWithColor(context, thumbColor.CGColor);
        [path fill];
    }];
    
    [self.base setThumbImage:thumbImage forState:UIControlStateNormal];
    [self.base setThumbImage:thumbImage forState:UIControlStateHighlighted];
}

@end

#pragma mark - FWSwitchWrapper+FWUIKit

@implementation FWSwitchWrapper (FWUIKit)

- (CGSize)preferredSize
{
    CGSize size = self.base.bounds.size;
    if (size.height <= 0) {
        size = [self.base sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        if (size.height <= 0) size = CGSizeMake(51, 31);
    }
    return size;
}

- (void)setPreferredSize:(CGSize)size
{
    CGFloat height = [self preferredSize].height;
    CGFloat scale = size.height / height;
    self.base.transform = CGAffineTransformMakeScale(scale, scale);
}

@end

#pragma mark - FWTextFieldWrapper+FWUIKit

@interface FWInnerInputTarget : NSObject

@property (nonatomic, weak, readonly) UIView<UITextInput> *textInput;
@property (nonatomic, weak, readonly) UITextField *textField;
@property (nonatomic, assign) NSInteger maxLength;
@property (nonatomic, assign) NSInteger maxUnicodeLength;
@property (nonatomic, assign) NSTimeInterval autoCompleteInterval;
@property (nonatomic, assign) NSTimeInterval autoCompleteTimestamp;
@property (nonatomic, copy) void (^autoCompleteBlock)(NSString *text);

@end

@implementation FWInnerInputTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput
{
    self = [super init];
    if (self) {
        _textInput = textInput;
        _autoCompleteInterval = 1.0;
    }
    return self;
}

- (UITextField *)textField
{
    return (UITextField *)self.textInput;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)interval
{
    _autoCompleteInterval = interval > 0 ? interval : 1.0;
}

- (void)textLengthChanged
{
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (self.textField.text.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
                }
            }
        } else {
            if (self.textField.text.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([self.textField.text.fw unicodeLength] > self.maxUnicodeLength) {
                    self.textField.text = [self.textField.text.fw unicodeSubstring:self.maxUnicodeLength];
                }
            }
        } else {
            if ([self.textField.text.fw unicodeLength] > self.maxUnicodeLength) {
                self.textField.text = [self.textField.text.fw unicodeSubstring:self.maxUnicodeLength];
            }
        }
    }
}

- (void)textChangedAction
{
    [self textLengthChanged];
    
    if (self.autoCompleteBlock) {
        self.autoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = self.textField.text;
        if (inputText.fw.trimString.length < 1) {
            self.autoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.autoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.autoCompleteTimestamp) {
                    self.autoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end

@implementation FWTextFieldWrapper (FWUIKit)

- (NSInteger)maxLength
{
    return [self innerInputTarget:NO].maxLength;
}

- (void)setMaxLength:(NSInteger)maxLength
{
    [self innerInputTarget:YES].maxLength = maxLength;
}

- (NSInteger)maxUnicodeLength
{
    return [self innerInputTarget:NO].maxUnicodeLength;
}

- (void)setMaxUnicodeLength:(NSInteger)maxUnicodeLength
{
    [self innerInputTarget:YES].maxUnicodeLength = maxUnicodeLength;
}

- (void)textLengthChanged
{
    [[self innerInputTarget:NO] textLengthChanged];
}

- (NSTimeInterval)autoCompleteInterval
{
    return [self innerInputTarget:NO].autoCompleteInterval;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)autoCompleteInterval
{
    [self innerInputTarget:YES].autoCompleteInterval = autoCompleteInterval;
}

- (void (^)(NSString *))autoCompleteBlock
{
    return [self innerInputTarget:NO].autoCompleteBlock;
}

- (void)setAutoCompleteBlock:(void (^)(NSString *))autoCompleteBlock
{
    [self innerInputTarget:YES].autoCompleteBlock = autoCompleteBlock;
}

- (FWInnerInputTarget *)innerInputTarget:(BOOL)lazyload
{
    FWInnerInputTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerInputTarget alloc] initWithTextInput:self.base];
        [self.base addTarget:target action:@selector(textChangedAction) forControlEvents:UIControlEventEditingChanged];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end

#pragma mark - FWTextViewWrapper+FWUIKit

@implementation FWTextViewWrapper (FWUIKit)

- (NSInteger)maxLength
{
    return [self innerInputTarget:NO].maxLength;
}

- (void)setMaxLength:(NSInteger)maxLength
{
    [self innerInputTarget:YES].maxLength = maxLength;
}

- (NSInteger)maxUnicodeLength
{
    return [self innerInputTarget:NO].maxUnicodeLength;
}

- (void)setMaxUnicodeLength:(NSInteger)maxUnicodeLength
{
    [self innerInputTarget:YES].maxUnicodeLength = maxUnicodeLength;
}

- (void)textLengthChanged
{
    [[self innerInputTarget:NO] textLengthChanged];
}

- (NSTimeInterval)autoCompleteInterval
{
    return [self innerInputTarget:NO].autoCompleteInterval;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)autoCompleteInterval
{
    [self innerInputTarget:YES].autoCompleteInterval = autoCompleteInterval;
}

- (void (^)(NSString *))autoCompleteBlock
{
    return [self innerInputTarget:NO].autoCompleteBlock;
}

- (void)setAutoCompleteBlock:(void (^)(NSString *))autoCompleteBlock
{
    [self innerInputTarget:YES].autoCompleteBlock = autoCompleteBlock;
}

- (FWInnerInputTarget *)innerInputTarget:(BOOL)lazyload
{
    FWInnerInputTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerInputTarget alloc] initWithTextInput:self.base];
        [self.base.fw observeNotification:UITextViewTextDidChangeNotification object:self.base target:target action:@selector(textChangedAction)];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end

#pragma mark - FWViewControllerWrapper+FWUIKit

@implementation FWViewControllerWrapper (FWUIKit)

- (BOOL)isRoot
{
    return !self.base.navigationController || self.base.navigationController.viewControllers.firstObject == self.base;
}

- (BOOL)isChild
{
    UIViewController *parentController = self.base.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)isPresented
{
    UIViewController *viewController = self.base;
    if (self.base.navigationController) {
        if (self.base.navigationController.viewControllers.firstObject != self.base) return NO;
        viewController = self.base.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)isPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.base.navigationController ?: self.base;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (BOOL)isViewVisible
{
    return self.base.isViewLoaded && self.base.view.window;
}

- (BOOL)isLoaded
{
    return [objc_getAssociatedObject(self.base, @selector(isLoaded)) boolValue];
}

- (void)setIsLoaded:(BOOL)isLoaded
{
    objc_setAssociatedObject(self.base, @selector(isLoaded), @(isLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
