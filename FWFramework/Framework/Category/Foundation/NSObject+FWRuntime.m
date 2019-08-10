/*!
 @header     NSObject+FWRuntime.m
 @indexgroup FWFramework
 @brief      NSObject运行时分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "NSObject+FWRuntime.h"
#import "NSString+FWFramework.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation NSObject (FWRuntime)

#pragma mark - Property

- (id)fwPropertyForName:(NSString *)name
{
    return objc_getAssociatedObject(self, NSSelectorFromString(name));
}

- (void)fwSetProperty:(id)object forName:(NSString *)name
{
    // 仅当值发生改变才触发KVO，下同
    if (object != [self fwPropertyForName:name]) {
        [self willChangeValueForKey:name];
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, object ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:name];
    }
}

- (void)fwSetPropertyWeak:(id)object forName:(NSString *)name
{
    if (object != [self fwPropertyForName:name]) {
        [self willChangeValueForKey:name];
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:name];
    }
}

- (void)fwSetPropertyCopy:(id)object forName:(NSString *)name
{
    if (object != [self fwPropertyForName:name]) {
        [self willChangeValueForKey:name];
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, object ? OBJC_ASSOCIATION_COPY_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:name];
    }
}

#pragma mark - Associate

- (id)fwAssociatedObjectForKey:(const void *)key
{
    return objc_getAssociatedObject(self, key);
}

- (void)fwSetAssociatedObject:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, object ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
}

- (void)fwSetAssociatedObjectWeak:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_ASSIGN);
}

- (void)fwSetAssociatedObjectCopy:(id)object forKey:(const void *)key
{
    objc_setAssociatedObject(self, key, object, object ? OBJC_ASSOCIATION_COPY_NONATOMIC : OBJC_ASSOCIATION_ASSIGN);
}

- (void)fwRemoveAssociatedObjectForKey:(const void *)key
{
    objc_setAssociatedObject(self, key, nil, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - Swizzle

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    // 添加当前类方法实现，防止影响到父类方法
    if (originalMethod) {
        class_addMethod(self, originalSelector, class_getMethodImplementation(self, originalSelector), method_getTypeEncoding(originalMethod));
    // 当前类方法不存在，添加空实现
    } else {
        class_addMethod(self, originalSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
    }
    class_addMethod(self, swizzleSelector, class_getMethodImplementation(self, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSelector), class_getInstanceMethod(self, swizzleSelector));
    return YES;
}

+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    return [object_getClass((id)self) fwSwizzleInstanceMethod:originalSelector with:swizzleSelector];
}

+ (BOOL)fwSwizzleMethod:(SEL)originalSelector in:(Class)originalClass with:(SEL)swizzleSelector in:(Class)swizzleClass
{
    if (!originalClass || !swizzleClass) {
        return NO;
    }
    
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(swizzleClass, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    BOOL addMethod = class_addMethod(originalClass, originalSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (addMethod) {
        if (originalMethod) {
            class_replaceMethod(swizzleClass, swizzleSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            class_replaceMethod(swizzleClass, swizzleSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
        }
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    return YES;
}

#pragma mark - Value

- (id)fwValueForKey:(NSString *)key
{
    if (@available(iOS 13.0, *)) {
        if ([self isKindOfClass:[UIView class]]) {
            key = [key hasPrefix:@"_"] ? [key substringFromIndex:1] : key;
            Ivar ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"_%@", key].UTF8String);
            if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"_is%@", key.fwUcfirstString].UTF8String);
            if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), key.UTF8String);
            if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"is%@", key.fwUcfirstString].UTF8String);
            
            if (ivar) {
                if (strncmp(@encode(id), ivar_getTypeEncoding(ivar), strlen(@encode(id))) == 0) {
                    return object_getIvar(self, ivar);
                }
                ptrdiff_t ivarOffset = ivar_getOffset(ivar);
                unsigned char * bytes = (unsigned char *)(__bridge void *)self;
                NSValue *value = @(*(bytes + ivarOffset));
                return value;
            } else {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", key.fwUcfirstString]);
                if ([self respondsToSelector:selector]) return [self performSelector:selector];
                selector = NSSelectorFromString(key);
                if ([self respondsToSelector:selector]) return [self performSelector:selector];
                selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", key.fwUcfirstString]);
                if ([self respondsToSelector:selector]) return [self performSelector:selector];
                selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", key]);// 这一步是额外加的，系统的 valueForKey: 没有
                if ([self respondsToSelector:selector]) return [self performSelector:selector];
                #pragma clang diagnostic pop
            }
            return nil;
        }
    }
    return [self valueForKey:key];
}

@end
