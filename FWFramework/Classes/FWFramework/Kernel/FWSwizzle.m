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

#pragma mark - NSObject+FWSwizzle

@implementation NSObject (FWSwizzle)

#pragma mark - Property

- (id)fw_tempObject
{
    return objc_getAssociatedObject(self, @selector(fw_tempObject));
}

- (void)setFw_tempObject:(id)tempObject
{
    if (tempObject != self.fw_tempObject) {
        objc_setAssociatedObject(self, @selector(fw_tempObject), tempObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end

#pragma mark - FWObjectWrapper+FWSwizzle

@implementation FWObjectWrapper (FWSwizzle)

- (BOOL)swizzleInstanceMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self.base)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self.base, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject.fw swizzleInstanceMethod:object_getClass(self.base) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)isSwizzleInstanceMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@_%@_%@", NSStringFromClass(object_getClass(self.base)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self.base, NSSelectorFromString(swizzleIdentifier)) boolValue];
}

#pragma mark - Runtime

- (id)invokeMethod:(SEL)aSelector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.base respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([self.base class], aSelector));
        if (type && *type == 'v') {
            free(type);
            [self.base performSelector:aSelector];
        } else {
            free(type);
            return [self.base performSelector:aSelector];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

- (id)invokeMethod:(SEL)aSelector withObject:(id)object
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self.base respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([self.base class], aSelector));
        if (type && *type == 'v') {
            free(type);
            [self.base performSelector:aSelector withObject:object];
        } else {
            free(type);
            return [self.base performSelector:aSelector withObject:object];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

- (id)invokeSuperMethod:(SEL)aSelector
{
    struct objc_super mySuper;
    mySuper.receiver = self.base;
    mySuper.super_class = class_getSuperclass(object_getClass(self.base));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector);
}

- (id)invokeSuperMethod:(SEL)aSelector withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self.base;
    mySuper.super_class = class_getSuperclass(object_getClass(self.base));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL, ...) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector, object);
}

- (id)invokeGetter:(NSString *)name
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", ucfirstName]);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector];
    selector = NSSelectorFromString(name);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", ucfirstName]);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", name]);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector];
    #pragma clang diagnostic pop
    return nil;
}

- (id)invokeSetter:(NSString *)name withObject:(id)object
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ucfirstName]);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector withObject:object];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ucfirstName]);
    if ([self.base respondsToSelector:selector]) return [self invokeMethod:selector withObject:object];
    #pragma clang diagnostic pop
    return nil;
}

#pragma mark - Property

@dynamic tempObject;

- (id)tempObject
{
    return objc_getAssociatedObject(self.base, @selector(tempObject));
}

- (void)setTempObject:(id)tempObject
{
    if (tempObject != self.tempObject) {
        objc_setAssociatedObject(self.base, @selector(tempObject), tempObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (id)propertyForName:(NSString *)name
{
    id object = objc_getAssociatedObject(self.base, NSSelectorFromString(name));
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)setProperty:(id)object forName:(NSString *)name
{
    if (object != [self propertyForName:name]) {
        objc_setAssociatedObject(self.base, NSSelectorFromString(name), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setPropertyAssign:(id)object forName:(NSString *)name
{
    if (object != [self propertyForName:name]) {
        objc_setAssociatedObject(self.base, NSSelectorFromString(name), object, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)setPropertyCopy:(id)object forName:(NSString *)name
{
    if (object != [self propertyForName:name]) {
        objc_setAssociatedObject(self.base, NSSelectorFromString(name), object, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)setPropertyWeak:(id)object forName:(NSString *)name
{
    if (object != [self propertyForName:name]) {
        objc_setAssociatedObject(self.base, NSSelectorFromString(name), [[FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Bind

- (NSMutableDictionary *)allBoundObjects
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self.base, _cmd);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self.base, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (void)bindObject:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self allBoundObjects] setObject:object forKey:key];
    } else {
        [[self allBoundObjects] removeObjectForKey:key];
    }
}

- (void)bindObjectWeak:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self allBoundObjects] setObject:[[FWWeakObject alloc] initWithObject:object] forKey:key];
    } else {
        [[self allBoundObjects] removeObjectForKey:key];
    }
}

- (id)boundObjectForKey:(NSString *)key
{
    if (!key.length) return nil;
    
    id object = [[self allBoundObjects] objectForKey:key];
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)bindDouble:(double)doubleValue forKey:(NSString *)key
{
    [self bindObject:@(doubleValue) forKey:key];
}

- (double)boundDoubleForKey:(NSString *)key
{
    id object = [self boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object doubleValue];
    } else {
        return 0.0;
    }
}

- (void)bindBool:(BOOL)boolValue forKey:(NSString *)key
{
    [self bindObject:@(boolValue) forKey:key];
}

- (BOOL)boundBoolForKey:(NSString *)key
{
    id object = [self boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object boolValue];
    } else {
        return NO;
    }
}

- (void)bindInt:(NSInteger)integerValue forKey:(NSString *)key
{
    [self bindObject:@(integerValue) forKey:key];
}

- (NSInteger)boundIntForKey:(NSString *)key
{
    id object = [self boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object integerValue];
    } else {
        return 0;
    }
}

- (void)removeBindingForKey:(NSString *)key
{
    [self bindObject:nil forKey:key];
}

- (void)removeAllBindings
{
    [[self allBoundObjects] removeAllObjects];
}

- (NSArray<NSString *> *)allBindingKeys
{
    return [[self allBoundObjects] allKeys];
}

- (BOOL)hasBindingKey:(NSString *)key
{
    return [[self allBindingKeys] containsObject:key];
}

@end

#pragma mark - FWClassWrapper+FWSwizzle

@implementation FWClassWrapper (FWSwizzle)

#pragma mark - Exchange

- (BOOL)exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector
{
    return [self exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector forClass:self.base];
}

- (BOOL)exchangeClassMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector
{
    return [self exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector forClass:object_getClass((id)self.base)];
}

- (BOOL)exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector forClass:(Class)clazz
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

- (BOOL)exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock
{
    return [self exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector withBlock:swizzleBlock forClass:self.base];
}

- (BOOL)exchangeClassMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock
{
    return [self exchangeInstanceMethod:originalSelector swizzleMethod:swizzleSelector withBlock:swizzleBlock forClass:object_getClass((id)self.base)];
}

- (BOOL)exchangeInstanceMethod:(SEL)originalSelector swizzleMethod:(SEL)swizzleSelector withBlock:(id)swizzleBlock forClass:(Class)clazz
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(clazz, originalSelector, class_getMethodImplementation(clazz, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(clazz, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(clazz, originalSelector), class_getInstanceMethod(clazz, swizzleSelector));
    return YES;
}

- (SEL)exchangeSwizzleSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"fw_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

#pragma mark - Swizzle

- (BOOL)swizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self swizzleInstanceMethod:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self swizzleInstanceMethod:target selector:originalSelector withBlock:block];
        }
    } else {
        return [((NSObject *)target).fw swizzleInstanceMethod:originalSelector identifier:identifier withBlock:block];
    }
}

- (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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

- (BOOL)swizzleClassMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    return [self swizzleInstanceMethod:object_getClass((id)originalClass) selector:originalSelector withBlock:block];
}

- (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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
            return [self swizzleInstanceMethod:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

- (BOOL)swizzleClassMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    return [self swizzleInstanceMethod:object_getClass((id)originalClass) selector:originalSelector identifier:identifier withBlock:block];
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
