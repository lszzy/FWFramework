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
