/*!
 @header     UIView+FWLayoutChain.h
 @indexgroup FWFramework
 @brief      UIView+FWLayoutChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import <UIKit/UIKit.h>

#pragma mark - FWLayoutChain

/*!
 @brief 视图链式布局类
 */
@interface FWLayoutChain : NSObject

#pragma mark - Compression

@property (nonatomic, copy, readonly) FWLayoutChain *(^compressionHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain *(^compressionVertical)(UILayoutPriority priority);

#pragma mark - Axis

@property (nonatomic, copy, readonly) FWLayoutChain *(^centerToSuperview)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToSuperview)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToSuperview)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperview)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperview)(NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperviewWithInset)(NSLayoutAttribute edge, CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperviewWithInsetAndRelation)(NSLayoutAttribute edge, CGFloat inset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToView)(NSLayoutAttribute edge, NSLayoutAttribute toEdge, UIView *view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToViewWithOffset)(NSLayoutAttribute edge, NSLayoutAttribute toEdge, UIView *view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToViewWithOffsetAndRelation)(NSLayoutAttribute edge, NSLayoutAttribute toEdge, UIView *view, CGFloat offset, NSLayoutRelation relation);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) FWLayoutChain *(^centerToSuperviewSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToSuperviewSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToSuperviewSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewSafeAreaHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSuperviewSafeAreaVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperviewSafeArea)(NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperviewSafeAreaWithInset)(NSLayoutAttribute edge, CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgeToSuperviewSafeAreaWithInsetAndRelation)(NSLayoutAttribute edge, CGFloat inset, NSLayoutRelation relation);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) FWLayoutChain *(^dimensionToView)(NSLayoutAttribute dimension, NSLayoutAttribute toDimension, UIView *view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^dimensionToViewWithOffset)(NSLayoutAttribute dimension, NSLayoutAttribute toDimension, UIView *view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^dimensionToViewWithOffsetAndRelation)(NSLayoutAttribute dimension, NSLayoutAttribute toDimension, UIView *view, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain *(^dimensionToViewWithMultiplier)(NSLayoutAttribute dimension, NSLayoutAttribute toDimension, UIView *view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^dimensionToViewWithMultiplierAndRelation)(NSLayoutAttribute dimension, NSLayoutAttribute toDimension, UIView *view, CGFloat multiplier, NSLayoutRelation relation);

@property (nonatomic, copy, readonly) FWLayoutChain *(^size)(CGSize size);
@property (nonatomic, copy, readonly) FWLayoutChain *(^width)(CGFloat width);
@property (nonatomic, copy, readonly) FWLayoutChain *(^height)(CGFloat height);
@property (nonatomic, copy, readonly) FWLayoutChain *(^widthWithRelation)(CGFloat width, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain *(^heightWithRelation)(CGFloat height, NSLayoutRelation relation);

#pragma mark - Constrain

@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeToView)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, UIView *view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeToViewWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, UIView *view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeToViewWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, UIView *view, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeToViewWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, UIView *view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeToViewWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, UIView *view, CGFloat multiplier, NSLayoutRelation relation);

@end

#pragma mark - UIView+FWLayoutChain

/*!
 @brief 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

@property (nonatomic, strong, readonly) FWLayoutChain *fwLayoutChain;

@end
