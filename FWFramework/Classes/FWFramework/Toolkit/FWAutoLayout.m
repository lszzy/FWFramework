/**
 @header     FWAutoLayout.m
 @indexgroup FWFramework
      UIView自动布局
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import "FWAutoLayout.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@interface NSLayoutConstraint (FWAutoLayout)

@property (nonatomic, assign) CGFloat innerOriginalConstant;

@end

@implementation NSLayoutConstraint (FWAutoLayout)

- (CGFloat)innerOriginalConstant
{
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setInnerOriginalConstant:(CGFloat)originalConstant
{
    objc_setAssociatedObject(self, @selector(innerOriginalConstant), @(originalConstant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static BOOL fwStaticAutoLayoutRTL = NO;

@implementation FWViewClassWrapper (FWAutoLayout)

- (BOOL)autoLayoutRTL
{
    return fwStaticAutoLayoutRTL;
}

- (void)setAutoLayoutRTL:(BOOL)enabled
{
    fwStaticAutoLayoutRTL = enabled;
}

@end

@implementation FWViewWrapper (FWAutoLayout)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(updateConstraints), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fw.autoCollapse && selfObject.fw.innerCollapseConstraints.count > 0) {
                // Absent意味着视图没有固有size，即{-1, -1}
                const CGSize absentIntrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
                
                // 计算固有尺寸
                const CGSize contentSize = [selfObject intrinsicContentSize];
                
                // 如果视图没有固定尺寸，自动设置约束
                if (CGSizeEqualToSize(contentSize, absentIntrinsicContentSize) ||
                    CGSizeEqualToSize(contentSize, CGSizeZero)) {
                    selfObject.fw.collapsed = YES;
                } else {
                    selfObject.fw.collapsed = NO;
                }
            }
        }));
        
        FWSwizzleClass(UIView, @selector(setHidden:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            FWSwizzleOriginal(hidden);
            
            if (selfObject.fw.hiddenCollapse && selfObject.fw.innerCollapseConstraints.count > 0) {
                selfObject.fw.collapsed = hidden;
            }
        }));
    });
}

#pragma mark - AutoLayout

- (BOOL)autoLayout
{
    return !self.base.translatesAutoresizingMaskIntoConstraints;
}

- (void)setAutoLayout:(BOOL)enabled
{
    self.base.translatesAutoresizingMaskIntoConstraints = !enabled;
}

- (void)autoLayoutSubviews
{
    // 保存当前的自动布局配置
    BOOL translateConstraint = self.base.translatesAutoresizingMaskIntoConstraints;
    
    // 启动自动布局，计算子视图尺寸
    self.base.translatesAutoresizingMaskIntoConstraints = NO;
    [self.base setNeedsLayout];
    [self.base layoutIfNeeded];
    
    // 还原自动布局设置
    self.base.translatesAutoresizingMaskIntoConstraints = translateConstraint;
}

- (CGFloat)layoutHeightWithWidth:(CGFloat)width
{
    CGFloat contentViewWidth = width;
    CGFloat fittingHeight = 0;
    
    // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
    NSLayoutConstraint *widthFenceConstraint = [NSLayoutConstraint constraintWithItem:self.base attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewWidth];
    [self.base addConstraint:widthFenceConstraint];
    // 自动布局引擎计算
    fittingHeight = [self.base systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    [self.base removeConstraint:widthFenceConstraint];
    
    if (fittingHeight == 0) {
        // 尝试frame布局，调用sizeThatFits:
        fittingHeight = [self.base sizeThatFits:CGSizeMake(contentViewWidth, 0)].height;
    }
    return fittingHeight;
}

- (CGFloat)layoutWidthWithHeight:(CGFloat)height
{
    CGFloat contentViewHeight = height;
    CGFloat fittingWidth = 0;
    
    // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
    NSLayoutConstraint *heightFenceConstraint = [NSLayoutConstraint constraintWithItem:self.base attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewHeight];
    [self.base addConstraint:heightFenceConstraint];
    // 自动布局引擎计算
    fittingWidth = [self.base systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width;
    [self.base removeConstraint:heightFenceConstraint];
    
    if (fittingWidth == 0) {
        // 尝试frame布局，调用sizeThatFits:
        fittingWidth = [self.base sizeThatFits:CGSizeMake(0, contentViewHeight)].width;
    }
    return fittingWidth;
}

#pragma mark - Compression

- (UILayoutPriority)compressionHorizontal
{
    return [self.base contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setCompressionHorizontal:(UILayoutPriority)priority
{
    [self.base setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)compressionVertical
{
    return [self.base contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setCompressionVertical:(UILayoutPriority)priority
{
    [self.base setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (UILayoutPriority)huggingHorizontal
{
    return [self.base contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setHuggingHorizontal:(UILayoutPriority)priority
{
    [self.base setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)huggingVertical
{
    return [self.base contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setHuggingVertical:(UILayoutPriority)priority
{
    [self.base setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - Collapse

- (BOOL)collapsed
{
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setCollapsed:(BOOL)collapsed
{
    [self.innerCollapseConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        if (collapsed) {
            constraint.constant = 0;
        } else {
            constraint.constant = constraint.innerOriginalConstant;
        }
    }];
    
    objc_setAssociatedObject(self.base, @selector(collapsed), @(collapsed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)autoCollapse
{
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setAutoCollapse:(BOOL)autoCollapse
{
    objc_setAssociatedObject(self.base, @selector(autoCollapse), @(autoCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hiddenCollapse
{
    return [objc_getAssociatedObject(self.base, _cmd) boolValue];
}

- (void)setHiddenCollapse:(BOOL)hiddenCollapse
{
    objc_setAssociatedObject(self.base, @selector(hiddenCollapse), @(hiddenCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)addCollapseConstraint:(NSLayoutConstraint *)constraint
{
    constraint.innerOriginalConstant = constraint.constant;
    if (![self.innerCollapseConstraints containsObject:constraint]) {
        [self.innerCollapseConstraints addObject:constraint];
    }
}

- (NSMutableArray *)innerCollapseConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self.base, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self.base, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

#pragma mark - Axis

- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperview
{
    return [self alignCenterToSuperviewWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperviewWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self alignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self alignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset.y]];
    return constraints;
}

- (NSLayoutConstraint *)alignAxisToSuperview:(NSLayoutAttribute)axis
{
    return [self alignAxisToSuperview:axis withOffset:0.0];
}

- (NSLayoutConstraint *)alignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    return [self constrainAttribute:axis toSuperview:self.base.superview withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView
{
    return [self alignAxis:axis toView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset
{
    return [self constrainAttribute:axis toAttribute:axis ofView:otherView withOffset:offset];
}

- (NSLayoutConstraint *)alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self constrainAttribute:axis toAttribute:axis ofView:otherView withMultiplier:multiplier];
}

#pragma mark - Edge

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperview
{
    return [self pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    }
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewHorizontal
{
    return [self pinEdgesToSuperviewHorizontalWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewHorizontalWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset]];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeRight withInset:inset]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewVertical
{
    return [self pinEdgesToSuperviewVerticalWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewVerticalWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeTop withInset:inset]];
    [constraints addObject:[self pinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset]];
    return constraints;
}

- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge
{
    return [self pinEdgeToSuperview:edge withInset:0.0];
}

- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self pinEdgeToSuperview:edge withInset:inset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:edge toSuperview:self.base.superview withOffset:inset relation:relation];
}

- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView
{
    return [self pinEdge:edge toEdge:toEdge ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self pinEdge:edge toEdge:toEdge ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:edge toAttribute:toEdge ofView:otherView withOffset:offset relation:relation];
}

#pragma mark - SafeArea

- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperviewSafeArea
{
    return [self alignCenterToSuperviewSafeAreaWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)alignCenterToSuperviewSafeAreaWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY withOffset:offset.y]];
    return constraints;
}

- (NSLayoutConstraint *)alignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis
{
    return [self alignAxisToSuperview:axis withOffset:0.0];
}

- (NSLayoutConstraint *)alignAxisToSuperviewSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    return [self constrainAttribute:axis toSuperview:self.base.superview.safeAreaLayoutGuide withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeArea
{
    return [self pinEdgesToSuperviewSafeAreaWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    }
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaHorizontal
{
    return [self pinEdgesToSuperviewSafeAreaHorizontalWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaHorizontalWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:inset]];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:inset]];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaVertical
{
    return [self pinEdgesToSuperviewSafeAreaVerticalWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)pinEdgesToSuperviewSafeAreaVerticalWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:inset]];
    [constraints addObject:[self pinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:inset]];
    return constraints;
}

- (NSLayoutConstraint *)pinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge
{
    return [self pinEdgeToSuperviewSafeArea:edge withInset:0.0];
}

- (NSLayoutConstraint *)pinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self pinEdgeToSuperviewSafeArea:edge withInset:inset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)pinEdgeToSuperviewSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:edge toSuperview:self.base.superview.safeAreaLayoutGuide withOffset:inset relation:relation];
}

#pragma mark - Dimension

- (NSArray<NSLayoutConstraint *> *)setDimensionsToSize:(CGSize)size
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self setDimension:NSLayoutAttributeWidth toSize:size.width]];
    [constraints addObject:[self setDimension:NSLayoutAttributeHeight toSize:size.height]];
    return constraints;
}

- (NSLayoutConstraint *)setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size
{
    return [self setDimension:dimension toSize:size relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:dimension toAttribute:NSLayoutAttributeNotAnAttribute ofView:nil withMultiplier:0.0 offset:size relation:relation];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier
{
    return [self matchDimension:dimension toDimension:toDimension withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
{
    return [self matchDimension:dimension toDimension:toDimension ofView:self.base withMultiplier:multiplier relation:relation];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView
{
    return [self matchDimension:dimension toDimension:toDimension ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self matchDimension:dimension toDimension:toDimension ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:dimension toAttribute:toDimension ofView:otherView withOffset:offset relation:relation];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self matchDimension:dimension toDimension:toDimension ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:dimension toAttribute:toDimension ofView:otherView withMultiplier:multiplier relation:relation];
}

#pragma mark - Constrain

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView
{
    return [self constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:offset relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:1.0 offset:offset relation:relation];
}

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
{
    return [self constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier offset:0.0 relation:relation];
}

#pragma mark - Constraint

- (NSLayoutConstraint *)lastConstraint
{
    return objc_getAssociatedObject(self.base, @selector(lastConstraint));
}

- (void)setLastConstraint:(NSLayoutConstraint *)lastConstraint
{
    objc_setAssociatedObject(self.base, @selector(lastConstraint), lastConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSLayoutConstraint *)constraintToSuperview:(NSLayoutAttribute)attribute
{
    return [self constraintToSuperview:attribute relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constraintToSuperview:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation
{
    return [self constraint:attribute toSuperview:self.base.superview relation:relation];
}

- (NSLayoutConstraint *)constraintToSuperviewSafeArea:(NSLayoutAttribute)attribute
{
    return [self constraintToSuperviewSafeArea:attribute relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constraintToSuperviewSafeArea:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation
{
    return [self constraint:attribute toSuperview:self.base.superview.safeAreaLayoutGuide relation:relation];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toSuperview:(id)superview relation:(NSLayoutRelation)relation
{
    NSAssert(self.base.superview, @"View's superview must not be nil.\nView: %@", self.base);
    if (attribute == NSLayoutAttributeBottom || attribute == NSLayoutAttributeRight || attribute == NSLayoutAttributeTrailing) {
        if (relation == NSLayoutRelationLessThanOrEqual) {
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else if (relation == NSLayoutRelationGreaterThanOrEqual) {
            relation = NSLayoutRelationLessThanOrEqual;
        }
    }
    return [self constraint:attribute toAttribute:attribute ofView:superview withMultiplier:1.0 relation:relation];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView
{
    return [self constraint:attribute toAttribute:toAttribute ofView:otherView relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView relation:(NSLayoutRelation)relation
{
    return [self constraint:attribute toAttribute:toAttribute ofView:otherView withMultiplier:1.0 relation:relation];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self constraint:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
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
    
    // 自动生成唯一约束Key，存在则获取之
    NSString *layoutKey = [NSString stringWithFormat:@"%ld-%ld-%lu-%ld-%@", (long)attribute, (long)relation, (unsigned long)[otherView hash], (long)toAttribute, @(multiplier)];
    return [self.innerLayoutConstraints objectForKey:layoutKey];
}

#pragma mark - Private

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toSuperview:(id)superview withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation
{
    NSAssert(self.base.superview, @"View's superview must not be nil.\nView: %@", self.base);
    if (attribute == NSLayoutAttributeBottom || attribute == NSLayoutAttributeRight || attribute == NSLayoutAttributeTrailing) {
        offset = -offset;
        if (relation == NSLayoutRelationLessThanOrEqual) {
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else if (relation == NSLayoutRelationGreaterThanOrEqual) {
            relation = NSLayoutRelationLessThanOrEqual;
        }
    }
    return [self constrainAttribute:attribute toAttribute:attribute ofView:superview withMultiplier:1.0 offset:offset relation:relation];
}

- (NSLayoutConstraint *)constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier offset:(CGFloat)offset relation:(NSLayoutRelation)relation
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
    
    self.base.translatesAutoresizingMaskIntoConstraints = NO;
    // 自动生成唯一约束Key，存在则更新，否则添加
    NSString *layoutKey = [NSString stringWithFormat:@"%ld-%ld-%lu-%ld-%@", (long)attribute, (long)relation, (unsigned long)[otherView hash], (long)toAttribute, @(multiplier)];
    NSLayoutConstraint *constraint = [self.innerLayoutConstraints objectForKey:layoutKey];
    if (constraint) {
        constraint.constant = offset;
    } else {
        constraint = [NSLayoutConstraint constraintWithItem:self.base attribute:attribute relatedBy:relation toItem:otherView attribute:toAttribute multiplier:multiplier constant:offset];
        [self.innerLayoutConstraints setObject:constraint forKey:layoutKey];
    }
    self.lastConstraint = constraint;
    constraint.active = YES;
    return constraint;
}

- (NSMutableDictionary *)innerLayoutConstraints
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self.base, _cmd);
    if (!constraints) {
        constraints = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self.base, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

#pragma mark - Key

- (void)setConstraint:(NSLayoutConstraint *)constraint forKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self.base, @selector(constraintForKey:));
    if (!constraints) {
        constraints = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self.base, @selector(constraintForKey:), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (constraint) {
        [constraints setObject:constraint forKey:key];
    } else {
        [constraints removeObjectForKey:key];
    }
}

- (NSLayoutConstraint *)constraintForKey:(id<NSCopying>)key
{
    NSMutableDictionary *constraints = objc_getAssociatedObject(self.base, @selector(constraintForKey:));
    return constraints ? [constraints objectForKey:key] : nil;
}

#pragma mark - All

- (NSArray<NSLayoutConstraint *> *)allConstraints
{
    return [self.innerLayoutConstraints allValues];
}

- (void)removeConstraint:(NSLayoutConstraint *)constraint
{
    constraint.active = NO;
    // 移除约束对象
    [self.innerLayoutConstraints enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqual:constraint]) {
            [self.innerLayoutConstraints removeObjectForKey:key];
            *stop = YES;
        }
    }];
    if (self.lastConstraint && [self.lastConstraint isEqual:constraint]) {
        self.lastConstraint = nil;
    }
}

- (void)removeAllConstraints
{
    // 禁用当前所有约束
    [NSLayoutConstraint deactivateConstraints:self.allConstraints];
    // 清空约束对象
    [self.innerLayoutConstraints removeAllObjects];
    self.lastConstraint = nil;
}

@end

#pragma mark - FWLayoutChain

@implementation FWLayoutChain

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
    }
    return self;
}

#pragma mark - Install

- (FWLayoutChain * (^)(void))remake
{
    return ^id(void) {
        [self.view.fw removeAllConstraints];
        return self;
    };
}

#pragma mark - Compression

- (FWLayoutChain * (^)(UILayoutPriority))compressionHorizontal
{
    return ^id(UILayoutPriority priority) {
        self.view.fw.compressionHorizontal = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))compressionVertical
{
    return ^id(UILayoutPriority priority) {
        self.view.fw.compressionVertical = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))huggingHorizontal
{
    return ^id(UILayoutPriority priority) {
        self.view.fw.huggingHorizontal = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))huggingVertical
{
    return ^id(UILayoutPriority priority) {
        self.view.fw.huggingVertical = priority;
        return self;
    };
}

#pragma mark - Collapse

- (FWLayoutChain * (^)(BOOL))collapsed
{
    return ^id(BOOL collapsed) {
        self.view.fw.collapsed = collapsed;
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))autoCollapse
{
    return ^id(BOOL autoCollapse) {
        self.view.fw.autoCollapse = autoCollapse;
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))hiddenCollapse
{
    return ^id(BOOL hiddenCollapse) {
        self.view.fw.hiddenCollapse = hiddenCollapse;
        return self;
    };
}

#pragma mark - Axis

- (FWLayoutChain * (^)(void))center
{
    return ^id(void) {
        [self.view.fw alignCenterToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerX
{
    return ^id(void) {
        [self.view.fw alignAxisToSuperview:NSLayoutAttributeCenterX];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerY
{
    return ^id(void) {
        [self.view.fw alignAxisToSuperview:NSLayoutAttributeCenterY];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerWithOffset
{
    return ^id(CGPoint offset) {
        [self.view.fw alignCenterToSuperviewWithOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXWithOffset
{
    return ^id(CGFloat offset) {
        [self.view.fw alignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYWithOffset
{
    return ^id(CGFloat offset) {
        [self.view.fw alignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerToView
{
    return ^id(id view) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterX toView:view];
        [self.view.fw alignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerXToView
{
    return ^id(id view) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterX toView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerYToView
{
    return ^id(id view) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterX toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterY toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterX toView:view withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view.fw alignAxis:NSLayoutAttributeCenterY toView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Edge

- (FWLayoutChain * (^)(void))edges
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view.fw pinEdgesToSuperviewWithInsets:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view.fw pinEdgesToSuperviewWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesHorizontal
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperviewHorizontal];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesVertical
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperviewVertical];
        return self;
    };
}

- (FWLayoutChain * (^)(void))top
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeTop];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottom
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeBottom];
        return self;
    };
}

- (FWLayoutChain * (^)(void))left
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeLeft];
        return self;
    };
}

- (FWLayoutChain * (^)(void))right
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeRight];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperview:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToBottomOfView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToTopOfView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToRightOfView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToLeftOfView
{
    return ^id(id view) {
        [self.view.fw pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToBottomOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToTopOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToRightOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToLeftOfViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

#pragma mark - SafeArea

- (FWLayoutChain * (^)(void))centerToSafeArea
{
    return ^id(void) {
        [self.view.fw alignCenterToSuperviewSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerXToSafeArea
{
    return ^id(void) {
        [self.view.fw alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerYToSafeArea
{
    return ^id(void) {
        [self.view.fw alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerToSafeAreaWithOffset
{
    return ^id(CGPoint offset) {
        [self.view.fw alignCenterToSuperviewSafeAreaWithOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view.fw alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view.fw alignAxisToSuperviewSafeArea:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesToSafeArea
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperviewSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesToSafeAreaWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view.fw pinEdgesToSuperviewSafeAreaWithInsets:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesToSafeAreaWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view.fw pinEdgesToSuperviewSafeAreaWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesToSafeAreaHorizontal
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperviewSafeAreaHorizontal];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesToSafeAreaVertical
{
    return ^id(void) {
        [self.view.fw pinEdgesToSuperviewSafeAreaVertical];
        return self;
    };
}

- (FWLayoutChain * (^)(void))topToSafeArea
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeTop];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottomToSafeArea
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom];
        return self;
    };
}

- (FWLayoutChain * (^)(void))leftToSafeArea
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft];
        return self;
    };
}

- (FWLayoutChain * (^)(void))rightToSafeArea
{
    return ^id(void) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeRight];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view.fw pinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

#pragma mark - Dimension

- (FWLayoutChain * (^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view.fw setDimensionsToSize:size];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view.fw setDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view.fw setDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))widthToHeight
{
    return ^id(CGFloat multiplier) {
        [self.view.fw matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeHeight withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))heightToWidth
{
    return ^id(CGFloat multiplier) {
        [self.view.fw matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeWidth withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id))sizeToView
{
    return ^id(id view) {
        [self.view.fw matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        [self.view.fw matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))widthToView
{
    return ^id(id view) {
        [self.view.fw matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))heightToView
{
    return ^id(id view) {
        [self.view.fw matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view.fw matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view.fw matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view.fw matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Attribute

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        [self.view.fw constrainAttribute:attribute toAttribute:toAttribute ofView:ofView];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
        [self.view.fw constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithOffsetAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation) {
        [self.view.fw constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset relation:relation];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        [self.view.fw constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        [self.view.fw constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
        return self;
    };
}

#pragma mark - Constraint

- (NSLayoutConstraint *)constraint
{
    return self.view.fw.lastConstraint;
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute))constraintToSuperview
{
    return ^id(NSLayoutAttribute attribute) {
        return [self.view.fw constraintToSuperview:attribute];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutRelation))constraintToSuperviewWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutRelation relation) {
        return [self.view.fw constraintToSuperview:attribute relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute))constraintToSafeArea
{
    return ^id(NSLayoutAttribute attribute) {
        return [self.view.fw constraintToSuperviewSafeArea:attribute];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutRelation))constraintToSafeAreaWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutRelation relation) {
        return [self.view.fw constraintToSuperviewSafeArea:attribute relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id))constraintToView
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        return [self.view.fw constraint:attribute toAttribute:toAttribute ofView:ofView];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, NSLayoutRelation))constraintToViewWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, NSLayoutRelation relation) {
        return [self.view.fw constraint:attribute toAttribute:toAttribute ofView:ofView relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))constraintToViewWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        return [self.view.fw constraint:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))constraintToViewWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        return [self.view.fw constraint:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
    };
}

@end

#pragma mark - FWViewWrapper+FWLayoutChain

@implementation FWViewWrapper (FWLayoutChain)

- (FWLayoutChain *)layoutChain
{
    FWLayoutChain *layoutChain = objc_getAssociatedObject(self.base, _cmd);
    if (!layoutChain) {
        layoutChain = [[FWLayoutChain alloc] initWithView:self.base];
        objc_setAssociatedObject(self.base, _cmd, layoutChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutChain;
}

- (void)layoutMaker:(__attribute__((noescape)) void (^)(FWLayoutChain *))block
{
    if (block) {
        block(self.layoutChain);
    }
}

@end
