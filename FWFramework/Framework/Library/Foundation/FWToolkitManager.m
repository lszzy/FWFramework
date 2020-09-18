/*!
 @header     FWToolkitManager.m
 @indexgroup FWFramework
 @brief      FWToolkitManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/18
 */

#import "FWToolkitManager.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>

#pragma mark - NSDate+FWToolkit

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWToolkit)

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

+ (void)setFwCurrentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fwSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

@end

#pragma mark - NSNull+FWToolkit

@implementation NSNull (FWToolkit)

+ (void)load
{
#ifndef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(NSNull, @selector(methodSignatureForSelector:), FWSwizzleReturn(NSMethodSignature *), FWSwizzleArgs(SEL selector), FWSwizzleCode({
            NSMethodSignature *signature = FWSwizzleOriginal(selector);
            if (!signature) {
                return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
            }
            return signature;
        }));
        FWSwizzleClass(NSNull, @selector(forwardInvocation:), FWSwizzleReturn(void), FWSwizzleArgs(NSInvocation *invocation), FWSwizzleCode({
            invocation.target = nil;
            [invocation invoke];
        }));
    });
#endif
}

@end

#pragma mark - NSObject+FWToolkit

@implementation NSObject (FWToolkit)

@dynamic fwTempObject;

- (id)fwTempObject
{
    return objc_getAssociatedObject(self, @selector(fwTempObject));
}

- (void)setFwTempObject:(id)fwTempObject
{
    if (fwTempObject != self.fwTempObject) {
        [self willChangeValueForKey:@"fwTempObject"];
        objc_setAssociatedObject(self, @selector(fwTempObject), fwTempObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwTempObject"];
    }
}

#pragma mark - Lock

- (void)fwLockCreate
{
    [self fwLockSemaphore];
}

- (void)fwLock
{
    dispatch_semaphore_wait([self fwLockSemaphore], DISPATCH_TIME_FOREVER);
}

- (void)fwUnlock
{
    dispatch_semaphore_signal([self fwLockSemaphore]);
}

- (dispatch_semaphore_t)fwLockSemaphore
{
    dispatch_semaphore_t semaphore = objc_getAssociatedObject(self, _cmd);
    if (!semaphore) {
        @synchronized (self) {
            semaphore = objc_getAssociatedObject(self, _cmd);
            if (!semaphore) {
                semaphore = dispatch_semaphore_create(1);
                objc_setAssociatedObject(self, _cmd, semaphore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return semaphore;
}

@end

#pragma mark - NSString+FWToolkit

@implementation NSString (FWToolkit)

- (NSString *)fwTrimString
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - Size

- (CGSize)fwSizeWithFont:(UIFont *)font
{
    return [self fwSizeWithFont:font drawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize
{
    return [self fwSizeWithFont:font drawSize:drawSize paragraphStyle:nil];
}

- (CGSize)fwSizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize paragraphStyle:(NSParagraphStyle *)paragraphStyle
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = font;
    if (paragraphStyle != nil) {
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    CGSize size = [self boundingRectWithSize:drawSize
                                     options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attr
                                     context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end
