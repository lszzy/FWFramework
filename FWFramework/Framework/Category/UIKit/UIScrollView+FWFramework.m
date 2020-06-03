//
//  UIScrollView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIScrollView+FWFramework.h"
#import "UIGestureRecognizer+FWFramework.h"
#import "UIView+FWAutoLayout.h"
#import "NSObject+FWSwizzle.h"
#import "FWProxy.h"
#import <objc/runtime.h>

@implementation UIScrollView (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizerShouldBegin:) with:@selector(fwInnerGestureRecognizerShouldBegin:)];
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:) with:@selector(fwInnerGestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:) with:@selector(fwInnerGestureRecognizer:shouldRequireFailureOfGestureRecognizer:)];
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:) with:@selector(fwInnerGestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)];
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldReceiveTouch:) with:@selector(fwInnerGestureRecognizer:shouldReceiveTouch:)];
        if (@available(iOS 9.0, *)) {
            [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldReceivePress:) with:@selector(fwInnerGestureRecognizer:shouldReceivePress:)];
        }
    });
}

#pragma mark - Frame

- (UIEdgeInsets)fwContentInset
{
    if (@available(iOS 11, *)) {
        return self.adjustedContentInset;
    } else {
        return self.contentInset;
    }
}

- (CGFloat)fwContentWidth
{
    return self.contentSize.width;
}

- (void)setFwContentWidth:(CGFloat)fwContentWidth
{
    self.contentSize = CGSizeMake(fwContentWidth, self.contentSize.height);
}

- (CGFloat)fwContentHeight
{
    return self.contentSize.height;
}

- (void)setFwContentHeight:(CGFloat)fwContentHeight
{
    self.contentSize = CGSizeMake(self.contentSize.width, fwContentHeight);
}

- (CGFloat)fwContentOffsetX
{
    return self.contentOffset.x;
}

- (void)setFwContentOffsetX:(CGFloat)fwContentOffsetX
{
    self.contentOffset = CGPointMake(fwContentOffsetX, self.contentOffset.y);
}

- (CGFloat)fwContentOffsetY
{
    return self.contentOffset.y;
}

- (void)setFwContentOffsetY:(CGFloat)fwContentOffsetY
{
    self.contentOffset = CGPointMake(self.contentOffset.x, fwContentOffsetY);
}

#pragma mark - Page

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

- (void)fwSetCurrentPage:(NSInteger)page
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

#pragma mark - Scroll

- (BOOL)fwCanScrollHorizontal
{
    if (self.bounds.size.width <= 0) {
        return NO;
    }
    
    return self.contentSize.width + self.contentInset.left + self.contentInset.right > CGRectGetWidth(self.bounds);
}

- (BOOL)fwCanScrollVertical
{
    if (self.bounds.size.height <= 0) {
        return NO;
    }
    
    return self.contentSize.height + self.contentInset.top + self.contentInset.bottom > CGRectGetHeight(self.bounds);
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

- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint contentOffset = [self fwContentOffsetOfEdge:edge];
    [self setContentOffset:contentOffset animated:animated];
}

- (CGPoint)fwContentOffsetOfEdge:(UIRectEdge)edge
{
    CGPoint contentOffset = self.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            contentOffset.y = -self.contentInset.top;
            break;
        case UIRectEdgeLeft:
            contentOffset.x = -self.contentInset.left;
            break;
        case UIRectEdgeBottom:
            contentOffset.y = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
            break;
        case UIRectEdgeRight:
            contentOffset.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
            break;
        default:
            break;
    }
    return contentOffset;
}

- (UISwipeGestureRecognizerDirection)fwScrollDirection
{
    return [self.panGestureRecognizer fwSwipeDirection];
}

- (CGFloat)fwScrollPercent
{
    return [self.panGestureRecognizer fwSwipePercent];
}

- (CGFloat)fwScrollPercentOfDirection:(UISwipeGestureRecognizerDirection)direction
{
    return [self.panGestureRecognizer fwSwipePercentOfDirection:direction];
}

#pragma mark - Content

- (void)fwContentInsetAdjustmentNever
{
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

#pragma mark - Keyboard

- (BOOL)fwKeyboardDismissOnDrag
{
    return self.keyboardDismissMode == UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)setFwKeyboardDismissOnDrag:(BOOL)fwKeyboardDismissOnDrag
{
    self.keyboardDismissMode = fwKeyboardDismissOnDrag ? UIScrollViewKeyboardDismissModeOnDrag : UIScrollViewKeyboardDismissModeNone;
}

#pragma mark - Gesture

- (id<UIGestureRecognizerDelegate>)fwPanGestureRecognizerDelegate
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwPanGestureRecognizerDelegate));
    return value.object;
}

- (void)setFwPanGestureRecognizerDelegate:(id<UIGestureRecognizerDelegate>)fwPanGestureRecognizerDelegate
{
    objc_setAssociatedObject(self, @selector(fwPanGestureRecognizerDelegate), [[FWWeakObject alloc] initWithObject:fwPanGestureRecognizerDelegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL (^)(UIGestureRecognizer *))fwShouldBegin
{
    return objc_getAssociatedObject(self, @selector(fwShouldBegin));
}

- (void)setFwShouldBegin:(BOOL (^)(UIGestureRecognizer *))fwShouldBegin
{
    objc_setAssociatedObject(self, @selector(fwShouldBegin), fwShouldBegin, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRecognizeSimultaneously
{
    return objc_getAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously));
}

- (void)setFwShouldRecognizeSimultaneously:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRecognizeSimultaneously
{
    objc_setAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously), fwShouldRecognizeSimultaneously, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRequireFailure
{
    return objc_getAssociatedObject(self, @selector(fwShouldRequireFailure));
}

- (void)setFwShouldRequireFailure:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRequireFailure
{
    objc_setAssociatedObject(self, @selector(fwShouldRequireFailure), fwShouldRequireFailure, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldBeRequiredToFail
{
    return objc_getAssociatedObject(self, @selector(fwShouldBeRequiredToFail));
}

- (void)setFwShouldBeRequiredToFail:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldBeRequiredToFail
{
    objc_setAssociatedObject(self, @selector(fwShouldBeRequiredToFail), fwShouldBeRequiredToFail, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)fwInnerGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizerShouldBegin:gestureRecognizer];
    }
    
    BOOL (^shouldBlock)(UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fwShouldBegin));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer);
    }
    
    return [self fwInnerGestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizer:shouldRequireFailureOfGestureRecognizer:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fwShouldRequireFailure));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizer:shouldBeRequiredToFailByGestureRecognizer:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
    }
    
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fwShouldBeRequiredToFail));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press API_AVAILABLE(ios(9.0))
{
    if (self.fwPanGestureRecognizerDelegate && [self.fwPanGestureRecognizerDelegate respondsToSelector:@selector(gestureRecognizer:shouldReceivePress:)]) {
        return [self.fwPanGestureRecognizerDelegate gestureRecognizer:gestureRecognizer shouldReceivePress:press];
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldReceivePress:press];
}

#pragma mark - Hover

- (CGFloat)fwHoverView:(UIView *)view
         fromSuperview:(UIView *)fromSuperview
           toSuperview:(UIView *)toSuperview
            toPosition:(CGFloat)toPosition
{
    CGFloat distance = [fromSuperview.superview convertPoint:fromSuperview.frame.origin toView:toSuperview].y - toPosition;
    if (distance <= 0) {
        if (view.superview != toSuperview) {
            [view removeFromSuperview];
            [toSuperview addSubview:view]; {
                [view fwPinEdgeToSuperview:NSLayoutAttributeLeft];
                [view fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:toPosition];
                [view fwSetDimensionsToSize:view.bounds.size];
            }
        }
    } else {
        if (view.superview != fromSuperview) {
            [view removeFromSuperview];
            [fromSuperview addSubview:view]; {
                [view fwPinEdgesToSuperview];
            }
        }
    }
    return distance;
}

@end
