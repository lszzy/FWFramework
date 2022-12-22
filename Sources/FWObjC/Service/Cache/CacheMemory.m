//
//  CacheMemory.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "CacheMemory.h"

@interface __FWCacheMemory () <__FWCacheEngineProtocol>

@property (nonatomic, strong) NSMutableDictionary *cachePool;

@end

@implementation __FWCacheMemory

+ (__FWCacheMemory *)sharedInstance
{
    static __FWCacheMemory *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWCacheMemory alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cachePool = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - __FWCacheEngineProtocol

- (id)readCacheForKey:(NSString *)key
{
    return [self.cachePool objectForKey:key];
}

- (void)writeCache:(id)object forKey:(NSString *)key
{
    [self.cachePool setObject:object forKey:key];
}

- (void)clearCacheForKey:(NSString *)key
{
    [self.cachePool removeObjectForKey:key];
}

- (void)clearAllCaches
{
    [self.cachePool removeAllObjects];
}

@end
