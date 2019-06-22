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

@end

#pragma mark - UIView+FWLayoutChain

/*!
 @brief 视图链式布局分类
 */
@interface UIView (FWLayoutChain)

@property (nonatomic, strong, readonly) FWLayoutChain *fwLayoutChain;

@end
