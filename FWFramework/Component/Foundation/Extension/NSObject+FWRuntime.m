/*!
 @header     NSObject+FWRuntime.m
 @indexgroup FWFramework
 @brief      NSObject运行时分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "NSObject+FWRuntime.h"
#import <objc/message.h>

@implementation NSObject (FWRuntime)

- (id)fwPerformSuperSelector:(SEL)aSelector
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector);
}

- (id)fwPerformSuperSelector:(SEL)aSelector withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL, ...) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector, object);
}

@end
