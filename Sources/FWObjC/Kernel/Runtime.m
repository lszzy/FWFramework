//
//  Runtime.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "Runtime.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface __WeakObject : NSObject

@property (nonatomic, weak, readonly, nullable) id object;

@end

@implementation __WeakObject

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        _object = object;
    }
    return self;
}

@end

@implementation NSObject (FWRuntime)

#pragma mark - Property

- (id)__propertyForName:(NSString *)name {
    id object = objc_getAssociatedObject(self, NSSelectorFromString(name));
    if ([object isKindOfClass:[__WeakObject class]]) {
        object = [(__WeakObject *)object object];
    }
    return object;
}

- (void)__setProperty:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)__setPropertyAssign:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (void)__setPropertyCopy:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), object, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)__setPropertyWeak:(id)object forName:(NSString *)name {
    if (object != [self __propertyForName:name]) {
        objc_setAssociatedObject(self, NSSelectorFromString(name), [[__WeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Method

- (id)__invokeMethod:(SEL)aSelector {
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

- (id)__invokeMethod:(SEL)aSelector withObject:(id)object {
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

- (id)__invokeMethod:(SEL)aSelector withObjects:(NSArray *)objects {
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

- (id)__invokeSuperMethod:(SEL)aSelector {
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector);
}

- (id)__invokeSuperMethod:(SEL)aSelector withObject:(id)object {
    struct objc_super mySuper;
    mySuper.receiver = self;
    mySuper.super_class = class_getSuperclass(object_getClass(self));
    
    id (*objc_superAllocTyped)(struct objc_super *, SEL, ...) = (void *)&objc_msgSendSuper;
    return (*objc_superAllocTyped)(&mySuper, aSelector, object);
}

- (id)__invokeGetter:(NSString *)name {
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector];
    selector = NSSelectorFromString(name);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", name]);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector];
    #pragma clang diagnostic pop
    return nil;
}

- (id)__invokeSetter:(NSString *)name withObject:(id)object {
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector withObject:object];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ucfirstName]);
    if ([self respondsToSelector:selector]) return [self __invokeMethod:selector withObject:object];
    #pragma clang diagnostic pop
    return nil;
}

@end
