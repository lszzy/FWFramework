//
//  Runtime.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "Runtime.h"
#import "Proxy.h"

@implementation __Runtime

#pragma mark - Property

+ (id)getProperty:(id)target forName:(NSString *)name {
    if (!target) return nil;
    id object = objc_getAssociatedObject(target, NSSelectorFromString(name));
    if ([object isKindOfClass:[__WeakObject class]]) {
        object = [(__WeakObject *)object object];
    }
    return object;
}

+ (void)setPropertyPolicy:(id)target withObject:(id)object policy:(objc_AssociationPolicy)policy forName:(NSString *)name {
    if (!target || [self getProperty:target forName:name] == object) return;
    objc_setAssociatedObject(target, NSSelectorFromString(name), object, policy);
}

+ (void)setPropertyWeak:(id)target withObject:(id)object forName:(NSString *)name {
    if (!target || [self getProperty:target forName:name] == object) return;
    objc_setAssociatedObject(target, NSSelectorFromString(name), [[__WeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Method

+ (id)invokeMethod:(id)target selector:(SEL)aSelector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([target respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([target class], aSelector));
        if (type && *type == 'v') {
            free(type);
            [target performSelector:aSelector];
        } else {
            free(type);
            return [target performSelector:aSelector];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

+ (id)invokeMethod:(id)target selector:(SEL)aSelector object:(id)object {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([target respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod([target class], aSelector));
        if (type && *type == 'v') {
            free(type);
            [target performSelector:aSelector withObject:object];
        } else {
            free(type);
            return [target performSelector:aSelector withObject:object];
        }
    }
#pragma clang diagnostic pop
    return nil;
}

+ (id)invokeMethod:(id)target selector:(SEL)aSelector objects:(NSArray *)objects {
    NSMethodSignature *signature = [object_getClass(target) instanceMethodSignatureForSelector:aSelector];
    if (!signature) return nil;
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
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

+ (id)invokeGetter:(id)target name:(NSString *)name {
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", ucfirstName]);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector];
    selector = NSSelectorFromString(name);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", ucfirstName]);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", name]);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector];
    #pragma clang diagnostic pop
    return nil;
}

+ (id)invokeSetter:(id)target name:(NSString *)name object:(id)object {
    name = [name hasPrefix:@"_"] ? [name substringFromIndex:1] : name;
    NSString *ucfirstName = name.length ? [NSString stringWithFormat:@"%@%@", [name substringToIndex:1].uppercaseString, [name substringFromIndex:1]] : nil;
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"set%@:", ucfirstName]);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector object:object];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_set%@:", ucfirstName]);
    if ([target respondsToSelector:selector]) return [self invokeMethod:target selector:selector object:object];
    #pragma clang diagnostic pop
    return nil;
}

@end
