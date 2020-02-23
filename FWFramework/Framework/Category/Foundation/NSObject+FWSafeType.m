/*!
 @header     NSObject+FWSafeType.h
 @indexgroup FWFramework
 @brief      NSObject类型安全分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "NSObject+FWSafeType.h"

NSString * FWSafeString(id value) {
    return value ? [NSString stringWithFormat:@"%@", value] : @"";
}

NSNumber * FWSafeNumber(id value) {
    if (!value) return @0;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    NSString *string = [NSString stringWithFormat:@"%@", value];
    return [NSNumber numberWithDouble:[string doubleValue]];
}

#pragma mark - NSObject+FWSafeType

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

#pragma mark - NSNumber+FWSafeType

@implementation NSNumber (FWSafeType)

- (BOOL)fwIsEqualToNumber:(NSNumber *)number
{
    if (!number) return NO;
    
    return [self isEqualToNumber:number];
}

- (NSComparisonResult)fwCompare:(NSNumber *)number
{
    if (!number) return NSOrderedDescending;
    
    return [self compare:number];
}

@end

#pragma mark - NSString+FWSafeType

@implementation NSString (FWSafeType)

- (NSString *)fwSubstringFromIndex:(NSInteger)from
{
    if (from < 0) {
        return nil;
    }
    
    if (from > self.length) {
        return nil;
    }
    
    return [self substringFromIndex:from];
}

- (NSString *)fwSubstringToIndex:(NSInteger)to
{
    if (to < 0) {
        return nil;
    }
    
    if (to > self.length) {
        return nil;
    }
    
    return [self substringToIndex:to];
}

- (NSString *)fwSubstringWithRange:(NSRange)range
{
    if (range.location > self.length) {
        return nil;
    }
    
    if (range.length > self.length) {
        return nil;
    }
    
    if (range.location + range.length > self.length) {
        return nil;
    }
    
    return [self substringWithRange:range];
}

@end

#pragma mark - NSArray+FWSafeType

@implementation NSArray (FWSafeType)

- (id)fwObjectAtIndex:(NSInteger)index
{
    if (index < 0) {
        return nil;
    }
    
    if (index >= self.count) {
        return nil;
    }
    
    return [self objectAtIndex:index];
}

- (NSArray *)fwSubarrayWithRange:(NSRange)range
{
    if (range.location > self.count) {
        return nil;
    }
    
    if (range.length > self.count) {
        return nil;
    }
    
    if (range.location + range.length > self.count) {
        return nil;
    }
    
    return [self subarrayWithRange:range];
}

@end

#pragma mark - NSMutableArray+FWSafeType

@implementation NSMutableArray (FWSafeType)

- (void)fwAddObject:(id)object
{
    if (object == nil) {
        return;
    }
    
    [self addObject:object];
}

- (void)fwRemoveObjectAtIndex:(NSInteger)index
{
    if (index < 0) {
        return;
    }
    
    if (index >= self.count) {
        return;
    }
    
    [self removeObjectAtIndex:index];
}

- (void)fwInsertObject:(id)object atIndex:(NSInteger)index
{
    if (object == nil) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index > self.count) {
        return;
    }
    
    [self insertObject:object atIndex:index];
}

- (void)fwReplaceObjectAtIndex:(NSInteger)index withObject:(id)object
{
    if (object == nil) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index >= self.count) {
        return;
    }
    
    [self replaceObjectAtIndex:index withObject:object];
}

- (void)fwRemoveObjectsInRange:(NSRange)range
{
    if (range.location > self.count) {
        return;
    }
    
    if (range.length > self.count) {
        return;
    }
    
    if (range.location + range.length > self.count) {
        return;
    }
    
    [self removeObjectsInRange:range];
}

- (void)fwInsertObjects:(NSArray *)objects atIndex:(NSInteger)index
{
    if (objects.count == 0) {
        return;
    }
    
    if (index < 0) {
        return;
    }
    
    if (index > self.count) {
        return;
    }
    
    for (NSInteger i = objects.count - 1; i >= 0; i--) {
        [self insertObject:objects[i] atIndex:index];
    }
}

@end

#pragma mark - NSDictionary+FWSafeType

@implementation NSDictionary (FWSafeType)

- (id)fwObjectForKey:(id)key
{
    if (!key) {
        return nil;
    }
    
    id object = [self objectForKey:key];
    if (object == nil || object == [NSNull null]) {
        return nil;
    }
    
    return object;
}

@end

#pragma mark - NSMutableDictionary+FWSafeType

@implementation NSMutableDictionary (FWSafeType)

- (void)fwRemoveObjectForKey:(id)key
{
    if (!key) {
        return;
    }
    
    [self removeObjectForKey:key];
}

- (void)fwSetObject:(id)object forKey:(id<NSCopying>)key
{
    if (!key) {
        return;
    }
    
    if (object == nil || object == [NSNull null]) {
        return;
    }
    
    [self setObject:object forKey:key];
}

@end
