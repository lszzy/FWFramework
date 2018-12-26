//
//  FWCacheDefaults.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheDefaults.h"

@interface FWCacheDefaults ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation FWCacheDefaults

+ (instancetype)sharedInstance
{
    static FWCacheDefaults *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheDefaults alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (instancetype)initWithGroup:(NSString *)group
{
    self = [super init];
    if (self) {
        self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:group];
    }
    return self;
}

#pragma mark - Private

// 和非缓存Key区分开，防止清除非缓存信息
- (NSString *)cacheKey:(NSString *)key
{
    return [NSString stringWithFormat:@"FWCache.%@", key];
}

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    return [self.userDefaults objectForKey:[self cacheKey:key]];
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    [self.userDefaults setObject:object forKey:[self cacheKey:key]];
    [self.userDefaults synchronize];
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    [self.userDefaults removeObjectForKey:[self cacheKey:key]];
    [self.userDefaults synchronize];
}

- (void)innerRemoveAllCaches
{
    NSDictionary *dict = [self.userDefaults dictionaryRepresentation];
    for (NSString *key in dict) {
        if ([key hasPrefix:@"FWCache."]) {
            [self.userDefaults removeObjectForKey:key];
        }
    }
    [self.userDefaults synchronize];
}

@end
