//
//  FWRuntime.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "FWRuntime.h"
#import "FWProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - NSObject+FWRuntime

@implementation NSObject (FWRuntime)

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

- (id)fw_invokeMethod:(SEL)aSelector withObjects:(NSArray *)objects
{
    NSMethodSignature *signature = [object_getClass(self) instanceMethodSignatureForSelector:aSelector];
    if (!signature) return nil;
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = self;
    invocation.selector = aSelector;
    NSInteger paramsCount = MIN(signature.numberOfArguments - 2, objects.count);
    for (NSInteger i = 0; i < paramsCount; i++) {
        id object = objects[i];
        if ([object isKindOfClass:[NSNull class]]) continue;
        [invocation setArgument:&object atIndex:i + 2];
    }
    @try {
        [invocation invoke];
    } @catch (NSException *exception) {
        return nil;
    }
    
    id returnValue = nil;
    if (signature.methodReturnLength) {
        [invocation getReturnValue:&returnValue];
    }
    return returnValue;
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

@end
