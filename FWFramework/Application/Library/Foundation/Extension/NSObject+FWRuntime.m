/*!
 @header     NSObject+FWRuntime.m
 @indexgroup FWFramework
 @brief      NSObject运行时分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "NSObject+FWRuntime.h"
#import "FWProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>

@implementation NSObject (FWRuntime)

#pragma mark - Associate

- (id)fwAssociatedObjectForKey:(const void *)key
{
    return objc_getAssociatedObject(self, key);
}

- (void)fwSetAssociatedObject:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwSetAssociatedObjectAssign:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_ASSIGN);
}

- (void)fwSetAssociatedObjectCopy:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)fwRemoveAssociatedObjectForKey:(const void *)key
{
    objc_setAssociatedObject(self, key, nil, OBJC_ASSOCIATION_ASSIGN);
}

- (id)fwAssociatedObjectWeakForKey:(const void *)key
{
    FWWeakObject *weakObject = objc_getAssociatedObject(self, key);
    return weakObject.object;
}

- (void)fwSetAssociatedObjectWeak:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, [[FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Selector

- (id)fwPerformSelector:(SEL)aSelector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([self class], aSelector));
        if (type && *type == 'v') {
            [self performSelector:aSelector];
        } else {
            return [self performSelector:aSelector];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

- (id)fwPerformSelector:(SEL)aSelector withObject:(id)object
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([self class], aSelector));
        if (type && *type == 'v') {
            [self performSelector:aSelector withObject:object];
        } else {
            return [self performSelector:aSelector withObject:object];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

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

- (id)fwPerformPropertySelector:(NSString *)name
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector];
    selector = NSSelectorFromString(name);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", name]);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector];
    #pragma clang diagnostic pop
    return nil;
}

- (id)fwPerformPropertySelector:(NSString *)name withObject:(id)object
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector withObject:object];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fwPerformSelector:selector withObject:object];
    #pragma clang diagnostic pop
    return nil;
}

@end
