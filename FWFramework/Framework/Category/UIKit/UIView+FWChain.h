/*!
 @header     UIView+FWChain.h
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface FWViewChain : NSObject

#pragma mark - UIView

@property (nonatomic, copy, readonly) FWViewChain *(^userInteractionEnabled)(BOOL enabled);
@property (nonatomic, copy, readonly) FWViewChain *(^tag)(NSInteger tag);

@property (nonatomic, copy, readonly) FWViewChain *(^frame)(CGRect frame);
@property (nonatomic, copy, readonly) FWViewChain *(^bounds)(CGRect bounds);
@property (nonatomic, copy, readonly) FWViewChain *(^center)(CGPoint center);

@property (nonatomic, copy, readonly) FWViewChain *(^removeFromSuperview)(void);
@property (nonatomic, copy, readonly) FWViewChain *(^addSubview)(UIView *view);
@property (nonatomic, copy, readonly) FWViewChain *(^moveToSuperview)(UIView * _Nullable view);

@property (nonatomic, copy, readonly) FWViewChain *(^clipsToBounds)(BOOL clipsToBounds);
@property (nonatomic, copy, readonly) FWViewChain *(^backgroundColor)(UIColor * _Nullable backgroundColor);
@property (nonatomic, copy, readonly) FWViewChain *(^alpha)(CGFloat alpha);
@property (nonatomic, copy, readonly) FWViewChain *(^opaque)(BOOL opaque);
@property (nonatomic, copy, readonly) FWViewChain *(^hidden)(BOOL hidden);
@property (nonatomic, copy, readonly) FWViewChain *(^contentMode)(UIViewContentMode contentMode);
@property (nonatomic, copy, readonly) FWViewChain *(^tintColor)(UIColor * _Nullable tintColor);
@property (nonatomic, copy, readonly) FWViewChain *(^tintAdjustmentMode)(UIViewTintAdjustmentMode tintAdjustmentMode);

#pragma mark - UILabel

@property (nonatomic, copy, readonly) FWViewChain *(^text)(NSString *text);

@end

#pragma mark - UIView+FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface UIView (FWViewChain)

@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwNew)(void);
@property (class, nonatomic, strong, readonly) __kindof UIView *(^fwNewWithFrame)(CGRect frame);

@property (nonatomic, strong, readonly) FWViewChain *fwViewChain;

@end

NS_ASSUME_NONNULL_END
