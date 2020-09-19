/*!
 @header     NSTimer+FWFramework.m
 @indexgroup FWFramework
 @brief      NSTimer分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-11
 */

#import "NSTimer+FWFramework.h"
#import <objc/runtime.h>

@implementation CADisplayLink (FWFramework)

+ (CADisplayLink *)fwCommonDisplayLinkWithTarget:(id)target selector:(SEL)selector
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:target selector:selector];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fwCommonDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [self fwDisplayLinkWithBlock:block];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    return displayLink;
}

+ (CADisplayLink *)fwDisplayLinkWithBlock:(void (^)(CADisplayLink *))block
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fwInnerDisplayLinkBlock:)];
    objc_setAssociatedObject(displayLink, @selector(fwDisplayLinkWithBlock:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return displayLink;
}

+ (void)fwInnerDisplayLinkBlock:(CADisplayLink *)displayLink
{
    void (^block)(CADisplayLink *displayLink) = objc_getAssociatedObject(displayLink, @selector(fwDisplayLinkWithBlock:));
    if (block) {
        block(displayLink);
    }
}

@end

@implementation NSTimer (FWFramework)

+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:seconds target:target selector:selector userInfo:userInfo repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fwCommonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    NSTimer *timer = [NSTimer fwTimerWithTimeInterval:seconds block:block repeats:repeats];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}

+ (NSTimer *)fwCommonTimerWithCountDown:(NSInteger)seconds block:(void (^)(NSInteger))block
{
    __block NSInteger countdown = seconds;
    NSTimer *timer = [self fwCommonTimerWithTimeInterval:1 block:^(NSTimer *timer) {
        if (countdown <= 0) {
            block(0);
            [timer invalidate];
        } else {
            countdown--;
            // 时间+1，防止倒计时显示0秒
            block(countdown + 1);
        }
    } repeats:YES];
    
    // 立即触发定时器，默认等待1秒后才执行
    [timer fire];
    return timer;
}

+ (NSTimer *)fwScheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(fwInnerTimerBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)fwTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *))block repeats:(BOOL)repeats
{
    return [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(fwInnerTimerBlock:) userInfo:[block copy] repeats:repeats];
}

+ (void)fwInnerTimerBlock:(NSTimer *)timer
{
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

- (void)fwPauseTimer
{
    if (![self isValid]) {
        return;
    }
    
    [self setFireDate:[NSDate distantFuture]];
}

- (void)fwResumeTimer
{
    if (![self isValid]) {
        return;
    }
    
    [self setFireDate:[NSDate date]];
}

- (void)fwResumeTimerAfterDelay:(NSTimeInterval)delay
{
    if (![self isValid]) {
        return;
    }
    
    [self setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
}

@end
