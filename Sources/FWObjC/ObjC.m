//
//  ObjC.m
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import "ObjC.h"
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - WeakProxyBridge

@implementation FWWeakProxyBridge

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

#pragma mark - DelegateProxyBridge

@implementation FWDelegateProxyBridge

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

#pragma mark - UnsafeObjectBridge

@implementation FWUnsafeObjectBridge

- (void)dealloc {
    [self deallocObject];
}

- (void)deallocObject {
}

@end

#pragma mark - ObjCBridge

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static void (*FWCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*FWCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*FWCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*FWCGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*FWCGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);
static SEL FWImageWithCGSVGDocumentSEL = NULL;
static SEL FWCGSVGDocumentSEL = NULL;

@implementation FWObjCBridge

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([FWObjCBridge respondsToSelector:@selector(autoload)]) {
            [FWObjCBridge performSelector:@selector(autoload)];
        }
    });
}

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
    if (![class respondsToSelector:@selector(appearance)]) return;
    
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

+ (void)logMessage:(NSString *)message {
    NSLog(@"%@", message);
}

+ (void)logDebug:(NSString *)message {
    if ([FWObjCBridge respondsToSelector:@selector(log:)]) {
        id objcBridge = [FWObjCBridge class];
        [objcBridge log:message];
    }
}

+ (UIImage *)decodeImage:(NSData *)data scale:(CGFloat)scale options:(NSDictionary *)options {
    if ([FWObjCBridge respondsToSelector:@selector(image:scale:options:)]) {
        id objcBridge = [FWObjCBridge class];
        return [objcBridge image:data scale:scale options:options];
    } else {
        UIImage *image = [UIImage imageWithData:data];
        if (image.images || !image) {
            return image;
        }
        return [[UIImage alloc] initWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
    }
}

+ (BOOL)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (^)(NSException * _Nonnull))exceptionHandler {
    @try {
        if (block) block();
        return YES;
    } @catch (NSException *exception) {
        if (exceptionHandler) exceptionHandler(exception);
        return NO;
    }
}

+ (void)captureExceptions:(NSArray<Class> *)captureClasses exceptionHandler:(nullable void (^)(NSException * _Nonnull, Class  _Nonnull __unsafe_unretained, SEL _Nonnull, NSString * _Nonnull, NSInteger))exceptionHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(methodSignatureForSelector:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSMethodSignature * (__unsafe_unretained NSObject *selfObject, SEL selector) {
                NSMethodSignature * (*originalMSG)(id, SEL, SEL) = (NSMethodSignature * (*)(id, SEL, SEL))originalIMP();
                NSMethodSignature *methodSignature = originalMSG(selfObject, originalCMD, selector);
                if (!methodSignature) {
                    for (Class captureClass in captureClasses) {
                        if ([selfObject isKindOfClass:captureClass]) {
                            methodSignature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
                            break;
                        }
                    }
                }
                return methodSignature;
            };
        }];
        
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(forwardInvocation:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSObject *selfObject, NSInvocation *invocation) {
                void (*originalMSG)(id, SEL, NSInvocation *) = (void (*)(id, SEL, NSInvocation *))originalIMP();
                BOOL isCaptured = NO;
                for (Class captureClass in captureClasses) {
                    if ([selfObject isKindOfClass:captureClass]) {
                        isCaptured = YES;
                        break;
                    }
                }
                
                if (isCaptured) {
                    @try {
                        originalMSG(selfObject, originalCMD, invocation);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, selfObject.class, invocation.selector, @(__FILE__), __LINE__);
                    }
                } else {
                    originalMSG(selfObject, originalCMD, invocation);
                }
            };
        }];
        
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(setValue:forKey:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *key) {
                void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, value, key);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, selfObject.class, @selector(setValue:forKey:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(setValue:forKeyPath:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *keyPath) {
                void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, value, keyPath);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, selfObject.class, @selector(setValue:forKeyPath:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(setValue:forUndefinedKey:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *key) {
                void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, value, key);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, selfObject.class, @selector(setValue:forUndefinedKey:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:[NSObject class] selector:@selector(setValuesForKeysWithDictionary:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSObject *selfObject, NSDictionary<NSString *, id> *keyValues) {
                void (*originalMSG)(id, SEL, NSDictionary<NSString *, id> *) = (void (*)(id, SEL, NSDictionary<NSString *, id> *))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, keyValues);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, selfObject.class, @selector(setValuesForKeysWithDictionary:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        NSArray<NSString *> *stringClasses = @[
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SCFCon", @"stantString"],
            [NSString stringWithFormat:@"%@%@%@", @"N", @"STaggedPo", @"interString"],
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SCFS", @"tring"]
        ];
        for (NSString *stringClass in stringClasses) {
            [self swizzleInstanceMethod:NSClassFromString(stringClass) selector:@selector(substringFromIndex:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^NSString * (__unsafe_unretained NSString *selfObject, NSUInteger from) {
                    NSString * (*originalMSG)(id, SEL, NSUInteger) = (NSString * (*)(id, SEL, NSUInteger))originalIMP();
                    NSString *result;
                    @try {
                        result = originalMSG(selfObject, originalCMD, from);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, NSString.class, @selector(substringFromIndex:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
            
            [self swizzleInstanceMethod:NSClassFromString(stringClass) selector:@selector(substringToIndex:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^NSString * (__unsafe_unretained NSString *selfObject, NSUInteger to) {
                    NSString * (*originalMSG)(id, SEL, NSUInteger) = (NSString * (*)(id, SEL, NSUInteger))originalIMP();
                    NSString *result;
                    @try {
                        result = originalMSG(selfObject, originalCMD, to);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, NSString.class, @selector(substringToIndex:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
            
            [self swizzleInstanceMethod:NSClassFromString(stringClass) selector:@selector(substringWithRange:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^NSString * (__unsafe_unretained NSString *selfObject, NSRange range) {
                    NSString * (*originalMSG)(id, SEL, NSRange) = (NSString * (*)(id, SEL, NSRange))originalIMP();
                    NSString *result;
                    @try {
                        result = originalMSG(selfObject, originalCMD, range);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, NSString.class, @selector(substringWithRange:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
        }
        
        [self swizzleInstanceMethod:object_getClass((id)NSArray.class) selector:@selector(arrayWithObjects:count:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSArray * (__unsafe_unretained Class selfObject, const id _Nonnull __unsafe_unretained *objects, NSUInteger cnt) {
                NSArray * (*originalMSG)(id, SEL, const id _Nonnull __unsafe_unretained *, NSUInteger) = (NSArray * (*)(id, SEL, const id _Nonnull __unsafe_unretained *, NSUInteger))originalIMP();
                NSArray *result;
                @try {
                    result = originalMSG(selfObject, originalCMD, objects, cnt);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, object_getClass((id)NSArray.class), @selector(arrayWithObjects:count:), @(__FILE__), __LINE__);
                    
                    NSInteger newCnt = 0;
                    id _Nonnull __unsafe_unretained newObjects[cnt];
                    for (int i = 0; i < cnt; i++) {
                        if (objects[i] != nil) {
                            newObjects[newCnt] = objects[i];
                            newCnt++;
                        }
                    }
                    result = originalMSG(selfObject, originalCMD, newObjects, newCnt);
                } @finally {
                    return result;
                }
            };
        }];
        
        NSArray<NSString *> *arrayClasses = @[
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"ray0"],
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayI"],
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SSingleObj", @"ectArrayI"],
            [NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]
        ];
        for (NSString *arrayClass in arrayClasses) {
            [self swizzleInstanceMethod:NSClassFromString(arrayClass) selector:@selector(objectAtIndex:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^id (__unsafe_unretained NSArray *selfObject, NSUInteger index) {
                    id (*originalMSG)(id, SEL, NSUInteger) = (id (*)(id, SEL, NSUInteger))originalIMP();
                    id result = nil;
                    @try {
                        result = originalMSG(selfObject, originalCMD, index);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, [NSArray class], @selector(objectAtIndex:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
            
            [self swizzleInstanceMethod:NSClassFromString(arrayClass) selector:@selector(objectAtIndexedSubscript:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^id (__unsafe_unretained NSArray *selfObject, NSUInteger index) {
                    id (*originalMSG)(id, SEL, NSUInteger) = (id (*)(id, SEL, NSUInteger))originalIMP();
                    id result = nil;
                    @try {
                        result = originalMSG(selfObject, originalCMD, index);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, [NSArray class], @selector(objectAtIndexedSubscript:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
            
            [self swizzleInstanceMethod:NSClassFromString(arrayClass) selector:@selector(subarrayWithRange:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
                return ^NSArray * (__unsafe_unretained NSArray *selfObject, NSRange range) {
                    NSArray * (*originalMSG)(id, SEL, NSRange) = (NSArray * (*)(id, SEL, NSRange))originalIMP();
                    NSArray *result = nil;
                    @try {
                        result = originalMSG(selfObject, originalCMD, range);
                    } @catch (NSException *exception) {
                        if (exceptionHandler) exceptionHandler(exception, [NSArray class], @selector(subarrayWithRange:), @(__FILE__), __LINE__);
                    } @finally {
                        return result;
                    }
                };
            }];
        }
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(addObject:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, id object) {
                void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(addObject:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(insertObject:atIndex:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, id object, NSUInteger index) {
                void (*originalMSG)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object, index);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(insertObject:atIndex:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(removeObjectAtIndex:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, NSUInteger index) {
                void (*originalMSG)(id, SEL, NSUInteger) = (void (*)(id, SEL, NSUInteger))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, index);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(removeObjectAtIndex:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(replaceObjectAtIndex:withObject:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, NSUInteger index, id object) {
                void (*originalMSG)(id, SEL, NSUInteger, id) = (void (*)(id, SEL, NSUInteger, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, index, object);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(replaceObjectAtIndex:withObject:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(setObject:atIndexedSubscript:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, id object, NSUInteger index) {
                void (*originalMSG)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object, index);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(setObject:atIndexedSubscript:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(removeObjectsInRange:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableArray *selfObject, NSRange range) {
                void (*originalMSG)(id, SEL, NSRange) = (void (*)(id, SEL, NSRange))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, range);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableArray class], @selector(removeObjectsInRange:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SSe", @"tM"]) selector:@selector(addObject:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableSet *selfObject, id object) {
                void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableSet class], @selector(addObject:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SSe", @"tM"]) selector:@selector(removeObject:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableSet *selfObject, id object) {
                void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableSet class], @selector(removeObject:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:object_getClass((id)NSDictionary.class) selector:@selector(dictionaryWithObjects:forKeys:count:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSDictionary * (__unsafe_unretained Class selfObject, const id _Nonnull __unsafe_unretained *objects, const id<NSCopying> _Nonnull __unsafe_unretained *keys, NSUInteger cnt) {
                NSDictionary * (*originalMSG)(id, SEL, const id _Nonnull __unsafe_unretained *, const id<NSCopying> _Nonnull __unsafe_unretained *, NSUInteger) = (NSDictionary * (*)(id, SEL, const id _Nonnull __unsafe_unretained *, const id<NSCopying> _Nonnull __unsafe_unretained *, NSUInteger))originalIMP();
                NSDictionary *result;
                @try {
                    result = originalMSG(selfObject, originalCMD, objects, keys, cnt);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, object_getClass((id)NSDictionary.class), @selector(dictionaryWithObjects:forKeys:count:), @(__FILE__), __LINE__);
                    
                    NSInteger newCnt = 0;
                    id _Nonnull __unsafe_unretained newObjects[cnt];
                    id _Nonnull __unsafe_unretained newKeys[cnt];
                    for (int i = 0; i < cnt; i++) {
                        if (objects[i] && keys[i]) {
                            newObjects[newCnt] = objects[i];
                            newKeys[newCnt] = keys[i];
                            newCnt++;
                        }
                    }
                    result = originalMSG(selfObject, originalCMD, newObjects, newKeys, newCnt);
                } @finally {
                    return result;
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(setObject:forKey:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id object, id key) {
                void (*originalMSG)(id, SEL, id, id) = (void (*)(id, SEL, id, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object, key);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableDictionary class], @selector(setObject:forKey:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(removeObjectForKey:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id key) {
                void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, key);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableDictionary class], @selector(removeObjectForKey:), @(__FILE__), __LINE__);
                }
            };
        }];
        
        [self swizzleInstanceMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(setObject:forKeyedSubscript:) withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id object, id<NSCopying> key) {
                void (*originalMSG)(id, SEL, id, id<NSCopying>) = (void (*)(id, SEL, id, id<NSCopying>))originalIMP();
                @try {
                    originalMSG(selfObject, originalCMD, object, key);
                } @catch (NSException *exception) {
                    if (exceptionHandler) exceptionHandler(exception, [NSMutableDictionary class], @selector(setObject:forKeyedSubscript:), @(__FILE__), __LINE__);
                }
            };
        }];
    });
}

+ (UIImage *)svgDecode:(NSData *)data thumbnailSize:(CGSize)thumbnailSize {
    if (![self svgSupported]) return nil;
    
    BOOL prefersBitmap = NO;
    CGSize imageSize = CGSizeZero;
    if (!CGSizeEqualToSize(thumbnailSize, CGSizeZero)) {
        prefersBitmap = YES;
        imageSize = thumbnailSize;
    }
    
    if (!prefersBitmap) {
        CGSVGDocumentRef document = FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) return nil;
        UIImage *image = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:FWImageWithCGSVGDocumentSEL])(UIImage.class, FWImageWithCGSVGDocumentSEL, document);
        FWCGSVGDocumentRelease(document);
        
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
        @try {
            __unused UIImage *dummyImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [image drawInRect:CGRectMake(0, 0, 1, 1)];
            }];
        } @catch (...) {
            return nil;
        }
        return image;
    } else {
        CGSVGDocumentRef document = FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) {
            return nil;
        }
        CGSize size = FWCGSVGDocumentGetCanvasSize(document);
        if (size.width == 0 || size.height == 0) {
            return nil;
        }
        
        CGFloat xScale;
        CGFloat yScale;
        if (thumbnailSize.width <= 0 && thumbnailSize.height <= 0) {
            thumbnailSize.width = size.width;
            thumbnailSize.height = size.height;
            xScale = 1;
            yScale = 1;
        } else {
            CGFloat xRatio = thumbnailSize.width / size.width;
            CGFloat yRatio = thumbnailSize.height / size.height;
            if (thumbnailSize.width <= 0) {
                yScale = yRatio;
                xScale = yRatio;
                thumbnailSize.width = size.width * xScale;
            } else if (thumbnailSize.height <= 0) {
                xScale = xRatio;
                yScale = xRatio;
                thumbnailSize.height = size.height * yScale;
            } else {
                xScale = MIN(xRatio, yRatio);
                yScale = MIN(xRatio, yRatio);
                thumbnailSize.width = size.width * xScale;
                thumbnailSize.height = size.height * yScale;
            }
        }
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGRect targetRect = CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height);
        
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
        CGAffineTransform transform = CGAffineTransformMakeTranslation((targetRect.size.width / xScale - rect.size.width) / 2, (targetRect.size.height / yScale - rect.size.height) / 2);
        
        UIGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, targetRect.size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextConcatCTM(context, scaleTransform);
        CGContextConcatCTM(context, transform);
        
        FWCGContextDrawSVGDocument(context, document);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        FWCGSVGDocumentRelease(document);
        return image;
    }
}

+ (NSData *)svgEncode:(UIImage *)image {
    if (![self svgSupported]) return nil;
    
    NSMutableData *data = [NSMutableData data];
    CGSVGDocumentRef document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:FWCGSVGDocumentSEL])(image, FWCGSVGDocumentSEL);
    if (!document) return nil;
    FWCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
    return [data copy];
}

+ (BOOL)svgSupported {
    static BOOL isSupported = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFJlbGVhc2U="].UTF8String);
        FWCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"].UTF8String);
        FWCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh"].UTF8String);
        FWCGContextDrawSVGDocument = (void (*)(CGContextRef context, CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50"].UTF8String);
        FWCGSVGDocumentGetCanvasSize = (CGSize (*)(CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU="].UTF8String);
        FWImageWithCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"]);
        FWCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X0NHU1ZHRG9jdW1lbnQ="]);
        
        isSupported = [UIImage respondsToSelector:FWImageWithCGSVGDocumentSEL];
    });
    return isSupported;
}

+ (NSString *)base64Decode:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end