//
//  FWAutoLayout.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAutoLayout.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

@property (nonatomic, assign) BOOL fw_autoScale;
@property (nonatomic, assign) UILayoutPriority fw_compressionHorizontal;
@property (nonatomic, assign) UILayoutPriority fw_compressionVertical;
@property (nonatomic, assign) UILayoutPriority fw_huggingHorizontal;
@property (nonatomic, assign) UILayoutPriority fw_huggingVertical;
@property (nonatomic, assign) BOOL fw_collapsed;
@property (nonatomic, assign) BOOL fw_autoCollapse;
@property (nonatomic, assign) BOOL fw_hiddenCollapse;
@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *fw_allConstraints;
@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *fw_lastConstraints;
- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;
- (void)fw_removeConstraints:(nullable NSArray<NSLayoutConstraint *> *)constraints;
- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSuperview:(CGPoint)offset;
- (NSLayoutConstraint *)fw_alignAxisToSuperview:(NSLayoutAttribute)axis offset:(CGFloat)offset;
- (NSLayoutConstraint *)fw_alignAxis:(NSLayoutAttribute)axis toView:(id)otherView offset:(CGFloat)offset;
- (NSLayoutConstraint *)fw_alignAxis:(NSLayoutAttribute)axis toView:(id)otherView multiplier:(CGFloat)multiplier;
- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;
- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSuperview:(CGFloat)inset;
- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSuperview:(CGFloat)inset;
- (NSLayoutConstraint *)fw_pinEdgeToSuperview:(NSLayoutAttribute)edge inset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(id)otherView offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSArray<NSLayoutConstraint *> *)fw_alignCenterToSafeArea:(CGPoint)offset;
- (NSLayoutConstraint *)fw_alignAxisToSafeArea:(NSLayoutAttribute)axis offset:(CGFloat)offset;
- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSafeArea:(UIEdgeInsets)insets;
- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSafeArea:(UIEdgeInsets)insets excludingEdge:(NSLayoutAttribute)edge;
- (NSArray<NSLayoutConstraint *> *)fw_pinHorizontalToSafeArea:(CGFloat)inset;
- (NSArray<NSLayoutConstraint *> *)fw_pinVerticalToSafeArea:(CGFloat)inset;
- (NSLayoutConstraint *)fw_pinEdgeToSafeArea:(NSLayoutAttribute)edge inset:(CGFloat)inset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSArray<NSLayoutConstraint *> *)fw_setDimensions:(CGSize)size;
- (NSLayoutConstraint *)fw_setDimension:(NSLayoutAttribute)dimension size:(CGFloat)size relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_matchDimension:(NSLayoutAttribute)dimension toDimension:(NSLayoutAttribute)toDimension ofView:(id)otherView multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView offset:(CGFloat)offset relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (NSLayoutConstraint *)fw_constrainAttribute:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation priority:(UILayoutPriority)priority;
- (nullable NSLayoutConstraint *)fw_constraintToSuperview:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;
- (nullable NSLayoutConstraint *)fw_constraintToSafeArea:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation;
- (nullable NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView relation:(NSLayoutRelation)relation;
- (nullable NSLayoutConstraint *)fw_constraint:(NSLayoutAttribute)attribute toAttribute:(NSLayoutAttribute)toAttribute ofView:(nullable id)otherView multiplier:(CGFloat)multiplier relation:(NSLayoutRelation)relation;
- (nullable NSLayoutConstraint *)fw_constraintWithIdentifier:(nullable NSString *)identifier;

@end

@interface NSLayoutConstraint ()

@property (nonatomic, assign) CGFloat fw_inset;
@property (nonatomic, assign) UILayoutPriority fw_priority;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

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

- (FWLayoutChain * (^)(BOOL))collapsed
{
    return ^id(BOOL collapsed) {
        self.view.fw_collapsed = collapsed;
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

#pragma mark - Axis

- (FWLayoutChain * (^)(void))center
{
    return ^id(void) {
        [self.view fw_alignCenterToSuperview:CGPointZero];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerX
{
    return ^id(void) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterX offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerY
{
    return ^id(void) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fw_alignCenterToSuperview:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterX offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSuperview:NSLayoutAttributeCenterY offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerToView
{
    return ^id(id view) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view offset:0];
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerXToView
{
    return ^id(id view) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(id))centerYToView
{
    return ^id(id view) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerXToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterX toView:view multiplier:multiplier];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))centerYToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_alignAxis:NSLayoutAttributeCenterY toView:view multiplier:multiplier];
        return self;
    };
}

#pragma mark - Edge

- (FWLayoutChain * (^)(void))edges
{
    return ^id(void) {
        [self.view fw_pinEdgesToSuperview:UIEdgeInsetsZero];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fw_pinEdgesToSuperview:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fw_pinEdgesToSuperview:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))horizontal
{
    return ^id(void) {
        [self.view fw_pinHorizontalToSuperview:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))vertical
{
    return ^id(void) {
        [self.view fw_pinVerticalToSuperview:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))top
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottom
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))left
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))right
{
    return ^id(void) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeTop inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeBottom inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeLeft inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSuperview:NSLayoutAttributeRight inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToView
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))topToViewBottom
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))bottomToViewTop
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))leftToViewRight
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))rightToViewLeft
{
    return ^id(id view) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeTop ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeBottom ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeLeft ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))topToViewBottomWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))bottomToViewTopWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))leftToViewRightWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))rightToViewLeftWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeLeft ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

#pragma mark - SafeArea

- (FWLayoutChain * (^)(void))centerToSafeArea
{
    return ^id(void) {
        [self.view fw_alignCenterToSafeArea:CGPointZero];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerXToSafeArea
{
    return ^id(void) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterX offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))centerYToSafeArea
{
    return ^id(void) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterY offset:0];
        return self;
    };
}

- (FWLayoutChain * (^)(CGPoint))centerToSafeAreaWithOffset
{
    return ^id(CGPoint offset) {
        [self.view fw_alignCenterToSafeArea:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerXToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterX offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))centerYToSafeAreaWithOffset
{
    return ^id(CGFloat offset) {
        [self.view fw_alignAxisToSafeArea:NSLayoutAttributeCenterY offset:offset];
        return self;
    };
}

- (FWLayoutChain * (^)(void))edgesToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgesToSafeArea:UIEdgeInsetsZero];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets))edgesToSafeAreaWithInsets
{
    return ^id(UIEdgeInsets insets) {
        [self.view fw_pinEdgesToSafeArea:insets];
        return self;
    };
}

- (FWLayoutChain * (^)(UIEdgeInsets, NSLayoutAttribute))edgesToSafeAreaWithInsetsExcludingEdge
{
    return ^id(UIEdgeInsets insets, NSLayoutAttribute edge) {
        [self.view fw_pinEdgesToSafeArea:insets excludingEdge:edge];
        return self;
    };
}

- (FWLayoutChain * (^)(void))horizontalToSafeArea
{
    return ^id(void) {
        [self.view fw_pinHorizontalToSafeArea:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))verticalToSafeArea
{
    return ^id(void) {
        [self.view fw_pinVerticalToSafeArea:0];
        return self;
    };
}

- (FWLayoutChain * (^)(void))topToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeTop inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))bottomToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeBottom inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))leftToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeLeft inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(void))rightToSafeArea
{
    return ^id(void) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeRight inset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))topToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeTop inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))bottomToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeBottom inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))leftToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeLeft inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))rightToSafeAreaWithInset
{
    return ^id(CGFloat inset) {
        [self.view fw_pinEdgeToSafeArea:NSLayoutAttributeRight inset:inset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

#pragma mark - Dimension

- (FWLayoutChain * (^)(CGSize))size
{
    return ^id(CGSize size) {
        [self.view fw_setDimensions:size];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))width
{
    return ^id(CGFloat width) {
        [self.view fw_setDimension:NSLayoutAttributeWidth size:width relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))height
{
    return ^id(CGFloat height) {
        [self.view fw_setDimension:NSLayoutAttributeHeight size:height relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))widthToHeight
{
    return ^id(CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeHeight multiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))heightToWidth
{
    return ^id(CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeWidth multiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))sizeToView
{
    return ^id(id view) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))widthToView
{
    return ^id(id view) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id))heightToView
{
    return ^id(id view) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithOffset
{
    return ^id(id view, CGFloat offset) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))widthToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view multiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(id, CGFloat))heightToViewWithMultiplier
{
    return ^id(id view, CGFloat multiplier) {
        [self.view fw_matchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view multiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

#pragma mark - Attribute

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView offset:0 relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView offset:offset relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation, UILayoutPriority))attributeWithOffsetAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation, UILayoutPriority priority) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView offset:offset relation:relation priority:priority];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView multiplier:multiplier relation:NSLayoutRelationEqual priority:UILayoutPriorityRequired];
        return self;
    };
}

- (FWLayoutChain * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation, UILayoutPriority))attributeWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation, UILayoutPriority priority) {
        [self.view fw_constrainAttribute:attribute toAttribute:toAttribute ofView:ofView multiplier:multiplier relation:relation priority:priority];
        return self;
    };
}

#pragma mark - Constraint

- (FWLayoutChain * (^)(CGFloat))offset
{
    return ^id(CGFloat offset) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.constant = offset;
        }];
        return self;
    };
}

- (FWLayoutChain * (^)(CGFloat))inset
{
    return ^id(CGFloat inset) {
        [self.view.fw_lastConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL *stop) {
            obj.fw_inset = inset;
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
        return [self.view fw_constraintToSuperview:attribute relation:NSLayoutRelationEqual];
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
        return [self.view fw_constraintToSafeArea:attribute relation:NSLayoutRelationEqual];
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
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView relation:NSLayoutRelationEqual];
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
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView multiplier:multiplier relation:NSLayoutRelationEqual];
    };
}

- (NSLayoutConstraint * (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))constraintToViewWithMultiplierAndRelation
{
    return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
        return [self.view fw_constraint:attribute toAttribute:toAttribute ofView:ofView multiplier:multiplier relation:relation];
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
    if (block) block(self.fw_layoutChain);
}

@end
