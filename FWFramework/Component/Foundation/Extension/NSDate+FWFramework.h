/*!
 @header     NSDate+FWFramework.h
 @indexgroup FWFramework
 @brief      NSDate+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 标记时间调试开始
#define FWBenchmarkBegin( x ) \
    [NSDate fwBenchmarkBegin:@(#x)];

// 标记时间调试结束并打印消耗时间
#define FWBenchmarkEnd( x ) \
    [NSDate fwBenchmarkEnd:@(#x)];

/*!
 @brief NSDate+FWFramework
 @discussion NSDate默认GMT时区；NSTimeZone默认系统时区(可设置应用默认时区)；NSDateFormatter默认当前时区(可自定义)，格式化时自动修正NSDate时区(无需手工修正NSDate)；NSLocale默认当前语言环境
 */
@interface NSDate (FWFramework)

#pragma mark - Current

// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

#pragma mark - System

// 系统运行时间
+ (long long)fwSystemUptime;

// 获取系统启动时间
+ (nullable NSDate *)fwSystemBoottime;

#pragma mark - Benchmark

// 标记时间调试开始
+ (void)fwBenchmarkBegin:(NSString *)name;

// 标记时间调试结束并打印消耗时间
+ (NSTimeInterval)fwBenchmarkEnd:(NSString *)name;

#pragma mark - Convert

/**
 *  从字符串初始化日期，默认当前时区
 *
 *  @param string 格式：yyyy-MM-dd HH:mm:ss
 *
 *  @return NSDate
 */
+ (nullable NSDate *)fwDateWithString:(NSString *)string;

/**
 *  从字符串初始化日期，默认当前时区
 *
 *  @param string 字符串
 *  @param format 自定义格式
 *
 *  @return NSDate
 */
+ (nullable NSDate *)fwDateWithString:(NSString *)string format:(nullable NSString *)format;

/**
 *  从字符串初始化日期，指定时区
 *
 *  @param string 字符串
 *  @param format 自定义格式
 *  @param timeZone 时区
 *
 *  @return NSDate
 */
+ (nullable NSDate *)fwDateWithString:(NSString *)string format:(nullable NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

/**
 *  从时间戳初始化日期
 *
 *  @param timestamp 时间戳
 *
 *  @return NSDate
 */
+ (NSDate *)fwDateWithTimestamp:(NSTimeInterval)timestamp;

/**
 *  转化为字符串，默认当前时区
 *
 *  @return 格式：yyyy-MM-dd HH:mm:ss
 */
- (NSString *)fwStringValue;

/**
 *  转化为字符串，默认当前时区
 *
 *  @param format 自定义格式
 *
 *  @return 字符串
 */
- (NSString *)fwStringWithFormat:(nullable NSString *)format;

/**
 *  转化为字符串，指定时区
 *
 *  @param format 自定义格式
 *  @param timeZone 时区
 *
 *  @return 字符串
 */
- (NSString *)fwStringWithFormat:(nullable NSString *)format timeZone:(nullable NSTimeZone *)timeZone;

/**
 *  计算两个时间差，并格式化为友好的时间字符串(类似微博)
 *  <10分钟：刚刚 <60分钟：n分钟前 <24小时：n小时前 <7天：n天前 <365天：n月/n日 >=365天：n年/n月
 *
 *  @return 字符串
 */
- (NSString *)fwStringSinceDate:(NSDate *)date;

/**
 *  转化为UTC时间戳
 *
 *  @return UTC时间戳
 */
- (NSTimeInterval)fwTimestampValue;

#pragma mark - TimeZone

// 转换为当前时区时间
- (NSDate *)fwDateWithLocalTimeZone;

// 转换为UTC时区时间
- (NSDate *)fwDateWithUTCTimeZone;

// 转换为指定时区时间
- (NSDate *)fwDateWithTimeZone:(nullable NSTimeZone *)timeZone;

#pragma mark - Calendar

// 获取日历单元值，如年、月、日等
- (NSInteger)fwCalendarUnit:(NSCalendarUnit)unit;

// 是否是闰年
- (BOOL)fwIsLeapYear;

// 是否是同一天
- (BOOL)fwIsSameDay:(NSDate *)date;

// 添加指定日期，如year:1|month:-1|day:1等
- (nullable NSDate *)fwDateByAdding:(NSDateComponents *)components;

// 与指定日期相隔天数
- (NSInteger)fwDaysFrom:(NSDate *)date;

// 与指定日期相隔秒数。分钟数/60，小时数/3600
- (double)fwSecondsFrom:(NSDate *)date;

#pragma mark - Format

// 格式化时长，格式"00:00"或"00:00:00"
+ (NSString *)fwFormatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour;

// 格式化16位、13位时间戳为秒
+ (NSTimeInterval)fwFormatTimestamp:(NSTimeInterval)timestamp;

@end

NS_ASSUME_NONNULL_END
