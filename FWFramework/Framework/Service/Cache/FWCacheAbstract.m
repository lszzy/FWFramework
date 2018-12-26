//
//  FWCacheAbstract.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheAbstract.h"

@implementation FWCacheAbstract

#pragma mark - Public

- (id)cacheForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    id object = [self innerCacheForKey:key];
    if (!object) {
        return nil;
    }
    
    // 检查缓存有效期
    NSNumber *expire = [self innerCacheForKey:[self expireKey:key]];
    if (expire) {
        // 检查是否过期，大于0为过期
        if ([[NSDate date] timeIntervalSince1970] > [expire doubleValue]) {
            [self removeCacheForKey:key];
            return nil;
        }
    }
    
    return object;
}

- (void)setCache:(id)object forKey:(NSString *)key
{
    [self setCache:object forKey:key withExpire:0];
}

- (void)setCache:(id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire
{
    if (!key) {
        return;
    }
    
    if (nil != object) {
        [self innerSetCache:object forKey:key];
        
        // 小于等于0为永久有效
        if (expire <= 0) {
            [self innerRemoveCacheForKey:[self expireKey:key]];
        } else {
            [self innerSetCache:@([[NSDate date] timeIntervalSince1970] + expire) forKey:[self expireKey:key]];
        }
    } else {
        [self removeCacheForKey:key];
    }
}

- (void)removeCacheForKey:(NSString *)key
{
    [self innerRemoveCacheForKey:key];
    [self innerRemoveCacheForKey:[self expireKey:key]];
}

- (void)removeAllCaches
{
    [self innerRemoveAllCaches];
}

#pragma mark - Private

- (NSString *)expireKey:(NSString *)key
{
    return [key stringByAppendingString:@".__EXPIRE__"];
}

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    // 子类重写
    return nil;
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    // 子类重写
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    // 子类重写
}

- (void)innerRemoveAllCaches
{
    // 子类重写
}

@end
