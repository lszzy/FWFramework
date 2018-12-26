//
//  FWCacheKeychain.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWCacheKeychain.h"
#import "FWKeychainManager.h"

@interface FWCacheKeychain ()

@property (nonatomic, strong) FWKeychainManager *keychainManager;

@end

@implementation FWCacheKeychain

+ (instancetype)sharedInstance
{
    static FWCacheKeychain *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWCacheKeychain alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.keychainManager = [FWKeychainManager sharedInstance];
    }
    return self;
}

- (instancetype)initWithGroup:(NSString *)group
{
    self = [super init];
    if (self) {
        self.keychainManager = [[FWKeychainManager alloc] initWithGroup:group];
    }
    return self;
}

#pragma mark - Protect

- (id)innerCacheForKey:(NSString *)key
{
    return [self.keychainManager passwordObjectForService:@"FWCache" account:key];
}

- (void)innerSetCache:(id)object forKey:(NSString *)key
{
    [self.keychainManager setPasswordObject:object forService:@"FWCache" account:key];
}

- (void)innerRemoveCacheForKey:(NSString *)key
{
    [self.keychainManager deletePasswordForService:@"FWCache" account:key];
}

- (void)innerRemoveAllCaches
{
    [self.keychainManager deletePasswordForService:@"FWCache" account:nil];
}

@end
