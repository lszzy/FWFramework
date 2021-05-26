/*!
 @header     FWMacro.m
 @indexgroup FWFramework
 @brief      核心宏定义
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-16
 */

#import "FWMacro.h"

@implementation FWBenchmark

+ (NSMutableDictionary *)benchmarkTimes
{
    static NSMutableDictionary *benchmarkTimes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        benchmarkTimes = [[NSMutableDictionary alloc] init];
    });
    return benchmarkTimes;
}

+ (void)benchmarkBegin:(NSString *)name
{
    self.benchmarkTimes[name] = [NSDate date];
}

+ (NSTimeInterval)benchmarkEnd:(NSString *)name
{
    NSDate *beginTime = self.benchmarkTimes[name] ?: [NSDate date];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] - [beginTime timeIntervalSince1970];
    NSLog(@"FWBenchmark-%@: %.3fms", name, timeInterval * 1000);
    return timeInterval;
}

@end
