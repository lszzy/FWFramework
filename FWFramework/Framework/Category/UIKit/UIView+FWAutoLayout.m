/*!
 @header     UIView+FWAutoLayout.m
 @indexgroup FWFramework
 @brief      UIView自动布局分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

static void *kUIViewFWConstraintsKey = &kUIViewFWConstraintsKey;

@implementation UIView (FWAutoLayout)

#pragma mark - AutoLayout

+ (instancetype)fwAutoLayoutView
{
    UIView *view = [self new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

- (void)fwSetAutoLayout:(BOOL)enabled
{
    self.translatesAutoresizingMaskIntoConstraints = !enabled;
}

- (void)fwAutoLayoutSubviews
{
    // 保存当前的自动布局配置
    BOOL translateConstraint = self.translatesAutoresizingMaskIntoConstraints;
    
    // 启动自动布局，计算子视图尺寸
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    // 还原自动布局设置
    self.translatesAutoresizingMaskIntoConstraints = translateConstraint;
}

#pragma mark - Key

- (void)fwSetConstraint:(NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self, kUIViewFWConstraintsKey);
    if (!constraints) {
        constraints = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kUIViewFWConstraintsKey, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (constraint) {
        [constraints setObject:constraint forKey:key];
    } else {
        [constraints removeObjectForKey:key];
    }
}

- (NSLayoutConstraint *)fwConstraintForKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self, kUIViewFWConstraintsKey);
    return constraints ? [constraints objectForKey:key] : nil;
}

#pragma mark - Axis

- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperview
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwAlignAxisToSuperview:NSLayoutAttributeCenterX]];
    [constraints addObject:[self fwAlignAxisToSuperview:NSLayoutAttributeCenterY]];
    return constraints;
}

- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis
{
    return [self fwConstrainAttribute:axis toSuperview:self.superview withOffset:0.0 relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView
{
    return [self fwAlignAxis:axis toView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fwConstrainAttribute:axis toAttribute:axis ofView:otherView withOffset:offset];
}

- (NSLayoutConstraint *)fwAlignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fwConstrainAttribute:axis toAttribute:axis ofView:otherView withMultiplier:multiplier];
}

#pragma mark - Edge

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperview
{
    return [self fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeading withInset:insets.left]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTrailing withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeading withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTrailing withInset:insets.right]];
    }
    return constraints;
}

- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge
{
    return [self fwPinEdgeToSuperview:edge withInset:0.0];
}

- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self fwPinEdgeToSuperview:edge withInset:inset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwPinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:edge toSuperview:self.superview withOffset:inset relation:relation];
}

- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView
{
    return [self fwPinEdge:edge toEdge:toEdge ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fwPinEdge:edge toEdge:toEdge ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwPinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:edge toAttribute:toEdge ofView:otherView withOffset:offset relation:relation];
}

#pragma mark - SafeArea

- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeArea
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX]];
    [constraints addObject:[self fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY]];
    return constraints;
}

- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis
{
    if (@available(iOS 11.0, *)) {
        return [self fwConstrainAttribute:axis toSuperview:self.superview.safeAreaLayoutGuide withOffset:0.0 relation:NSLayoutRelationEqual];
    } else {
        return [self fwConstrainAttribute:axis toSuperview:self.superview withOffset:0.0 relation:NSLayoutRelationEqual];
    }
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeArea
{
    return [self fwPinEdgesToSuperviewSafeAreaWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeading withInset:insets.left]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTrailing withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeading withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTrailing withInset:insets.right]];
    }
    return constraints;
}

- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge
{
    return [self fwPinEdgeToSuperviewSafeArea:edge withInset:0.0];
}

- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self fwPinEdgeToSuperviewSafeArea:edge withInset:inset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwPinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation
{
    if (@available(iOS 11.0, *)) {
        return [self fwConstrainAttribute:edge toSuperview:self.superview.safeAreaLayoutGuide withOffset:inset relation:relation];
    } else {
        return [self fwConstrainAttribute:edge toSuperview:self.superview withOffset:inset relation:relation];
    }
}

#pragma mark - Dimension

- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView
{
    return [self fwMatchDimension:dimension toDimension:toDimension ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fwMatchDimension:dimension toDimension:toDimension ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:dimension toAttribute:toDimension ofView:otherView withOffset:offset relation:relation];
}

- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fwMatchDimension:dimension toDimension:toDimension ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwMatchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:dimension toAttribute:toDimension ofView:otherView withMultiplier:multiplier relation:relation];
}

- (NSArray<NSLayoutConstraint *> *)fwSetDimensionsToSize:(CGSize)size
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwSetDimension:NSLayoutAttributeWidth toSize:size.width]];
    [constraints addObject:[self fwSetDimension:NSLayoutAttributeHeight toSize:size.height]];
    return constraints;
}

- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size
{
    return [self fwSetDimension:dimension toSize:size relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwSetDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:dimension toAttribute:NSLayoutAttributeNotAnAttribute ofView:nil withMultiplier:0.0 offset:size relation:relation];
}

#pragma mark - Constrain

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView
{
    return [self fwConstrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fwConstrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:1.0 offset:offset relation:relation];
}

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fwConstrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
{
    return [self fwConstrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier offset:0.0 relation:relation];
}

#pragma mark - Private

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toSuperview:(id)superview withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    NSAssert(self.superview, @"View's superview must not be nil.\nView: %@", self);
    if (attribute == NSLayoutAttributeBottom || attribute == NSLayoutAttributeRight || attribute == NSLayoutAttributeTrailing) {
        offset = -offset;
        if (relation == NSLayoutRelationLessThanOrEqual) {
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else if (relation == NSLayoutRelationGreaterThanOrEqual) {
            relation = NSLayoutRelationLessThanOrEqual;
        }
    }
    return [self fwConstrainAttribute:attribute toAttribute:attribute ofView:superview withMultiplier:1.0 offset:offset relation:relation];
}

- (NSLayoutConstraint *)fwConstrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier offset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:attribute relatedBy:relation toItem:otherView attribute:toAttribute multiplier:multiplier constant:offset];
    constraint.active = YES;
    // 自动添加到当前约束列表中
    [self.fwInnerAllConstraints addObject:constraint];
    return constraint;
}

#pragma mark - All

- (NSMutableArray *)fwInnerAllConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, @selector(fwInnerAllConstraints));
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, @selector(fwInnerAllConstraints), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwAllConstraints
{
    return [self.fwInnerAllConstraints copy];
}

- (void)fwRemoveAllConstraints
{
    // 禁用当前约束
    [NSLayoutConstraint deactivateConstraints:self.fwInnerAllConstraints];
    // 清空约束对象
    [self.fwInnerAllConstraints removeAllObjects];
}

@end
