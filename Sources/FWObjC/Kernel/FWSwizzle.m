//
//  FWSwizzle.m
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import "FWSwizzle.h"
#import <objc/runtime.h>

#pragma mark - NSObject+FWSwizzle

@implementation NSObject (FWSwizzle)

#pragma mark - Exchange

+ (BOOL)fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector
{
    return [self fw_exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector forClass:self];
}

+ (BOOL)fw_exchangeClassMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector
{
    return [self fw_exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector forClass:object_getClass((id)self)];
}

+ (BOOL)fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector forClass:(Class)clazz
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    if (originalMethod) {
        class_addMethod(clazz, originalSelector, class_getMethodImplementation(clazz, originalSelector), method_getTypeEncoding(originalMethod));
    } else {
        class_addMethod(clazz, originalSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
    }
    class_addMethod(clazz, swizzleSelector, class_getMethodImplementation(clazz, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(clazz, originalSelector), class_getInstanceMethod(clazz, swizzleSelector));
    return YES;
}

+ (BOOL)fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock
{
    return [self fw_exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector withBlock:swizzleBlock forClass:self];
}

+ (BOOL)fw_exchangeClassMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock
{
    return [self fw_exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector withBlock:swizzleBlock forClass:object_getClass((id)self)];
}

+ (BOOL)fw_exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock forClass:(Class)clazz
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(clazz, originalSelector, class_getMethodImplementation(clazz, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(clazz, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(swizzleMethod));
    method_exchangeImplementations(class_getInstanceMethod(clazz, originalSelector), class_getInstanceMethod(clazz, swizzleSelector));
    return YES;
}

+ (SEL)fw_exchangeSwizzleSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"fw_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

#pragma mark - Swizzle

+ (BOOL)fw_swizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self fw_swizzleInstanceMethod:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self fw_swizzleInstanceMethod:target selector:originalSelector withBlock:block];
        }
    } else {
        return [((NSObject *)target) fw_swizzleInstanceMethod:originalSelector identifier:(identifier ?: @"") withBlock:block];
    }
}

+ (BOOL)fw_swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) return NO;
    
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
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            SEL typeSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@String", @"type"]);
            NSString *typeString = [methodSignature respondsToSelector:typeSelector] ? [methodSignature performSelector:typeSelector] : nil;
            #pragma clang diagnostic pop
            typeEncoding = typeString.UTF8String;
        }
        
        class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)), typeEncoding);
    }
    return YES;
}

+ (BOOL)fw_swizzleClassMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    return [self fw_swizzleInstanceMethod:object_getClass((id)originalClass) selector:originalSelector withBlock:block];
}

+ (BOOL)fw_swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) return NO;
    
    static NSMutableSet *swizzleIdentifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleIdentifiers = [NSMutableSet new];
    });
    
    @synchronized (swizzleIdentifiers) {
        NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@%@%@-%@", NSStringFromClass(originalClass), class_isMetaClass(originalClass) ? @"+" : @"-", NSStringFromSelector(originalSelector), identifier];
        if (![swizzleIdentifiers containsObject:swizzleIdentifier]) {
            [swizzleIdentifiers addObject:swizzleIdentifier];
            return [self fw_swizzleInstanceMethod:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

+ (BOOL)fw_swizzleClassMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    return [self fw_swizzleInstanceMethod:object_getClass((id)originalClass) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)fw_swizzleInstanceMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject fw_swizzleInstanceMethod:object_getClass(self) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)fw_isSwizzleInstanceMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self, NSSelectorFromString(swizzleIdentifier)) boolValue];
}

@end
