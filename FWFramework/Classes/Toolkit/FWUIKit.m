/*!
 @header     FWUIKit.m
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWUIKit.h"
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

- (CGRect)fwFrameApplyTransform
{
    return self.frame;
}

- (void)setFwFrameApplyTransform:(CGRect)fwFrameApplyTransform
{
    self.frame = [UIView fwRectApplyTransform:fwFrameApplyTransform transform:self.transform anchorPoint:self.layer.anchorPoint];
}

/// 计算目标点 targetPoint 围绕坐标点 coordinatePoint 通过 transform 之后此点的坐标。@see https://github.com/Tencent/QMUI_iOS
+ (CGPoint)fwPointApplyTransform:(CGPoint)coordinatePoint targetPoint:(CGPoint)targetPoint transform:(CGAffineTransform)transform
{
    CGPoint p;
    p.x = (targetPoint.x - coordinatePoint.x) * transform.a + (targetPoint.y - coordinatePoint.y) * transform.c + coordinatePoint.x;
    p.y = (targetPoint.x - coordinatePoint.x) * transform.b + (targetPoint.y - coordinatePoint.y) * transform.d + coordinatePoint.y;
    p.x += transform.tx;
    p.y += transform.ty;
    return p;
}

/// 系统的 CGRectApplyAffineTransform 只会按照 anchorPoint 为 (0, 0) 的方式去计算，但通常情况下我们面对的是 UIView/CALayer，它们默认的 anchorPoint 为 (.5, .5)，所以增加这个函数，在计算 transform 时可以考虑上 anchorPoint 的影响。@see https://github.com/Tencent/QMUI_iOS
+ (CGRect)fwRectApplyTransform:(CGRect)rect transform:(CGAffineTransform)transform anchorPoint:(CGPoint)anchorPoint
{
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    CGPoint oPoint = CGPointMake(rect.origin.x + width * anchorPoint.x, rect.origin.y + height * anchorPoint.y);
    CGPoint top_left = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x, rect.origin.y) transform:transform];
    CGPoint bottom_left = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x, rect.origin.y + height) transform:transform];
    CGPoint top_right = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x + width, rect.origin.y) transform:transform];
    CGPoint bottom_right = [self fwPointApplyTransform:oPoint targetPoint:CGPointMake(rect.origin.x + width, rect.origin.y + height) transform:transform];
    CGFloat minX = MIN(MIN(MIN(top_left.x, bottom_left.x), top_right.x), bottom_right.x);
    CGFloat maxX = MAX(MAX(MAX(top_left.x, bottom_left.x), top_right.x), bottom_right.x);
    CGFloat minY = MIN(MIN(MIN(top_left.y, bottom_left.y), top_right.y), bottom_right.y);
    CGFloat maxY = MAX(MAX(MAX(top_left.y, bottom_left.y), top_right.y), bottom_right.y);
    CGFloat newWidth = maxX - minX;
    CGFloat newHeight = maxY - minY;
    CGRect result = CGRectMake(minX, minY, newWidth, newHeight);
    return result;
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

- (UILabel *)fwPlaceholderLabel
{
    UILabel *label = objc_getAssociatedObject(self, @selector(fwPlaceholderLabel));
    if (!label) {
        static UIColor *defaultPlaceholderColor = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UITextField *textField = [[UITextField alloc] init];
            textField.placeholder = @" ";
            UILabel *placeholderLabel = [textField fwPerformGetter:@"_placeholderLabel"];
            defaultPlaceholderColor = placeholderLabel.textColor;
        });
        
        NSAttributedString *originalText = self.attributedText;
        self.text = @" ";
        self.attributedText = originalText;
        
        label = [[UILabel alloc] init];
        label.textColor = defaultPlaceholderColor;
        label.numberOfLines = 0;
        label.userInteractionEnabled = NO;
        label.font = self.font;
        objc_setAssociatedObject(self, @selector(fwPlaceholderLabel), label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self fwSetNeedsUpdatePlaceholder];
        [self insertSubview:label atIndex:0];
        
        [self fwObserveNotification:UITextViewTextDidChangeNotification object:self target:self action:@selector(fwSetNeedsUpdateText)];

        [self fwObserveProperty:@"attributedText" target:self action:@selector(fwSetNeedsUpdateText)];
        [self fwObserveProperty:@"text" target:self action:@selector(fwSetNeedsUpdateText)];
        [self fwObserveProperty:@"bounds" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"frame" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"textAlignment" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        [self fwObserveProperty:@"textContainerInset" target:self action:@selector(fwSetNeedsUpdatePlaceholder)];
        
        [self fwObserveProperty:@"font" block:^(UITextView *textView, NSDictionary *change) {
            if (change[NSKeyValueChangeNewKey] != nil) textView.fwPlaceholderLabel.font = textView.font;
            [textView fwSetNeedsUpdatePlaceholder];
        }];
    }
    return label;
}

- (void)fwSetNeedsUpdatePlaceholder
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwUpdatePlaceholder) object:nil];
    [self performSelector:@selector(fwUpdatePlaceholder) withObject:nil afterDelay:0];
}

- (void)fwSetNeedsUpdateText
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fwUpdateText) object:nil];
    [self performSelector:@selector(fwUpdateText) withObject:nil afterDelay:0];
}

- (void)fwUpdatePlaceholder
{
    // 调整contentInset实现垂直分布，不使用contentOffset是因为光标移动会不正常
    UIEdgeInsets contentInset = self.contentInset;
    contentInset.top = 0;
    if (self.contentSize.height < self.bounds.size.height) {
        CGFloat height = ceil([self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)].height);
        switch (self.fwVerticalAlignment) {
            case UIControlContentVerticalAlignmentCenter:
                contentInset.top = (self.bounds.size.height - height) / 2.0;
                break;
            case UIControlContentVerticalAlignmentBottom:
                contentInset.top = self.bounds.size.height - height;
                break;
            default:
                break;
        }
    }
    self.contentInset = contentInset;
    
    if (self.text.length) {
        self.fwPlaceholderLabel.hidden = YES;
    } else {
        CGRect targetFrame;
        UIEdgeInsets inset = [self fwPlaceholderInset];
        if (!UIEdgeInsetsEqualToEdgeInsets(inset, UIEdgeInsetsZero)) {
            targetFrame = CGRectMake(inset.left, inset.top, CGRectGetWidth(self.bounds) - inset.left - inset.right, CGRectGetHeight(self.bounds) - inset.top - inset.bottom);
        } else {
            CGFloat x = self.textContainer.lineFragmentPadding + self.textContainerInset.left;
            CGFloat width = CGRectGetWidth(self.bounds) - x - self.textContainer.lineFragmentPadding - self.textContainerInset.right;
            CGFloat height = ceil([self.fwPlaceholderLabel sizeThatFits:CGSizeMake(width, 0)].height);
            height = MIN(height, self.bounds.size.height - self.textContainerInset.top - self.textContainerInset.bottom);
            
            CGFloat y = self.textContainerInset.top;
            switch (self.fwVerticalAlignment) {
                case UIControlContentVerticalAlignmentCenter:
                    y = (self.bounds.size.height - height) / 2.0 - self.contentInset.top;
                    break;
                case UIControlContentVerticalAlignmentBottom:
                    y = self.bounds.size.height - height - self.textContainerInset.bottom - self.contentInset.top;
                    break;
                default:
                    break;
            }
            targetFrame = CGRectMake(x, y, width, height);
        }
        
        self.fwPlaceholderLabel.hidden = NO;
        self.fwPlaceholderLabel.textAlignment = self.textAlignment;
        self.fwPlaceholderLabel.frame = targetFrame;
    }
}

- (void)fwUpdateText
{
    [self fwUpdatePlaceholder];
    if (!self.fwAutoHeightEnabled) return;
    
    CGFloat height = ceil([self sizeThatFits:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)].height);
    height = MAX(self.fwMinHeight, MIN(height, self.fwMaxHeight));
    if (height == self.fwLastHeight) return;
    
    CGRect targetFrame = self.frame;
    targetFrame.size.height = height;
    self.frame = targetFrame;
    if (self.fwHeightDidChange) self.fwHeightDidChange(height);
    self.fwLastHeight = height;
}

- (NSString *)fwPlaceholder
{
    return self.fwPlaceholderLabel.text;
}

- (void)setFwPlaceholder:(NSString *)fwPlaceholder
{
    self.fwPlaceholderLabel.text = fwPlaceholder;
    [self fwSetNeedsUpdatePlaceholder];
}

- (NSAttributedString *)fwAttributedPlaceholder
{
    return self.fwPlaceholderLabel.attributedText;
}

- (void)setFwAttributedPlaceholder:(NSAttributedString *)fwAttributedPlaceholder
{
    self.fwPlaceholderLabel.attributedText = fwAttributedPlaceholder;
    [self fwSetNeedsUpdatePlaceholder];
}

- (UIColor *)fwPlaceholderColor
{
    return self.fwPlaceholderLabel.textColor;
}

- (void)setFwPlaceholderColor:(UIColor *)fwPlaceholderColor
{
    self.fwPlaceholderLabel.textColor = fwPlaceholderColor;
}

- (UIEdgeInsets)fwPlaceholderInset
{
    NSValue *value = objc_getAssociatedObject(self, @selector(fwPlaceholderInset));
    return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setFwPlaceholderInset:(UIEdgeInsets)inset
{
    objc_setAssociatedObject(self, @selector(fwPlaceholderInset), [NSValue valueWithUIEdgeInsets:inset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdatePlaceholder];
}

- (UIControlContentVerticalAlignment)fwVerticalAlignment
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwVerticalAlignment));
    return value ? value.integerValue : UIControlContentVerticalAlignmentTop;
}

- (void)setFwVerticalAlignment:(UIControlContentVerticalAlignment)fwVerticalAlignment
{
    objc_setAssociatedObject(self, @selector(fwVerticalAlignment), @(fwVerticalAlignment), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdatePlaceholder];
}

- (BOOL)fwAutoHeightEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwAutoHeightEnabled)) boolValue];
}

- (void)setFwAutoHeightEnabled:(BOOL)enabled
{
    objc_setAssociatedObject(self, @selector(fwAutoHeightEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
}

- (CGFloat)fwMaxHeight
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwMaxHeight));
    return value ? value.doubleValue : CGFLOAT_MAX;
}

- (void)setFwMaxHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMaxHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
}

- (CGFloat)fwMinHeight
{
    return [objc_getAssociatedObject(self, @selector(fwMinHeight)) doubleValue];
}

- (void)setFwMinHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwMinHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self fwSetNeedsUpdateText];
}

- (void (^)(CGFloat))fwHeightDidChange
{
    return objc_getAssociatedObject(self, @selector(fwHeightDidChange));
}

- (void)setFwHeightDidChange:(void (^)(CGFloat))block
{
    objc_setAssociatedObject(self, @selector(fwHeightDidChange), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)fwLastHeight
{
    return [objc_getAssociatedObject(self, @selector(fwLastHeight)) doubleValue];
}

- (void)setFwLastHeight:(CGFloat)height
{
    objc_setAssociatedObject(self, @selector(fwLastHeight), @(height), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwAutoHeightWithMaxHeight:(CGFloat)maxHeight didChange:(void (^)(CGFloat))didChange
{
    self.fwMaxHeight = maxHeight;
    if (didChange) self.fwHeightDidChange = didChange;
    self.fwAutoHeightEnabled = YES;
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
