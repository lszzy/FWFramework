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

#pragma mark - FWLayoutChainProtocol

/*!
 @brief 视图链式布局协议
 @discussion 如果约束条件完全相同，会自动更新约束而不是重新添加
 */
@protocol FWLayoutChainProtocol <NSObject>

@required

#pragma mark - Install

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^remake)(void);

#pragma mark - Compression

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^contentCompressionResistance)(UILayoutConstraintAxis axis, UILayoutPriority priority);

#pragma mark - Axis

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^center)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerX)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerY)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerXToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerYToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerXToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerYToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerXToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerYToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Edge

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edges)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesWithAxis)(UILayoutConstraintAxis axis);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^top)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottom)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^left)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^right)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToBottomOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToTopOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToRightOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToLeftOfView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToBottomOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToTopOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToRightOfViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToLeftOfViewWithOffset)(id view, CGFloat offset);

#pragma mark - SafeArea

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerXToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^centerYToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesToSafeAreaWithInsets)(UIEdgeInsets insets);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesToSafeAreaWithInsetsExcludingEdge)(UIEdgeInsets insets, NSLayoutAttribute edge);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^edgesToSafeAreaWithAxis)(UILayoutConstraintAxis axis);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToSafeArea)(void);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^topToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^bottomToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^leftToSafeAreaWithInset)(CGFloat inset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^rightToSafeAreaWithInset)(CGFloat inset);

#pragma mark - Dimension

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^size)(CGSize size);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^width)(CGFloat width);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^height)(CGFloat height);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^sizeToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^widthToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^heightToView)(id view);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^widthToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^heightToViewWithOffset)(id view, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^widthToViewWithMultiplier)(id view, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^heightToViewWithMultiplier)(id view, CGFloat multiplier);

#pragma mark - Attribute

@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^attribute)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^attributeWithOffset)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^attributeWithOffsetAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^attributeWithMultiplier)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier);
@property (nonatomic, copy, readonly) id<FWLayoutChainProtocol> (^attributeWithMultiplierAndRelation)(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation);

@end

#pragma mark - UIView+FWLayoutChain

/*!
 @brief 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

@property (nonatomic, strong, readonly) id<FWLayoutChainProtocol> fwLayoutChain NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
