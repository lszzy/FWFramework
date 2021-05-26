//
//  FWCacheAbstract.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheAbstract.h"

@interface FWCacheAbstract ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation FWCacheAbstract

- (instancetype)init
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Public

- (id)objectForKey:(NSString *)key
{
    if (!key) return nil;
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    id object = [self innerObjectForKey:key];
    if (!object) {
        dispatch_semaphore_signal(self.semaphore);
        return nil;
    }
    
    // 检查缓存有效期
    NSNumber *expire = [self innerObjectForKey:[self expireKey:key]];
    if (expire) {
        // 检查是否过期，大于0为过期
        if ([[NSDate date] timeIntervalSince1970] > [expire doubleValue]) {
            [self innerRemoveObjectForKey:key];
            [self innerRemoveObjectForKey:[self expireKey:key]];
            dispatch_semaphore_signal(self.semaphore);
            return nil;
        }
    }

    dispatch_semaphore_signal(self.semaphore);
    return object;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    [self setObject:object forKey:key withExpire:0];
}

- (void)setObject:(id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire
{
    if (!key) return;
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (nil != object) {
        [self innerSetObject:object forKey:key];
        
        // 小于等于0为永久有效
        if (expire <= 0) {
            [self innerRemoveObjectForKey:[self expireKey:key]];
        } else {
            [self innerSetObject:@([[NSDate date] timeIntervalSince1970] + expire) forKey:[self expireKey:key]];
        }
    } else {
        [self innerRemoveObjectForKey:key];
        [self innerRemoveObjectForKey:[self expireKey:key]];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)removeObjectForKey:(NSString *)key
{
    if (!key) return;
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self innerRemoveObjectForKey:key];
    [self innerRemoveObjectForKey:[self expireKey:key]];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)removeAllObjects
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self innerRemoveAllObjects];
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Private

- (NSString *)expireKey:(NSString *)key
{
    return [key stringByAppendingString:@".__EXPIRE__"];
}

#pragma mark - Protected

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
