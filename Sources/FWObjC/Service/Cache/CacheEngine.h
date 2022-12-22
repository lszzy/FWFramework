//
//  CacheEngine.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWCacheProtocol

/**
 *  缓存调用协议
 */
NS_SWIFT_NAME(CacheProtocol)
@protocol __FWCacheProtocol <NSObject>
@required

/// 读取某个缓存
- (nullable id)objectForKey:(NSString *)key;

/// 设置某个缓存
- (void)setObject:(nullable id)object forKey:(NSString *)key;

/// 设置某个缓存，支持缓存有效期，小于等于0为永久有效
- (void)setObject:(nullable id)object forKey:(NSString *)key withExpire:(NSTimeInterval)expire;

/// 移除某个缓存
- (void)removeObjectForKey:(NSString *)key;

/// 清空所有缓存
- (void)removeAllObjects;

@end

#pragma mark - __FWCacheEngineProtocol

/// 缓存引擎内部协议
NS_SWIFT_NAME(CacheEngineProtocol)
@protocol __FWCacheEngineProtocol <NSObject>
@required

/// 从引擎读取某个缓存，内部方法，必须实现
- (nullable id)readCacheForKey:(NSString *)key;

/// 从引擎写入某个缓存，内部方法，必须实现
- (void)writeCache:(id)object forKey:(NSString *)key;

/// 从引擎清空某个缓存，内部方法，必须实现
- (void)clearCacheForKey:(NSString *)key;

/// 从引擎清空所有缓存，内部方法，必须实现
- (void)clearAllCaches;

@end

#pragma mark - __FWCacheEngine

/**
 *  缓存引擎基类，自动管理缓存有效期，线程安全
 */
NS_SWIFT_NAME(CacheEngine)
@interface __FWCacheEngine : NSObject <__FWCacheProtocol>

@end

NS_ASSUME_NONNULL_END
