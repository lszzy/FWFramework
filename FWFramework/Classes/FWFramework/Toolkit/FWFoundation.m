/**
 @header     FWFoundation.m
 @indexgroup FWFramework
      FWFoundation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWFoundation.h"
#import <sys/sysctl.h>
#import <objc/runtime.h>

#pragma mark - FWArrayWrapper+FWFoundation

@implementation FWArrayWrapper (FWFoundation)

- (NSArray *)filterWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self.base enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            [result addObject:obj];
        }
    }];
    return result;
}

- (NSArray *)mapWithBlock:(id (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self.base enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];
    return result;
}

- (id)matchWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self.base enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (id)randomObject
{
    if (self.base.count < 1) return nil;
    
    return self.base[arc4random_uniform((u_int32_t)self.base.count)];
}

@end

#pragma mark - FWAttributedStringWrapper+FWFoundation

@implementation FWAttributedStringWrapper (FWFoundation)

- (NSString *)htmlString
{
    NSData *htmlData = [self.base dataFromRange:NSMakeRange(0, self.base.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
}

- (CGSize)textSize
{
    return [self textSizeWithDrawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)textSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self.base boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

@end

#pragma mark - FWAttributedStringClassWrapper+FWFoundation

@implementation FWAttributedStringClassWrapper (FWFoundation)

- (NSAttributedString *)attributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self.base alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

- (NSAttributedString *)attributedStringWithImage:(UIImage *)image bounds:(CGRect)bounds
{
    NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
    imageAttachment.image = image;
    imageAttachment.bounds = CGRectMake(0, bounds.origin.y, bounds.size.width, bounds.size.height);
    NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    if (bounds.origin.x <= 0) return imageString;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    NSTextAttachment *spacingAttachment = [[NSTextAttachment alloc] init];
    spacingAttachment.image = nil;
    spacingAttachment.bounds = CGRectMake(0, bounds.origin.y, bounds.origin.x, bounds.size.height);
    [attributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:spacingAttachment]];
    [attributedString appendAttributedString:imageString];
    return attributedString;
}

@end

#pragma mark - FWDataWrapper+FWFoundation

@implementation FWDataWrapper (FWFoundation)

- (id)unarchiveObject:(Class)clazz
{
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:clazz fromData:self.base error:NULL];
    } @catch (NSException *exception) { }
    return object;
}

@end

#pragma mark - FWDataClassWrapper+FWFoundation

@implementation FWDataClassWrapper (FWFoundation)

- (NSData *)archiveObject:(id)object
{
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:NULL];
    } @catch (NSException *exception) { }
    return data;
}

- (BOOL)archiveObject:(id)object toFile:(NSString *)path
{
    NSData *data = [self archiveObject:object];
    if (!data) return NO;
    return [data writeToFile:path atomically:YES];
}

- (id)unarchiveObject:(Class)clazz withFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    return [data.fw unarchiveObject:clazz];
}

@end

#pragma mark - FWDateWrapper+FWFoundation

@implementation FWDateWrapper (FWFoundation)

- (NSString *)stringValue
{
    return [self stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)stringWithFormat:(NSString *)format
{
    return [self stringWithFormat:format timeZone:nil];
}

- (NSString *)stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSString *string = [formatter stringFromDate:self.base];
    return string;
}

@end

#pragma mark - FWDateClassWrapper+FWFoundation

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation FWDateClassWrapper (FWFoundation)

- (NSTimeInterval)currentTime
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
        NSTimeInterval offsetTime = [self currentSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self currentSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval)currentSystemUptime
{
    struct timeval bootTime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(bootTime);
    int resctl = sysctl(mib, 2, &bootTime, &size, NULL, 0);

    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    
    NSTimeInterval uptime = 0;
    if (resctl != -1 && bootTime.tv_sec != 0) {
        uptime = now.tv_sec - bootTime.tv_sec;
        uptime += (now.tv_usec - bootTime.tv_usec) / 1.e6;
    }
    return uptime;
}

- (NSDate *)dateWithString:(NSString *)string
{
    return [self dateWithString:string format:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSDate *)dateWithString:(NSString *)string format:(NSString *)format
{
    return [self dateWithString:string format:format timeZone:nil];
}

- (NSDate *)dateWithString:(NSString *)string format:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSDate *date = [formatter dateFromString:string];
    return date;
}

- (NSString *)formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour
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

- (NSTimeInterval)formatTimestamp:(NSTimeInterval)timestamp
{
    NSString *string = [NSString stringWithFormat:@"%ld", (long)timestamp];
    if (string.length == 16) {
        return timestamp / 1000.0 / 1000.0;
    } else if (string.length == 13) {
        return timestamp / 1000.0;
    } else {
        return timestamp;
    }
}

@end

#pragma mark - FWDictionaryWrapper+FWFoundation

@implementation FWDictionaryWrapper (FWFoundation)

- (NSDictionary *)filterWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self.base enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result[key] = obj;
        }
    }];
    return result;
}

- (NSDictionary *)mapWithBlock:(id (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self.base enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = block(key, obj);
        if (value) {
            result[key] = value;
        }
    }];
    return result;
}

- (id)matchWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self.base enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

@end

#pragma mark - FWObjectWrapper+FWFoundation

@implementation FWObjectWrapper (FWFoundation)

- (void)lock
{
    dispatch_semaphore_wait([self lockSemaphore], DISPATCH_TIME_FOREVER);
}

- (void)unlock
{
    dispatch_semaphore_signal([self lockSemaphore]);
}

- (dispatch_semaphore_t)lockSemaphore
{
    dispatch_semaphore_t semaphore = objc_getAssociatedObject(self.base, _cmd);
    if (!semaphore) {
        @synchronized (self.base) {
            semaphore = objc_getAssociatedObject(self.base, _cmd);
            if (!semaphore) {
                semaphore = dispatch_semaphore_create(1);
                objc_setAssociatedObject(self.base, _cmd, semaphore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return semaphore;
}

@end

#pragma mark - FWStringWrapper+FWFoundation

@implementation FWStringWrapper (FWFoundation)

- (CGSize)sizeWithFont:(UIFont *)font
{
    return [self sizeWithFont:font drawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize
{
    return [self sizeWithFont:font drawSize:drawSize attributes:nil];
}

- (CGSize)sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = font;
    if (attributes != nil) {
        [attr addEntriesFromDictionary:attributes];
    }
    CGSize size = [self.base boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (BOOL)matchesRegex:(NSString *)regex
{
    NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [regexPredicate evaluateWithObject:self.base] == YES;
}

@end

#pragma mark - FWStringClassWrapper+FWFoundation

@implementation FWStringClassWrapper (FWFoundation)

- (NSString *)sizeString:(NSUInteger)aFileSize
{
    NSString *sizeStr;
    if (aFileSize <= 0) {
        sizeStr = @"0K";
    } else {
        double fileSize = aFileSize / 1024.f;
        if (fileSize >= 1024.f) {
            fileSize = fileSize / 1024.f;
            if (fileSize >= 1024.f) {
                fileSize = fileSize / 1024.f;
                sizeStr = [NSString stringWithFormat:@"%0.1fG", fileSize];
            } else {
                sizeStr = [NSString stringWithFormat:@"%0.1fM", fileSize];
            }
        } else {
            sizeStr = [NSString stringWithFormat:@"%dK", (int)ceil(fileSize)];
        }
    }
    return sizeStr;
}

@end

#pragma mark - FWTimerWrapper+FWFoundation

@implementation FWTimerWrapper (FWFoundation)

- (void)pauseTimer
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate distantFuture]];
}

- (void)resumeTimer
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate date]];
}

- (void)resumeTimerAfterDelay:(NSTimeInterval)delay
{
    if (![self.base isValid]) return;
    [self.base setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
}

@end

#pragma mark - FWUserDefaultsWrapper+FWFoundation

@implementation FWUserDefaultsWrapper (FWFoundation)

- (id)objectForKey:(NSString *)key
{
    return [self.base objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    if (object == nil) {
        [self.base removeObjectForKey:key];
    } else {
        [self.base setObject:object forKey:key];
    }
    [self.base synchronize];
}

@end

#pragma mark - FWUserDefaultsClassWrapper+FWFoundation

@implementation FWUserDefaultsClassWrapper (FWFoundation)

- (id)objectForKey:(NSString *)key
{
    return [NSUserDefaults.standardUserDefaults.fw objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [NSUserDefaults.standardUserDefaults.fw setObject:object forKey:key];
}

@end
