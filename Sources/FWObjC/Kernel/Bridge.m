//
//  Bridge.m
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import "Bridge.h"
#import <sys/sysctl.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Accelerate/Accelerate.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>

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

#pragma mark - __FWBlockProxy

typedef NS_OPTIONS(int, __ProxyBlockFlags) {
    __ProxyBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    __ProxyBlockFlagsHasSignature          = (1 << 30),
};

typedef struct __ProxyBlock {
    __unused Class isa;
    __ProxyBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct __ProxyBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        const char *signature;
        const char *layout;
    } *descriptor;
} *__ProxyBlockRef;

@interface __FWBlockProxy ()

@property (nonatomic, readonly) NSMethodSignature *blockSignature;

@end

@implementation __FWBlockProxy

+ (NSMethodSignature *)typeSignatureForBlock:(id)block __attribute__((pure, nonnull(1))) {
    __ProxyBlockRef layout = (__bridge void *)block;
    
    if (!(layout->flags & __ProxyBlockFlagsHasSignature))
        return nil;
    
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    
    if (layout->flags & __ProxyBlockFlagsHasCopyDisposeHelpers)
        desc += 2 * sizeof(void *);
    
    if (!desc)
        return nil;
    
    const char *signature = (*(const char **)desc);
    
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

+ (NSMethodSignature *)methodSignatureForBlockSignature:(NSMethodSignature *)original {
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

+ (NSMethodSignature *)methodSignatureForBlock:(id)block {
    NSMethodSignature *original = [self typeSignatureForBlock:block];
    if (!original) return nil;
    return [self methodSignatureForBlockSignature:original];
}

+ (instancetype)proxyWithBlock:(id)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(id)block {
    NSParameterAssert(block);
    NSMethodSignature *blockSignature = [[self class] typeSignatureForBlock:block];
    NSMethodSignature *methodSignature = [[self class] methodSignatureForBlockSignature:blockSignature];
    NSAssert(methodSignature, @"Incompatible block: %@", block);
    return (self = [self initWithBlock:block methodSignature:methodSignature blockSignature:blockSignature]);
}

- (instancetype)initWithBlock:(id)block methodSignature:(NSMethodSignature *)methodSignature blockSignature:(NSMethodSignature *)blockSignature {
    self = [super init];
    if (self) {
        _block = [block copy];
        _methodSignature = methodSignature;
        _blockSignature = blockSignature;
    }
    return self;
}

- (BOOL)invokeWithInvocation:(NSInvocation *)outerInv returnValue:(out NSValue **)outReturnValue setOnInvocation:(BOOL)setOnInvocation {
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

- (void)invokeWithInvocation:(NSInvocation *)invocation {
    [self invokeWithInvocation:invocation returnValue:NULL setOnInvocation:YES];
}

- (BOOL)invokeWithInvocation:(NSInvocation *)invocation returnValue:(out NSValue **)returnValue {
    return [self invokeWithInvocation:invocation returnValue:returnValue setOnInvocation:NO];
}

@end

#pragma mark - __FWDelegateProxy

@interface __FWDelegateProxy ()

@property (nonatomic, strong) NSMutableDictionary *blockProxies;

@end

@implementation __FWDelegateProxy

- (instancetype)init {
    self = [super init];
    if (self) {
        _blockProxies = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)isProxy {
    return YES;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([self.proxyDelegate conformsToProtocol:aProtocol]) {
        return YES;
    }
    return [super conformsToProtocol:aProtocol];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    __FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(invocation.selector)];
    if (blockProxy) {
        [blockProxy invokeWithInvocation:invocation];
    } else if ([self.proxyDelegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.proxyDelegate];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    __FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(selector)];
    if (blockProxy) {
        return blockProxy.methodSignature;
    }
    if ([self.proxyDelegate respondsToSelector:selector]) {
        return [self.proxyDelegate methodSignatureForSelector:selector];
    }
    return [super methodSignatureForSelector:selector];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if ([self.blockProxies objectForKey:NSStringFromSelector(selector)]) {
        return YES;
    }
    if ([self.proxyDelegate respondsToSelector:selector]) {
        return YES;
    }
    return [super respondsToSelector:selector];
}

- (void)setSelector:(SEL)selector withBlock:(id)block {
    NSCAssert(selector, @"Attempt to implement or remove NULL selector");
    
    NSString *blockKey = NSStringFromSelector(selector);
    if (!block) {
        [self.blockProxies removeObjectForKey:blockKey];
        return;
    }
    
    __FWBlockProxy *blockProxy = [[__FWBlockProxy alloc] initWithBlock:block];
    [self.blockProxies setObject:blockProxy forKey:blockKey];
}

- (id)blockForSelector:(SEL)selector {
    __FWBlockProxy *blockProxy = [self.blockProxies objectForKey:NSStringFromSelector(selector)];
    return blockProxy ? blockProxy.block : nil;
}

@end

#pragma mark - __FWWeakObject

@implementation __FWWeakObject

- (instancetype)initWithObject:(id)object {
    self = [super init];
    if (self) {
        _object = object;
    }
    return self;
}

@end

#pragma mark - __FWRuntime

@implementation __FWRuntime

+ (id)getProperty:(id)target forName:(NSString *)name {
    if (!target) return nil;
    id object = objc_getAssociatedObject(target, NSSelectorFromString(name));
    if ([object isKindOfClass:[__FWWeakObject class]]) {
        object = [(__FWWeakObject *)object object];
    }
    return object;
}

+ (void)setPropertyPolicy:(id)target withObject:(id)object policy:(objc_AssociationPolicy)policy forName:(NSString *)name {
    if (!target || [self getProperty:target forName:name] == object) return;
    objc_setAssociatedObject(target, NSSelectorFromString(name), object, policy);
}

+ (void)setPropertyWeak:(id)target withObject:(id)object forName:(NSString *)name {
    if (!target || [self getProperty:target forName:name] == object) return;
    objc_setAssociatedObject(target, NSSelectorFromString(name), [[__FWWeakObject alloc] initWithObject:object], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (id)invokeMethod:(id)target selector:(SEL)aSelector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([target respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod(object_getClass(target), aSelector));
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
        char *type = method_copyReturnType(class_getInstanceMethod(object_getClass(target), aSelector));
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

+ (id)invokeMethod:(id)target selector:(SEL)aSelector object:(id)object1 object:(id)object2 {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([target respondsToSelector:aSelector]) {
        char *type = method_copyReturnType(class_getInstanceMethod(object_getClass(target), aSelector));
        if (type && *type == 'v') {
            free(type);
            [target performSelector:aSelector withObject:object1 withObject:object2];
        } else {
            free(type);
            return [target performSelector:aSelector withObject:object1 withObject:object2];
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

+ (BOOL)invokeMethod:(id)target selector:(SEL)selector arguments:(NSArray *)arguments returnValue:(void *)result {
    if (!target || ![target respondsToSelector:selector]) return NO;
    
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:target];
    [invocation setSelector:selector];
    for (NSUInteger i = 0; i< arguments.count; i++) {
        NSUInteger argIndex = i + 2;
        id argument = arguments[i];
        if ([argument isKindOfClass:NSNumber.class]) {
            BOOL shouldContinue = NO;
            NSNumber *num = (NSNumber *)argument;
            const char *type = [sig getArgumentTypeAtIndex:argIndex];
            if (strcmp(type, @encode(BOOL)) == 0) {
                BOOL rawNum = [num boolValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(int)) == 0
                       || strcmp(type, @encode(short)) == 0
                       || strcmp(type, @encode(long)) == 0) {
                NSInteger rawNum = [num integerValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if(strcmp(type, @encode(long long)) == 0) {
                long long rawNum = [num longLongValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(unsigned int)) == 0
                       || strcmp(type, @encode(unsigned short)) == 0
                       || strcmp(type, @encode(unsigned long)) == 0) {
                NSUInteger rawNum = [num unsignedIntegerValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if(strcmp(type, @encode(unsigned long long)) == 0) {
                unsigned long long rawNum = [num unsignedLongLongValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(float)) == 0) {
                float rawNum = [num floatValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            } else if (strcmp(type, @encode(double)) == 0) {
                double rawNum = [num doubleValue];
                [invocation setArgument:&rawNum atIndex:argIndex];
                shouldContinue = YES;
            }
            if (shouldContinue) {
                continue;
            }
        }
        if ([argument isKindOfClass:[NSNull class]]) {
            argument = nil;
        }
        [invocation setArgument:&argument atIndex:argIndex];
    }
    [invocation invoke];
    
    NSString *methodReturnType = [NSString stringWithUTF8String:sig.methodReturnType];
    if (result && ![methodReturnType isEqualToString:@"v"]) {
        if ([methodReturnType isEqualToString:@"@"]) {
            CFTypeRef cfResult = nil;
            [invocation getReturnValue:&cfResult];
            if (cfResult) {
                CFRetain(cfResult);
                *(void**)result = (__bridge_retained void *)((__bridge_transfer id)cfResult);
            }
        } else {
            [invocation getReturnValue:result];
        }
    }
    return YES;
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

+ (id)appearanceForClass:(Class)aClass {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"appearanceForClass", @"withContainerList"]);
    id appearance = [NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"_U", @"IAppea", @"rance"]) performSelector:selector withObject:aClass withObject:nil];
    #pragma clang diagnostic pop
    return appearance;
}

+ (Class)classForAppearance:(id)appearance {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"customizable", @"ClassInfo"]);
    if (![appearance respondsToSelector:selector]) return [appearance class];

    id classInfo = [appearance performSelector:selector];
    selector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"customizable", @"ViewClass"]);
    if (!classInfo || ![classInfo respondsToSelector:selector]) return [appearance class];
    
    Class viewClass = [classInfo performSelector:selector];
    if (viewClass && object_isClass(viewClass)) return viewClass;
    #pragma clang diagnostic pop
    return [appearance class];
}

+ (void)applyAppearance:(NSObject *)object {
    Class class = [object class];
    if ([class respondsToSelector:@selector(appearance)]) {
        SEL appearanceGuideClassSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@", @"_a", @"ppearanceG", @"uideClass"]);
        if (!class_respondsToSelector(class, appearanceGuideClassSelector)) {
            const char * typeEncoding = method_getTypeEncoding(class_getInstanceMethod(UIView.class, appearanceGuideClassSelector));
            class_addMethod(class, appearanceGuideClassSelector, imp_implementationWithBlock(^Class(void) {
                return nil;
            }), typeEncoding);
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"_%@:%@:", @"applyInvocationsTo", @"window"]);
        [NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"_U", @"IAppea", @"rance"]) performSelector:selector withObject:object withObject:nil];
#pragma clang diagnostic pop
    }
}

+ (NSArray<Class> *)getClasses:(Class)superClass {
    NSMutableArray<Class> *resultClasses = [[NSMutableArray<Class> alloc] init];
    unsigned int classesCount = 0;
    Class *classList = objc_copyClassList(&classesCount);
    Class classType = Nil, parentType = Nil, rootClass = [NSObject class];
    for (unsigned int i = 0; i < classesCount; ++i) {
        classType = classList[i];
        parentType = class_getSuperclass(classType);
        while (parentType && parentType != rootClass) {
            if (parentType == superClass) {
                [resultClasses addObject:classType];
                break;
            }
            parentType = class_getSuperclass(parentType);
        }
    }
    free(classList);
    return resultClasses;
}

+ (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (^)(NSException * _Nonnull))exceptionHandler {
    @try {
        if (block) block();
    } @catch (NSException *exception) {
        if (exceptionHandler) exceptionHandler(exception);
    }
}

+ (BOOL)isEqual:(id)obj1 with:(id)obj2 {
    return obj1 == obj2;
}

@end

#pragma mark - __FWSwizzle

@implementation __FWSwizzle

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block {
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

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block {
    if (!originalClass) return NO;
    if (identifier.length < 1) return [self swizzleInstanceMethod:originalClass selector:originalSelector withBlock:block];
    
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

+ (BOOL)swizzleDeallocMethod:(Class)originalClass identifier:(NSString *)identifier withBlock:(void (^)(__kindof NSObject *__unsafe_unretained _Nonnull))block {
    return [self swizzleInstanceMethod:originalClass selector:NSSelectorFromString(@"dealloc") identifier:identifier withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(__unsafe_unretained NSObject *selfObject) {
            if (block) block(selfObject);
            
            void (*originalMSG)(id, SEL) = (void (*)(id, SEL))originalIMP();
            originalMSG(selfObject, originalCMD);
        };
    }];
}

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    if (originalMethod) {
        class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector), method_getTypeEncoding(originalMethod));
    } else {
        class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
    }
    class_addMethod(originalClass, swizzleSelector, class_getMethodImplementation(originalClass, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector), class_getInstanceMethod(originalClass, swizzleSelector));
    return YES;
}

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(originalClass, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector), class_getInstanceMethod(originalClass, swizzleSelector));
    return YES;
}

@end

#pragma mark - __FWBridge

@implementation __FWBridge

+ (void)logMessage:(NSString *)message {
    NSLog(@"%@", message);
}

+ (NSTimeInterval)systemUptime {
    struct timeval bootTime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(bootTime);
    int resctl = sysctl(mib, 2, &bootTime, &size, NULL, 0);

    struct timeval now;
    struct timezone tz;
    gettimeofday(&now, &tz);
    
    NSTimeInterval uptime = 0;
    if (resctl != -1 && bootTime.tv_sec != 0) {
        uptime = now.tv_sec - bootTime.tv_sec;
        uptime += (now.tv_usec - bootTime.tv_usec) / 1.e6;
    }
    return uptime;
}

+ (NSString *)escapeHtml:(NSString *)string {
    NSUInteger len = string.length;
    if (!len) return string;
    
    unichar *buf = malloc(sizeof(unichar) * len);
    if (!buf) return string;
    [string getCharacters:buf range:NSMakeRange(0, len)];
    
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < len; i++) {
        unichar c = buf[i];
        NSString *esc = nil;
        switch (c) {
            case 34: esc = @"&quot;"; break;
            case 38: esc = @"&amp;"; break;
            case 39: esc = @"&apos;"; break;
            case 60: esc = @"&lt;"; break;
            case 62: esc = @"&gt;"; break;
            default: break;
        }
        if (esc) {
            [result appendString:esc];
        } else {
            CFStringAppendCharacters((CFMutableStringRef)result, &c, 1);
        }
    }
    free(buf);
    return result;
}

+ (NSString *)ipAddress {
    NSString *ipAddr = nil;
    struct ifaddrs *addrs = NULL;
    
    int ret = getifaddrs(&addrs);
    if (0 == ret) {
        const struct ifaddrs * cursor = addrs;
        
        while (cursor) {
            if (AF_INET == cursor->ifa_addr->sa_family && 0 == (cursor->ifa_flags & IFF_LOOPBACK)) {
                ipAddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                break;
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return ipAddr;
}

+ (NSString *)hostName {
    char hostName[256];
    int success = gethostname(hostName, 255);
    if (success != 0) return nil;
    hostName[255] = '\0';
    
#if TARGET_OS_SIMULATOR
    return [NSString stringWithFormat:@"%s", hostName];
#else
    return [NSString stringWithFormat:@"%s.local", hostName];
#endif
}

+ (NSString *)ipAddress:(NSString *)host {
    if ([host hasPrefix:@"http"]) {
        host = [NSURL URLWithString:host].host;
    }
    
    Boolean result, bResolved;
    CFHostRef hostRef;
    CFArrayRef addresses = NULL;
    NSMutableArray *ipsArr = [[NSMutableArray alloc] init];
    CFStringRef hostNameRef = CFStringCreateWithCString(kCFAllocatorDefault, [host cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII);
    
    hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostNameRef);
    result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL);
    if (result == TRUE) {
        addresses = CFHostGetAddressing(hostRef, &result);
    }
    bResolved = result == TRUE ? true : false;
    
    if (bResolved) {
        struct sockaddr_in *remoteAddr;
        for(int i = 0; i < CFArrayGetCount(addresses); i++){
            CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
            remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
            if (remoteAddr != NULL) {
                char ip[16];
                strcpy(ip, inet_ntoa(remoteAddr->sin_addr));
                NSString *ipStr = [NSString stringWithCString:ip encoding:NSUTF8StringEncoding];
                [ipsArr addObject:ipStr];
            }
        }
    }
    if (ipsArr.count) {
        return ipsArr[0];
    }
    return nil;
}

@end

#pragma mark - __FWEncrypt

@implementation NSData (__FWEncrypt)

- (id)__fw_unarchiveObject:(Class)clazz {
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:clazz fromData:self error:NULL];
    } @catch (NSException *exception) { }
    return object;
}

- (NSData *)__fw_AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus status = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (status == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAEncryptWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Encode:YES];
}

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:NO];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSADecryptWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Decode:YES];
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSASignWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Encode:YES];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:YES];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAVerifyWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Decode:YES];
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

+ (NSData *)__fw_RSAEncryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef isSign:(BOOL)isSign {
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        
        if (isSign) {
            status = SecKeyRawSign(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        } else {
            status = SecKeyEncrypt(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        }
        if (status != 0) {
            ret = nil;
            break;
        } else {
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (NSData *)__fw_RSADecryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef {
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    UInt8 *outbuf = malloc(block_size);
    size_t src_block_size = block_size;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyDecrypt(keyRef,
                               kSecPaddingNone,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            ret = nil;
            break;
        } else {
            int idxFirstZero = -1;
            int idxNextZero = (int)outlen;
            for (int i = 0; i < outlen; i++) {
                if (outbuf[i] == 0) {
                    if (idxFirstZero < 0) {
                        idxFirstZero = i;
                    } else {
                        idxNextZero = i;
                        break;
                    }
                }
            }
            [ret appendBytes:&outbuf[idxFirstZero + 1] length:idxNextZero - idxFirstZero - 1];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (SecKeyRef)__fw_RSAAddPublicKey:(NSString *)key andTag:(NSString *)tagName {
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self __fw_RSAStripPublicKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (SecKeyRef)__fw_RSAAddPrivateKey:(NSString *)key andTag:(NSString *)tagName {
    NSRange spos;
    NSRange epos;
    spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
    if (spos.length > 0) {
        epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
    } else {
        spos = [key rangeOfString:@"-----BEGIN PRIVATE KEY-----"];
        epos = [key rangeOfString:@"-----END PRIVATE KEY-----"];
    }
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];

    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self __fw_RSAStripPrivateKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [privateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [privateKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)privateKey);

    [privateKey setObject:data forKey:(__bridge id)kSecValueData];
    [privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [privateKey removeObjectForKey:(__bridge id)kSecValueData];
    [privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (NSData *)__fw_RSAStripPublicKeyHeader:(NSData *)d_key {
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    if (c_key[idx++] != 0x30) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;

    static unsigned char seqiod[] = { 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return nil;
    
    idx += 15;
    if (c_key[idx++] != 0x03) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    if (c_key[idx++] != '\0') return nil;
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (NSData *)__fw_RSAStripPrivateKeyHeader:(NSData *)d_key {
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;

    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx     = 22;
    if (0x04 != c_key[idx++]) return d_key;

    unsigned int c_len = c_key[idx++];
    int det = c_len & 0x80;
    if (!det) {
        c_len = c_len & 0x7f;
    } else {
        int byteCount = c_len & 0x7f;
        if (byteCount + idx > len) {
            return nil;
        }
        unsigned int accum = 0;
        unsigned char *ptr = &c_key[idx];
        idx += byteCount;
        while (byteCount) {
            accum = (accum << 8) + *ptr;
            ptr++;
            byteCount--;
        }
        c_len = accum;
    }
    return [d_key subdataWithRange:NSMakeRange(idx, c_len)];
}

@end

#pragma mark - UIImage+__FWBridge

@implementation UIImage (__FWBridge)

- (UIImage *)__fw_maskImage {
    NSInteger width = CGImageGetWidth(self.CGImage);
    NSInteger height = CGImageGetHeight(self.CGImage);
    
    NSInteger bytesPerRow = ((width + 3) / 4) * 4;
    void *data = calloc(bytesPerRow * height, sizeof(unsigned char *));
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, NULL, kCGImageAlphaOnly);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSInteger index = y * bytesPerRow + x;
            ((unsigned char *)data)[index] = 255 - ((unsigned char *)data)[index];
        }
    }
    
    CGImageRef maskRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *mask = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    free(data);
    
    return mask;
}

- (UIImage *)__fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(UIColor *)tintColor maskImage:(UIImage *)maskImage {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDelta - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDelta;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

@end

#pragma mark - UIImageView+__FWBridge

@implementation UIImageView (__FWBridge)

- (void)__fw_faceAware {
    if (self.image == nil) {
        return;
    }
    
    [self __fw_faceDetect:self.image];
}

- (void)__fw_faceDetect:(UIImage *)aImage {
    static CIDetector *_faceDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    });
    
    __weak UIImageView *weakBase = self;
    dispatch_queue_t queue = dispatch_queue_create("site.wuyong.queue.uikit.face", NULL);
    dispatch_async(queue, ^{
        CIImage *image = aImage.CIImage;
        if (image == nil) {
            image = [CIImage imageWithCGImage:aImage.CGImage];
        }
        
        NSArray *features = [_faceDetector featuresInImage:image];
        if (features.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakBase __fw_faceLayer:NO] removeFromSuperlayer];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakBase __fw_faceMark:features size:CGSizeMake(CGImageGetWidth(aImage.CGImage), CGImageGetHeight(aImage.CGImage))];
            });
        }
    });
}

- (void)__fw_faceMark:(NSArray *)features size:(CGSize)size {
    CGRect fixedRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    CGFloat rightBorder = 0, bottomBorder = 0;
    for (CIFaceFeature *f in features){
        CGRect oneRect = f.bounds;
        oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height;
        
        fixedRect.origin.x = MIN(oneRect.origin.x, fixedRect.origin.x);
        fixedRect.origin.y = MIN(oneRect.origin.y, fixedRect.origin.y);
        
        rightBorder = MAX(oneRect.origin.x + oneRect.size.width, rightBorder);
        bottomBorder = MAX(oneRect.origin.y + oneRect.size.height, bottomBorder);
    }
    
    fixedRect.size.width = rightBorder - fixedRect.origin.x;
    fixedRect.size.height = bottomBorder - fixedRect.origin.y;
    
    CGPoint fixedCenter = CGPointMake(fixedRect.origin.x + fixedRect.size.width / 2.0,
                                      fixedRect.origin.y + fixedRect.size.height / 2.0);
    CGPoint offset = CGPointZero;
    CGSize finalSize = size;
    if (size.width / size.height > self.bounds.size.width / self.bounds.size.height) {
        finalSize.height = self.bounds.size.height;
        finalSize.width = size.width/size.height * finalSize.height;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.x = fixedCenter.x - self.bounds.size.width * 0.5;
        if (offset.x < 0) {
            offset.x = 0;
        } else if (offset.x + self.bounds.size.width > finalSize.width) {
            offset.x = finalSize.width - self.bounds.size.width;
        }
        offset.x = - offset.x;
    } else {
        finalSize.width = self.bounds.size.width;
        finalSize.height = size.height/size.width * finalSize.width;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.y = fixedCenter.y - self.bounds.size.height * (1 - 0.618);
        if (offset.y < 0) {
            offset.y = 0;
        } else if (offset.y + self.bounds.size.height > finalSize.height){
            offset.y = finalSize.height - self.bounds.size.height;
        }
        offset.y = - offset.y;
    }
    
    CALayer *layer = [self __fw_faceLayer:YES];
    layer.frame = CGRectMake(offset.x, offset.y, finalSize.width, finalSize.height);
    layer.contents = (id)self.image.CGImage;
}

- (CALayer *)__fw_faceLayer:(BOOL)lazyload {
    for (CALayer *layer in self.layer.sublayers) {
        if ([@"FWFaceLayer" isEqualToString:layer.name]) {
            return layer;
        }
    }
    
    if (lazyload) {
        CALayer *layer = [CALayer layer];
        layer.name = @"FWFaceLayer";
        layer.actions = @{
                          @"contents": [NSNull null],
                          @"bounds": [NSNull null],
                          @"position": [NSNull null],
                          };
        [self.layer addSublayer:layer];
        return layer;
    }
    
    return nil;
}

@end

#pragma mark - __FWNotificationTarget

@implementation __FWNotificationTarget

- (void)dealloc {
    if (self.broadcast) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)handleNotification:(NSNotification *)notification {
    if (self.block) {
        self.block(notification);
        return;
    }
    
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:notification];
#pragma clang diagnostic pop
    }
}

- (BOOL)equalsObject:(id)object {
    return object == self.object;
}

- (BOOL)equalsObject:(id)object target:(id)target action:(SEL)action {
    return object == self.object && target == self.target && (!action || action == self.action);
}

@end

#pragma mark - __FWKvoTarget

@implementation __FWKvoTarget

- (void)dealloc {
    [self removeObserver];
}

- (void)addObserver {
    if (!_isObserving) {
        _isObserving = YES;
        [self.object addObserver:self forKeyPath:self.keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)removeObserver {
    if (_isObserving) {
        _isObserving = NO;
        [self.object removeObserver:self forKeyPath:self.keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPrior) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    NSMutableDictionary *newChange = [NSMutableDictionary dictionary];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldValue && oldValue != [NSNull null]) {
        [newChange setObject:oldValue forKey:NSKeyValueChangeOldKey];
    }
    
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    if (newValue && newValue != [NSNull null]) {
        [newChange setObject:newValue forKey:NSKeyValueChangeNewKey];
    }
    
    if (self.block) {
        self.block(object, [newChange copy]);
        return;
    }
    
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:object withObject:[newChange copy]];
#pragma clang diagnostic pop
    }
}

- (BOOL)equalsTarget:(id)target action:(SEL)action {
    return target == self.target && (!action || action == self.action);
}

@end

#pragma mark - __FWInputTarget

@interface __FWInputTarget ()

@property (nonatomic, weak, nullable, readonly) UITextField *textField;

@end

@implementation __FWInputTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput {
    self = [super init];
    if (self) {
        _textInput = textInput;
        _autoCompleteInterval = 0.5;
    }
    return self;
}

+ (NSUInteger)unicodeLength:(NSString *)text {
    NSUInteger strLength = 0;
    for (int i = 0; i < text.length; i++) {
        if ([text characterAtIndex:i] > 0xff) {
            strLength += 2;
        } else {
            strLength ++;
        }
    }
    return ceil(strLength / 2.0);
}

+ (NSString *)unicodeSubstring:(NSString *)text length:(NSUInteger)length {
    length = length * 2;
    int i = 0;
    int len = 0;
    while (i < text.length) {
        if ([text characterAtIndex:i] > 0xff) {
            len += 2;
        } else {
            len++;
        }
        
        i++;
        if (i >= text.length) {
            return text;
        }
        
        if (len == length) {
            return [text substringToIndex:i];
        } else if (len > length) {
            if (i - 1 <= 0) {
                return @"";
            }
            
            return [text substringToIndex:i - 1];
        }
    }
    return text;
}

- (UITextField *)textField {
    return (UITextField *)self.textInput;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)interval {
    _autoCompleteInterval = interval > 0 ? interval : 0.5;
}

- (void)textLengthChanged {
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (self.textField.text.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
                }
            }
        } else {
            if (self.textField.text.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([__FWInputTarget unicodeLength:self.textField.text] > self.maxUnicodeLength) {
                    self.textField.text = [__FWInputTarget unicodeSubstring:self.textField.text length:self.maxUnicodeLength];
                }
            }
        } else {
            if ([__FWInputTarget unicodeLength:self.textField.text] > self.maxUnicodeLength) {
                self.textField.text = [__FWInputTarget unicodeSubstring:self.textField.text length:self.maxUnicodeLength];
            }
        }
    }
}

- (NSString *)filterText:(NSString *)text {
    NSString *filterText = text;
    
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (filterText.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    filterText = [filterText substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // filterText = [filterText substringToIndex:self.maxLength];
                }
            }
        } else {
            if (filterText.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                filterText = [filterText substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // filterText = [filterText substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([__FWInputTarget unicodeLength:filterText] > self.maxUnicodeLength) {
                    filterText = [__FWInputTarget unicodeSubstring:filterText length:self.maxUnicodeLength];
                }
            }
        } else {
            if ([__FWInputTarget unicodeLength:filterText] > self.maxUnicodeLength) {
                filterText = [__FWInputTarget unicodeSubstring:filterText length:self.maxUnicodeLength];
            }
        }
    }
    
    return filterText;
}

- (void)textChangedAction {
    [self textLengthChanged];
    
    if (self.textChangedBlock) {
        NSString *inputText = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.textChangedBlock(inputText ?: @"");
    }
    
    if (self.autoCompleteBlock) {
        self.autoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (inputText.length < 1) {
            self.autoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.autoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.autoCompleteTimestamp) {
                    self.autoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end
