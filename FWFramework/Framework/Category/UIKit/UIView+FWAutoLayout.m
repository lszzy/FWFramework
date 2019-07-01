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

#pragma mark - Compression

- (void)fwSetContentCompressionResistance:(UILayoutConstraintAxis)axis priority:(UILayoutPriority)priority
{
    [self setContentCompressionResistancePriority:priority forAxis:axis];
}

#pragma mark - Axis

- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperview
{
    return [self fwAlignCenterToSuperviewWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwAlignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self fwAlignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset.y]];
    return constraints;
}

- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis
{
    return [self fwAlignAxisToSuperview:axis withOffset:0.0];
}

- (NSLayoutConstraint *)fwAlignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    return [self fwConstrainAttribute:axis toSuperview:self.superview withOffset:offset relation:NSLayoutRelationEqual];
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
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    }
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewWithAxis:(UILayoutConstraintAxis)axis
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (axis == UILayoutConstraintAxisHorizontal) {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeft]];
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeRight]];
    } else {
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTop]];
        [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom]];
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
    return [self fwAlignCenterToSuperviewSafeAreaWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)fwAlignCenterToSuperviewSafeAreaWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self fwAlignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY withOffset:offset.y]];
    return constraints;
}

- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis
{
    return [self fwAlignAxisToSuperview:axis withOffset:0.0];
}

- (NSLayoutConstraint *)fwAlignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    if (@available(iOS 11.0, *)) {
        return [self fwConstrainAttribute:axis toSuperview:self.superview.safeAreaLayoutGuide withOffset:offset relation:NSLayoutRelationEqual];
    } else {
        return [self fwConstrainAttribute:axis toSuperview:self.superview withOffset:offset relation:NSLayoutRelationEqual];
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
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    }
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaWithAxis:(UILayoutConstraintAxis)axis
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (axis == UILayoutConstraintAxisHorizontal) {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft]];
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight]];
    } else {
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop]];
        [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom]];
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
    // 自动生成唯一约束Key，存在则更新，否则添加
    NSString *layoutKey = [NSString stringWithFormat:@"%ld-%ld-%lu-%ld-%@", (long)attribute, (long)relation, (unsigned long)[otherView hash], (long)toAttribute, @(multiplier)];
    NSLayoutConstraint *constraint = [self.fwInnerLayoutConstraints objectForKey:layoutKey];
    if (constraint) {
        constraint.constant = offset;
    } else {
        constraint = [NSLayoutConstraint constraintWithItem:self attribute:attribute relatedBy:relation toItem:otherView attribute:toAttribute multiplier:multiplier constant:offset];
        [self.fwInnerLayoutConstraints setObject:constraint forKey:layoutKey];
    }
    constraint.active = YES;
    return constraint;
}

- (NSMutableDictionary *)fwInnerLayoutConstraints
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self, @selector(fwInnerLayoutConstraints));
    if (!constraints) {
        constraints = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(fwInnerLayoutConstraints), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

#pragma mark - Key

- (void)fwSetConstraint:(NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self, @selector(fwConstraintForKey:));
    if (!constraints) {
        constraints = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(fwConstraintForKey:), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (constraint) {
        [constraints setObject:constraint forKey:key];
    } else {
        [constraints removeObjectForKey:key];
    }
}

- (NSLayoutConstraint *)fwConstraintForKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self, @selector(fwConstraintForKey:));
    return constraints ? [constraints objectForKey:key] : nil;
}

#pragma mark - All

- (NSArray<NSLayoutConstraint *> *)fwAllConstraints
{
    return [self.fwInnerLayoutConstraints allValues];
}

- (void)fwRemoveConstraint:(NSLayoutConstraint *)constraint
{
    constraint.active = NO;
    // 移除约束对象
    [self.fwInnerLayoutConstraints enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:constraint]) {
            [self.fwInnerLayoutConstraints removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

- (void)fwRemoveAllConstraints
{
    // 禁用当前所有约束
    [NSLayoutConstraint deactivateConstraints:self.fwAllConstraints];
    // 清空约束对象
    [self.fwInnerLayoutConstraints removeAllObjects];
}

@end
