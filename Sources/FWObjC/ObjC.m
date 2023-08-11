//
//  ObjC.m
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import "ObjC.h"

#pragma mark - __FWAutoloader

@protocol __FWAutoloadProtocol <NSObject>
@optional

+ (void)autoload;

@end

@interface __FWAutoloader () <__FWAutoloadProtocol>

@end

@implementation __FWAutoloader

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([__FWAutoloader respondsToSelector:@selector(autoload)]) {
            [__FWAutoloader autoload];
        }
    });
}

@end

#pragma mark - __FWWeakProxy

@implementation __FWWeakProxy

- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}

- (NSUInteger)hash {
    return [_target hash];
}

- (Class)superclass {
    return [_target superclass];
}

- (Class)class {
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy {
    return YES;
}

- (NSString *)description {
    return [_target description];
}

- (NSString *)debugDescription {
    return [_target debugDescription];
}

@end

#pragma mark - __FWDelegateProxy

@implementation __FWDelegateProxy

- (BOOL)isProxy {
    return YES;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([self.target conformsToProtocol:aProtocol]) {
        return YES;
    }
    return [super conformsToProtocol:aProtocol];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.target respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.target];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    if ([self.target respondsToSelector:selector]) {
        return [self.target methodSignatureForSelector:selector];
    }
    return [super methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([self.target respondsToSelector:selector]) {
        return YES;
    }
    return [super respondsToSelector:selector];
}

@end

#pragma mark - __FWObjC

@implementation __FWObjC

+ (id)getAssociatedObject:(id)object forName:(NSString *)name {
    return objc_getAssociatedObject(object, NSSelectorFromString(name));
}

+ (void)setAssociatedObject:(id)object value:(id)value policy:(objc_AssociationPolicy)policy forName:(NSString *)name {
    objc_setAssociatedObject(object, NSSelectorFromString(name), value, policy);
}

@end
