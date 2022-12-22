//
//  CacheEngine.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheEngine.h"

@interface __FWCacheEngine () <__FWCacheEngineProtocol>

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation __FWCacheEngine

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
    id object = [self readCacheForKey:key];
    if (!object) {
        dispatch_semaphore_signal(self.semaphore);
        return nil;
    }
    
    // 检查缓存有效期
    NSNumber *expire = [self readCacheForKey:[self expireKey:key]];
    if (expire) {
        // 检查是否过期，大于0为过期
        if ([[NSDate date] timeIntervalSince1970] > [expire doubleValue]) {
            [self clearCacheForKey:key];
            [self clearCacheForKey:[self expireKey:key]];
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
        [self writeCache:object forKey:key];
        
        // 小于等于0为永久有效
        if (expire <= 0) {
            [self clearCacheForKey:[self expireKey:key]];
        } else {
            [self writeCache:@([[NSDate date] timeIntervalSince1970] + expire) forKey:[self expireKey:key]];
        }
    } else {
        [self clearCacheForKey:key];
        [self clearCacheForKey:[self expireKey:key]];
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)removeObjectForKey:(NSString *)key
{
    if (!key) return;
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self clearCacheForKey:key];
    [self clearCacheForKey:[self expireKey:key]];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)removeAllObjects
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self clearAllCaches];
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Private

- (NSString *)expireKey:(NSString *)key
{
    return [key stringByAppendingString:@".__EXPIRE__"];
}

#pragma mark - __FWCacheEngineProtocol

- (id)readCacheForKey:(NSString *)key
{
    // 子类重写
    return nil;
}

- (void)writeCache:(id)object forKey:(NSString *)key
{
    // 子类重写
}

- (void)clearCacheForKey:(NSString *)key
{
    // 子类重写
}

- (void)clearAllCaches
{
    // 子类重写
}

@end
