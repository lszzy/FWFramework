//
//  FWKeychainManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

// Keychain管理器
@interface FWKeychainManager : NSObject

// 单例对象
+ (instancetype)sharedInstance;

// 分组对象
- (instancetype)initWithGroup:(NSString *)group;

// 读取String数据
- (NSString *)passwordForService:(NSString *)service account:(NSString *)account;

// 读取Data数据
- (NSData *)passwordDataForService:(NSString *)service account:(NSString *)account;

// 读取Object数据
- (id)passwordObjectForService:(NSString *)service account:(NSString *)account;

// 保存String数据
- (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account;

// 保存Data数据
- (BOOL)setPasswordData:(NSData *)passwordData forService:(NSString *)service account:(NSString *)account;

// 保存Object数据
- (BOOL)setPasswordObject:(id)passwordObject forService:(NSString *)service account:(NSString *)account;

// 删除数据
- (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account;

@end
