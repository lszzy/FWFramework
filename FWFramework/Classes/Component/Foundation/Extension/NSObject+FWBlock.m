/*!
 @header     NSObject+FWBlock.m
 @indexgroup FWFramework
 @brief      NSObject+FWBlock
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import "NSObject+FWBlock.h"
#import <objc/runtime.h>

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

+ (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block
{
    static NSMutableSet *identifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identifiers = [NSMutableSet new];
    });
    
    @synchronized (identifiers) {
        if (![identifiers containsObject:identifier]) {
            if (block) {
                block();
            }
            [identifiers addObject:identifier];
        }
    }
}

- (void)fwPerformOnce:(NSString *)identifier withBlock:(void (^)(void))block
{
    @synchronized (self) {
        NSMutableSet *identifiers = objc_getAssociatedObject(self, @selector(fwPerformOnce:withBlock:));
        if (!identifiers) {
            identifiers = [NSMutableSet new];
            objc_setAssociatedObject(self, @selector(fwPerformOnce:withBlock:), identifiers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        if (![identifiers containsObject:identifier]) {
            if (block) {
                block();
            }
            [identifiers addObject:identifier];
        }
    }
}

+ (void)fwPerformBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval)delayInterval
{
    NSParameterAssert(block != nil);
    NSParameterAssert(completion != nil);
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    [NSObject fwPerformBlock:block completion:completion retryCount:retryCount timeoutInterval:timeoutInterval delayInterval:delayInterval startTime:startTime];
}

+ (void)fwPerformBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval)delayInterval startTime:(NSTimeInterval)startTime
{
    block(^(BOOL success, id _Nullable obj) {
        if (!success && retryCount > 0 && ([[NSDate date] timeIntervalSince1970] - startTime) < timeoutInterval) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [NSObject fwPerformBlock:block completion:completion retryCount:retryCount - 1 timeoutInterval:timeoutInterval delayInterval:delayInterval startTime:startTime];
            });
        } else {
            completion(success, obj);
        }
    });
}

- (void)fwPerformBlock:(void (^)(void (^completionHandler)(BOOL success, id _Nullable obj)))block completion:(void (^)(BOOL success, id _Nullable obj))completion retryCount:(NSUInteger)retryCount timeoutInterval:(NSTimeInterval)timeoutInterval delayInterval:(NSTimeInterval)delayInterval
{
    [NSObject fwPerformBlock:block completion:completion retryCount:retryCount timeoutInterval:timeoutInterval delayInterval:delayInterval];
}

@end
