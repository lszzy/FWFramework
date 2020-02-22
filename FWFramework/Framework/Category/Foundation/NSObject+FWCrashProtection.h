/*!
 @header     NSObject+FWCrashProtection.h
 @indexgroup FWFramework
 @brief      NSObject+FWCrashProtection
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/22
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 常用方法崩溃保护，开启后仅正式环境生效，尽量开发阶段避免此问题
 */
@interface NSObject (FWCrashProtection)

// 启用常用方法崩溃保护，仅正式环境生效，尽量开发阶段避免此问题
+ (void)fwEnableCrashProtection;

@end

NS_ASSUME_NONNULL_END
