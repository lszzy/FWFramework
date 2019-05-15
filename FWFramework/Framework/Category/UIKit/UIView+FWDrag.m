//
//  UIView+FWDrag.m
//  FWFramework
//
//  Created by wuyong on 2017/6/1.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIView+FWDrag.h"
#import <objc/runtime.h>

@implementation UIView (FWDrag)

- (BOOL)fwDragEnabled
{
    return self.fwDragGesture.enabled;
}

- (void)setFwDragEnabled:(BOOL)fwDragEnabled
{
    self.fwDragGesture.enabled = fwDragEnabled;
}

- (CGRect)fwDragLimit
{
    return [objc_getAssociatedObject(self, @selector(fwDragLimit)) CGRectValue];
}

- (void)setFwDragLimit:(CGRect)fwDragLimit
{
    if (CGRectEqualToRect(fwDragLimit, CGRectZero) ||
        CGRectContainsRect(fwDragLimit, self.frame)) {
        objc_setAssociatedObject(self, @selector(fwDragLimit), [NSValue valueWithCGRect:fwDragLimit], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (CGRect)fwDragArea
{
    return [objc_getAssociatedObject(self, @selector(fwDragArea)) CGRectValue];
}

- (void)setFwDragArea:(CGRect)fwDragArea
{
    CGRect relativeFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    if (CGRectContainsRect(relativeFrame, fwDragArea)) {
        objc_setAssociatedObject(self, @selector(fwDragArea), [NSValue valueWithCGRect:fwDragArea], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)fwDragVertical
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwDragVertical));
    return value ? [value boolValue] : YES;
}

- (void)setFwDragVertical:(BOOL)fwDragVertical
{
    objc_setAssociatedObject(self, @selector(fwDragVertical), [NSNumber numberWithBool:fwDragVertical], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwDragHorizontal
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwDragHorizontal));
    return value ? [value boolValue] : YES;
}

- (void)setFwDragHorizontal:(BOOL)fwDragHorizontal
{
    objc_setAssociatedObject(self, @selector(fwDragHorizontal), [NSNumber numberWithBool:fwDragHorizontal], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(UIView *))fwDragStartedBlock
{
    return objc_getAssociatedObject(self, @selector(fwDragStartedBlock));
}

- (void)setFwDragStartedBlock:(void (^)(UIView *))fwDragStartedBlock
{
    objc_setAssociatedObject(self, @selector(fwDragStartedBlock), fwDragStartedBlock, OBJC_ASSOCIATION_COPY);
}

- (void (^)(UIView *))fwDragMovedBlock
{
    return objc_getAssociatedObject(self, @selector(fwDragMovedBlock));
}

- (void)setFwDragMovedBlock:(void (^)(UIView *))fwDragMovedBlock
{
    objc_setAssociatedObject(self, @selector(fwDragMovedBlock), fwDragMovedBlock, OBJC_ASSOCIATION_COPY);
}

- (void (^)(UIView *))fwDragEndedBlock
{
    return objc_getAssociatedObject(self, @selector(fwDragEndedBlock));
}

- (void)setFwDragEndedBlock:(void (^)(UIView *))fwDragEndedBlock
{
    objc_setAssociatedObject(self, @selector(fwDragEndedBlock), fwDragEndedBlock, OBJC_ASSOCIATION_COPY);
}

- (UIPanGestureRecognizer *)fwDragGesture
{
    UIPanGestureRecognizer *gesture = objc_getAssociatedObject(self, _cmd);
    if (!gesture) {
        // 初始化拖动手势，默认禁用
        gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fwInnerDragHandler:)];
        gesture.maximumNumberOfTouches = 1;
        gesture.minimumNumberOfTouches = 1;
        gesture.cancelsTouchesInView = NO;
        gesture.enabled = NO;
        self.fwDragArea = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self addGestureRecognizer:gesture];
        
        objc_setAssociatedObject(self, _cmd, gesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return gesture;
}

- (void)fwInnerDragHandler:(UIPanGestureRecognizer *)sender
{
    // 检查是否能够在拖动区域拖动
    CGPoint locationInView = [sender locationInView:self];
    if (!CGRectContainsPoint(self.fwDragArea, locationInView) &&
        sender.state == UIGestureRecognizerStateBegan) {
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [sender locationInView:self];
        CGPoint locationInSuperview = [sender locationInView:self.superview];
        
        self.layer.anchorPoint = CGPointMake(locationInView.x / self.bounds.size.width, locationInView.y / self.bounds.size.height);
        self.center = locationInSuperview;
    }
    
    if (sender.state == UIGestureRecognizerStateBegan && self.fwDragStartedBlock) {
        self.fwDragStartedBlock(self);
    }
    
    if (sender.state == UIGestureRecognizerStateChanged && self.fwDragMovedBlock) {
        self.fwDragMovedBlock(self);
    }
    
    if (sender.state == UIGestureRecognizerStateEnded && self.fwDragEndedBlock) {
        self.fwDragEndedBlock(self);
    }
    
    CGPoint translation = [sender translationInView:[self superview]];
    
    CGFloat newXOrigin = CGRectGetMinX(self.frame) + (([self fwDragHorizontal]) ? translation.x : 0);
    CGFloat newYOrigin = CGRectGetMinY(self.frame) + (([self fwDragVertical]) ? translation.y : 0);
    
    CGRect cagingArea = self.fwDragLimit;
    
    CGFloat cagingAreaOriginX = CGRectGetMinX(cagingArea);
    CGFloat cagingAreaOriginY = CGRectGetMinY(cagingArea);
    
    CGFloat cagingAreaRightSide = cagingAreaOriginX + CGRectGetWidth(cagingArea);
    CGFloat cagingAreaBottomSide = cagingAreaOriginY + CGRectGetHeight(cagingArea);
    
    if (!CGRectEqualToRect(cagingArea, CGRectZero)) {
        // 确保视图在限制区域内
        if (newXOrigin <= cagingAreaOriginX ||
            newXOrigin + CGRectGetWidth(self.frame) >= cagingAreaRightSide) {
            newXOrigin = CGRectGetMinX(self.frame);
        }
        
        if (newYOrigin <= cagingAreaOriginY ||
            newYOrigin + CGRectGetHeight(self.frame) >= cagingAreaBottomSide) {
            newYOrigin = CGRectGetMinY(self.frame);
        }
    }
    
    [self setFrame:CGRectMake(newXOrigin,
                              newYOrigin,
                              CGRectGetWidth(self.frame),
                              CGRectGetHeight(self.frame))];
    
    [sender setTranslation:(CGPoint){0, 0} inView:[self superview]];
}

@end
