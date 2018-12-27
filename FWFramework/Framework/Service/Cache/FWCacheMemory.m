//
//  FWCacheMemory.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheMemory.h"

@interface FWCacheMemory ()

@property (nonatomic, strong) NSMutableDictionary *cachePool;

@end

@implementation FWCacheMemory

+ (instancetype)sharedInstance
{
    static FWCacheMemory *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheMemory alloc] init];
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

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    return [self.cachePool objectForKey:key];
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    [self.cachePool setObject:object forKey:key];
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    [self.cachePool removeObjectForKey:key];
}

- (void)innerRemoveAllCaches
{
    [self.cachePool removeAllObjects];
}

@end
