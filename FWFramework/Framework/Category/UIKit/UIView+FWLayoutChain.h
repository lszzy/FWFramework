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

#pragma mark - Install

@property (nonatomic, copy, readonly) FWLayoutChain *(^remake)(void);

#pragma mark - Compression

@property (nonatomic, copy, readonly) FWLayoutChain *(^compressionHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) FWLayoutChain *(^compressionVertical)(UILayoutPriority priority);

#pragma mark - Axis

@property (nonatomic, copy, readonly) FWLayoutChain *(^center)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerX)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerY)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) FWLayoutChain *(^edges)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^top)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottom)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^left)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^right)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToBottomOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToTopOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToRightOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToLeftOfView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToBottomOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToTopOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToRightOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToLeftOfViewWithOffset)(id view, CGFloat offset);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) FWLayoutChain *(^centerToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerXToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^centerYToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSafeAreaHorizontal)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^edgesToSafeAreaVertical)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToSafeArea)(void);
@property (nonatomic, copy, readonly) FWLayoutChain *(^topToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^bottomToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^leftToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^rightToSafeAreaWithInset)(CGFloat inset);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) FWLayoutChain *(^size)(CGSize size);
@property (nonatomic, copy, readonly) FWLayoutChain *(^width)(CGFloat width);
@property (nonatomic, copy, readonly) FWLayoutChain *(^height)(CGFloat height);
@property (nonatomic, copy, readonly) FWLayoutChain *(^sizeToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^widthToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^heightToView)(id view);
@property (nonatomic, copy, readonly) FWLayoutChain *(^widthToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^heightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^widthToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^heightToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Attribute

@property (nonatomic, copy, readonly) FWLayoutChain *(^attribute)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) FWLayoutChain *(^attributeWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation);

@end

#pragma mark - UIView+FWLayoutChain

/*!
 @brief 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

@property (nonatomic, strong, readonly) FWLayoutChain *fwLayoutChain;

@end
