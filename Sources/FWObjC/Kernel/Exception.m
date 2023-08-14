//
//  Exception.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Exception.h"
#import <objc/runtime.h>
#import <FWFramework/FWFramework-Swift.h>

NSNotificationName const __FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

#define __FWLogDebug( aFormat, ... ) \
    [NSObject __fw_logDebug:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

#define __FWExceptionRemark(clazz, selector) \
    [NSString stringWithFormat:@"%@[%@ %@]", class_isMetaClass(clazz) ? @"+" : @"-", NSStringFromClass(clazz), NSStringFromSelector(selector)]

static NSArray<Class> *fwStaticCaptureClasses = nil;

@implementation __FWExceptionManager

#pragma mark - Capture

+ (NSArray<Class> *)captureClasses {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!fwStaticCaptureClasses) {
            fwStaticCaptureClasses = @[
                [NSNull class],
                [NSNumber class],
                [NSString class],
                [NSArray class],
                [NSDictionary class],
            ];
        }
    });
    return fwStaticCaptureClasses;
}

+ (void)setCaptureClasses:(NSArray<Class> *)captureClasses {
    if (captureClasses) fwStaticCaptureClasses = captureClasses;
}

+ (void)startCaptureExceptions {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self captureObjectException];
        [self captureKvcException];
        [self captureStringException];
        [self captureArrayException];
        [self captureSetException];
        [self captureDictionaryException];
    });
}

+ (void)captureException:(NSException *)exception remark:(NSString *)remark {
    __block NSString *callStackMethod = nil;
    NSArray *callStackSymbols = [NSThread callStackSymbols];
    NSArray *skipStackSymbols = @[@"FWException", @"Foundation", @"UIKit"];
    [callStackSymbols enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
        for (NSString *skipStackSymbol in skipStackSymbols) {
            if ([str containsString:skipStackSymbol]) return;
        }
        
        NSString *regularPattern = @"[-\\+]\\[.+\\]";
        NSRegularExpression *regularExpression = [[NSRegularExpression alloc] initWithPattern:regularPattern options:NSRegularExpressionCaseInsensitive error:nil];
        [regularExpression enumerateMatchesInString:str options:NSMatchingReportProgress range:NSMakeRange(0, str.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                callStackMethod = [str substringWithRange:result.range];
                *stop = YES;
            }
        }];
        *stop = YES;
    }];
    
#ifdef DEBUG
    NSString *errorMessage = [NSString stringWithFormat:@"\n========== EXCEPTION ==========\n  name: %@\nreason: %@\nmethod: %@\nremark: %@\n========== EXCEPTION ==========", exception.name, (exception.reason ?: @"-"), (callStackMethod ?: @"-"), (remark ?: @"-")];
    __FWLogDebug(@"%@", errorMessage);
#endif
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"name"] = exception.name;
    userInfo[@"reason"] = exception.reason;
    userInfo[@"method"] = callStackMethod;
    userInfo[@"remark"] = remark;
    userInfo[@"symbols"] = callStackSymbols;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:__FWExceptionCapturedNotification object:exception userInfo:userInfo.copy];
    });
}

#pragma mark - NSObject

+ (void)captureObjectException {
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(methodSignatureForSelector:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^NSMethodSignature * (__unsafe_unretained NSObject *selfObject, SEL selector) {
            NSMethodSignature * (*originalMSG)(id, SEL, SEL) = (NSMethodSignature * (*)(id, SEL, SEL))originalIMP();
            NSMethodSignature *methodSignature = originalMSG(selfObject, originalCMD, selector);
            if (!methodSignature) {
                for (Class captureClass in [self captureClasses]) {
                    if ([selfObject isKindOfClass:captureClass]) {
                        methodSignature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
                        break;
                    }
                }
            }
            return methodSignature;
        };
    }];
    
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(forwardInvocation:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSObject *selfObject, NSInvocation *invocation) {
            void (*originalMSG)(id, SEL, NSInvocation *) = (void (*)(id, SEL, NSInvocation *))originalIMP();
            BOOL isCaptured = NO;
            for (Class captureClass in [self captureClasses]) {
                if ([selfObject isKindOfClass:captureClass]) {
                    isCaptured = YES;
                    break;
                }
            }
            
            if (isCaptured) {
                @try {
                    originalMSG(selfObject, originalCMD, invocation);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark(selfObject.class, invocation.selector)];
                }
            } else {
                originalMSG(selfObject, originalCMD, invocation);
            }
        };
    }];
}

+ (void)captureKvcException {
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(setValue:forKey:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *key) {
            void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, value, key);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forKey:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(setValue:forKeyPath:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *keyPath) {
            void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, value, keyPath);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forKeyPath:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(setValue:forUndefinedKey:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSObject *selfObject, id value, NSString *key) {
            void (*originalMSG)(id, SEL, id, NSString *) = (void (*)(id, SEL, id, NSString *))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, value, key);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forUndefinedKey:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:[NSObject class] selector:@selector(setValuesForKeysWithDictionary:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSObject *selfObject, NSDictionary<NSString *, id> *keyValues) {
            void (*originalMSG)(id, SEL, NSDictionary<NSString *, id> *) = (void (*)(id, SEL, NSDictionary<NSString *, id> *))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, keyValues);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValuesForKeysWithDictionary:))];
            }
        };
    }];
}

#pragma mark - NSString

+ (void)captureStringException {
    NSArray<NSString *> *stringClasses = @[
        [NSString stringWithFormat:@"%@%@%@", @"__N", @"SCFCon", @"stantString"],
        [NSString stringWithFormat:@"%@%@%@", @"N", @"STaggedPo", @"interString"],
        [NSString stringWithFormat:@"%@%@%@", @"__N", @"SCFS", @"tring"]
    ];
    for (NSString *stringClass in stringClasses) {
        [NSObject __fw_swizzleMethod:NSClassFromString(stringClass) selector:@selector(substringFromIndex:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSString * (__unsafe_unretained NSString *selfObject, NSUInteger from) {
                NSString * (*originalMSG)(id, SEL, NSUInteger) = (NSString * (*)(id, SEL, NSUInteger))originalIMP();
                NSString *result;
                @try {
                    result = originalMSG(selfObject, originalCMD, from);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringFromIndex:))];
                } @finally {
                    return result;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:NSClassFromString(stringClass) selector:@selector(substringToIndex:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSString * (__unsafe_unretained NSString *selfObject, NSUInteger to) {
                NSString * (*originalMSG)(id, SEL, NSUInteger) = (NSString * (*)(id, SEL, NSUInteger))originalIMP();
                NSString *result;
                @try {
                    result = originalMSG(selfObject, originalCMD, to);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringToIndex:))];
                } @finally {
                    return result;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:NSClassFromString(stringClass) selector:@selector(substringWithRange:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSString * (__unsafe_unretained NSString *selfObject, NSRange range) {
                NSString * (*originalMSG)(id, SEL, NSRange) = (NSString * (*)(id, SEL, NSRange))originalIMP();
                NSString *result;
                @try {
                    result = originalMSG(selfObject, originalCMD, range);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringWithRange:))];
                } @finally {
                    return result;
                }
            };
        }];
    }
}

#pragma mark - NSArray

+ (void)captureArrayException {
    [NSObject __fw_swizzleMethod:object_getClass((id)NSArray.class) selector:@selector(arrayWithObjects:count:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^NSArray * (__unsafe_unretained Class selfObject, const id _Nonnull __unsafe_unretained *objects, NSUInteger cnt) {
            NSArray * (*originalMSG)(id, SEL, const id _Nonnull __unsafe_unretained *, NSUInteger) = (NSArray * (*)(id, SEL, const id _Nonnull __unsafe_unretained *, NSUInteger))originalIMP();
            NSArray *result;
            @try {
                result = originalMSG(selfObject, originalCMD, objects, cnt);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(object_getClass((id)NSArray.class), @selector(arrayWithObjects:count:))];
                
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
        [NSObject __fw_swizzleMethod:NSClassFromString(arrayClass) selector:@selector(objectAtIndex:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^id (__unsafe_unretained NSArray *selfObject, NSUInteger index) {
                id (*originalMSG)(id, SEL, NSUInteger) = (id (*)(id, SEL, NSUInteger))originalIMP();
                id result = nil;
                @try {
                    result = originalMSG(selfObject, originalCMD, index);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(objectAtIndex:))];
                } @finally {
                    return result;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:NSClassFromString(arrayClass) selector:@selector(objectAtIndexedSubscript:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^id (__unsafe_unretained NSArray *selfObject, NSUInteger index) {
                id (*originalMSG)(id, SEL, NSUInteger) = (id (*)(id, SEL, NSUInteger))originalIMP();
                id result = nil;
                @try {
                    result = originalMSG(selfObject, originalCMD, index);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(objectAtIndexedSubscript:))];
                } @finally {
                    return result;
                }
            };
        }];
        
        [NSObject __fw_swizzleMethod:NSClassFromString(arrayClass) selector:@selector(subarrayWithRange:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSArray * (__unsafe_unretained NSArray *selfObject, NSRange range) {
                NSArray * (*originalMSG)(id, SEL, NSRange) = (NSArray * (*)(id, SEL, NSRange))originalIMP();
                NSArray *result = nil;
                @try {
                    result = originalMSG(selfObject, originalCMD, range);
                } @catch (NSException *exception) {
                    [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(subarrayWithRange:))];
                } @finally {
                    return result;
                }
            };
        }];
    }
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(addObject:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, id object) {
            void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(addObject:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(insertObject:atIndex:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, id object, NSUInteger index) {
            void (*originalMSG)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object, index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(insertObject:atIndex:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(removeObjectAtIndex:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, NSUInteger index) {
            void (*originalMSG)(id, SEL, NSUInteger) = (void (*)(id, SEL, NSUInteger))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(removeObjectAtIndex:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(replaceObjectAtIndex:withObject:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, NSUInteger index, id object) {
            void (*originalMSG)(id, SEL, NSUInteger, id) = (void (*)(id, SEL, NSUInteger, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, index, object);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(replaceObjectAtIndex:withObject:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(setObject:atIndexedSubscript:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, id object, NSUInteger index) {
            void (*originalMSG)(id, SEL, id, NSUInteger) = (void (*)(id, SEL, id, NSUInteger))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object, index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(setObject:atIndexedSubscript:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SAr", @"rayM"]) selector:@selector(removeObjectsInRange:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableArray *selfObject, NSRange range) {
            void (*originalMSG)(id, SEL, NSRange) = (void (*)(id, SEL, NSRange))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, range);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(removeObjectsInRange:))];
            }
        };
    }];
}

#pragma mark - NSSet

+ (void)captureSetException {
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SSe", @"tM"]) selector:@selector(addObject:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableSet *selfObject, id object) {
            void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableSet class], @selector(addObject:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SSe", @"tM"]) selector:@selector(removeObject:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableSet *selfObject, id object) {
            void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableSet class], @selector(removeObject:))];
            }
        };
    }];
}

#pragma mark - NSDictionary

+ (void)captureDictionaryException {
    [NSObject __fw_swizzleMethod:object_getClass((id)NSDictionary.class) selector:@selector(dictionaryWithObjects:forKeys:count:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^NSDictionary * (__unsafe_unretained Class selfObject, const id _Nonnull __unsafe_unretained *objects, const id<NSCopying> _Nonnull __unsafe_unretained *keys, NSUInteger cnt) {
            NSDictionary * (*originalMSG)(id, SEL, const id _Nonnull __unsafe_unretained *, const id<NSCopying> _Nonnull __unsafe_unretained *, NSUInteger) = (NSDictionary * (*)(id, SEL, const id _Nonnull __unsafe_unretained *, const id<NSCopying> _Nonnull __unsafe_unretained *, NSUInteger))originalIMP();
            NSDictionary *result;
            @try {
                result = originalMSG(selfObject, originalCMD, objects, keys, cnt);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(object_getClass((id)NSDictionary.class), @selector(dictionaryWithObjects:forKeys:count:))];
                
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
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(setObject:forKey:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id object, id key) {
            void (*originalMSG)(id, SEL, id, id) = (void (*)(id, SEL, id, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object, key);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKey:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(removeObjectForKey:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id key) {
            void (*originalMSG)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, key);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(removeObjectForKey:))];
            }
        };
    }];
    
    [NSObject __fw_swizzleMethod:NSClassFromString([NSString stringWithFormat:@"%@%@%@", @"__N", @"SDict", @"ionaryM"]) selector:@selector(setObject:forKeyedSubscript:) identifier:nil block:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^void (__unsafe_unretained NSMutableDictionary *selfObject, id object, id<NSCopying> key) {
            void (*originalMSG)(id, SEL, id, id<NSCopying>) = (void (*)(id, SEL, id, id<NSCopying>))originalIMP();
            @try {
                originalMSG(selfObject, originalCMD, object, key);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKeyedSubscript:))];
            }
        };
    }];
}

@end
