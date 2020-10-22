/*!
 @header     NSTimer+FWFramework.h
 @indexgroup FWFramework
 @brief      NSTimer分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-11
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSTimer分类
 */
@interface NSTimer (FWFramework)

/*!
 @brief 暂停NSTimer
 */
- (void)fwPauseTimer;

/*!
 @brief 开始NSTimer
 */
- (void)fwResumeTimer;

/*!
 @brief 延迟几秒后开始NSTimer
 
 @param delay 延迟秒数
 */
- (void)fwResumeTimerAfterDelay:(NSTimeInterval)delay;

@end

NS_ASSUME_NONNULL_END
