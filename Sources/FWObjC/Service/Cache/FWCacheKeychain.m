//
//  FWCacheKeychain.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWCacheKeychain.h"
#import <Security/Security.h>

@interface FWCacheKeychain () <FWCacheEngineProtocol>

@property (nonatomic, copy, readonly) NSString *group;

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

- (instancetype)initWithGroup:(NSString *)group
{
    self = [super init];
    if (self) {
        _group = group;
    }
    return self;
}

#pragma mark - FWCacheEngineProtocol

- (id)readCacheForKey:(NSString *)key
{
    return [self passwordObjectForService:@"FWCache" account:key];
}

- (void)writeCache:(id)object forKey:(NSString *)key
{
    [self setPasswordObject:object forService:@"FWCache" account:key];
}

- (void)clearCacheForKey:(NSString *)key
{
    [self deletePasswordForService:@"FWCache" account:key];
}

- (void)clearAllCaches
{
    [self deletePasswordForService:@"FWCache" account:nil];
}

#pragma mark - Private

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
        id object = nil;
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:passwordData];
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
        return object;
    }
    return nil;
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
    NSData *passwordData = nil;
    @try {
        passwordData = [NSKeyedArchiver archivedDataWithRootObject:passwordObject];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
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

@end
