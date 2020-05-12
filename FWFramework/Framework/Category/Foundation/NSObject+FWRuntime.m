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
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:name];
    }
}

- (void)fwSetPropertyAssign:(id)object forName:(NSString *)name
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
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_COPY_NONATOMIC);
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

#pragma mark - Weak

- (id)fwPropertyWeakForName:(NSString *)name
{
    FWWeakObject *weakObject = objc_getAssociatedObject(self, NSSelectorFromString(name));
    return weakObject.object;
}

- (void)fwSetPropertyWeak:(id)object forName:(NSString *)name
{
    if (object != [self fwPropertyForName:name]) {
        [self willChangeValueForKey:name];
        objc_setAssociatedObject(self, NSSelectorFromString(name), [[FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:name];
    }
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

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector in:(Class)originalClass with:(SEL)swizzleSelector in:(Class)swizzleClass
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

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector in:(Class)originalClass withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) {
        return NO;
    }
    
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP imp = method_getImplementation(originalMethod);
    BOOL isOverride = NO;
    if (originalMethod) {
        Method superclassMethod = class_getInstanceMethod(class_getSuperclass(originalClass), originalSelector);
        if (!superclassMethod) {
            isOverride = YES;
        } else {
            isOverride = (originalMethod != superclassMethod);
        }
    }
    
    IMP (^originalIMP)(void) = ^IMP(void) {
        IMP result = NULL;
        if (isOverride) {
            result = imp;
        } else {
            Class superclass = class_getSuperclass(originalClass);
            result = class_getMethodImplementation(superclass, originalSelector);
        }
        if (!result) {
            result = imp_implementationWithBlock(^(id selfObject){});
        }
        return result;
    };
    
    if (isOverride) {
        method_setImplementation(originalMethod, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)));
    } else {
        const char *typeEncoding = method_getTypeEncoding(originalMethod);
        if (!typeEncoding) {
            NSMethodSignature *methodSignature = [originalClass instanceMethodSignatureForSelector:originalSelector];
            NSString *typeString = [methodSignature fwPerformSelector:NSSelectorFromString([NSString stringWithFormat:@"_%@String", @"type"])];
            typeEncoding = typeString.UTF8String;
        }
        
        class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)), typeEncoding);
    }
    return YES;
}

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector in:(Class)originalClass identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) {
        return NO;
    }
    
    static NSMutableSet *swizzleIdentifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleIdentifiers = [NSMutableSet new];
    });
    
    @synchronized (swizzleIdentifiers) {
        NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(originalClass), NSStringFromSelector(originalSelector), identifier];
        if (![swizzleIdentifiers containsObject:swizzleIdentifier]) {
            [swizzleIdentifiers addObject:swizzleIdentifier];
            return [self fwSwizzleInstanceMethod:originalSelector in:originalClass withBlock:block];
        }
        return NO;
    }
}

- (BOOL)fwSwizzleMethod:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    @synchronized ([self class]) {
        static NSInteger swizzleCount = 0;
        Class statedClass = self.class;
        Class baseClass = object_getClass(self);
        
        const char *newClassName = [NSStringFromClass(statedClass) stringByAppendingFormat:@"FWRuntime_%@", @(++swizzleCount)].UTF8String;
        Class newClass = objc_allocateClassPair(baseClass, newClassName, 0);
        Class newBaseClass = object_getClass(newClass);
        if (newClass == nil) return NO;
        
        class_replaceMethod(newClass, @selector(class), imp_implementationWithBlock(^(id self){
            return statedClass;
        }), method_getTypeEncoding(class_getInstanceMethod(newClass, @selector(class))));
        class_replaceMethod(newBaseClass, @selector(class), imp_implementationWithBlock(^(id self){
            return statedClass;
        }), method_getTypeEncoding(class_getInstanceMethod(newBaseClass, @selector(class))));
        objc_registerClassPair(newClass);
        [NSObject fwSwizzleInstanceMethod:originalSelector in:newClass withBlock:block];
        
        object_setClass(self, newClass);
        return YES;
    }
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
