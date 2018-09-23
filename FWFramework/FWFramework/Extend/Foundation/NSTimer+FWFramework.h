/*!
 @header     NSTimer+FWFramework.h
 @indexgroup FWFramework
 @brief      NSTimer分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-11
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSTimer分类
 */
@interface NSTimer (FWFramework)

/*!
 @brief 创建NSTimer，使用target-action，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param target 目标
 @param selector 方法
 @param userInfo 参数
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;

/*!
 @brief 创建NSTimer，使用block，自动CommonModes添加到当前的运行循环中，避免ScrollView滚动时不触发
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/*!
 @brief 创建NSTimer，使用block，需要调用addTimer:forMode:安排到当前的运行循环中(CommonModes避免ScrollView滚动时不触发)。
 @discussion 示例：[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes]
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

/*!
 @brief 创建NSTimer，使用block，默认模式安排到当前的运行循环中
 
 @param seconds 时间
 @param block 代码块
 @param repeats 是否重复
 @return 定时器
 */
+ (NSTimer *)fwScheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

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
