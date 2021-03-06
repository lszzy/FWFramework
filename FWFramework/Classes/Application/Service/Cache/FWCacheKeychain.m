//
//  FWCacheKeychain.m
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWCacheKeychain.h"
#import "FWKeychain.h"

@interface FWCacheKeychain ()

@property (nonatomic, strong) FWKeychainManager *keychainManager;

@end

@implementation FWCacheKeychain

+ (FWCacheKeychain *)sharedInstance
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

#pragma mark - Protected

- (id)innerObjectForKey:(NSString *)key
{
    return [self.keychainManager passwordObjectForService:@"FWCache" account:key];
}

- (void)innerSetObject:(id)object forKey:(NSString *)key
{
    [self.keychainManager setPasswordObject:object forService:@"FWCache" account:key];
}

- (void)innerRemoveObjectForKey:(NSString *)key
{
    [self.keychainManager deletePasswordForService:@"FWCache" account:key];
}

- (void)innerRemoveAllObjects
{
    [self.keychainManager deletePasswordForService:@"FWCache" account:nil];
}

@end
