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

@interface FWLayoutChainObjc : NSObject <FWLayoutChain>

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWLayoutChainObjc

#pragma mark - Install

- (id<FWLayoutChain> (^)(void))remake
{
    return ^id(void) {
        [self.view fwRemoveAllConstraints];
        return self;
    };
}

#pragma mark - Compression

- (id<FWLayoutChain> (^)(UILayoutPriority))compressionHorizontal
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionHorizontalPriority:priority];
        return self;
    };
}

- (id<FWLayoutChain> (^)(UILayoutPriority))compressionVertical
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionVerticalPriority:priority];
        return self;
    };
}

#pragma mark - Axis

- (id<FWLayoutChain> (^)(void))center
{
    return ^id(void) {
        [self.view fwAlignCenterToSuperview];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))centerX
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))centerY
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))centerToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))centerXToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))centerYToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Edge

- (id<FWLayoutChain> (^)(void))edges
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperview];
        return self;
    };
}

- (id<FWLayoutChain> (^)(UIEdgeInsets))edgesWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fwPinEdgesToSuperviewWithInsets:insets];
        return self;
    };
}

- (id<FWLayoutChain> (^)(UIEdgeInsets, NSLayoutAttribute))edgesWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fwPinEdgesToSuperviewWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))edgesHorizontal
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewHorizontal];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))edgesVertical
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewVertical];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))top
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeTop];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))bottom
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeBottom];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))left
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))right
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeRight];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))topWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))bottomWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))leftWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))rightWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))topToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))bottomToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))leftToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))rightToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))topToBottomOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))bottomToTopOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))leftToRightOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))rightToLeftOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))topToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))bottomToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))leftToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))rightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))topToBottomOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))bottomToTopOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))leftToRightOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))rightToLeftOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

#pragma mark - SafeArea

- (id<FWLayoutChain> (^)(void))centerToSafeArea
{
    return ^id(void) {
        [self.view fwAlignCenterToSuperviewSafeArea];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))centerXToSafeArea
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))centerYToSafeArea
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))edgesToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeArea];
        return self;
    };
}

- (id<FWLayoutChain> (^)(UIEdgeInsets))edgesToSafeAreaWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fwPinEdgesToSuperviewSafeAreaWithInsets:insets];
        return self;
    };
}

- (id<FWLayoutChain> (^)(UIEdgeInsets, NSLayoutAttribute))edgesToSafeAreaWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fwPinEdgesToSuperviewSafeAreaWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))edgesToSafeAreaHorizontal
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeAreaHorizontal];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))edgesToSafeAreaVertical
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeAreaVertical];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))topToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))bottomToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))leftToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft];
        return self;
    };
}

- (id<FWLayoutChain> (^)(void))rightToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))topToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))bottomToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))leftToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))rightToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

#pragma mark - Dimension

- (id<FWLayoutChain> (^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fwSetDimensionsToSize:size];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (id<FWLayoutChain> (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))sizeToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))widthToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id))heightToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))widthToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))heightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))widthToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChain> (^)(id, CGFloat))heightToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Attribute

- (id<FWLayoutChain> (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView];
        return self;
    };
}

- (id<FWLayoutChain> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChain> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithOffsetAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset relation:relation];
        return self;
    };
}

- (id<FWLayoutChain> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChain> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
        return self;
    };
}

@end

#pragma mark - UIView+FWLayoutChain

@implementation UIView (FWLayoutChain)

- (id<FWLayoutChain>)fwLayoutChain
{
    FWLayoutChainObjc *layoutChain = objc_getAssociatedObject(self, _cmd);
    if (!layoutChain) {
        layoutChain = [[FWLayoutChainObjc alloc] init];
        layoutChain.view = self;
        objc_setAssociatedObject(self, _cmd, layoutChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutChain;
}

@end
