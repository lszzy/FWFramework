//
//  FWCacheDefaults.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheUserDefaults.h"

@interface FWCacheUserDefaults ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation FWCacheUserDefaults

+ (instancetype)sharedInstance
{
    static FWCacheUserDefaults *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheUserDefaults alloc] init];
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
