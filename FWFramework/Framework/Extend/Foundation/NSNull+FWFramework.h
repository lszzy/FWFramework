/*!
 @header     NSNull+FWFramework.h
 @indexgroup FWFramework
 @brief      NSNull分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

#ifdef DEBUG

/*! @brief 调试环境不处理崩溃，尽量开发阶段避免此问题 */
#define FWNullEnabled 0

#else

/*! @brief 正式环境处理崩溃 */
#define FWNullEnabled 1

#endif

#pragma mark - NSNull+FWFramework

/*!
 @brief NSNull分类，解决值为NSNull时调用不存在方法崩溃问题(如JSON中包含null)
 
 @see https://github.com/nicklockwood/NullSafe
 */
@interface NSNull (FWFramework)

@end
