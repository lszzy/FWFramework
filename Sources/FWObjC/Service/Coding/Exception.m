//
//  Exception.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Exception.h"
#import "Swizzle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (BOOL)__fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;
+ (void)__fw_logDebug:(NSString *)message;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

NSNotificationName const __FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

#define __FWExceptionRemark(clazz, selector) \
    [NSString stringWithFormat:@"%@[%@ %@]", class_isMetaClass(clazz) ? @"+" : @"-", NSStringFromClass(clazz), NSStringFromSelector(selector)]

#define __FWLogGroup( aFormat, ... ) \
    [NSObject __fw_logDebug:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

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
    NSString *errorMessage = [NSString stringWithFormat:@"\n========== EXCEPTION ==========\n  name: %@\nreason: %@\nmethod: %@\nremark: %@\n========== EXCEPTION ==========", exception.name, exception.reason ?: @"-", callStackMethod ?: @"-", remark ?: @"-"];
    __FWLogGroup(@"%@", errorMessage);
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
    __FWSwizzleClass(NSObject, @selector(methodSignatureForSelector:), __FWSwizzleReturn(NSMethodSignature *), __FWSwizzleArgs(SEL selector), __FWSwizzleCode({
        NSMethodSignature *methodSignature = __FWSwizzleOriginal(selector);
        if (!methodSignature) {
            for (Class captureClass in [self captureClasses]) {
                if ([selfObject isKindOfClass:captureClass]) {
                    methodSignature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
                    break;
                }
            }
        }
        return methodSignature;
    }));
    
    __FWSwizzleClass(NSObject, @selector(forwardInvocation:), __FWSwizzleReturn(void), __FWSwizzleArgs(NSInvocation *invocation), __FWSwizzleCode({
        BOOL isCaptured = NO;
        for (Class captureClass in [self captureClasses]) {
            if ([selfObject isKindOfClass:captureClass]) {
                isCaptured = YES;
                break;
            }
        }
        
        if (isCaptured) {
            @try {
                __FWSwizzleOriginal(invocation);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(selfObject.class, invocation.selector)];
            } @finally { }
        } else {
            __FWSwizzleOriginal(invocation);
        }
    }));
}

+ (void)captureKvcException {
    __FWSwizzleClass(NSObject, @selector(setValue:forKey:), __FWSwizzleReturn(void), __FWSwizzleArgs(id value, NSString *key), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(value, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forKey:))];
        } @finally { }
    }));
    
    __FWSwizzleClass(NSObject, @selector(setValue:forKeyPath:), __FWSwizzleReturn(void), __FWSwizzleArgs(id value, NSString *keyPath), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(value, keyPath);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forKeyPath:))];
        } @finally { }
    }));
    
    __FWSwizzleClass(NSObject, @selector(setValue:forUndefinedKey:), __FWSwizzleReturn(void), __FWSwizzleArgs(id value, NSString *key), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(value, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValue:forUndefinedKey:))];
        } @finally { }
    }));
    
    __FWSwizzleClass(NSObject, @selector(setValuesForKeysWithDictionary:), __FWSwizzleReturn(void), __FWSwizzleArgs(NSDictionary<NSString *, id> *keyValues), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(keyValues);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark(selfObject.class, @selector(setValuesForKeysWithDictionary:))];
        } @finally { }
    }));
}

#pragma mark - NSString

+ (void)captureStringException {
    NSArray<NSString *> *stringClasses = @[@"__NSCFConstantString", @"NSTaggedPointerString", @"__NSCFString"];
    for (NSString *stringClass in stringClasses) {
        __FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringFromIndex:), nil, NSString *, __FWSwizzleReturn(NSString *), __FWSwizzleArgs(NSUInteger from), __FWSwizzleCode({
            NSString *result;
            @try {
                result = __FWSwizzleOriginal(from);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringFromIndex:))];
            } @finally {
                return result;
            }
        }));
        
        __FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringToIndex:), nil, NSString *, __FWSwizzleReturn(NSString *), __FWSwizzleArgs(NSUInteger to), __FWSwizzleCode({
            NSString *result;
            @try {
                result = __FWSwizzleOriginal(to);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringToIndex:))];
            } @finally {
                return result;
            }
        }));
        
        __FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringWithRange:), nil, NSString *, __FWSwizzleReturn(NSString *), __FWSwizzleArgs(NSRange range), __FWSwizzleCode({
            NSString *result;
            @try {
                result = __FWSwizzleOriginal(range);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark(NSString.class, @selector(substringWithRange:))];
            } @finally {
                return result;
            }
        }));
    }
}

#pragma mark - NSArray

+ (void)captureArrayException {
    __FWSwizzleMethod(object_getClass((id)NSArray.class), @selector(arrayWithObjects:count:), nil, Class, __FWSwizzleReturn(NSArray *), __FWSwizzleArgs(const id _Nonnull __unsafe_unretained *objects, NSUInteger cnt), __FWSwizzleCode({
        NSArray *result;
        @try {
            result = __FWSwizzleOriginal(objects, cnt);
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
            result = __FWSwizzleOriginal(newObjects, newCnt);
        } @finally {
            return result;
        }
    }));
    
    NSArray<NSString *> *arrayClasses = @[@"__NSArray0", @"__NSArrayI", @"__NSSingleObjectArrayI", @"__NSArrayM"];
    for (NSString *arrayClass in arrayClasses) {
        __FWSwizzleMethod(NSClassFromString(arrayClass), @selector(objectAtIndex:), nil, NSArray *, __FWSwizzleReturn(id), __FWSwizzleArgs(NSUInteger index), __FWSwizzleCode({
            id result = nil;
            @try {
                result = __FWSwizzleOriginal(index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(objectAtIndex:))];
            } @finally {
                return result;
            }
        }));
        
        __FWSwizzleMethod(NSClassFromString(arrayClass), @selector(objectAtIndexedSubscript:), nil, NSArray *, __FWSwizzleReturn(id), __FWSwizzleArgs(NSUInteger index), __FWSwizzleCode({
            id result = nil;
            @try {
                result = __FWSwizzleOriginal(index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(objectAtIndexedSubscript:))];
            } @finally {
                return result;
            }
        }));
        
        __FWSwizzleMethod(NSClassFromString(arrayClass), @selector(subarrayWithRange:), nil, NSArray *, __FWSwizzleReturn(NSArray *), __FWSwizzleArgs(NSRange range), __FWSwizzleCode({
            NSArray *result = nil;
            @try {
                result = __FWSwizzleOriginal(range);
            } @catch (NSException *exception) {
                [self captureException:exception remark:__FWExceptionRemark([NSArray class], @selector(subarrayWithRange:))];
            } @finally {
                return result;
            }
        }));
    }
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(addObject:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(addObject:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object, NSUInteger index), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object, index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(insertObject:atIndex:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectAtIndex:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(NSUInteger index), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(removeObjectAtIndex:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectAtIndex:withObject:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(NSUInteger index, id object), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(index, object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(replaceObjectAtIndex:withObject:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(setObject:atIndexedSubscript:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object, NSUInteger index), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object, index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(setObject:atIndexedSubscript:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), nil, NSMutableArray *, __FWSwizzleReturn(void), __FWSwizzleArgs(NSRange range), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(range);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableArray class], @selector(removeObjectsInRange:))];
        } @finally { }
    }));
}

#pragma mark - NSSet

+ (void)captureSetException {
    __FWSwizzleMethod(NSClassFromString(@"__NSSetM"), @selector(addObject:), nil, NSMutableSet *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableSet class], @selector(addObject:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSSetM"), @selector(removeObject:), nil, NSMutableSet *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableSet class], @selector(removeObject:))];
        } @finally { }
    }));
}

#pragma mark - NSDictionary

+ (void)captureDictionaryException {
    __FWSwizzleMethod(object_getClass((id)NSDictionary.class), @selector(dictionaryWithObjects:forKeys:count:), nil, Class, __FWSwizzleReturn(NSDictionary *), __FWSwizzleArgs(const id _Nonnull __unsafe_unretained *objects, const id<NSCopying> _Nonnull __unsafe_unretained *keys, NSUInteger cnt), __FWSwizzleCode({
        NSDictionary *result;
        @try {
            result = __FWSwizzleOriginal(objects, keys, cnt);
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
            result = __FWSwizzleOriginal(newObjects, newKeys, newCnt);
        } @finally {
            return result;
        }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKey:), nil, NSMutableDictionary *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object, id key), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKey:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(removeObjectForKey:), nil, NSMutableDictionary *, __FWSwizzleReturn(void), __FWSwizzleArgs(id key), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(removeObjectForKey:))];
        } @finally { }
    }));
    
    __FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKeyedSubscript:), nil, NSMutableDictionary *, __FWSwizzleReturn(void), __FWSwizzleArgs(id object, id<NSCopying> key), __FWSwizzleCode({
        @try {
            __FWSwizzleOriginal(object, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:__FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKeyedSubscript:))];
        } @finally { }
    }));
}

@end
