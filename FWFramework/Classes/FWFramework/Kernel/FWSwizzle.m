/**
 @header     FWSwizzle.m
 @indexgroup FWFramework
      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/5
 */

#import "FWSwizzle.h"
#import "FWProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

- (BOOL)swizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self.base)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self.base, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject.fw swizzleClass:object_getClass(self.base) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)isSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self.base)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self.base, NSSelectorFromString(swizzleIdentifier)) boolValue];
}

@end

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    return [FWObjectWrapper wrapperWithBase:self];
}

@end

#pragma mark - FWObjectClassWrapper

@implementation FWObjectClassWrapper

#pragma mark - Simple

- (BOOL)swizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    return [self swizzleInstanceMethod:originalSelector with:swizzleSelector clazz:self.base];
}

- (BOOL)swizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    return [self swizzleInstanceMethod:originalSelector with:swizzleSelector clazz:object_getClass((id)self.base)];
}

- (BOOL)swizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector clazz:(Class)clazz
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

- (BOOL)swizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    return [self swizzleInstanceMethod:originalSelector with:swizzleSelector block:swizzleBlock clazz:self.base];
}

- (BOOL)swizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    return [self swizzleInstanceMethod:originalSelector with:swizzleSelector block:swizzleBlock clazz:object_getClass((id)self.base)];
}

- (BOOL)swizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock clazz:(Class)clazz
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(clazz, originalSelector, class_getMethodImplementation(clazz, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(clazz, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(clazz, originalSelector), class_getInstanceMethod(clazz, swizzleSelector));
    return YES;
}

- (SEL)swizzleSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"fw_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

#pragma mark - Complex

- (BOOL)swizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self swizzleClass:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self swizzleClass:target selector:originalSelector withBlock:block];
        }
    } else {
        return [((NSObject *)target).fw swizzleMethod:originalSelector identifier:identifier withBlock:block];
    }
}

- (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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

- (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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
            return [self swizzleClass:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

#pragma mark - Class

- (NSArray<NSString *> *)classMethods:(Class)clazz superclass:(BOOL)superclass
{
    NSMutableArray *resultNames = [NSMutableArray array];
    while (clazz != NULL) {
        unsigned int resultCount = 0;
        Method *methods = class_copyMethodList(clazz, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:sel_getName(method_getName(methods[i])) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(methods);
        
        clazz = superclass ? class_getSuperclass(clazz) : NULL;
        if (clazz == NULL || clazz == [NSObject class]) break;
    }
    return resultNames;
}

- (NSArray<NSString *> *)classProperties:(Class)clazz superclass:(BOOL)superclass
{
    NSMutableArray *resultNames = [NSMutableArray array];
    while (clazz != NULL) {
        unsigned int resultCount = 0;
        objc_property_t *properties = class_copyPropertyList(clazz, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:property_getName(properties[i]) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(properties);
        
        clazz = superclass ? class_getSuperclass(clazz) : NULL;
        if (clazz == NULL || clazz == [NSObject class]) break;
    }
    return resultNames;
}

- (NSArray<NSString *> *)classIvars:(Class)clazz superclass:(BOOL)superclass
{
    NSMutableArray *resultNames = [NSMutableArray array];
    while (clazz != NULL) {
        unsigned int resultCount = 0;
        Ivar *ivars = class_copyIvarList(clazz, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:ivar_getName(ivars[i]) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(ivars);
        
        clazz = superclass ? class_getSuperclass(clazz) : NULL;
        if (clazz == NULL || clazz == [NSObject class]) break;
    }
    return resultNames;
}

@end

@implementation NSObject (FWObjectClassWrapper)

+ (FWObjectClassWrapper *)fw {
    return [FWObjectClassWrapper wrapperWithBase:self];
}

@end

@implementation NSObject (FWSwizzle)

#pragma mark - Runtime

- (id)fwPerformSelector:(SEL)aSelector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([self class], aSelector));
        if (type && *type == 'v') {
            free(type);
            [self performSelector:aSelector];
        } else {
            free(type);
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
            free(type);
            [self performSelector:aSelector withObject:object];
        } else {
            free(type);
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

- (id)fwPerformGetter:(NSString *)name
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

- (id)fwPerformSetter:(NSString *)name withObject:(id)object
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
