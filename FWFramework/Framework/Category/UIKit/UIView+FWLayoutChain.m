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

#pragma mark - FWLayoutChainObjc

@interface FWLayoutChainObjc : NSObject <FWLayoutChainProtocol>

@property (nonatomic, weak) __kindof UIView *view;

@end

@implementation FWLayoutChainObjc

#pragma mark - Install

- (id<FWLayoutChainProtocol> (^)(void))remake
{
    return ^id(void) {
        [self.view fwRemoveAllConstraints];
        return self;
    };
}

#pragma mark - Compression

- (id<FWLayoutChainProtocol> (^)(UILayoutConstraintAxis, UILayoutPriority))contentCompressionResistance
{
    return ^id(UILayoutConstraintAxis axis, UILayoutPriority priority) {
        [self.view fwSetContentCompressionResistance:axis priority:priority];
        return self;
    };
}

#pragma mark - Axis

- (id<FWLayoutChainProtocol> (^)(void))center
{
    return ^id(void) {
        [self.view fwAlignCenterToSuperview];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))centerX
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))centerY
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGPoint))centerWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fwAlignCenterToSuperviewWithOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))centerXWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))centerYWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fwAlignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))centerToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))centerXToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))centerYToView
{
    return ^id(id view) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterX toView:view withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwAlignAxis:NSLayoutAttributeCenterY toView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Edge

- (id<FWLayoutChainProtocol> (^)(void))edges
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperview];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UIEdgeInsets))edgesWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fwPinEdgesToSuperviewWithInsets:insets];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UIEdgeInsets, NSLayoutAttribute))edgesWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fwPinEdgesToSuperviewWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UILayoutConstraintAxis))edgesWithAxis
{
    return ^id(UILayoutConstraintAxis axis) {
        [self.view fwPinEdgesToSuperviewWithAxis:axis];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))top
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeTop];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))bottom
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeBottom];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))left
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeLeft];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))right
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeRight];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))topWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))bottomWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))leftWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))rightWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))topToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))bottomToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))leftToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))rightToView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))topToBottomOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))bottomToTopOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))leftToRightOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))rightToLeftOfView
{
    return ^id(id view) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))topToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))bottomToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))leftToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))rightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))topToBottomOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))bottomToTopOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))leftToRightOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))rightToLeftOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwPinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

#pragma mark - SafeArea

- (id<FWLayoutChainProtocol> (^)(void))centerToSafeArea
{
    return ^id(void) {
        [self.view fwAlignCenterToSuperviewSafeArea];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))centerXToSafeArea
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))centerYToSafeArea
{
    return ^id(void) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGPoint))centerToSafeAreaWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fwAlignCenterToSuperviewSafeAreaWithOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))centerXToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))centerYToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))edgesToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeArea];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UIEdgeInsets))edgesToSafeAreaWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fwPinEdgesToSuperviewSafeAreaWithInsets:insets];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UIEdgeInsets, NSLayoutAttribute))edgesToSafeAreaWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fwPinEdgesToSuperviewSafeAreaWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UILayoutConstraintAxis))edgesToSafeAreaWithAxis
{
    return ^id(UILayoutConstraintAxis axis) {
        [self.view fwPinEdgesToSuperviewSafeAreaWithAxis:axis];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))topToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))bottomToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))leftToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))rightToSafeArea
{
    return ^id(void) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))topToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))bottomToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))leftToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))rightToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

#pragma mark - Dimension

- (id<FWLayoutChainProtocol> (^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fwSetDimensionsToSize:size];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))sizeToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))widthToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id))heightToView
{
    return ^id(id view) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))widthToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))heightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))widthToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(id, CGFloat))heightToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Attribute

- (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithOffsetAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset relation:relation];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
        return self;
    };
}

@end

#pragma mark - UIView+FWLayoutChain

@implementation UIView (FWLayoutChain)

- (id<FWLayoutChainProtocol>)fwLayoutChain
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
