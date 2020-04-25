/*!
 @header     NSDictionary+FWFramework.m
 @indexgroup FWFramework
 @brief      NSDictionary分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSDictionary+FWFramework.h"
#import "NSArray+FWFramework.h"

@implementation NSDictionary (FWFramework)

- (instancetype)fwFilterWithBlock:(BOOL (^)(id, id))block
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

- (NSDictionary *)fwMapWithBlock:(id (^)(id, id))block
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

- (id)fwMatchWithBlock:(BOOL (^)(id, id))block
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

- (id)fwRandomKey
{
    if (self.count < 1) return nil;
    
    return self.allKeys.fwRandomObject;
}

- (id)fwRandomObject
{
    if (self.count < 1) return nil;
        
    return self.allValues.fwRandomObject;
}

- (id)fwRandomWeightKey
{
    if (self.count < 1) return nil;
    
    return [self.allKeys fwRandomObject:self.allValues];
}

- (BOOL)fwIncludeNull
{
    __block BOOL includeNull = NO;
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNull class]]) {
            includeNull = YES;
            *stop = YES;
        }
    }];
    return includeNull;
}

- (NSDictionary *)fwRemoveNull
{
    return [self fwRemoveNullRecursive:YES];
}

- (NSDictionary *)fwRemoveNullRecursive:(BOOL)recursive
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:self];
    for (id key in [self allKeys]) {
        id object = [self objectForKey:key];
        
        if (object == [NSNull null]) {
            [dictionary removeObjectForKey:key];
        }
        
        if (recursive) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *subdictionary = [object fwRemoveNullRecursive:YES];
                [dictionary setValue:subdictionary forKey:key];
            }
            
            if ([object isKindOfClass:[NSArray class]]) {
                NSArray *subarray = [(NSArray *)object fwRemoveNullRecursive:YES];
                [dictionary setValue:subarray forKey:key];
            }
        }
    }
    return [dictionary copy];
}

@end
