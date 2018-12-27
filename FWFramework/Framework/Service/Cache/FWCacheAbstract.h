//
//  FWCacheAbstract.h
//  FWFramework
//
//  Created by wuyong on 2017/5/10.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - FWCacheProtocol

/**
 *  缓存协议
 */
@protocol FWCacheProtocol <NSObject>

@required

// 读取某个缓存
- (id)cacheForKey:(NSString *)key;

// 设置某个缓存
- (void)setCache:(id)object forKey:(NSString *)key;

// 设置某个缓存，支持缓存有效期，小于等于0为永久有效
- (void)setCache:(id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire;

// 移除某个缓存
- (void)removeCacheForKey:(NSString *)key;

// 清空所有缓存
- (void)removeAllCaches;

@end

#pragma mark - FWCacheAbstract

/**
 *  缓存抽象类，自动管理缓存有效期
 */
@interface FWCacheAbstract : NSObject <FWCacheProtocol>

#pragma mark - Protect

// 读取某个缓存，内部方法，子类重写
- (id)innerCacheForKey:(NSString *)key;

// 设置某个缓存，内部方法，子类重写
- (void)innerSetCache:(id)object forKey:(NSString *)key;

// 移除某个缓存，内部方法，子类重写
- (void)innerRemoveCacheForKey:(NSString *)key;

// 清空所有缓存，内部方法，子类重写
- (void)innerRemoveAllCaches;

@end
