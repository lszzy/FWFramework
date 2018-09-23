/*!
 @header     NSThread+FWFramework.h
 @indexgroup FWFramework
 @brief      NSThread+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <Foundation/Foundation.h>

#pragma mark - GCD

// 执行一次block
#define FWDispatchOnce( block ) \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, block);

// 主并行队列执行block
#define FWDispatchGlobal( block ) \
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);

// 主UI线程执行block
#define FWDispatchMain( block ) \
    if ([NSThread isMainThread]) { \
        block(); \
    } else { \
        dispatch_async(dispatch_get_main_queue(), block); \
    }

// 延迟几秒后主UI线程执行block
#define FWDispatchAfter( time, block ) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), block);

// 线程group同步：声明、异步执行(适合内部同步任务)、进入(适合内部异步任务，可调用FWDispatchGlobal等)、离开、通知
#define FWDispatchGroupCreate( ) \
    dispatch_group_t fwGroup = dispatch_group_create();

#define FWDispatchGroupAsync( block ) \
    dispatch_group_async(fwGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);

#define FWDispatchGroupEnter( ) \
    dispatch_group_enter(fwGroup);

#define FWDispatchGroupLeave( ) \
    dispatch_group_leave(fwGroup);

#define FWDispatchGroupNotify( block ) \
    dispatch_group_notify(fwGroup, dispatch_get_main_queue(), block);

#define FWDispatchGroupWait( ) \
    dispatch_group_wait(fwGroup, DISPATCH_TIME_FOREVER);

// 创建GCD信号量，value为初始值，大于等于0
#define FWDispatchSemaphoreCreate( value ) \
    dispatch_semaphore_t fwSemaphore = dispatch_semaphore_create(value);

// 发送GCD信号量，信号量值+1
#define FWDispatchSemaphoreSignal( ) \
    dispatch_semaphore_signal(fwSemaphore);

// 等待GCD信号量。如当前信号量值>0，则信号量值-1并执行后续代码；否则一直等待信号值增加
#define FWDispatchSemaphoreWait( ) \
    dispatch_semaphore_wait(fwSemaphore, DISPATCH_TIME_FOREVER);

// GCD队列创建和同步异步执行
#define FWDispatchQueueCreate( name, type ) \
    dispatch_queue_t fwQueue = dispatch_queue_create(name, type);

#define FWDispatchQueueAsync( block ) \
    dispatch_async(fwQueue, block);

#define FWDispatchQueueSync( block ) \
    dispatch_sync(fwQueue, block);

/*!
 @brief NSThread+FWFramework
 */
@interface NSThread (FWFramework)

@end
