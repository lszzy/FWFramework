//
//  ObjC.m
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import "ObjC.h"
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - ObjCBridge

@implementation FWObjCBridge

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

@end
