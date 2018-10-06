//
//  FWKeychainManager.m
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWKeychainManager.h"
#import <Security/Security.h>

@interface FWKeychainManager ()

@property (nonatomic, copy, readonly) NSString *group;

@end

@implementation FWKeychainManager

+ (instancetype)sharedInstance
{
    static FWKeychainManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWKeychainManager alloc] init];
    });
    return instance;
}

- (instancetype)initWithGroup:(NSString *)group
{
    self = [super init];
    if (self) {
        _group = group;
    }
    return self;
}

#pragma mark - Private

- (NSMutableDictionary *)queryForService:(NSString *)service account:(NSString *)account
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    if (service) {
        [query setObject:service forKey:(__bridge id)kSecAttrService];
    }
    if (account) {
        [query setObject:account forKey:(__bridge id)kSecAttrAccount];
    }
    if (self.group) {
        [query setObject:self.group forKey:(__bridge id)kSecAttrAccessGroup];
    }
    return query;
}

#pragma mark - Public

- (NSString *)passwordForService:(NSString *)service account:(NSString *)account
{
    NSData *passwordData = [self passwordDataForService:service account:account];
    if (passwordData) {
        return [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (NSData *)passwordDataForService:(NSString *)service account:(NSString *)account
{
    CFTypeRef result = NULL;
    NSMutableDictionary *query = [self queryForService:service account:account];
    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess) {
        return nil;
    }
    
    return (__bridge_transfer NSData *)result;
}

- (id)passwordObjectForService:(NSString *)service account:(NSString *)account
{
    NSData *passwordData = [self passwordDataForService:service account:account];
    if (passwordData) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:passwordData];
    }
    return nil;
}

- (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account
{
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if (passwordData) {
        return [self setPasswordData:passwordData forService:service account:account];
    }
    return NO;
}

- (BOOL)setPasswordData:(NSData *)passwordData forService:(NSString *)service account:(NSString *)account
{
    NSMutableDictionary *query = nil;
    NSMutableDictionary *searchQuery = [self queryForService:service account:account];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, nil);
    // 更新数据
    if (status == errSecSuccess) {
        query = [[NSMutableDictionary alloc] init];
        [query setObject:passwordData forKey:(__bridge id)kSecValueData];
        status = SecItemUpdate((__bridge CFDictionaryRef)searchQuery, (__bridge CFDictionaryRef)query);
        // 添加数据
    } else if (status == errSecItemNotFound) {
        query = [self queryForService:service account:account];
        [query setObject:passwordData forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

- (BOOL)setPasswordObject:(id)passwordObject forService:(NSString *)service account:(NSString *)account
{
    NSData *passwordData = [NSKeyedArchiver archivedDataWithRootObject:passwordObject];
    if (passwordData) {
        return [self setPasswordData:passwordData forService:service account:account];
    }
    return NO;
}

- (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account
{
    NSMutableDictionary *query = [self queryForService:service account:account];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

@end
