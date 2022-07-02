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

#pragma mark - Runtime

- (id)fw_invokeMethod:(SEL)aSelector
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

- (id)fw_invokeMethod:(SEL)aSelector withObject:(id)object
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

- (id)fw_invokeSuperMethod:(SEL)aSelector
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector);
}

- (id)fw_invokeSuperMethod:(SEL)aSelector withObject:(id)object
{
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL, ...) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector, object);
}

- (id)fw_invokeGetter:(NSString *)name
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector];
    selector = NSSelectorFromString(name);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", name]);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector];
    #pragma clang diagnostic pop
    return nil;
}

- (id)fw_invokeSetter:(NSString *)name withObject:(id)object
{
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector withObject:object];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self fw_invokeMethod:selector withObject:object];
    #pragma clang diagnostic pop
    return nil;
}

#pragma mark - Property

@dynamic fw_tempObject;

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

- (id)fw_propertyForName:(NSString *)name
{
    id object = objc_getAssociatedObject(self, NSSelectorFromString(name));
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)fw_setProperty:(id)object forName:(NSString *)name
{
    if (object != [self fw_propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)fw_setPropertyAssign:(id)object forName:(NSString *)name
{
    if (object != [self fw_propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)fw_setPropertyCopy:(id)object forName:(NSString *)name
{
    if (object != [self fw_propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)fw_setPropertyWeak:(id)object forName:(NSString *)name
{
    if (object != [self fw_propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), [[FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Bind

- (NSMutableDictionary *)fw_allBoundObjects
{
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (void)fw_bindObject:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self fw_allBoundObjects] setObject:object forKey:key];
    } else {
        [[self fw_allBoundObjects] removeObjectForKey:key];
    }
}

- (void)fw_bindObjectWeak:(id)object forKey:(NSString *)key
{
    if (!key.length) return;
    
    if (object) {
        [[self fw_allBoundObjects] setObject:[[FWWeakObject alloc] initWithObject:object] forKey:key];
    } else {
        [[self fw_allBoundObjects] removeObjectForKey:key];
    }
}

- (id)fw_boundObjectForKey:(NSString *)key
{
    if (!key.length) return nil;
    
    id object = [[self fw_allBoundObjects] objectForKey:key];
    if ([object isKindOfClass:[FWWeakObject class]]) {
        object = [(FWWeakObject *)object object];
    }
    return object;
}

- (void)fw_bindDouble:(double)doubleValue forKey:(NSString *)key
{
    [self fw_bindObject:@(doubleValue) forKey:key];
}

- (double)fw_boundDoubleForKey:(NSString *)key
{
    id object = [self fw_boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object doubleValue];
    } else {
        return 0.0;
    }
}

- (void)fw_bindBool:(BOOL)boolValue forKey:(NSString *)key
{
    [self fw_bindObject:@(boolValue) forKey:key];
}

- (BOOL)fw_boundBoolForKey:(NSString *)key
{
    id object = [self fw_boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object boolValue];
    } else {
        return NO;
    }
}

- (void)fw_bindInt:(NSInteger)integerValue forKey:(NSString *)key
{
    [self fw_bindObject:@(integerValue) forKey:key];
}

- (NSInteger)fw_boundIntForKey:(NSString *)key
{
    id object = [self fw_boundObjectForKey:key];
    if ([object isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)object integerValue];
    } else {
        return 0;
    }
}

- (void)fw_removeBindingForKey:(NSString *)key
{
    [self fw_bindObject:nil forKey:key];
}

- (void)fw_removeAllBindings
{
    [[self fw_allBoundObjects] removeAllObjects];
}

- (NSArray<NSString *> *)fw_allBindingKeys
{
    return [[self fw_allBoundObjects] allKeys];
}

- (BOOL)fw_hasBindingKey:(NSString *)key
{
    return [[self fw_allBindingKeys] containsObject:key];
}

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
    class_addMethod(clazz, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
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
        return [((NSObject *)target) fw_swizzleInstanceMethod:originalSelector identifier:identifier withBlock:block];
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

#pragma mark - Class

+ (NSArray<NSString *> *)fw_classMethods:(Class)clazz superclass:(BOOL)superclass
{
    NSArray<NSString *> *cacheNames = [self fw_classCaches:clazz superclass:superclass type:@"M" values:nil];
    if (cacheNames) return cacheNames;
    
    NSMutableArray *resultNames = [NSMutableArray array];
    Class targetClass = clazz;
    while (targetClass != NULL) {
        unsigned int resultCount = 0;
        Method *methods = class_copyMethodList(targetClass, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:sel_getName(method_getName(methods[i])) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(methods);
        
        targetClass = superclass ? class_getSuperclass(targetClass) : NULL;
        if (targetClass == NULL || targetClass == [NSObject class]) break;
    }
    
    [self fw_classCaches:clazz superclass:superclass type:@"M" values:resultNames];
    return resultNames;
}

+ (NSArray<NSString *> *)fw_classProperties:(Class)clazz superclass:(BOOL)superclass
{
    NSArray<NSString *> *cacheNames = [self fw_classCaches:clazz superclass:superclass type:@"P" values:nil];
    if (cacheNames) return cacheNames;
    
    NSMutableArray *resultNames = [NSMutableArray array];
    Class targetClass = clazz;
    while (targetClass != NULL) {
        unsigned int resultCount = 0;
        objc_property_t *properties = class_copyPropertyList(targetClass, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:property_getName(properties[i]) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(properties);
        
        targetClass = superclass ? class_getSuperclass(targetClass) : NULL;
        if (targetClass == NULL || targetClass == [NSObject class]) break;
    }
    
    [self fw_classCaches:clazz superclass:superclass type:@"P" values:resultNames];
    return resultNames;
}

+ (NSArray<NSString *> *)fw_classIvars:(Class)clazz superclass:(BOOL)superclass
{
    NSArray<NSString *> *cacheNames = [self fw_classCaches:clazz superclass:superclass type:@"V" values:nil];
    if (cacheNames) return cacheNames;
    
    NSMutableArray *resultNames = [NSMutableArray array];
    Class targetClass = clazz;
    while (targetClass != NULL) {
        unsigned int resultCount = 0;
        Ivar *ivars = class_copyIvarList(targetClass, &resultCount);
        for (unsigned int i = 0; i < resultCount; i++) {
            NSString *resultName = [NSString stringWithUTF8String:ivar_getName(ivars[i]) ?: ""];
            if (resultName.length > 0 && ![resultNames containsObject:resultName]) {
                [resultNames addObject:resultName];
            }
        }
        free(ivars);
        
        targetClass = superclass ? class_getSuperclass(targetClass) : NULL;
        if (targetClass == NULL || targetClass == [NSObject class]) break;
    }
    
    [self fw_classCaches:clazz superclass:superclass type:@"V" values:resultNames];
    return resultNames;
}

+ (NSArray<NSString *> *)fw_classCaches:(Class)clazz
                             superclass:(BOOL)superclass
                                   type:(NSString *)type
                                 values:(NSArray<NSString *> *)values
{
    static NSMutableDictionary *caches = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        caches = [[NSMutableDictionary alloc] init];
    });
    
    NSString *identifier = [NSString stringWithFormat:@"%@.%@%@%@",
                            NSStringFromClass(clazz),
                            class_isMetaClass(clazz) ? @"M" : @"C",
                            superclass ? @"S" : @"C",
                            type];
    if (values) [caches setObject:values forKey:identifier];
    return [caches objectForKey:identifier];
}

@end
