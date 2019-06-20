/*!
 @header     UIView+FWChain.h
 @indexgroup FWFramework
 @brief      UIView+FWChain
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import <UIKit/UIKit.h>

#pragma mark - FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface FWViewChain : NSObject

// UIView
@property (nonatomic, copy, readonly) FWViewChain *(^frame)(CGRect frame);
@property (nonatomic, copy, readonly) FWViewChain *(^backgroundColor)(UIColor *backgroundColor);
@property (nonatomic, copy, readonly) FWViewChain *(^addSubview)(UIView *view);
@property (nonatomic, copy, readonly) FWViewChain *(^moveToSuperview)(UIView *view);

// UILabel
@property (nonatomic, copy, readonly) FWViewChain *(^text)(NSString *text);

@end

#pragma mark - UIView+FWViewChain

/*!
 @brief UIView链式调用协议，不支持的属性不会生效
 */
@interface UIView (FWViewChain)

@property (nonatomic, strong, readonly) FWViewChain *fwViewChain;

@end
