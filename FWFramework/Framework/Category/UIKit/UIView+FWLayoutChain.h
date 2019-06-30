/*!
 @header     UIView+FWLayoutChain.h
 @indexgroup FWFramework
 @brief      UIView+FWLayoutChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWLayoutChain

/*!
 @brief 视图链式布局类
 @discussion 如果约束条件完全相同，会自动更新约束而不是重新添加
 */
@protocol FWLayoutChain <NSObject>

@required

#pragma mark - Install

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^remake)(void);

#pragma mark - Compression

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^compressionHorizontal)(UILayoutPriority priority);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^compressionVertical)(UILayoutPriority priority);

#pragma mark - Axis

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^center)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerX)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerY)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerXToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerYToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edges)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesHorizontal)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesVertical)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^top)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottom)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^left)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^right)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToBottomOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToTopOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToRightOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToLeftOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToBottomOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToTopOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToRightOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToLeftOfViewWithOffset)(id view, CGFloat offset);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerXToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^centerYToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesToSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesToSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesToSafeAreaHorizontal)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^edgesToSafeAreaVertical)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^topToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^bottomToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^leftToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^rightToSafeAreaWithInset)(CGFloat inset);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^size)(CGSize size);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^width)(CGFloat width);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^height)(CGFloat height);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^sizeToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^widthToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^heightToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^widthToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^heightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^widthToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^heightToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Attribute

@property (nonatomic, copy, readonly) id<FWLayoutChain> (^attribute)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^attributeWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^attributeWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^attributeWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChain> (^attributeWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation);

@end

#pragma mark - UIView+FWLayoutChain

/*!
 @brief 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

@property (nonatomic, strong, readonly) id<FWLayoutChain> fwLayoutChain NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
