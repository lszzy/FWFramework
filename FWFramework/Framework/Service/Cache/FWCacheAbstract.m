//
//  FWCacheAbstract.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

@implementation FWCacheAbstract

#pragma mark - Public

- (id)objectForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    id object = [self innerObjectForKey:key];
    if (!object) {
        return nil;
    }
    
    // 检查缓存有效期
    NSNumber *expire = [self innerObjectForKey:[self expireKey:key]];
    if (expire) {
        // 检查是否过期，大于0为过期
        if ([[NSDate date] timeIntervalSince1970] > [expire doubleValue]) {
            [self removeObjectForKey:key];
            return nil;
        }
    }
    
    return object;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [self setObject:object forKey:key withExpire:0];
}

- (void)setObject:(id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire
{
    if (!key) {
        return;
    }
    
    if (nil != object) {
        [self innerSetObject:object forKey:key];
        
        // 小于等于0为永久有效
        if (expire <= 0) {
            [self innerRemoveObjectForKey:[self expireKey:key]];
        } else {
            [self innerSetObject:@([[NSDate date] timeIntervalSince1970] + expire) forKey:[self expireKey:key]];
        }
    } else {
        [self removeObjectForKey:key];
    }
}

- (void)removeObjectForKey:(NSString *)key
{
    [self innerRemoveObjectForKey:key];
    [self innerRemoveObjectForKey:[self expireKey:key]];
}

- (void)removeAllObjects
{
    [self innerRemoveAllObjects];
}

#pragma mark - Private

- (NSString *)expireKey:(NSString *)key
{
    return [key stringByAppendingString:@".__EXPIRE__"];
}

#pragma mark - Protect

- (id)innerObjectForKey:(NSString *)key
{
    // 子类重写
    return nil;
}

- (void)innerSetObject:(id)object forKey:(NSString *)key
{
    // 子类重写
}

- (void)innerRemoveObjectForKey:(NSString *)key
{
    // 子类重写
}

- (void)innerRemoveAllObjects
{
    // 子类重写
}

@end
