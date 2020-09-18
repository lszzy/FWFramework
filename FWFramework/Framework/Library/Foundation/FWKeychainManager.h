//
//  FWKeychainManager.h
//  FWFramework
//
//  Created by wuyong on 2017/5/18.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Keychain管理器
@interface FWKeychainManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWKeychainManager *sharedInstance;

// 分组对象
- (instancetype)initWithGroup:(nullable NSString *)group;

// 读取String数据
- (nullable NSString *)passwordForService:(nullable NSString *)service account:(nullable NSString *)account;

// 读取Data数据
- (nullable NSData *)passwordDataForService:(nullable NSString *)service account:(nullable NSString *)account;

// 读取Object数据
- (nullable id)passwordObjectForService:(nullable NSString *)service account:(nullable NSString *)account;

// 保存String数据
- (BOOL)setPassword:(NSString *)password forService:(nullable NSString *)service account:(nullable NSString *)account;

// 保存Data数据
- (BOOL)setPasswordData:(NSData *)passwordData forService:(nullable NSString *)service account:(nullable NSString *)account;

// 保存Object数据
- (BOOL)setPasswordObject:(id)passwordObject forService:(nullable NSString *)service account:(nullable NSString *)account;

// 删除数据
- (BOOL)deletePasswordForService:(nullable NSString *)service account:(nullable NSString *)account;

@end

NS_ASSUME_NONNULL_END
