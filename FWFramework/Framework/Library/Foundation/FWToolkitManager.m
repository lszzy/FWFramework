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

#pragma mark - NSTimer+FWToolkit

@implementation CADisplayLink (FWToolkit)

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

@implementation NSTimer (FWToolkit)

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

@end

#pragma mark - NSAttributedString+FWToolkit

@implementation NSAttributedString (FWToolkit)

#pragma mark - Html

+ (instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

- (NSString *)fwHtmlString
{
    NSData *htmlData = [self dataFromRange:NSMakeRange(0, self.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
}

#pragma mark - Size

- (CGSize)fwSize
{
    return [self fwSizeWithDrawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self boundingRectWithSize:drawSize
                                     options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                     context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end
