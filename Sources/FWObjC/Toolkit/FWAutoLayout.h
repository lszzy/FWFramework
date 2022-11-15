//
//  FWAutoLayout.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWLayoutChain

/**
 视图链式布局类
 @note 如果约束条件完全相同，会自动更新约束而不是重新添加。
 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
 */
NS_SWIFT_UNAVAILABLE("")
@interface FWLayoutChain : NSObject

@property (nonatomic, weak, nullable, readonly) UIView *view;

- (instancetype)initWithView:(UIView *)view;

#pragma mark - Install

@property (nonatomic, copy, readonly) FWLayoutChain * (^remake)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^autoScale)(BOOL autoScale);

#pragma mark - Compression

@property (nonatomic, copy, readonly) FWLayoutChain * (^compressionHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^compressionVertical)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^huggingHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^huggingVertical)(UILayoutPriority priority);

#pragma mark - Collapse

@property (nonatomic, copy, readonly) FWLayoutChain * (^collapsed)(BOOL collapsed);
@property (nonatomic, copy, readonly) FWLayoutChain * (^autoCollapse)(BOOL autoCollapse);
@property (nonatomic, copy, readonly) FWLayoutChain * (^hiddenCollapse)(BOOL hiddenCollapse);

#pragma mark - Axis

@property (nonatomic, copy, readonly) FWLayoutChain * (^center)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerX)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerY)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerWithOffset)(CGPoint offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) FWLayoutChain * (^edges)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain * (^horizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^vertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^top)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottom)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^left)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^right)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewBottom)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewTop)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewRight)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewLeft)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToViewBottomWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToViewTopWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToViewRightWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToViewLeftWithOffset)(id view, CGFloat offset);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerToSafeAreaWithOffset)(CGPoint offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerXToSafeAreaWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^centerYToSafeAreaWithOffset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain * (^edgesToSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain * (^horizontalToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^verticalToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain * (^topToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^bottomToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^leftToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^rightToSafeAreaWithInset)(CGFloat inset);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) FWLayoutChain * (^size)(CGSize size);
@property (nonatomic, copy, readonly) FWLayoutChain * (^width)(CGFloat width);
@property (nonatomic, copy, readonly) FWLayoutChain * (^height)(CGFloat height);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToHeight)(CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToWidth)(CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^sizeToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^widthToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^heightToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Attribute

@property (nonatomic, copy, readonly) FWLayoutChain * (^attribute)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat offset, NSLayoutRelation relation, UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^attributeWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier, NSLayoutRelation relation, UILayoutPriority priority);

#pragma mark - Constraint

@property (nonatomic, copy, readonly) FWLayoutChain * (^offset)(CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^inset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain * (^priority)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain * (^identifier)(NSString * _Nullable identifier);
@property (nonatomic, copy, readonly) FWLayoutChain * (^active)(BOOL active);
@property (nonatomic, copy, readonly) FWLayoutChain * (^remove)(void);

@property (nonatomic, copy, readonly) NSArray<NSLayoutConstraint *> *constraints;
@property (nonatomic, nullable, readonly) NSLayoutConstraint *constraint;
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSuperview)(NSLayoutAttribute attribute);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSuperviewWithRelation)(NSLayoutAttribute attribute, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSafeArea)(NSLayoutAttribute attribute);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToSafeAreaWithRelation)(NSLayoutAttribute attribute, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToView)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintToViewWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id _Nullable ofView, CGFloat multiplier, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) NSLayoutConstraint * _Nullable (^constraintWithIdentifier)(NSString * _Nullable identifier);

@end

#pragma mark - UIView+FWLayoutChain

/**
 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

/// 链式布局对象
@property (nonatomic, strong, readonly) FWLayoutChain *fw_layoutChain NS_SWIFT_UNAVAILABLE("");

/// 链式布局句柄
- (void)fw_layoutMaker:(void (NS_NOESCAPE ^)(FWLayoutChain *make))block NS_SWIFT_UNAVAILABLE("");

@end

NS_ASSUME_NONNULL_END
