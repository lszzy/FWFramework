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
 @brief 通用不带参数block
 */
typedef void (^FWBlockVoid)(void);

/*!
 @brief 通用id参数block
 
 @param param id参数
 */
typedef void (^FWBlockParam)(id _Nullable param);

/*!
 @brief 通用bool参数block
 
 @param isTrue bool参数
 */
typedef void (^FWBlockBool)(BOOL isTrue);

/*!
 @brief 通用NSInteger参数block
 
 @param index NSInteger参数
 */
typedef void (^FWBlockInt)(NSInteger index);

/*!
 @brief NSObject+FWBlock
 
 @see https://github.com/BlocksKit/BlocksKit
 */
@interface NSObject (FWBlock)

// 延迟delay秒后主线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后后台线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后指定线程执行，返回可取消的block，全局范围
+ (id)fwPerformBlock:(void (^)(void))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

// 取消指定延迟block，全局范围
+ (void)fwCancelBlock:(id)block;

// 延迟delay秒后主线程执行，返回可取消的block，对象范围
- (id)fwPerformBlock:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后后台线程执行，返回可取消的block，对象范围
- (id)fwPerformBlockInBackground:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后指定线程执行，返回可取消的block，对象范围
- (id)fwPerformBlock:(void (^)(id obj))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
+ (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler，全局范围
- (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

// 同一个identifier仅执行一次block，全局范围
+ (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block;

// 同一个identifier仅执行一次block，对象范围
- (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
