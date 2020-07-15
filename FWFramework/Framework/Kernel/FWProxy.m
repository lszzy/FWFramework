/*!
 @header     FWProxy.m
 @indexgroup FWFramework
 @brief      FWProxy代理类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-18
 */

#import "FWProxy.h"
#import <objc/runtime.h>

#pragma mark - FWWeakProxy

@implementation FWWeakProxy

+ (instancetype)proxyWithTarget:(id)target
{
    return [[FWWeakProxy alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target
{
    _target = target;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)selector
{
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [_target respondsToSelector:aSelector];
}

- (BOOL)isEqual:(id)object
{
    return [_target isEqual:object];
}

- (NSUInteger)hash
{
    return [_target hash];
}

- (Class)superclass
{
    return [_target superclass];
}

- (Class)class
{
    return [_target class];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [_target isKindOfClass:aClass];
}

- (BOOL)isMemberOfClass:(Class)aClass
{
    return [_target isMemberOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [_target conformsToProtocol:aProtocol];
}

- (BOOL)isProxy
{
    return YES;
}

- (NSString *)description
{
    return [_target description];
}

- (NSString *)debugDescription
{
    return [_target debugDescription];
}

@end

#pragma mark - FWWeakObject

@implementation FWWeakObject

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self) {
        _object = object;
    }
    return self;
}

@end

#pragma mark - FWBlockProxy

// 内部block
typedef NS_OPTIONS(int, FWProxyBlockFlags) {
    FWProxyBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    FWProxyBlockFlagsHasSignature          = (1 << 30),
};

typedef struct FWProxyBlock {
    __unused Class isa;
    FWProxyBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct FWProxyBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // 需要FWProxyBlockHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // 需要FWProxyBlockHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
} *FWProxyBlockRef;

@interface FWBlockProxy ()

@property (nonatomic, readonly) NSMethodSignature *blockSignature;

@end

@implementation FWBlockProxy

+ (NSMethodSignature *)typeSignatureForBlock:(id)block __attribute__((pure, nonnull(1)))
{
    FWProxyBlockRef layout = (__bridge void *)block;
    
    if (!(layout->flags & FWProxyBlockFlagsHasSignature))
        return nil;
    
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    
    if (layout->flags & FWProxyBlockFlagsHasCopyDisposeHelpers)
        desc += 2 * sizeof(void *);
    
    if (!desc)
        return nil;
    
    const char *signature = (*(const char **)desc);
    
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

+ (NSMethodSignature *)methodSignatureForBlockSignature:(NSMethodSignature *)original
{
    if (!original) return nil;
    
    if (original.numberOfArguments < 1) {
        return nil;
    }
    
    if (original.numberOfArguments >= 2 && strcmp(@encode(SEL), [original getArgumentTypeAtIndex:1]) == 0) {
        return original;
    }
    
    NSMutableString *signature = [[NSMutableString alloc] initWithCapacity:original.numberOfArguments + 1];
    
    const char *retTypeStr = original.methodReturnType;
    [signature appendFormat:@"%s%s%s", retTypeStr, @encode(id), @encode(SEL)];
    
    for (NSUInteger i = 1; i < original.numberOfArguments; i++) {
        const char *typeStr = [original getArgumentTypeAtIndex:i];
        NSString *type = [[NSString alloc] initWithBytesNoCopy:(void *)typeStr length:strlen(typeStr) encoding:NSUTF8StringEncoding freeWhenDone:NO];
        [signature appendString:type];
    }
    
    return [NSMethodSignature signatureWithObjCTypes:signature.UTF8String];
}

+ (NSMethodSignature *)methodSignatureForBlock:(id)block
{
    NSMethodSignature *original = [self typeSignatureForBlock:block];
    if (!original) return nil;
    return [self methodSignatureForBlockSignature:original];
}

+ (instancetype)proxyWithBlock:(id)block
{
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(id)block
{
    NSParameterAssert(block);
    NSMethodSignature *blockSignature = [[self class] typeSignatureForBlock:block];
    NSMethodSignature *methodSignature = [[self class] methodSignatureForBlockSignature:blockSignature];
    NSAssert(methodSignature, @"Incompatible block: %@", block);
    return (self = [self initWithBlock:block methodSignature:methodSignature blockSignature:blockSignature]);
}

- (instancetype)initWithBlock:(id)block methodSignature:(NSMethodSignature *)methodSignature blockSignature:(NSMethodSignature *)blockSignature
{
    self = [super init];
    if (self) {
        _block = [block copy];
        _methodSignature = methodSignature;
        _blockSignature = blockSignature;
    }
    return self;
}

- (BOOL)invokeWithInvocation:(NSInvocation *)outerInv returnValue:(out NSValue **)outReturnValue setOnInvocation:(BOOL)setOnInvocation
{
    NSParameterAssert(outerInv);
    
    NSMethodSignature *sig = self.methodSignature;
    
    if (![outerInv.methodSignature isEqual:sig]) {
        NSAssert(0, @"Attempted to invoke block invocation with incompatible frame");
        return NO;
    }
    
    NSInvocation *innerInv = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    
    void *argBuf = NULL;
    
    for (NSUInteger i = 2; i < sig.numberOfArguments; i++) {
        const char *type = [sig getArgumentTypeAtIndex:i];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            return NO;
        }
        
        [outerInv getArgument:argBuf atIndex:i];
        [innerInv setArgument:argBuf atIndex:i - 1];
    }
    
    [innerInv invokeWithTarget:self.block];
    
    NSUInteger retSize = sig.methodReturnLength;
    if (retSize) {
        if (outReturnValue || setOnInvocation) {
            if (!(argBuf = reallocf(argBuf, retSize))) {
                return NO;
            }
            
            [innerInv getReturnValue:argBuf];
            
            if (setOnInvocation) {
                [outerInv setReturnValue:argBuf];
            }
            
            if (outReturnValue) {
                *outReturnValue = [NSValue valueWithBytes:argBuf objCType:sig.methodReturnType];
            }
        }
    } else {
        if (outReturnValue) {
            *outReturnValue = nil;
        }
    }
    
    free(argBuf);
    
    return YES;
}

- (void)invokeWithInvocation:(NSInvocation *)invocation
{
    [self invokeWithInvocation:invocation returnValue:NULL setOnInvocation:YES];
}

- (BOOL)invokeWithInvocation:(NSInvocation *)invocation returnValue:(out NSValue **)returnValue
{
    return [self invokeWithInvocation:invocation returnValue:returnValue setOnInvocation:NO];
}

@end

#pragma mark - FWDelegateProxy

@interface FWDelegateProxy ()

@property (nonatomic, strong) NSMutableDictionary *blockProxies;

@end

@implementation FWDelegateProxy

+ (instancetype)proxyWithProtocol:(Protocol *)protocol
{
    return [[self alloc] initWithProtocol:protocol];
}

- (instancetype)initWithProtocol:(Protocol *)protocol
{
    self = [super init];
    if (self) {
        _protocol = protocol;
        _blockProxies = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _blockProxies = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)isProxy
{
    return YES;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if (protocol_isEqual(aProtocol, self.protocol)) {
        return YES;
    }
    if ([self.delegate conformsToProtocol:aProtocol]) {
        return YES;
    }
    return [super conformsToProtocol:aProtocol];
}

// 仅当Proxy没实现方法时触发
- (void)forwardInvocation:(NSInvocation *)invocation
{
    FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(invocation.selector)];
    if (blockProxy) {
        [blockProxy invokeWithInvocation:invocation];
    } else if ([self.delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.delegate];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(selector)];
    if (blockProxy) {
        return blockProxy.methodSignature;
    }
    if ([self.delegate respondsToSelector:selector]) {
        return [self.delegate methodSignatureForSelector:selector];
    }
    return [super methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([self.blockProxies objectForKey:NSStringFromSelector(selector)]) {
        return YES;
    }
    if ([self.delegate respondsToSelector:selector]) {
        return YES;
    }
    return [super respondsToSelector:selector];
}

#pragma mark - Public

- (void)setSelector:(SEL)selector withBlock:(id)block
{
    NSCAssert(selector, @"Attempt to implement or remove NULL selector");
    
    NSString *blockKey = NSStringFromSelector(selector);
    if (!block) {
        [self.blockProxies removeObjectForKey:blockKey];
        return;
    }
    
    FWBlockProxy *blockProxy = [[FWBlockProxy alloc] initWithBlock:block];
    [self.blockProxies setObject:blockProxy forKey:blockKey];
}

- (id)blockForSelector:(SEL)selector
{
    FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(selector)];
    return blockProxy ? blockProxy.block : nil;
}

@end
