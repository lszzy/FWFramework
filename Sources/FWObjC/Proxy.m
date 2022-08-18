//
//  Proxy.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "Proxy.h"
#import <objc/runtime.h>

#pragma mark - __WeakProxy

@implementation __WeakProxy

- (instancetype)init {
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

#pragma mark - __DelegateProxy

@implementation __DelegateProxy

- (BOOL)isProxy {
    return YES;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if (protocol_isEqual(aProtocol, self.protocol)) {
        return YES;
    }
    if ([self.delegate conformsToProtocol:aProtocol]) {
        return YES;
    }
    return [super conformsToProtocol:aProtocol];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([self.delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.delegate];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate methodSignatureForSelector:selector];
    }
    return [super methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([self.delegate respondsToSelector:selector]) {
        return YES;
    }
    return [super respondsToSelector:selector];
}

@end
