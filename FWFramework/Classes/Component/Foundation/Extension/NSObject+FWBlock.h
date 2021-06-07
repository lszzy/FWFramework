/*!
 @header     NSObject+FWBlock.h
 @indexgroup FWFramework
 @brief      NSObject+FWBlock
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSObject+FWBlock
 
 @see https://github.com/BlocksKit/BlocksKit
 */
@interface NSObject (FWBlock)

/// 延迟delay秒后主线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

/// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

/// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlock:(void (^)(void))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

/// 取消指定延迟block，全局范围
+ (void)fwCancelBlock:(id)block;

/// 延迟delay秒后主线程执行，返回可取消的block，对象范围
- (id)fwPerformBlock:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

/// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
- (id)fwPerformBlockInBackground:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

/// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
- (id)fwPerformBlock:(void (^)(id obj))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

/// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
+ (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

/// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
- (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

/// 同一个identifier仅执行一次block，全局范围
+ (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block;

/// 同一个identifier仅执行一次block，对象范围
- (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block;

/// 重试方式执行异步block，直至成功或者次数为0或者超时，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
+ (void)fwPerformBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval)delayInterval;

/// 重试方式执行异步block，直至成功或者次数为0或者超时，完成后回调completion。block必须调用completionHandler，参数示例：重试4次|超时8秒|延迟2秒
- (void)fwPerformBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval)delayInterval;

@end

NS_ASSUME_NONNULL_END
