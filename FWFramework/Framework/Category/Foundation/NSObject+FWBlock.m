/*!
 @header     NSObject+FWBlock.m
 @indexgroup FWFramework
 @brief      NSObject+FWBlock
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import "NSObject+FWBlock.h"

@implementation NSObject (FWBlock)

+ (id)fwPerformBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    return [NSObject fwPerformBlock:block onQueue:dispatch_get_main_queue() afterDelay:delay];
}

+ (id)fwPerformBlockInBackground:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    return [NSObject fwPerformBlock:block onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) afterDelay:delay];
}

+ (id)fwPerformBlock:(void (^)(void))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay
{
    NSParameterAssert(block != nil);
    
    __block BOOL cancelled = NO;

    void (^wrapper)(BOOL) = ^(BOOL cancel) {
        if (cancel) {
            cancelled = YES;
            return;
        }
        if (!cancelled) block();
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(NSEC_PER_SEC * delay)), queue, ^{ wrapper(NO); });
    
    return [wrapper copy];
}

+ (void)fwCancelBlock:(id)block
{
    NSParameterAssert(block != nil);
    void (^wrapper)(BOOL) = block;
    wrapper(YES);
}

- (id)fwPerformBlock:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay
{
    return [self fwPerformBlock:block onQueue:dispatch_get_main_queue() afterDelay:delay];
}

- (id)fwPerformBlockInBackground:(void (^)(id obj))block afterDelay:(NSTimeInterval)delay
{
    return [self fwPerformBlock:block onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) afterDelay:delay];
}

- (id)fwPerformBlock:(void (^)(id obj))block onQueue:(dispatch_queue_t)queue afterDelay:(NSTimeInterval)delay
{
    NSParameterAssert(block != nil);
    
    __block BOOL cancelled = NO;
    
    void (^wrapper)(BOOL) = ^(BOOL cancel) {
        if (cancel) {
            cancelled = YES;
            return;
        }
        if (!cancelled) block(self);
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(NSEC_PER_SEC * delay)), queue, ^{
        wrapper(NO);
    });
    
    return [wrapper copy];
}

+ (void)fwSyncPerformAsyncBlock:(void (^)(void (^)(void)))asyncBlock
{
    // 使用信号量阻塞当前线程，等待block执行结果
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    void (^completionHandler)(void) = ^{
        dispatch_semaphore_signal(semaphore);
    };
    asyncBlock(completionHandler);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)fwSyncPerformAsyncBlock:(void (^)(void (^)(void)))asyncBlock
{
    [NSObject fwSyncPerformAsyncBlock:asyncBlock];
}

@end
