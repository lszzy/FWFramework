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
    
    if (originalMethod) {
        class_addMethod(self, originalSelector, class_getMethodImplementation(self, originalSelector), method_getTypeEncoding(originalMethod));
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

- (BOOL)fwSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject fwSwizzleInstanceMethod:originalSelector in:object_getClass(self) identifier:identifier withBlock:block];
}

- (BOOL)fwIsSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self, NSSelectorFromString(swizzleIdentifier)) boolValue];
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

#ifdef DEBUG

#pragma mark - Test

#import "FWTest.h"

@interface FWTestCase_FWRuntime : FWTestCase

@end

@interface FWTestCase_FWRuntime_Person : NSObject

@property (nonatomic, assign) NSInteger count;

@end

@implementation FWTestCase_FWRuntime_Person

- (void)sayHello
{
    self.count += 1;
}

- (void)sayHello2
{
    self.count += 1;
}

- (void)sayHello3
{
    self.count += 1;
}

@end

@interface FWTestCase_FWRuntime_Student : FWTestCase_FWRuntime_Person

@end

@implementation FWTestCase_FWRuntime_Student

@end

@implementation FWTestCase_FWRuntime_Student (swizzle)

- (void)s_sayHello
{
    [self s_sayHello];
    self.count += 2;
}

@end

@implementation FWTestCase_FWRuntime_Person (swizzle)

- (void)p_sayHello
{
    [self p_sayHello];
    self.count += 3;
}

@end

@implementation FWTestCase_FWRuntime

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWTestCase_FWRuntime_Student fwSwizzleInstanceMethod:@selector(sayHello) with:@selector(s_sayHello)];
        [FWTestCase_FWRuntime_Person fwSwizzleInstanceMethod:@selector(sayHello) with:@selector(p_sayHello)];
        
        [NSObject fwSwizzleInstanceMethod:@selector(sayHello3) in:[FWTestCase_FWRuntime_Student class] withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
            return ^(FWTestCase_FWRuntime_Student *obj) {
                void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
                originalMSG(obj, originalCMD);
                
                obj.count += 2;
            };
        }];
        
        [NSObject fwSwizzleInstanceMethod:@selector(sayHello3) in:[FWTestCase_FWRuntime_Person class] withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
            return ^(FWTestCase_FWRuntime_Person *obj) {
                void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
                originalMSG(obj, originalCMD);
                
                obj.count += 3;
            };
        }];
    });
}

- (void)testMethod
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello];
    FWAssertTrue(student.count == 3);
}

- (void)testBlock
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello3];
    FWAssertTrue(student.count == 6);
}

- (void)testObject
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello2];
    FWAssertTrue(student.count == 1);
    
    student = [FWTestCase_FWRuntime_Student new];
    [student fwSwizzleMethod:@selector(sayHello2) identifier:@"s_sayHello2" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(FWTestCase_FWRuntime_Student *obj) {
            void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
            originalMSG(obj, originalCMD);
            
            if (![obj fwIsSwizzleMethod:@selector(sayHello2) identifier:@"s_sayHello2"]) return;
            obj.count += 2;
        };
    }];
    [student fwSwizzleMethod:@selector(sayHello2) identifier:@"p_sayHello2" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(FWTestCase_FWRuntime_Person *obj) {
            void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
            originalMSG(obj, originalCMD);
            
            if (![obj fwIsSwizzleMethod:@selector(sayHello2) identifier:@"p_sayHello2"]) return;
            obj.count += 3;
        };
    }];
    [student sayHello2];
    FWAssertTrue(student.count == 6);
    
    student = [FWTestCase_FWRuntime_Student new];
    [student sayHello2];
    FWAssertTrue(student.count == 1);
}

@end

#endif
