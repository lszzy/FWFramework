/*!
 @header     FWLayoutManager.m
 @indexgroup FWFramework
 @brief      UIView自动布局
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import "FWLayoutManager.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

static BOOL fwStaticAutoLayoutRTL = NO;

@interface NSLayoutConstraint (FWAutoLayout)

@property (nonatomic, assign) CGFloat fwOriginalConstant;

@end

@implementation NSLayoutConstraint (FWAutoLayout)

- (CGFloat)fwOriginalConstant
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setFwOriginalConstant:(CGFloat)fwOriginalConstant
{
    objc_setAssociatedObject(self, @selector(fwOriginalConstant), @(fwOriginalConstant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIView (FWAutoLayout)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(updateConstraints), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fwAutoCollapse && selfObject.fwInnerCollapseConstraints.count > 0) {
                // Absent意味着视图没有固有size，即{-1, -1}
                const CGSize absentIntrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
                
                // 计算固有尺寸
                const CGSize contentSize = [selfObject intrinsicContentSize];
                
                // 如果视图没有固定尺寸，自动设置约束
                if (CGSizeEqualToSize(contentSize, absentIntrinsicContentSize) ||
                    CGSizeEqualToSize(contentSize, CGSizeZero)) {
                    selfObject.fwCollapsed = YES;
                } else {
                    selfObject.fwCollapsed = NO;
                }
            }
        }));
    });
}

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

+ (void)fwAutoLayoutRTL:(BOOL)enabled
{
    fwStaticAutoLayoutRTL = enabled;
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

- (CGFloat)fwLayoutHeightWithWidth:(CGFloat)width
{
    CGFloat contentViewWidth = width;
    CGFloat fittingHeight = 0;
    
    // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
    NSLayoutConstraint *widthFenceConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewWidth];
    [self addConstraint:widthFenceConstraint];
    // 自动布局引擎计算
    fittingHeight = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    [self removeConstraint:widthFenceConstraint];
    
    if (fittingHeight == 0) {
        // 尝试frame布局，调用sizeThatFits:
        fittingHeight = [self sizeThatFits:CGSizeMake(contentViewWidth, 0)].height;
    }
    return fittingHeight;
}

#pragma mark - Compression

- (void)fwSetCompressionHorizontal:(UILayoutPriority)priority
{
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)fwSetCompressionVertical:(UILayoutPriority)priority
{
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - Collapse

- (BOOL)fwCollapsed
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwCollapsed:(BOOL)fwCollapsed
{
    [self.fwInnerCollapseConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        if (fwCollapsed) {
            constraint.constant = 0;
        } else {
            constraint.constant = constraint.fwOriginalConstant;
        }
    }];
    
    objc_setAssociatedObject(self, @selector(fwCollapsed), @(fwCollapsed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwAutoCollapse
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFwAutoCollapse:(BOOL)fwAutoCollapse
{
    objc_setAssociatedObject(self, @selector(fwAutoCollapse), @(fwAutoCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwAddCollapseConstraint:(NSLayoutConstraint *)constraint
{
    constraint.fwOriginalConstant = constraint.constant;
    [self.fwInnerCollapseConstraints addObject:constraint];
}

- (NSMutableArray *)fwInnerCollapseConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
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

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewHorizontal
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeLeft]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeRight]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewVertical
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeTop]];
    [constraints addObject:[self fwPinEdgeToSuperview:NSLayoutAttributeBottom]];
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

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaHorizontal
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fwPinEdgesToSuperviewSafeAreaVertical
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop]];
    [constraints addObject:[self fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom]];
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
    if (fwStaticAutoLayoutRTL) {
        switch (attribute) {
            case NSLayoutAttributeLeft: { attribute = NSLayoutAttributeLeading; break; }
            case NSLayoutAttributeRight: { attribute = NSLayoutAttributeTrailing; break; }
            case NSLayoutAttributeLeftMargin: { attribute = NSLayoutAttributeLeadingMargin; break; }
            case NSLayoutAttributeRightMargin: { attribute = NSLayoutAttributeTrailingMargin; break; }
            default: break;
        }
        switch (toAttribute) {
            case NSLayoutAttributeLeft: { toAttribute = NSLayoutAttributeLeading; break; }
            case NSLayoutAttributeRight: { toAttribute = NSLayoutAttributeTrailing; break; }
            case NSLayoutAttributeLeftMargin: { toAttribute = NSLayoutAttributeLeadingMargin; break; }
            case NSLayoutAttributeRightMargin: { toAttribute = NSLayoutAttributeTrailingMargin; break; }
            default: break;
        }
    }
    
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

- (id<FWLayoutChainProtocol> (^)(UILayoutPriority))compressionHorizontal
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionHorizontal:priority];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(UILayoutPriority))compressionVertical
{
    return ^id(UILayoutPriority priority) {
        [self.view fwSetCompressionVertical:priority];
        return self;
    };
}

#pragma mark - Collapse

- (id<FWLayoutChainProtocol> (^)(BOOL))collapsed
{
    return ^id(BOOL collapsed) {
        self.view.fwCollapsed = collapsed;
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(BOOL))autoCollapse
{
    return ^id(BOOL autoCollapse) {
        self.view.fwAutoCollapse = autoCollapse;
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

- (id<FWLayoutChainProtocol> (^)(void))edgesHorizontal
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewHorizontal];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))edgesVertical
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewVertical];
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

- (id<FWLayoutChainProtocol> (^)(void))edgesToSafeAreaHorizontal
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeAreaHorizontal];
        return self;
    };
}

- (id<FWLayoutChainProtocol> (^)(void))edgesToSafeAreaVertical
{
    return ^id(void) {
        [self.view fwPinEdgesToSuperviewSafeAreaVertical];
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

- (void)fwLayoutMaker:(__attribute__((noescape)) void (^)(id<FWLayoutChainProtocol>))block
{
    if (block) {
        block(self.fwLayoutChain);
    }
}

@end
