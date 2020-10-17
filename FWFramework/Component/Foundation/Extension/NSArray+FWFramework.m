/*!
 @header     NSArray+FWFramework.m
 @indexgroup FWFramework
 @brief      NSArray分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSArray+FWFramework.h"
#import "NSDictionary+FWFramework.h"
#import "FWEncode.h"

@implementation NSArray (FWFramework)

- (instancetype)fwFilterWithBlock:(BOOL (^)(id))block
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

- (NSArray *)fwMapWithBlock:(id (^)(id))block
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

- (id)fwMatchWithBlock:(BOOL (^)(id))block
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

- (id)fwRandomObject
{
    if (self.count < 1) return nil;
    
    return self[arc4random_uniform((u_int32_t)self.count)];
}

- (id)fwRandomObject:(NSArray *)weights
{
    NSInteger count = self.count;
    if (count < 1) return nil;
    
    __block NSInteger sum = 0;
    [weights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSInteger val = [obj fwAsInteger];
        if (val > 0 && idx < count) {
            sum += val;
        }
    }];
    if (sum < 1) return self.fwRandomObject;
    
    __block NSInteger index = -1;
    __block NSInteger weight = 0;
    NSInteger random = arc4random_uniform((u_int32_t)sum);
    [weights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSInteger val = [obj fwAsInteger];
        if (val > 0 && idx < count) {
            weight += val;
            if (weight > random) {
                index = idx;
                *stop = YES;
            }
        }
    }];
    return index >= 0 ? [self fwObjectAtIndex:index] : self.fwRandomObject;
}

- (NSArray *)fwReverseArray
{
    NSMutableArray *reverseArray = [NSMutableArray arrayWithArray:self];
    [reverseArray fwReverse];
    return [reverseArray copy];
}

- (NSArray *)fwShuffleArray
{
    NSMutableArray *shuffleArray = [NSMutableArray arrayWithArray:self];
    [shuffleArray fwShuffle];
    return [shuffleArray copy];
}

- (BOOL)fwIncludeNull
{
    __block BOOL includeNull = NO;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSNull class]]) {
            includeNull = YES;
            *stop = YES;
        }
    }];
    return includeNull;
}

- (NSArray *)fwRemoveNull
{
    return [self fwRemoveNullRecursive:YES];
}

- (NSArray *)fwRemoveNullRecursive:(BOOL)recursive
{
    NSMutableArray *array = [self mutableCopy];
    for (id object in self) {
        if (object == [NSNull null]) {
            [array removeObject:object];
        }
        
        if (recursive) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSInteger index = [array indexOfObject:object];
                NSDictionary *subdictionary = [(NSDictionary *)object fwRemoveNullRecursive:YES];
                [array replaceObjectAtIndex:index withObject:subdictionary];
            }
            
            if ([object isKindOfClass:[NSArray class]]) {
                NSInteger index = [array indexOfObject:object];
                NSArray *subarray = [object fwRemoveNullRecursive:YES];
                [array replaceObjectAtIndex:index withObject:subarray];
            }
        }
    }
    return [array copy];
}

@end

#pragma mark - NSMutableArray+FWFramework

@implementation NSMutableArray (FWFramework)

- (void)fwReverse
{
    NSUInteger count = self.count;
    int mid = floor(count / 2.0);
    for (NSUInteger i = 0; i < mid; i++) {
        [self exchangeObjectAtIndex:i withObjectAtIndex:(count - (i + 1))];
    }
}

- (void)fwShuffle
{
    for (NSUInteger i = self.count; i > 1; i--) {
        [self exchangeObjectAtIndex:(i - 1)
                  withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
}

@end
