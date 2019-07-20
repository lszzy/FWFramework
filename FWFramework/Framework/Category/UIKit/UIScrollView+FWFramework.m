//
//  UIScrollView+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIScrollView+FWFramework.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>
#import "NSObject+FWRuntime.h"

@implementation UIScrollView (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:) with:@selector(fwInnerGestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
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
    switch (edge) {
        case UIRectEdgeTop:
            return self.contentOffset.y <= 0 - self.contentInset.top;
        case UIRectEdgeLeft:
            return self.contentOffset.x <= 0 - self.contentInset.left;
        case UIRectEdgeBottom:
            return self.contentOffset.y >= self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
        case UIRectEdgeRight:
            return self.contentOffset.x >= self.contentSize.width - self.bounds.size.width + self.contentInset.right;
        default:
            return NO;
    }
}

- (void)fwScrollToEdge:(UIRectEdge)edge animated:(BOOL)animated
{
    CGPoint offset = self.contentOffset;
    switch (edge) {
        case UIRectEdgeTop:
            offset.y = 0 - self.contentInset.top;
            break;
        case UIRectEdgeLeft:
            offset.x = 0 - self.contentInset.left;
            break;
        case UIRectEdgeBottom:
            offset.y = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
            break;
        case UIRectEdgeRight:
            offset.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
            break;
        default:
            break;
    }
    [self setContentOffset:offset animated:animated];
}

- (UISwipeGestureRecognizerDirection)fwScrollDirection
{
    if ([self.panGestureRecognizer translationInView:self.superview].y > 0.0f) {
        return UISwipeGestureRecognizerDirectionUp;
    } else if ([self.panGestureRecognizer translationInView:self.superview].y < 0.0f) {
        return UISwipeGestureRecognizerDirectionDown;
    } else if ([self.panGestureRecognizer translationInView:self].x < 0.0f) {
        return UISwipeGestureRecognizerDirectionLeft;
    } else if ([self.panGestureRecognizer translationInView:self].x > 0.0f) {
        return UISwipeGestureRecognizerDirectionRight;
    }
    return 0;
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

- (BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRecognizeSimultaneously
{
    return objc_getAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously));
}

- (void)setFwShouldRecognizeSimultaneously:(BOOL (^)(UIGestureRecognizer *, UIGestureRecognizer *))fwShouldRecognizeSimultaneously
{
    objc_setAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously), fwShouldRecognizeSimultaneously, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)fwInnerGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL (^shouldBlock)(UIGestureRecognizer *, UIGestureRecognizer *) = objc_getAssociatedObject(self, @selector(fwShouldRecognizeSimultaneously));
    if (shouldBlock) {
        return shouldBlock(gestureRecognizer, otherGestureRecognizer);
    }
    
    return [self fwInnerGestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
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
