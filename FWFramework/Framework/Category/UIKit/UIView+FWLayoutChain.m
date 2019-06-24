/*!
 @header     UIView+FWLayoutChain.m
 @indexgroup FWFramework
 @brief      UIView+FWLayoutChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import "UIView+FWLayoutChain.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - FWLayoutChain

@interface FWLayoutChain ()

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWLayoutChain

#pragma mark - Compression

- (FWLayoutChain *(^)(UILayoutPriority))compressionHorizontal
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionHorizontalPriority:priority];
        return self;
    };
}

- (FWLayoutChain *(^)(UILayoutPriority))compressionVertical
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionVerticalPriority:priority];
        return self;
    };
}

#pragma mark - Axis

- (FWLayoutChain *(^)(void))center
{
    return ^id(void) {
        [self.view fwAlignCenterToSuperview];
        return self;
    };
}

- (FWLayoutChain *(^)(void))centerX
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        return self;
    };
}

- (FWLayoutChain *(^)(void))centerY
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        return self;
    };
}

- (FWLayoutChain *(^)(id))centerToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (FWLayoutChain *(^)(id))centerXToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        return self;
    };
}

- (FWLayoutChain *(^)(id))centerYToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (FWLayoutChain *(^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain *(^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain *(^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain *(^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Dimension

- (FWLayoutChain *(^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fwSetDimensionsToSize:size];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat, NSLayoutRelation))widthWithRelation
{
    return ^id(CGFloat width, NSLayoutRelation relation) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width relation:relation];
        return self;
    };
}

- (FWLayoutChain *(^)(CGFloat, NSLayoutRelation))heightWithRelation
{
    return ^id(CGFloat height, NSLayoutRelation relation) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height relation:relation];
        return self;
    };
}

@end

#pragma mark - UIView+FWLayoutChain

@implementation UIView (FWLayoutChain)

- (FWLayoutChain *)fwLayoutChain
{
    FWLayoutChain *layoutChain = objc_getAssociatedObject(self, _cmd);
    if (!layoutChain) {
        layoutChain = [[FWLayoutChain alloc] init];
        layoutChain.view = self;
        objc_setAssociatedObject(self, _cmd, layoutChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutChain;
}

@end
