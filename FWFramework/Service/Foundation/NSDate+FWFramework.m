/*!
 @header     NSDate+FWFramework.m
 @indexgroup FWFramework
 @brief      NSDate+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import "NSDate+FWFramework.h"
#import <sys/sysctl.h>

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWFramework)

#pragma mark - Current

+ (void)fwSetCurrentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fwSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSTimeInterval)fwCurrentTime
{
    // 没有同步过返回本地时间
    if (fwStaticCurrentBaseTime == 0) {
        // 是否本地有服务器时间
        NSNumber *preCurrentTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWCurrentTime"];
        NSNumber *preLocalTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalTime"];
        if (preCurrentTime && preLocalTime) {
            // 计算当前服务器时间
            NSTimeInterval offsetTime = [[NSDate date] timeIntervalSince1970] - preLocalTime.doubleValue;
            return preCurrentTime.doubleValue + offsetTime;
        } else {
            return [[NSDate date] timeIntervalSince1970];
        }
    // 同步过计算当前服务器时间
    } else {
        NSTimeInterval offsetTime = [self fwSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

#pragma mark - System

+ (long long)fwSystemUptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    (void)time(&now);
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}

+ (NSDate *)fwSystemBoottime
{
    const int MIB_SIZE = 2;
    
    int mib[MIB_SIZE];
    size_t size;
    struct timeval boottime;
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_BOOTTIME;
    size = sizeof(boottime);
    
    if (sysctl(mib, MIB_SIZE, &boottime, &size, NULL, 0) != -1) {
        NSDate* bootDate = [NSDate dateWithTimeIntervalSince1970:boottime.tv_sec + boottime.tv_usec / 1.e6];
        return bootDate;
    }
    
    return nil;
}

#pragma mark - Benchmark

+ (NSMutableDictionary *)fwBenchmarkTimes
{
    static NSMutableDictionary *benchmarkTimes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        benchmarkTimes = [[NSMutableDictionary alloc] init];
    });
    return benchmarkTimes;
}

+ (void)fwBenchmarkBegin:(NSString *)name
{
    self.fwBenchmarkTimes[name] = [NSDate date];
}

+ (NSTimeInterval)fwBenchmarkEnd:(NSString *)name
{
    NSDate *beginTime = self.fwBenchmarkTimes[name] ?: [NSDate date];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970] - [beginTime timeIntervalSince1970];
    NSLog(@"FWBenchmark-%@: %.3fms", name, timeInterval * 1000);
    return timeInterval;
}

#pragma mark - Convert

+ (NSDate *)fwDateWithString:(NSString *)string
{
    return [self fwDateWithString:string format:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)fwDateWithString:(NSString *)string format:(NSString *)format
{
    return [self fwDateWithString:string format:format timeZone:nil];
}

+ (NSDate *)fwDateWithString:(NSString *)string format:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) {
        formatter.timeZone = timeZone;
    }
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+ (NSDate *)fwDateWithTimestamp:(NSTimeInterval)timestamp
{
    return [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
}

- (NSString *)fwStringValue
{
    return [self fwStringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)fwStringWithFormat:(NSString *)format
{
    return [self fwStringWithFormat:format timeZone:nil];
}

- (NSString *)fwStringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) {
        formatter.timeZone = timeZone;
    }
    NSString *string = [formatter stringFromDate:self];
    return string;
}

- (NSString *)fwStringSinceDate:(NSDate *)date
{
    double delta = fabs([self timeIntervalSinceDate:date]);
    if (delta < 10 * 60) {
        return @"刚刚";
    } else if (delta < 60 * 60) {
        int minutes = floor((double)delta / 60);
        return [NSString stringWithFormat:@"%d分钟前", minutes];
    } else if (delta < 24 * 3600) {
        int hours = floor((double)delta / 3600);
        return [NSString stringWithFormat:@"%d小时前", hours];
    } else if (delta < 7 * 86400) {
        int days = floor((double)delta / 86400);
        return [NSString stringWithFormat:@"%d天前", days];
    } else if (delta < 365 * 86400) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd"];
        return [dateFormatter stringFromDate:self];
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM"];
        return [dateFormatter stringFromDate:self];
    }
}

- (NSTimeInterval)fwTimestampValue
{
    return [self timeIntervalSince1970];
}

#pragma mark - TimeZone

- (NSDate *)fwDateWithLocalTimeZone
{
    return [self fwDateWithTimeZone:[NSTimeZone localTimeZone]];
}

- (NSDate *)fwDateWithUTCTimeZone
{
    return [self fwDateWithTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (NSDate *)fwDateWithTimeZone:(NSTimeZone *)timeZone
{
    NSInteger timeOffset = [timeZone secondsFromGMTForDate:self];
    NSDate *newDate = [self dateByAddingTimeInterval:timeOffset];
    return newDate;
}

#pragma mark - Calendar

- (NSInteger)fwCalendarUnit:(NSCalendarUnit)unit
{
    return [[NSCalendar currentCalendar] component:unit fromDate:self];
}

- (BOOL)fwIsLeapYear
{
    NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:self];
    if (year % 400 == 0) {
        return YES;
    } else if (year % 100 == 0) {
        return NO;
    } else if (year % 4 == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)fwIsSameDay:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:date];
    NSDate *dateOne = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    components = [[NSCalendar currentCalendar] components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:self];
    NSDate *dateTwo = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    return [dateOne isEqualToDate:dateTwo];
}

- (NSDate *)fwDateByAdding:(NSDateComponents *)components
{
    return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self options:0];
}

- (NSInteger)fwDaysFrom:(NSDate *)date
{
    NSDate *earliest = [self earlierDate:date];
    NSDate *latest = (earliest == self) ? date : self;
    NSInteger multipier = (earliest == self) ? -1 : 1;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:earliest toDate:latest options:0];
    return multipier * components.day;
}

- (double)fwSecondsFrom:(NSDate *)date
{
    return [self timeIntervalSinceDate:date];
}

#pragma mark - Format

+ (NSString *)fwFormatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour
{
    long long seconds = (long long)duration;
    if (hasHour) {
        long long minute = seconds / 60;
        long long hour   = minute / 60;
        
        seconds -= minute * 60;
        minute -= hour * 60;
        
        return [NSString stringWithFormat:@"%02d:%02d:%02d", (int)hour, (int)minute, (int)seconds];
    } else {
        long long minute = seconds / 60;
        long long second = seconds % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
    }
}

+ (NSTimeInterval)fwFormatTimestamp:(NSTimeInterval)timestamp
{
    NSString *timestampStr = [NSString stringWithFormat:@"%ld", (long)timestamp];
    if (timestampStr.length == 16) {
        return timestamp / 1000.f / 1000.f;
    } else if (timestampStr.length == 13) {
        return timestamp / 1000.f;
    } else {
        return timestamp;
    }
}

@end
