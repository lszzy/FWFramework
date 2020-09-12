//
//  FWCacheAbstract.h
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWCacheProtocol

/**
 *  缓存协议
 */
@protocol FWCacheProtocol <NSObject>

@required

// 读取某个缓存
- (nullable id)objectForKey:(NSString *)key;

// 设置某个缓存
- (void)setObject:(nullable id)object forKey:(NSString *)key;

// 设置某个缓存，支持缓存有效期，小于等于0为永久有效
- (void)setObject:(nullable id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire;

// 移除某个缓存
- (void)removeObjectForKey:(NSString *)key;

// 清空所有缓存
- (void)removeAllObjects;

@end

#pragma mark - FWCacheAbstract

/**
 *  缓存抽象类，自动管理缓存有效期
 */
@interface FWCacheAbstract : NSObject <FWCacheProtocol>

#pragma mark - Protected

// 读取某个缓存，内部方法，子类重写
- (nullable id)innerObjectForKey:(NSString *)key;

// 设置某个缓存，内部方法，子类重写
- (void)innerSetObject:(id)object forKey:(NSString *)key;

// 移除某个缓存，内部方法，子类重写
- (void)innerRemoveObjectForKey:(NSString *)key;

// 清空所有缓存，内部方法，子类重写
- (void)innerRemoveAllObjects;

@end

NS_ASSUME_NONNULL_END
