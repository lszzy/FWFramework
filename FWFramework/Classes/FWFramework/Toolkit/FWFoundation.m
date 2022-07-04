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

#pragma mark - NSArray+FWFoundation

@implementation NSArray (FWFoundation)

- (NSArray *)fw_filterWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            [result addObject:obj];
        }
    }];
    return result;
}

- (NSArray *)fw_mapWithBlock:(id (^)(id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];
    return result;
}

- (id)fw_matchWithBlock:(BOOL (^)(id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (id)fw_randomObject
{
    if (self.count < 1) return nil;
    
    return self[arc4random_uniform((u_int32_t)self.count)];
}

@end

#pragma mark - NSAttributedString+FWFoundation

@implementation NSAttributedString (FWFoundation)

- (NSString *)fw_htmlString
{
    NSData *htmlData = [self dataFromRange:NSMakeRange(0, self.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
}

- (CGSize)fw_textSize
{
    return [self fw_textSizeWithDrawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fw_textSizeWithDrawSize:(CGSize)drawSize
{
    CGSize size = [self boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

+ (instancetype)fw_attributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

+ (NSAttributedString *)fw_attributedStringWithImage:(UIImage *)image bounds:(CGRect)bounds
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

+ (instancetype)fw_attributedString:(NSString *)string withFont:(UIFont *)font
{
    return [self fw_attributedString:string withFont:font textColor:nil];
}

+ (instancetype)fw_attributedString:(NSString *)string withFont:(UIFont *)font textColor:(UIColor *)textColor
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    if (font) attr[NSFontAttributeName] = font;
    if (textColor) attr[NSForegroundColorAttributeName] = textColor;
    return [[self alloc] initWithString:string attributes:attr];
}

@end

#pragma mark - NSData+FWFoundation

@implementation NSData (FWFoundation)

- (id)fw_unarchiveObject:(Class)clazz
{
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:clazz fromData:self error:NULL];
    } @catch (NSException *exception) { }
    return object;
}

+ (NSData *)fw_archiveObject:(id)object
{
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:NULL];
    } @catch (NSException *exception) { }
    return data;
}

+ (BOOL)fw_archiveObject:(id)object toFile:(NSString *)path
{
    NSData *data = [self fw_archiveObject:object];
    if (!data) return NO;
    return [data writeToFile:path atomically:YES];
}

+ (id)fw_unarchiveObject:(Class)clazz withFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) return nil;
    return [data fw_unarchiveObject:clazz];
}

@end

#pragma mark - NSDate+FWFoundation

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWFoundation)

- (NSString *)fw_stringValue
{
    return [self fw_stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (NSString *)fw_stringWithFormat:(NSString *)format
{
    return [self fw_stringWithFormat:format timeZone:nil];
}

- (NSString *)fw_stringWithFormat:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSString *string = [formatter stringFromDate:self];
    return string;
}

+ (NSTimeInterval)fw_currentTime
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
        NSTimeInterval offsetTime = [self fw_currentSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

+ (void)setFw_currentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fw_currentSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSTimeInterval)fw_currentSystemUptime
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

+ (NSDate *)fw_dateWithString:(NSString *)string
{
    return [self fw_dateWithString:string format:@"yyyy-MM-dd HH:mm:ss"];
}

+ (NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format
{
    return [self fw_dateWithString:string format:format timeZone:nil];
}

+ (NSDate *)fw_dateWithString:(NSString *)string format:(NSString *)format timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    if (timeZone) formatter.timeZone = timeZone;
    NSDate *date = [formatter dateFromString:string];
    return date;
}

+ (NSString *)fw_formatDuration:(NSTimeInterval)duration hasHour:(BOOL)hasHour
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

+ (NSTimeInterval)fw_formatTimestamp:(NSTimeInterval)timestamp
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

#pragma mark - NSDictionary+FWFoundation

@implementation NSDictionary (FWFoundation)

- (NSDictionary *)fw_filterWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result[key] = obj;
        }
    }];
    return result;
}

- (NSDictionary *)fw_mapWithBlock:(id (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = block(key, obj);
        if (value) {
            result[key] = value;
        }
    }];
    return result;
}

- (id)fw_matchWithBlock:(BOOL (^)(id, id))block
{
    NSParameterAssert(block != nil);
    
    __block id result = nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (block(key, obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

@end

#pragma mark - NSObject+FWFoundation

@implementation NSObject (FWFoundation)

- (void)fw_lock
{
    dispatch_semaphore_wait([self fw_lockSemaphore], DISPATCH_TIME_FOREVER);
}

- (void)fw_unlock
{
    dispatch_semaphore_signal([self fw_lockSemaphore]);
}

- (dispatch_semaphore_t)fw_lockSemaphore
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

#pragma mark - NSString+FWFoundation

@implementation NSString (FWFoundation)

- (CGSize)fw_sizeWithFont:(UIFont *)font
{
    return [self fw_sizeWithFont:font drawSize:CGSizeMake(MAXFLOAT, MAXFLOAT)];
}

- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize
{
    return [self fw_sizeWithFont:font drawSize:drawSize attributes:nil];
}

- (CGSize)fw_sizeWithFont:(UIFont *)font drawSize:(CGSize)drawSize attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes
{
    NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
    attr[NSFontAttributeName] = font;
    if (attributes != nil) {
        [attr addEntriesFromDictionary:attributes];
    }
    CGSize size = [self boundingRectWithSize:drawSize
                                          options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attr
                                          context:nil].size;
    return CGSizeMake(MIN(drawSize.width, ceilf(size.width)), MIN(drawSize.height, ceilf(size.height)));
}

- (BOOL)fw_matchesRegex:(NSString *)regex
{
    NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [regexPredicate evaluateWithObject:self] == YES;
}

+ (NSString *)fw_sizeString:(NSUInteger)aFileSize
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

#pragma mark - NSUserDefaults+FWFoundation

@implementation NSUserDefaults (FWFoundation)

- (id)fw_objectForKey:(NSString *)key
{
    return [self objectForKey:key];
}

- (void)fw_setObject:(id)object forKey:(NSString *)key
{
    if (object == nil) {
        [self removeObjectForKey:key];
    } else {
        [self setObject:object forKey:key];
    }
    [self synchronize];
}

+ (id)fw_objectForKey:(NSString *)key
{
    return [NSUserDefaults.standardUserDefaults fw_objectForKey:key];
}

+ (void)fw_setObject:(id)object forKey:(NSString *)key
{
    [NSUserDefaults.standardUserDefaults fw_setObject:object forKey:key];
}

@end
