/*!
 @header     UIView+FWFramework.m
 @indexgroup FWFramework
 @brief      UIView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIView+FWFramework.h"
#import "FWSwizzle.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

@implementation UIView (FWFramework)

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
        
        FWSwizzleClass(UIView, @selector(intrinsicContentSize), FWSwizzleReturn(CGSize), FWSwizzleArgs(), FWSwizzleCode({
            NSValue *value = objc_getAssociatedObject(selfObject, @selector(fwIntrinsicContentSize));
            if (value) {
                return [value CGSizeValue];
            } else {
                return FWSwizzleOriginal();
            }
        }));
    });
}

#pragma mark - Touch

- (UIEdgeInsets)fwTouchInsets
{
    return [objc_getAssociatedObject(self, @selector(fwTouchInsets)) UIEdgeInsetsValue];
}

- (void)setFwTouchInsets:(UIEdgeInsets)fwTouchInsets
{
    objc_setAssociatedObject(self, @selector(fwTouchInsets), [NSValue valueWithUIEdgeInsets:fwTouchInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Transform

- (CGFloat)fwScaleX
{
    return self.transform.a;
}

- (CGFloat)fwScaleY
{
    return self.transform.d;
}

- (CGFloat)fwTranslationX
{
    return self.transform.tx;
}

- (CGFloat)fwTranslationY
{
    return self.transform.ty;
}

#pragma mark - Size

- (CGSize)fwIntrinsicContentSize
{
    return self.intrinsicContentSize;
}

- (void)setFwIntrinsicContentSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        objc_setAssociatedObject(self, @selector(fwIntrinsicContentSize), nil, OBJC_ASSOCIATION_ASSIGN);
    } else {
        objc_setAssociatedObject(self, @selector(fwIntrinsicContentSize), [NSValue valueWithCGSize:size], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (CGRect)fwFitFrame
{
    return self.frame;
}

- (void)setFwFitFrame:(CGRect)fitFrame
{
    fitFrame.size = [self fwFitSizeWithDrawSize:CGSizeMake(fitFrame.size.width, CGFLOAT_MAX)];
    self.frame = fitFrame;
}

- (CGSize)fwFitSize
{
    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    CGSize drawSize = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    return [self fwFitSizeWithDrawSize:drawSize];
}

- (CGSize)fwFitSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self sizeThatFits:drawSize];
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

#pragma mark - Subview

- (void)fwRemoveAllSubviews
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (UIView *)fwSubviewOfClass:(Class)clazz
{
    return [self fwSubviewOfBlock:^BOOL(UIView *view) {
        return [view isKindOfClass:clazz];
    }];
}

- (UIView *)fwSubviewOfBlock:(BOOL (^)(UIView *view))block
{
    if (block(self)) {
        return self;
    }
    
    /* 如果需要顺序查找所有子视图，失败后再递归查找，参考此代码即可
    for (UIView *subview in self.subviews) {
        if (block(subview)) {
            return subview;
        }
    } */
    
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview fwSubviewOfBlock:block];
        if (resultView) {
            return resultView;
        }
    }
    
    return nil;
}

- (void)fwMoveToSuperview:(UIView *)view
{
    if (view) {
        [view addSubview:self];
    } else {
        [self removeFromSuperview];
    }
}

#pragma mark - Snapshot

- (UIImage *)fwSnapshotImage
{
    return [UIImage fwImageWithView:self];
}

- (NSData *)fwSnapshotPdf
{
    CGRect bounds = self.bounds;
    NSMutableData *data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
    CGContextRef context = CGPDFContextCreate(consumer, &bounds, NULL);
    CGDataConsumerRelease(consumer);
    if (!context) return nil;
    CGPDFContextBeginPage(context, NULL);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self.layer renderInContext:context];
    CGPDFContextEndPage(context);
    CGPDFContextClose(context);
    CGContextRelease(context);
    return data;
}

@end
