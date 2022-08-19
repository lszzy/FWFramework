//
//  Swizzle.m
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

#import "Swizzle.h"
#import <objc/runtime.h>

@implementation __Swizzle

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block {
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

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block {
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
            return [self swizzleInstanceMethod:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    if (originalMethod) {
        class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector), method_getTypeEncoding(originalMethod));
    } else {
        class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
    }
    class_addMethod(originalClass, swizzleSelector, class_getMethodImplementation(originalClass, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector), class_getInstanceMethod(originalClass, swizzleSelector));
    return YES;
}

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(originalClass, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector), class_getInstanceMethod(originalClass, swizzleSelector));
    return YES;
}

@end
