/*!
 @header     NSObject+FWThread.m
 @indexgroup FWFramework
 @brief      NSObject+FWThread
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/21
 */

#import "NSObject+FWThread.h"
#import <objc/runtime.h>

@implementation NSObject (FWThread)

- (void)fwLock
{
    dispatch_semaphore_wait(self.fwLockSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)fwUnlock
{
    dispatch_semaphore_signal(self.fwLockSemaphore);
}

- (dispatch_semaphore_t)fwLockSemaphore
{
    dispatch_semaphore_t semaphore = objc_getAssociatedObject(self, _cmd);
    if (!semaphore) {
        semaphore = dispatch_semaphore_create(1);
        objc_setAssociatedObject(self, _cmd, semaphore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return semaphore;
}

@end
