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

#pragma mark - Block

#ifndef	weakify

/*!
 @brief 解决block循环引用，@weakify，和@strongify配对使用
 
 @param x 变量名，如self
 */
#define weakify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

#endif /* weakify */

#ifndef	strongify

/*!
 @brief 解决block循环引用，@strongify，和@weakify配对使用
 
 @param x 变量名，如self
 */
#define strongify( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

#endif /* strongify */

/*!
 @brief 解决block循环引用，和FWStrongify配对使用
 
 @param x 变量名，如self
 */
#define FWWeakify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) x##_weak_ = x; \
    _Pragma("clang diagnostic pop")

/*!
 @brief 解决block循环引用，和FWWeakify配对使用
 
 @param x 变量名，如self
 */
#define FWStrongify( x ) \
    @_Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = x##_weak_; \
    _Pragma("clang diagnostic pop")

/*!
 @brief 解决self循环引用。等价于：typeof(self) __weak self_weak_ = self;
 */
#define FWWeakifySelf( ) \
    FWWeakify( self )

/*!
 @brief 解决self循环引用。等价于：typeof(self_weak_) __strong self = self_weak_;
 */
#define FWStrongifySelf( ) \
    FWStrongify( self )

/*!
 @brief 通用不带参数block
 */
typedef void (^FWBlockVoid)(void);

/*!
 @brief 通用id参数block
 
 @param param id参数
 */
typedef void (^FWBlockParam)(id param);

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

// 延迟delay秒后主线程执行，返回可取消的block
+ (id)fwPerformBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后后台线程执行，返回可取消的block
+ (id)fwPerformBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后指定线程执行，返回可取消的block
+ (id)fwPerformBlock:(void (^)(void))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

// 取消指定延迟block
+ (void)fwCancelBlock:(id)block;

// 延迟delay秒后主线程执行，返回可取消的block
- (id)fwPerformBlock:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后后台线程执行，返回可取消的block
- (id)fwPerformBlockInBackground:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay;

// 延迟delay秒后指定线程执行，返回可取消的block
- (id)fwPerformBlock:(void (^)(id obj))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay;

// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler
+ (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

// 同步方式执行异步block，阻塞当前线程(信号量)，异步block必须调用completionHandler
- (void)fwSyncPerformAsyncBlock:(void (^)(void (^completionHandler)(void)))asyncBlock;

@end

NS_ASSUME_NONNULL_END
