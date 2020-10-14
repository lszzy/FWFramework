/*!
 @header     FWSwizzle.m
 @indexgroup FWFramework
 @brief      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/5
 */

#import "FWSwizzle.h"
#import "FWProxy.h"
#import <objc/runtime.h>

@implementation NSObject (FWSwizzle)

#pragma mark - Simple

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

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(self, originalSelector, class_getMethodImplementation(self, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(self, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(self, originalSelector), class_getInstanceMethod(self, swizzleSelector));
    return YES;
}

+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    return [object_getClass((id)self) fwSwizzleInstanceMethod:originalSelector with:swizzleSelector block:swizzleBlock];
}

+ (SEL)fwSwizzleSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"fw_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

#pragma mark - Complex

+ (BOOL)fwSwizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self fwSwizzleClass:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self fwSwizzleClass:target selector:originalSelector withBlock:block];
        }
    } else {
        return [target fwSwizzleMethod:originalSelector identifier:identifier withBlock:block];
    }
}

+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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

+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) return NO;
    
    static NSMutableSet *swizzleIdentifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleIdentifiers = [NSMutableSet new];
    });
    
    @synchronized (swizzleIdentifiers) {
        NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(originalClass), NSStringFromSelector(originalSelector), identifier];
        if (![swizzleIdentifiers containsObject:swizzleIdentifier]) {
            [swizzleIdentifiers addObject:swizzleIdentifier];
            return [self fwSwizzleClass:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

- (BOOL)fwSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject fwSwizzleClass:object_getClass(self) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)fwIsSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self, NSSelectorFromString(swizzleIdentifier)) boolValue];
}

#pragma mark - Property

@dynamic fwTempObject;

- (id)fwTempObject
{
    return objc_getAssociatedObject(self, @selector(fwTempObject));
}

- (void)setFwTempObject:(id)fwTempObject
{
    if (fwTempObject != self.fwTempObject) {
        [self willChangeValueForKey:@"fwTempObject"];
        objc_setAssociatedObject(self, @selector(fwTempObject), fwTempObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwTempObject"];
    }
}

- (id)fwPropertyForName:(NSString *)name
{
    id object = objc_getAssociatedObject(self, NSSelectorFromString(name));
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)fwSetProperty:(id)object forName:(NSString *)name
{
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

- (void)fwSetPropertyWeak:(id)object forName:(NSString *)name
{
    if (object != [self fwPropertyForName:name]) {
        [self willChangeValueForKey:name];
        objc_setAssociatedObject(self, NSSelectorFromString(name), [[FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:name];
    }
}

#pragma mark - Bind

- (NSMutableDictionary *)fwAllBoundObjects
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (void)fwBindObject:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self fwAllBoundObjects] setObject:object forKey:key];
    } else {
        [[self fwAllBoundObjects] removeObjectForKey:key];
    }
}

- (void)fwBindObjectWeak:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self fwAllBoundObjects] setObject:[[FWWeakObject alloc] initWithObject:object] forKey:key];
    } else {
        [[self fwAllBoundObjects] removeObjectForKey:key];
    }
}

- (id)fwBoundObjectForKey:(NSString *)key
{
    if (!key.length) return nil;
    
    id object = [[self fwAllBoundObjects] objectForKey:key];
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)fwBindDouble:(double)doubleValue forKey:(NSString *)key
{
    [self fwBindObject:@(doubleValue) forKey:key];
}

- (double)fwBoundDoubleForKey:(NSString *)key
{
    id object = [self fwBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object doubleValue];
    } else {
        return 0.0;
    }
}

- (void)fwBindBool:(BOOL)boolValue forKey:(NSString *)key
{
    [self fwBindObject:@(boolValue) forKey:key];
}

- (BOOL)fwBoundBoolForKey:(NSString *)key
{
    id object = [self fwBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object boolValue];
    } else {
        return NO;
    }
}

- (void)fwBindInt:(NSInteger)integerValue forKey:(NSString *)key
{
    [self fwBindObject:@(integerValue) forKey:key];
}

- (NSInteger)fwBoundIntForKey:(NSString *)key
{
    id object = [self fwBoundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object integerValue];
    } else {
        return 0;
    }
}

- (void)fwRemoveBindingForKey:(NSString *)key
{
    [self fwBindObject:nil forKey:key];
}

- (void)fwRemoveAllBindings
{
    [[self fwAllBoundObjects] removeAllObjects];
}

- (NSArray<NSString *> *)fwAllBindingKeys
{
    return [[self fwAllBoundObjects] allKeys];
}

- (BOOL)fwHasBindingKey:(NSString *)key
{
    return [[self fwAllBindingKeys] containsObject:key];
}

@end
