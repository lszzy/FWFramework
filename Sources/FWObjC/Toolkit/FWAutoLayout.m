//
//  FWAutoLayout.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAutoLayout.h"
#import "FWAdaptive.h"
#import "FWSwizzle.h"
#import "FWUIKit.h"
#import <objc/runtime.h>

#pragma mark - NSLayoutConstraint+FWAutoLayout

#ifdef DEBUG
static BOOL fwStaticAutoLayoutDebug = YES;
#else
static BOOL fwStaticAutoLayoutDebug = NO;
#endif

static BOOL fwStaticAutoFlatLayout = NO;

@implementation NSLayoutConstraint (FWAutoLayout)

- (CGFloat)fw_offset
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_offset:(CGFloat)offset
{
    objc_setAssociatedObject(self, @selector(fw_offset), @(offset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    BOOL autoScale = UIView.fw_autoScale;
    if ([self.firstItem isKindOfClass:[UIView class]]) {
        autoScale = ((UIView *)self.firstItem).fw_autoScale;
    } else if ([self.firstItem isKindOfClass:[UILayoutGuide class]]) {
        UIView *view = ((UILayoutGuide *)self.firstItem).owningView;
        if (view) autoScale = view.fw_autoScale;
    }
    
    if (autoScale) {
        offset = [UIScreen fw_relativeValue:offset];
        if (fwStaticAutoFlatLayout) offset = [UIScreen fw_flatValue:offset];
    }
    self.constant = self.fw_isOpposite ? -offset : offset;
}

- (BOOL)fw_isOpposite
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_isOpposite:(BOOL)isOpposite
{
    objc_setAssociatedObject(self, @selector(fw_isOpposite), @(isOpposite), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILayoutPriority)fw_priority
{
    return self.priority;
}

- (void)setFw_priority:(UILayoutPriority)priority
{
    @try {
        self.priority = priority;
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

- (CGFloat)fw_collapseOffset
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_collapseOffset:(CGFloat)collapseOffset
{
    objc_setAssociatedObject(self, @selector(fw_collapseOffset), @(collapseOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_originalOffset
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFw_originalOffset:(CGFloat)originalOffset
{
    objc_setAssociatedObject(self, @selector(fw_originalOffset), @(originalOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_originalActive
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_originalActive:(BOOL)originalActive
{
    objc_setAssociatedObject(self, @selector(fw_originalActive), @(originalActive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fw_layoutIdentifier
{
    return (NSString *)objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_layoutIdentifier:(NSString *)layoutIdentifier
{
    objc_setAssociatedObject(self, @selector(fw_layoutIdentifier), layoutIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

// MARK: - Debug

#ifdef DEBUG

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(NSLayoutConstraint, @selector(description), FWSwizzleReturn(NSString *), FWSwizzleArgs(), FWSwizzleCode({
            if (!fwStaticAutoLayoutDebug) {
                return FWSwizzleOriginal();
            }
            
            return selfObject.fw_layoutDescription;
        }));
    });
}

+ (NSDictionary *)fw_relationDescriptions
{
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
        descriptionMap = @{
            @(NSLayoutRelationEqual)              : @"==",
            @(NSLayoutRelationGreaterThanOrEqual) : @">=",
            @(NSLayoutRelationLessThanOrEqual)    : @"<=",
        };
    });
    return descriptionMap;
}

+ (NSDictionary *)fw_attributeDescriptions
{
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
        descriptionMap = @{
            @(NSLayoutAttributeTop)                  : @"top",
            @(NSLayoutAttributeLeft)                 : @"left",
            @(NSLayoutAttributeBottom)               : @"bottom",
            @(NSLayoutAttributeRight)                : @"right",
            @(NSLayoutAttributeLeading)              : @"leading",
            @(NSLayoutAttributeTrailing)             : @"trailing",
            @(NSLayoutAttributeWidth)                : @"width",
            @(NSLayoutAttributeHeight)               : @"height",
            @(NSLayoutAttributeCenterX)              : @"centerX",
            @(NSLayoutAttributeCenterY)              : @"centerY",
            @(NSLayoutAttributeFirstBaseline)        : @"firstBaseline",
            @(NSLayoutAttributeLastBaseline)         : @"lastBaseline",
            @(NSLayoutAttributeLeftMargin)           : @"leftMargin",
            @(NSLayoutAttributeRightMargin)          : @"rightMargin",
            @(NSLayoutAttributeTopMargin)            : @"topMargin",
            @(NSLayoutAttributeBottomMargin)         : @"bottomMargin",
            @(NSLayoutAttributeLeadingMargin)        : @"leadingMargin",
            @(NSLayoutAttributeTrailingMargin)       : @"trailingMargin",
            @(NSLayoutAttributeCenterXWithinMargins) : @"centerXWithinMargins",
            @(NSLayoutAttributeCenterYWithinMargins) : @"centerYWithinMargins",
        };
    });
    return descriptionMap;
}


+ (NSDictionary *)fw_priorityDescriptions
{
    static dispatch_once_t once;
    static NSDictionary *descriptionMap;
    dispatch_once(&once, ^{
        descriptionMap = @{
            @(UILayoutPriorityDefaultHigh)               : @"defaultHigh",
            @(UILayoutPriorityDefaultLow)                : @"defaultLow",
            @(UILayoutPriorityRequired)                  : @"required",
            @(UILayoutPriorityFittingSizeLevel)          : @"fittingSizeLevel",
            @(UILayoutPriorityDragThatCanResizeScene)    : @"dragThatCanResizeScene",
            @(UILayoutPrioritySceneSizeStayPut)          : @"sceneSizeStayPut",
            @(UILayoutPriorityDragThatCannotResizeScene) : @"dragThatCannotResizeScene",
        };
    });
    return descriptionMap;
}

+ (NSString *)fw_layoutDescription:(id)object
{
    NSString *objectDesc = @"";
    if ([object isKindOfClass:[NSLayoutConstraint class]] && ((NSLayoutConstraint *)object).identifier.length > 0) {
        objectDesc = [NSString stringWithFormat:@" '%@'", ((NSLayoutConstraint *)object).identifier];
    } else if ([object isKindOfClass:[UILayoutGuide class]] && ((UILayoutGuide *)object).owningView.fw_layoutKey.length > 0) {
        objectDesc = [NSString stringWithFormat:@" '%@'", ((UILayoutGuide *)object).owningView.fw_layoutKey];
    } else if ([object isKindOfClass:[UIView class]] && ((UIView *)object).fw_layoutKey.length > 0) {
        objectDesc = [NSString stringWithFormat:@" '%@'", ((UIView *)object).fw_layoutKey];
    }
    return [NSString stringWithFormat:@"%@:%p%@", [object class], object, objectDesc];
}

/// 布局调试描述，参考：[Masonry](https://github.com/SnapKit/Masonry)
- (NSString *)fw_layoutDescription
{
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"<"];

    [description appendString:[self.class fw_layoutDescription:self]];

    [description appendFormat:@" %@", [self.class fw_layoutDescription:self.firstItem]];
    if (self.firstAttribute != NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@".%@", self.class.fw_attributeDescriptions[@(self.firstAttribute)]];
    }

    [description appendFormat:@" %@", self.class.fw_relationDescriptions[@(self.relation)]];

    if (self.secondItem) {
        [description appendFormat:@" %@", [self.class fw_layoutDescription:self.secondItem]];
    }
    if (self.secondAttribute != NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@".%@", self.class.fw_attributeDescriptions[@(self.secondAttribute)]];
    }
    
    if (self.multiplier != 1) {
        [description appendFormat:@" * %g", self.multiplier];
    }
    
    if (self.secondAttribute == NSLayoutAttributeNotAnAttribute) {
        [description appendFormat:@" %g", self.constant];
    } else {
        if (self.constant) {
            [description appendFormat:@" %@ %g", (self.constant < 0 ? @"-" : @"+"), ABS(self.constant)];
        }
    }

    if (self.priority != UILayoutPriorityRequired) {
        [description appendFormat:@" ^%@", self.class.fw_priorityDescriptions[@(self.priority)] ?: [NSNumber numberWithDouble:self.priority]];
    }

    [description appendString:@">"];
    return description;
}

#endif

@end

#pragma mark - UIView+FWAutoLayout

static BOOL fwStaticAutoLayoutRTL = NO;
static BOOL fwStaticAutoScaleLayout = NO;

@implementation UIView (FWAutoLayout)

#pragma mark - Debug

+ (BOOL)fw_autoLayoutDebug
{
    return fwStaticAutoLayoutDebug;
}

+ (void)setFw_autoLayoutDebug:(BOOL)debug
{
    fwStaticAutoLayoutDebug = debug;
}

- (NSString *)fw_layoutKey
{
    return (NSString *)objc_getAssociatedObject(self, _cmd);
}

- (void)setFw_layoutKey:(NSString *)layoutKey
{
    objc_setAssociatedObject(self, @selector(fw_layoutKey), layoutKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - AutoLayout

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIView, @selector(updateConstraints), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            
            if (selfObject.fw_autoCollapse && selfObject.fw_innerCollapseConstraints.count > 0) {
                // Absent意味着视图没有固有size，即{-1, -1}
                const CGSize absentIntrinsicContentSize = CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
                
                // 计算固有尺寸
                const CGSize contentSize = [selfObject intrinsicContentSize];
                
                // 如果视图没有固定尺寸，自动设置约束
                if (CGSizeEqualToSize(contentSize, absentIntrinsicContentSize) ||
                    CGSizeEqualToSize(contentSize, CGSizeZero)) {
                    selfObject.fw_isCollapsed = YES;
                } else {
                    selfObject.fw_isCollapsed = NO;
                }
            }
        }));
        
        FWSwizzleClass(UIView, @selector(setHidden:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL hidden), FWSwizzleCode({
            FWSwizzleOriginal(hidden);
            
            if (selfObject.fw_hiddenCollapse && selfObject.fw_innerCollapseConstraints.count > 0) {
                selfObject.fw_isCollapsed = hidden;
            }
        }));
    });
}

+ (BOOL)fw_autoLayoutRTL
{
    return fwStaticAutoLayoutRTL;
}

+ (void)setFw_autoLayoutRTL:(BOOL)enabled
{
    fwStaticAutoLayoutRTL = enabled;
}

+ (BOOL)fw_autoScale
{
    return fwStaticAutoScaleLayout;
}

+ (void)setFw_autoScale:(BOOL)autoScale
{
    fwStaticAutoScaleLayout = autoScale;
}

+ (BOOL)fw_autoFlat
{
    return fwStaticAutoFlatLayout;
}

+ (void)setFw_autoFlat:(BOOL)autoFlat
{
    fwStaticAutoFlatLayout = autoFlat;
}

- (BOOL)fw_autoScale
{
    NSNumber *value = objc_getAssociatedObject(self, _cmd);
    if (value) return value.boolValue;
    return fwStaticAutoScaleLayout;
}

- (void)setFw_autoScale:(BOOL)autoScale
{
    objc_setAssociatedObject(self, @selector(fw_autoScale), @(autoScale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_autoLayoutSubviews
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

- (CGFloat)fw_layoutHeightWithWidth:(CGFloat)width
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

- (CGFloat)fw_layoutWidthWithHeight:(CGFloat)height
{
    CGFloat contentViewHeight = height;
    CGFloat fittingWidth = 0;
    
    // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
    NSLayoutConstraint *heightFenceConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:contentViewHeight];
    [self addConstraint:heightFenceConstraint];
    // 自动布局引擎计算
    fittingWidth = [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width;
    [self removeConstraint:heightFenceConstraint];
    
    if (fittingWidth == 0) {
        // 尝试frame布局，调用sizeThatFits:
        fittingWidth = [self sizeThatFits:CGSizeMake(0, contentViewHeight)].width;
    }
    return fittingWidth;
}

- (CGFloat)fw_dynamicHeightWithWidth:(CGFloat)width maxYViewExpanded:(BOOL)maxYViewExpanded maxYViewPadding:(CGFloat)maxYViewPadding maxYView:(UIView *)maxYView
{
    UIView *view = [UIView new];
    [view addSubview:self];
    view.frame = CGRectMake(0.0, 0.0, width, 0.0);
    self.frame = CGRectMake(0.0, 0.0, width, 0.0);
    
    CGFloat dynamicHeight = 0.0;
    // 自动撑开方式
    if (maxYViewExpanded) {
        dynamicHeight = [self fw_layoutHeightWithWidth:width];
    // 无需撑开
    } else {
        [view setNeedsLayout];
        [view layoutIfNeeded];
        
        __block CGFloat maxY = 0.0;
        if (maxYView) {
            maxY = CGRectGetMaxY(maxYView.frame);
        } else {
            [self.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                }
            }];
        }
        dynamicHeight = maxY + maxYViewPadding;
    }
    
    [self removeFromSuperview];
    self.frame = CGRectMake(0, 0, width, dynamicHeight);
    return dynamicHeight;
}

- (CGFloat)fw_dynamicWidthWithHeight:(CGFloat)height maxYViewExpanded:(BOOL)maxYViewExpanded maxYViewPadding:(CGFloat)maxYViewPadding maxYView:(UIView *)maxYView
{
    UIView *view = [UIView new];
    [view addSubview:self];
    view.frame = CGRectMake(0.0, 0.0, 0.0, height);
    self.frame = CGRectMake(0.0, 0.0, 0.0, height);
    
    CGFloat dynamicWidth = 0.0;
    // 自动撑开方式
    if (maxYViewExpanded) {
        dynamicWidth = [self fw_layoutWidthWithHeight:height];
    // 无需撑开
    } else {
        [view setNeedsLayout];
        [view layoutIfNeeded];
        
        __block CGFloat maxY = 0.0;
        if (maxYView) {
            maxY = CGRectGetMaxX(maxYView.frame);
        } else {
            [self.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxX(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                }
            }];
        }
        dynamicWidth = maxY + maxYViewPadding;
    }
    
    [self removeFromSuperview];
    self.frame = CGRectMake(0, 0, dynamicWidth, height);
    return dynamicWidth;
}

#pragma mark - Compression

- (UILayoutPriority)fw_compressionHorizontal
{
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setFw_compressionHorizontal:(UILayoutPriority)priority
{
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)fw_compressionVertical
{
    return [self contentCompressionResistancePriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setFw_compressionVertical:(UILayoutPriority)priority
{
    [self setContentCompressionResistancePriority:priority forAxis:UILayoutConstraintAxisVertical];
}

- (UILayoutPriority)fw_huggingHorizontal
{
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setFw_huggingHorizontal:(UILayoutPriority)priority
{
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisHorizontal];
}

- (UILayoutPriority)fw_huggingVertical
{
    return [self contentHuggingPriorityForAxis:UILayoutConstraintAxisVertical];
}

- (void)setFw_huggingVertical:(UILayoutPriority)priority
{
    [self setContentHuggingPriority:priority forAxis:UILayoutConstraintAxisVertical];
}

#pragma mark - Collapse

- (BOOL)fw_isCollapsed
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_isCollapsed:(BOOL)isCollapsed
{
    [self.fw_innerCollapseConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        constraint.fw_offset = isCollapsed ? constraint.fw_collapseOffset : constraint.fw_originalOffset;
    }];
    
    objc_setAssociatedObject(self, @selector(fw_isCollapsed), @(isCollapsed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_autoCollapse
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_autoCollapse:(BOOL)autoCollapse
{
    objc_setAssociatedObject(self, @selector(fw_autoCollapse), @(autoCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_hiddenCollapse
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_hiddenCollapse:(BOOL)hiddenCollapse
{
    objc_setAssociatedObject(self, @selector(fw_hiddenCollapse), @(hiddenCollapse), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_addCollapseConstraint:(NSLayoutConstraint *)constraint
{
    constraint.fw_originalOffset = constraint.fw_offset;
    if (![self.fw_innerCollapseConstraints containsObject:constraint]) {
        [self.fw_innerCollapseConstraints addObject:constraint];
    }
}

- (NSMutableArray *)fw_innerCollapseConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

#pragma mark - Inactive

- (BOOL)fw_isInactive
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setFw_isInactive:(BOOL)isInactive
{
    NSArray *inactiveConstraints = [self.fw_innerInactiveConstraints sortedArrayUsingComparator:^NSComparisonResult(NSLayoutConstraint *obj1, NSLayoutConstraint *obj2) {
        BOOL active1 = isInactive ? !obj1.fw_originalActive : obj1.fw_originalActive;
        return !active1 ? NSOrderedAscending : NSOrderedDescending;
    }];
    [inactiveConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        constraint.active = isInactive ? !constraint.fw_originalActive : constraint.fw_originalActive;
    }];
    
    objc_setAssociatedObject(self, @selector(fw_isInactive), @(isInactive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fw_addInactiveConstraint:(NSLayoutConstraint *)constraint
{
    constraint.fw_originalActive = constraint.isActive;
    if (![self.fw_innerInactiveConstraints containsObject:constraint]) {
        [self.fw_innerInactiveConstraints addObject:constraint];
    }
}

- (NSMutableArray *)fw_innerInactiveConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

#pragma mark - Axis

- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSuperview
{
    return [self fw_alignCenterToSuperviewWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSuperviewWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_alignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self fw_alignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset.y]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSLayoutConstraint *)fw_alignAxisToSuperview:(NSLayoutAttribute)axis
{
    return [self fw_alignAxisToSuperview:axis withOffset:0.0];
}

- (NSLayoutConstraint *)fw_alignAxisToSuperview:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    return [self fw_constrainAttribute:axis toSuperview:self.superview withOffset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_alignAxis:(NSLayoutAttribute)axis toView:(id)otherView
{
    return [self fw_alignAxis:axis toView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fw_alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fw_constrainAttribute:axis toAttribute:axis ofView:otherView withOffset:offset];
}

- (NSLayoutConstraint *)fw_alignAxis:(NSLayoutAttribute)axis toView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fw_constrainAttribute:axis toAttribute:axis ofView:otherView withMultiplier:multiplier];
}

#pragma mark - Edge

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview
{
    return [self fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:insets.right]];
    }
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSuperview
{
    return [self fw_pinHorizontalToSuperviewWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSuperviewWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset]];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:inset]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSuperview
{
    return [self fw_pinVerticalToSuperviewWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSuperviewWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:inset]];
    [constraints addObject:[self fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge
{
    return [self fw_pinEdgeToSuperview:edge withInset:0.0];
}

- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self fw_pinEdgeToSuperview:edge withInset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:edge toSuperview:self.superview withOffset:inset relation:relation priority:priority];
}

- (NSLayoutConstraint *)fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView
{
    return [self fw_pinEdge:edge toEdge:toEdge ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fw_pinEdge:edge toEdge:toEdge ofView:otherView withOffset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:edge toAttribute:toEdge ofView:otherView withOffset:offset relation:relation priority:priority];
}

#pragma mark - SafeArea

- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSafeArea
{
    return [self fw_alignCenterToSafeAreaWithOffset:CGPointZero];
}

- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSafeAreaWithOffset:(CGPoint)offset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_alignAxisToSafeArea:NSLayoutAttributeCenterX withOffset:offset.x]];
    [constraints addObject:[self fw_alignAxisToSafeArea:NSLayoutAttributeCenterY withOffset:offset.y]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSLayoutConstraint *)fw_alignAxisToSafeArea:(NSLayoutAttribute)axis
{
    return [self fw_alignAxisToSafeArea:axis withOffset:0.0];
}

- (NSLayoutConstraint *)fw_alignAxisToSafeArea:(NSLayoutAttribute)axis withOffset:(CGFloat)offset
{
    return [self fw_constrainAttribute:axis toSuperview:self.superview.safeAreaLayoutGuide withOffset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSafeArea
{
    return [self fw_pinEdgesToSafeAreaWithInsets:UIEdgeInsetsZero];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSafeAreaWithInsets:(UIEdgeInsets)insets
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSafeAreaWithInsets:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    if (edge != NSLayoutAttributeTop) {
        [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:insets.top]];
    }
    if (edge != NSLayoutAttributeLeading && edge != NSLayoutAttributeLeft) {
        [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeLeft withInset:insets.left]];
    }
    if (edge != NSLayoutAttributeBottom) {
        [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeBottom withInset:insets.bottom]];
    }
    if (edge != NSLayoutAttributeTrailing && edge != NSLayoutAttributeRight) {
        [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeRight withInset:insets.right]];
    }
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSafeArea
{
    return [self fw_pinHorizontalToSafeAreaWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSafeAreaWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeLeft withInset:inset]];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeRight withInset:inset]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSafeArea
{
    return [self fw_pinVerticalToSafeAreaWithInset:0.0];
}

- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSafeAreaWithInset:(CGFloat)inset
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:inset]];
    [constraints addObject:[self fw_pinEdgeToSafeArea:NSLayoutAttributeBottom withInset:inset]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSLayoutConstraint *)fw_pinEdgeToSafeArea:(NSLayoutAttribute)edge
{
    return [self fw_pinEdgeToSafeArea:edge withInset:0.0];
}

- (NSLayoutConstraint *)fw_pinEdgeToSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset
{
    return [self fw_pinEdgeToSafeArea:edge withInset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_pinEdgeToSafeArea:(NSLayoutAttribute)edge withInset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:edge toSuperview:self.superview.safeAreaLayoutGuide withOffset:inset relation:relation priority:priority];
}

#pragma mark - Dimension

- (NSArray<NSLayoutConstraint *> *)fw_setDimensionsToSize:(CGSize)size
{
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    [constraints addObject:[self fw_setDimension:NSLayoutAttributeWidth toSize:size.width]];
    [constraints addObject:[self fw_setDimension:NSLayoutAttributeHeight toSize:size.height]];
    [self.fw_innerLastConstraints setArray:constraints];
    return constraints;
}

- (NSLayoutConstraint *)fw_setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size
{
    return [self fw_setDimension:dimension toSize:size relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_setDimension:(NSLayoutAttribute)dimension toSize:(CGFloat)size relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:dimension toAttribute:NSLayoutAttributeNotAnAttribute ofView:nil withMultiplier:0.0 offset:size relation:relation priority:priority isOpposite:NO];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier
{
    return [self fw_matchDimension:dimension toDimension:toDimension withMultiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_matchDimension:dimension toDimension:toDimension ofView:self withMultiplier:multiplier relation:relation priority:priority];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView
{
    return [self fw_matchDimension:dimension toDimension:toDimension ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fw_matchDimension:dimension toDimension:toDimension ofView:otherView withOffset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:dimension toAttribute:toDimension ofView:otherView withOffset:offset relation:relation priority:priority];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fw_matchDimension:dimension toDimension:toDimension ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:dimension toAttribute:toDimension ofView:otherView withMultiplier:multiplier relation:relation priority:priority];
}

#pragma mark - Constrain

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView
{
    return [self fw_constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:0.0];
}

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset
{
    return [self fw_constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withOffset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:1.0 offset:offset relation:relation priority:priority isOpposite:NO];
}

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fw_constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
}

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    return [self fw_constrainAttribute:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier offset:0.0 relation:relation priority:priority isOpposite:NO];
}

#pragma mark - Constraint

- (NSLayoutConstraint *)fw_constraintToSuperview:(NSLayoutAttribute)attribute
{
    return [self fw_constraintToSuperview:attribute relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fw_constraintToSuperview:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation
{
    return [self fw_constraint:attribute toSuperview:self.superview relation:relation];
}

- (NSLayoutConstraint *)fw_constraintToSafeArea:(NSLayoutAttribute)attribute
{
    return [self fw_constraintToSafeArea:attribute relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fw_constraintToSafeArea:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation
{
    return [self fw_constraint:attribute toSuperview:self.superview.safeAreaLayoutGuide relation:relation];
}

- (NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toSuperview:(id)superview relation:(NSLayoutRelation)relation
{
    NSAssert(self.superview, @"View's superview must not be nil.\nView: %@", self);
    if (attribute == NSLayoutAttributeBottom || attribute == NSLayoutAttributeRight || attribute == NSLayoutAttributeTrailing) {
        if (relation == NSLayoutRelationLessThanOrEqual) {
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else if (relation == NSLayoutRelationGreaterThanOrEqual) {
            relation = NSLayoutRelationLessThanOrEqual;
        }
    }
    return [self fw_constraint:attribute toAttribute:attribute ofView:superview withMultiplier:1.0 relation:relation];
}

- (NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView
{
    return [self fw_constraint:attribute toAttribute:toAttribute ofView:otherView relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView relation:(NSLayoutRelation)relation
{
    return [self fw_constraint:attribute toAttribute:toAttribute ofView:otherView withMultiplier:1.0 relation:relation];
}

- (NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier
{
    return [self fw_constraint:attribute toAttribute:toAttribute ofView:otherView withMultiplier:multiplier relation:NSLayoutRelationEqual];
}

- (NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation
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
    
    // 自动生成唯一约束标记，存在则获取之
    NSString *layoutIdentifier = [NSString stringWithFormat:@"%ld-%ld-%lu-%ld-%@", (long)attribute, (long)relation, (unsigned long)[otherView hash], (long)toAttribute, @(multiplier)];
    return [self fw_constraintWithIdentifier:layoutIdentifier];
}

- (NSLayoutConstraint *)fw_constraintWithIdentifier:(NSString *)identifier
{
    if (identifier.length < 1) return nil;
    __block NSLayoutConstraint *constraint = nil;
    [self.fw_innerLayoutConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
        if ((obj.identifier && [identifier isEqualToString:obj.identifier]) ||
            (obj.fw_layoutIdentifier && [identifier isEqualToString:obj.fw_layoutIdentifier])) {
            constraint = obj;
            *stop = YES;
        }
    }];
    return constraint;
}

- (NSArray<NSLayoutConstraint *> *)fw_lastConstraints
{
    return self.fw_innerLastConstraints.copy;
}

- (void)setFw_lastConstraints:(NSArray<NSLayoutConstraint *> *)constraints
{
    [self.fw_innerLastConstraints setArray:constraints];
}

- (NSArray<NSLayoutConstraint *> *)fw_allConstraints
{
    return self.fw_innerLayoutConstraints.copy;
}

- (void)fw_removeConstraints:(NSArray<NSLayoutConstraint *> *)constraints
{
    if (constraints.count < 1) return;
    [NSLayoutConstraint deactivateConstraints:constraints];
    [self.fw_innerLayoutConstraints removeObjectsInArray:constraints];
    [self.fw_innerLastConstraints removeObjectsInArray:constraints];
}

#pragma mark - Private

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toSuperview:(id)superview withOffset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority
{
    NSAssert(self.superview, @"View's superview must not be nil.\nView: %@", self);
    BOOL isOpposite = NO;
    if (attribute == NSLayoutAttributeBottom || attribute == NSLayoutAttributeRight || attribute == NSLayoutAttributeTrailing) {
        isOpposite = YES;
        if (relation == NSLayoutRelationLessThanOrEqual) {
            relation = NSLayoutRelationGreaterThanOrEqual;
        } else if (relation == NSLayoutRelationGreaterThanOrEqual) {
            relation = NSLayoutRelationLessThanOrEqual;
        }
    }
    NSLayoutConstraint *layoutConstraint = [self fw_constrainAttribute:attribute toAttribute:attribute ofView:superview withMultiplier:1.0 offset:offset relation:relation priority:priority isOpposite:isOpposite];
    return layoutConstraint;
}

- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(id)otherView withMultiplier:(CGFloat)multiplier offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority isOpposite:(BOOL)isOpposite
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
    // 自动生成唯一约束标记，存在则更新，否则添加
    NSString *layoutIdentifier = [NSString stringWithFormat:@"%ld-%ld-%lu-%ld-%@", (long)attribute, (long)relation, (unsigned long)[otherView hash], (long)toAttribute, @(multiplier)];
    NSLayoutConstraint *constraint = [self fw_constraintWithIdentifier:layoutIdentifier];
    if (!constraint) {
        constraint = [NSLayoutConstraint constraintWithItem:self attribute:attribute relatedBy:relation toItem:otherView attribute:toAttribute multiplier:multiplier constant:offset];
        constraint.fw_isOpposite = isOpposite;
        constraint.fw_layoutIdentifier = layoutIdentifier;
        constraint.identifier = layoutIdentifier;
        [self.fw_innerLayoutConstraints addObject:constraint];
    }
    [self.fw_innerLastConstraints setArray:[NSArray arrayWithObjects:constraint, nil]];
    constraint.fw_offset = offset;
    if (constraint.priority != priority) constraint.fw_priority = priority;
    if (!constraint.isActive) constraint.active = YES;
    return constraint;
}

- (NSMutableArray<NSLayoutConstraint *> *)fw_innerLayoutConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

- (NSMutableArray<NSLayoutConstraint *> *)fw_innerLastConstraints
{
    NSMutableArray *constraints = objc_getAssociatedObject(self, _cmd);
    if (!constraints) {
        constraints = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
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
        [self.view fw_removeConstraints:self.view.fw_allConstraints];
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))autoScale
{
    return ^id(BOOL autoScale) {
        self.view.fw_autoScale = autoScale;
        return self;
    };
}

#pragma mark - Compression

- (FWLayoutChain * (^)(UILayoutPriority))compressionHorizontal
{
    return ^id(UILayoutPriority priority) {
        self.view.fw_compressionHorizontal = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))compressionVertical
{
    return ^id(UILayoutPriority priority) {
        self.view.fw_compressionVertical = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))huggingHorizontal
{
    return ^id(UILayoutPriority priority) {
        self.view.fw_huggingHorizontal = priority;
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))huggingVertical
{
    return ^id(UILayoutPriority priority) {
        self.view.fw_huggingVertical = priority;
        return self;
    };
}

#pragma mark - Collapse

- (FWLayoutChain * (^)(BOOL))isCollapsed
{
    return ^id(BOOL isCollapsed) {
        self.view.fw_isCollapsed = isCollapsed;
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))autoCollapse
{
    return ^id(BOOL autoCollapse) {
        self.view.fw_autoCollapse = autoCollapse;
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))hiddenCollapse
{
    return ^id(BOOL hiddenCollapse) {
        self.view.fw_hiddenCollapse = hiddenCollapse;
        return self;
    };
}

#pragma mark - Inactive

- (FWLayoutChain * (^)(BOOL))isInactive
{
    return ^id(BOOL isInactive) {
        self.view.fw_isInactive = isInactive;
        return self;
    };
}

#pragma mark - Axis

- (FWLayoutChain * (^)(void))center
{
    return ^id(void) {
        [self.view fw_alignCenterToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerX
{
    return ^id(void) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterX];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerY
{
    return ^id(void) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterY];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fw_alignCenterToSuperviewWithOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerToView
{
    return ^id(id view) {
        NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
        NSLayoutConstraint *constraint = [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view];
        if (constraint) [constraints addObject:constraint];
        constraint = [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view];
        if (constraint) [constraints addObject:constraint];
        self.view.fw_lastConstraints = constraints;
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerXToView
{
    return ^id(id view) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerYToView
{
    return ^id(id view) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Edge

- (FWLayoutChain * (^)(void))edges
{
    return ^id(void) {
        [self.view fw_pinEdgesToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fw_pinEdgesToSuperviewWithInsets:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fw_pinEdgesToSuperviewWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))horizontal
{
    return ^id(void) {
        [self.view fw_pinHorizontalToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(void))vertical
{
    return ^id(void) {
        [self.view fw_pinVerticalToSuperview];
        return self;
    };
}

- (FWLayoutChain * (^)(void))top
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeTop];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottom
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeBottom];
        return self;
    };
}

- (FWLayoutChain * (^)(void))left
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeLeft];
        return self;
    };
}

- (FWLayoutChain * (^)(void))right
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeRight];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))horizontalToView
{
    return ^id(id view) {
        NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
        NSLayoutConstraint *constraint = [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view];
        if (constraint) [constraints addObject:constraint];
        constraint = [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view];
        if (constraint) [constraints addObject:constraint];
        self.view.fw_lastConstraints = constraints;
        return self;
    };
}

- (FWLayoutChain * (^)(id))verticalToView
{
    return ^id(id view) {
        NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
        NSLayoutConstraint *constraint = [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view];
        if (constraint) [constraints addObject:constraint];
        constraint = [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view];
        if (constraint) [constraints addObject:constraint];
        self.view.fw_lastConstraints = constraints;
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToViewBottom
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToViewTop
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToViewRight
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToViewLeft
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToViewBottomWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToViewTopWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToViewRightWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToViewLeftWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view withOffset:offset];
        return self;
    };
}

#pragma mark - SafeArea

- (FWLayoutChain * (^)(void))centerToSafeArea
{
    return ^id(void) {
        [self.view fw_alignCenterToSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerXToSafeArea
{
    return ^id(void) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterX];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerYToSafeArea
{
    return ^id(void) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterY];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerToSafeAreaWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fw_alignCenterToSafeAreaWithOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterX withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterY withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgesToSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesToSafeAreaWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fw_pinEdgesToSafeAreaWithInsets:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesToSafeAreaWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fw_pinEdgesToSafeAreaWithInsets:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))horizontalToSafeArea
{
    return ^id(void) {
        [self.view fw_pinHorizontalToSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(void))verticalToSafeArea
{
    return ^id(void) {
        [self.view fw_pinVerticalToSafeArea];
        return self;
    };
}

- (FWLayoutChain * (^)(void))topToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeTop];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottomToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeBottom];
        return self;
    };
}

- (FWLayoutChain * (^)(void))leftToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeLeft];
        return self;
    };
}

- (FWLayoutChain * (^)(void))rightToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeRight];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeTop withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeBottom withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeLeft withInset:inset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeRight withInset:inset];
        return self;
    };
}

#pragma mark - Dimension

- (FWLayoutChain * (^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fw_setDimensionsToSize:size];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fw_setDimension:NSLayoutAttributeWidth toSize:width];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fw_setDimension:NSLayoutAttributeHeight toSize:height];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))widthToHeight
{
    return ^id(CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeHeight withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))heightToWidth
{
    return ^id(CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeWidth withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id))sizeToView
{
    return ^id(id view) {
        NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
        NSLayoutConstraint *constraint = [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        if (constraint) [constraints addObject:constraint];
        constraint = [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        if (constraint) [constraints addObject:constraint];
        self.view.fw_lastConstraints = constraints;
        return self;
    };
}

- (FWLayoutChain * (^)(id))widthToView
{
    return ^id(id view) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id))heightToView
{
    return ^id(id view) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withMultiplier:multiplier];
        return self;
    };
}

#pragma mark - Attribute

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation, UILayoutPriority))attributeWithOffsetAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation, UILayoutPriority priority) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset relation:relation priority:priority];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation, UILayoutPriority))attributeWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation, UILayoutPriority priority) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation priority:priority];
        return self;
    };
}

#pragma mark - Constraint

- (FWLayoutChain * (^)(CGFloat))offset
{
    return ^id(CGFloat offset) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.fw_offset = offset;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))constant
{
    return ^id(CGFloat constant) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.constant = constant;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(UILayoutPriority))priority
{
    return ^id(UILayoutPriority priority) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.fw_priority = priority;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))collapse
{
    return ^id(CGFloat offset) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            [self.view fw_addCollapseConstraint:obj];
            obj.fw_collapseOffset = offset;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))original
{
    return ^id(CGFloat offset) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.fw_originalOffset = offset;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))toggle
{
    return ^id(BOOL active) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.active = active;
            [self.view fw_addInactiveConstraint:obj];
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(NSString *))identifier
{
    return ^id(NSString *identifier) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.identifier = identifier;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(BOOL))active
{
    return ^id(BOOL active) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.active = active;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(void))remove
{
    return ^id(void) {
        [self.view fw_removeConstraints:self.view.fw_lastConstraints];
        return self;
    };
}

- (NSArray<NSLayoutConstraint *> *)constraints
{
    return self.view.fw_lastConstraints;
}

- (NSLayoutConstraint *)constraint
{
    return self.view.fw_lastConstraints.lastObject;
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute))constraintToSuperview
{
    return ^id(NSLayoutAttribute attribute) {
        return [self.view fw_constraintToSuperview:attribute];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutRelation))constraintToSuperviewWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutRelation relation) {
        return [self.view fw_constraintToSuperview:attribute relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute))constraintToSafeArea
{
    return ^id(NSLayoutAttribute attribute) {
        return [self.view fw_constraintToSafeArea:attribute];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutRelation))constraintToSafeAreaWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutRelation relation) {
        return [self.view fw_constraintToSafeArea:attribute relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id))constraintToView
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, NSLayoutRelation))constraintToViewWithRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, NSLayoutRelation relation) {
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))constraintToViewWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))constraintToViewWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
    };
}

- (NSLayoutConstraint * (^)(NSString *))constraintWithIdentifier
{
    return ^id(NSString *identifier) {
        return [self.view fw_constraintWithIdentifier:identifier];
    };
}

@end

#pragma mark - UIView+FWLayoutChain

@implementation UIView (FWLayoutChain)

- (FWLayoutChain *)fw_layoutChain
{
    FWLayoutChain *layoutChain = objc_getAssociatedObject(self, _cmd);
    if (!layoutChain) {
        layoutChain = [[FWLayoutChain alloc] initWithView:self];
        objc_setAssociatedObject(self, _cmd, layoutChain, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return layoutChain;
}

- (void)fw_layoutMaker:(__attribute__((noescape)) void (^)(FWLayoutChain *))block
{
    if (block) {
        block(self.fw_layoutChain);
    }
}

@end
