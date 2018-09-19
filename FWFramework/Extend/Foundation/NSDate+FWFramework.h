/*!
 @header     NSDate+FWFramework.h
 @indexgroup FWFramework
 @brief      NSDate+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <Foundation/Foundation.h>

// 标记时间调试开始
#define FWBenchmarkBegin( x ) \
    NSDate *fwBenchmarkBegin_##x = [NSDate date];

// 标记时间调试结束并打印消耗时间
#define FWBenchmarkEnd( x ) \
    NSDate *fwBenchmarkEnd_##x = [NSDate date]; \
    NSLog(@"FWBenchmark-%@: %.3fms", @(#x), [fwBenchmarkEnd_##x timeIntervalSince1970] * 1000 - [fwBenchmarkBegin_##x timeIntervalSince1970] * 1000);

/*!
 @brief NSDate+FWFramework
 */
@interface NSDate (FWFramework)

#pragma mark - Server

// 同步服务器基准时间戳
+ (void)fwSetServerTime:(NSTimeInterval)serverTime;

// 当前服务器时间戳，没有同步过返回本地时间
+ (NSTimeInterval)fwServerTime;

#pragma mark - System

// 系统运行时间
+ (long long)fwSystemUptime;

// 获取系统启动时间
+ (NSDate *)fwSystemBoottime;

#pragma mark - Convert

/**
 *  从字符串初始化日期
 *
 *  @param string 格式：yyyy-MM-dd HH:mm:ss
 *
 *  @return NSDate
 */
+ (NSDate *)fwDateWithString:(NSString *)string;

/**
 *  从字符串初始化日期
 *
 *  @param string 字符串
 *  @param format 自定义格式
 *
 *  @return NSDate
 */
+ (NSDate *)fwDateWithString:(NSString *)string format:(NSString *)format;

/**
 *  从时间戳初始化日期
 *
 *  @param timestamp 时间戳
 *
 *  @return NSDate
 */
+ (NSDate *)fwDateWithTimestamp:(NSTimeInterval)timestamp;

/**
 *  从当前时间间隔获取日期
 *
 *  @param interval 当前时间间隔
 *
 *  @return NSDate
 */
+ (NSDate *)fwDateWithInterval:(NSTimeInterval)interval;

/**
 *  转化为字符串
 *
 *  @return 格式：yyyy-MM-dd HH:mm:ss
 */
- (NSString *)fwStringValue;

/**
 *  转化为字符串
 *
 *  @param format 自定义格式
 *
 *  @return 字符串
 */
- (NSString *)fwStringWithFormat:(NSString *)format;

/**
 *  计算两个时间差，并格式化为友好的时间字符串(类似微博)
 *  <10分钟：刚刚 <60分钟：n分钟前 <24小时：n小时前 <7天：n天前 <365天：n月/n日 >=365天：n年/n月
 *
 *  @return 字符串
 */
- (NSString *)fwStringSinceDate:(NSDate *)date;

/**
 *  转化为时间戳
 *
 *  @return 时间戳
 */
- (NSTimeInterval)fwTimestampValue;

/**
 *  转换为当前时间间隔
 *
 *  @return 当前时间间隔
 */
- (NSTimeInterval)fwIntervalValue;

#pragma mark - TimeZone

// 转换为当前时区时间
- (NSDate *)fwDateWithLocalTimeZone;

// 转换为指定时区时间
- (NSDate *)fwDateWithTimeZone:(NSTimeZone *)timeZone;

#pragma mark - Calendar

// 获取日历单元值，如年、月、日等
- (NSInteger)fwCalendarUnit:(NSCalendarUnit)unit;

// 是否是闰年
- (BOOL)fwIsLeapYear;

// 是否是同一天
- (BOOL)fwIsSameDay:(NSDate *)date;

// 添加指定日期，如year:1|month:-1|day:1等
- (NSDate *)fwDateByAdding:(NSDateComponents *)components;

// 与指定日期相隔天数
- (NSInteger)fwDaysFrom:(NSDate *)date;

// 与指定日期相隔秒数。分钟数/60，小时数/3600
- (double)fwSecondsFrom:(NSDate *)date;

#pragma mark - Format

// 格式化时长，格式"00:00"或"00:00:00"
+ (NSString *)fwFormatDuration:(float)duration hasHour:(BOOL)hasHour;

@end
