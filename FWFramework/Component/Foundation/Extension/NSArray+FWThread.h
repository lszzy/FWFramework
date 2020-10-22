/*!
 @header     NSArray+FWThread.h
 @indexgroup FWFramework
 @brief      线程安全的可变数组
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/4
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 线程安全的可变数组，参考自YYKit
 
 @see https://github.com/ibireme/YYKit
 */
@interface FWMutableArray : NSMutableArray

@end

NS_ASSUME_NONNULL_END
