/*!
 @header     NSObject+FWSafeType.h
 @indexgroup FWFramework
 @brief      NSObject类型安全分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "NSObject+FWSafeType.h"

@implementation NSObject (FWSafeType)

- (BOOL)fwIsNotNull
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]]);
}

- (BOOL)fwIsNotEmpty
{
    return !(self == nil ||
             [self isKindOfClass:[NSNull class]] ||
             ([self respondsToSelector:@selector(length)] && [(NSData *)self length] == 0) ||
             ([self respondsToSelector:@selector(count)] && [(NSArray *)self count] == 0));
}

- (NSInteger)fwAsInteger
{
    return [[self fwAsNSNumber] integerValue];
}

- (float)fwAsFloat
{
    return [[self fwAsNSNumber] floatValue];
}

- (double)fwAsDouble
{
    return [[self fwAsNSNumber] doubleValue];
}

- (BOOL)fwAsBool
{
    return [[self fwAsNSNumber] boolValue];
}

- (NSNumber *)fwAsNSNumber
{
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        return [NSNumber numberWithDouble:[(NSString *)self doubleValue]];
    } else if ([self isKindOfClass:[NSDate class]]) {
        return [NSNumber numberWithDouble:[(NSDate *)self timeIntervalSince1970]];
    } else if ([self isKindOfClass:[NSNull class]]) {
        return [NSNumber numberWithInteger:0];
    } else {
        return nil;
    }
}

- (NSString *)fwAsNSString
{
    if ([self isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    } else if ([self isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:(NSDate *)self];
    } else if ([self isKindOfClass:[NSData class]]) {
        return [[NSString alloc] initWithData:(NSData *)self encoding:NSUTF8StringEncoding];
    } else {
        return [NSString stringWithFormat:@"%@", self];
    }
}

- (NSDate *)fwAsNSDate
{
    if ([self isKindOfClass:[NSDate class]]) {
        return (NSDate *)self;
    } else if ([self isKindOfClass:[NSString class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter dateFromString:(NSString *)self];
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)self doubleValue]];
    } else {
        return nil;
    }
}

- (NSData *)fwAsNSData
{
    if ([self isKindOfClass:[NSString class]]) {
        return [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([self isKindOfClass:[NSData class]]) {
        return (NSData *)self;
    } else {
        return nil;
    }
}

- (NSArray *)fwAsNSArray
{
    if ([self isKindOfClass:[NSArray class]]) {
        return (NSArray *)self;
    } else {
        return nil;
    }
}

- (NSMutableArray *)fwAsNSMutableArray
{
    if ([self isKindOfClass:[NSMutableArray class]]) {
        return (NSMutableArray *)self;
    } else if ([self isKindOfClass:[NSArray class]]) {
        return [NSMutableArray arrayWithArray:(NSArray *)self];
    } else {
        return nil;
    }
}

- (NSDictionary *)fwAsNSDictionary
{
    if ([self isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)self;
    } else {
        return nil;
    }
}

- (NSMutableDictionary *)fwAsNSMutableDictionary
{
    if ([self isKindOfClass:[NSMutableDictionary class]]) {
        return (NSMutableDictionary *)self;
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)self];
    } else {
        return nil;
    }
}

- (id)fwAsClass:(Class)clazz
{
    if ([self isKindOfClass:clazz]) {
        return self;
    } else {
        return nil;
    }
}

@end
