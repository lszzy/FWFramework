/**
 @header     FWException.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2022/04/01
 */

#import "FWException.h"
#import "FWSwizzle.h"
#import "FWLogger.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSNotificationName const FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

#define FWExceptionRemark(clazz, selector) \
    [NSString stringWithFormat:@"%@[%@ %@]", class_isMetaClass(clazz) ? @"+" : @"-", NSStringFromClass(clazz), NSStringFromSelector(selector)]

static NSArray<Class> *fwStaticCaptureClasses = nil;

@implementation FWException

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
    FWLogGroup(@"FWFramework", FWLogTypeDebug, @"%@", errorMessage);
#endif
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"name"] = exception.name;
    userInfo[@"reason"] = exception.reason;
    userInfo[@"method"] = callStackMethod;
    userInfo[@"remark"] = remark;
    userInfo[@"symbols"] = callStackSymbols;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FWExceptionCapturedNotification object:exception userInfo:userInfo.copy];
    });
}

#pragma mark - NSObject

+ (void)captureObjectException {
    FWSwizzleClass(NSObject, @selector(methodSignatureForSelector:), FWSwizzleReturn(NSMethodSignature *), FWSwizzleArgs(SEL selector), FWSwizzleCode({
        NSMethodSignature *methodSignature = FWSwizzleOriginal(selector);
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
    
    FWSwizzleClass(NSObject, @selector(forwardInvocation:), FWSwizzleReturn(void), FWSwizzleArgs(NSInvocation *invocation), FWSwizzleCode({
        BOOL isCaptured = NO;
        for (Class captureClass in [self captureClasses]) {
            if ([selfObject isKindOfClass:captureClass]) {
                isCaptured = YES;
                break;
            }
        }
        
        if (isCaptured) {
            @try {
                FWSwizzleOriginal(invocation);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(selfObject.class, invocation.selector)];
            } @finally { }
        } else {
            FWSwizzleOriginal(invocation);
        }
    }));
}

+ (void)captureKvcException {
    FWSwizzleClass(NSObject, @selector(setValue:forKey:), FWSwizzleReturn(void), FWSwizzleArgs(id value, NSString *key), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(value, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(selfObject.class, @selector(setValue:forKey:))];
        } @finally { }
    }));
    
    FWSwizzleClass(NSObject, @selector(setValue:forKeyPath:), FWSwizzleReturn(void), FWSwizzleArgs(id value, NSString *keyPath), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(value, keyPath);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(selfObject.class, @selector(setValue:forKeyPath:))];
        } @finally { }
    }));
    
    FWSwizzleClass(NSObject, @selector(setValue:forUndefinedKey:), FWSwizzleReturn(void), FWSwizzleArgs(id value, NSString *key), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(value, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(selfObject.class, @selector(setValue:forUndefinedKey:))];
        } @finally { }
    }));
    
    FWSwizzleClass(NSObject, @selector(setValuesForKeysWithDictionary:), FWSwizzleReturn(void), FWSwizzleArgs(NSDictionary<NSString *, id> *keyValues), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(keyValues);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(selfObject.class, @selector(setValuesForKeysWithDictionary:))];
        } @finally { }
    }));
}

#pragma mark - NSString

+ (void)captureStringException {
    NSArray<NSString *> *stringClasses = @[@"__NSCFConstantString", @"NSTaggedPointerString", @"__NSCFString"];
    for (NSString *stringClass in stringClasses) {
        FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringFromIndex:), nil, NSString *, FWSwizzleReturn(NSString *), FWSwizzleArgs(NSUInteger from), FWSwizzleCode({
            NSString *result;
            @try {
                result = FWSwizzleOriginal(from);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(NSString.class, @selector(substringFromIndex:))];
            } @finally {
                return result;
            }
        }));
        
        FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringToIndex:), nil, NSString *, FWSwizzleReturn(NSString *), FWSwizzleArgs(NSUInteger to), FWSwizzleCode({
            NSString *result;
            @try {
                result = FWSwizzleOriginal(to);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(NSString.class, @selector(substringToIndex:))];
            } @finally {
                return result;
            }
        }));
        
        FWSwizzleMethod(NSClassFromString(stringClass), @selector(substringWithRange:), nil, NSString *, FWSwizzleReturn(NSString *), FWSwizzleArgs(NSRange range), FWSwizzleCode({
            NSString *result;
            @try {
                result = FWSwizzleOriginal(range);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(NSString.class, @selector(substringWithRange:))];
            } @finally {
                return result;
            }
        }));
    }
}

#pragma mark - NSArray

+ (void)captureArrayException {
    FWSwizzleMethod(object_getClass((id)NSArray.class), @selector(arrayWithObjects:count:), nil, Class, FWSwizzleReturn(NSArray *), FWSwizzleArgs(const id _Nonnull __unsafe_unretained *objects, NSUInteger cnt), FWSwizzleCode({
        NSArray *result;
        @try {
            result = FWSwizzleOriginal(objects, cnt);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(object_getClass((id)NSArray.class), @selector(arrayWithObjects:count:))];
            
            NSInteger newCnt = 0;
            id _Nonnull __unsafe_unretained newObjects[cnt];
            for (int i = 0; i < cnt; i++) {
                if (objects[i] != nil) {
                    newObjects[newCnt] = objects[i];
                    newCnt++;
                }
            }
            result = FWSwizzleOriginal(newObjects, newCnt);
        } @finally {
            return result;
        }
    }));
    
    NSArray<NSString *> *arrayClasses = @[@"__NSArray0", @"__NSArrayI", @"__NSSingleObjectArrayI", @"__NSArrayM"];
    for (NSString *arrayClass in arrayClasses) {
        FWSwizzleMethod(NSClassFromString(arrayClass), @selector(objectAtIndex:), nil, NSArray *, FWSwizzleReturn(id), FWSwizzleArgs(NSUInteger index), FWSwizzleCode({
            id result = nil;
            @try {
                result = FWSwizzleOriginal(index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark([NSArray class], @selector(objectAtIndex:))];
            } @finally {
                return result;
            }
        }));
        
        FWSwizzleMethod(NSClassFromString(arrayClass), @selector(objectAtIndexedSubscript:), nil, NSArray *, FWSwizzleReturn(id), FWSwizzleArgs(NSUInteger index), FWSwizzleCode({
            id result = nil;
            @try {
                result = FWSwizzleOriginal(index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark([NSArray class], @selector(objectAtIndexedSubscript:))];
            } @finally {
                return result;
            }
        }));
        
        FWSwizzleMethod(NSClassFromString(arrayClass), @selector(subarrayWithRange:), nil, NSArray *, FWSwizzleReturn(NSArray *), FWSwizzleArgs(NSRange range), FWSwizzleCode({
            NSArray *result = nil;
            @try {
                result = FWSwizzleOriginal(range);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark([NSArray class], @selector(subarrayWithRange:))];
            } @finally {
                return result;
            }
        }));
    }
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(addObject:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(id object), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(addObject:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(id object, NSUInteger index), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object, index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(insertObject:atIndex:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectAtIndex:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(NSUInteger index), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(removeObjectAtIndex:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectAtIndex:withObject:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(NSUInteger index, id object), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(index, object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(replaceObjectAtIndex:withObject:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(setObject:atIndexedSubscript:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(id object, NSUInteger index), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object, index);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(setObject:atIndexedSubscript:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), nil, NSMutableArray *, FWSwizzleReturn(void), FWSwizzleArgs(NSRange range), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(range);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableArray class], @selector(removeObjectsInRange:))];
        } @finally { }
    }));
}

#pragma mark - NSSet

+ (void)captureSetException {
    FWSwizzleMethod(NSClassFromString(@"__NSSetM"), @selector(addObject:), nil, NSMutableSet *, FWSwizzleReturn(void), FWSwizzleArgs(id object), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableSet class], @selector(addObject:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSSetM"), @selector(removeObject:), nil, NSMutableSet *, FWSwizzleReturn(void), FWSwizzleArgs(id object), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableSet class], @selector(removeObject:))];
        } @finally { }
    }));
}

#pragma mark - NSDictionary

+ (void)captureDictionaryException {
    FWSwizzleMethod(object_getClass((id)NSDictionary.class), @selector(dictionaryWithObjects:forKeys:count:), nil, Class, FWSwizzleReturn(NSDictionary *), FWSwizzleArgs(const id _Nonnull __unsafe_unretained *objects, const id<NSCopying> _Nonnull __unsafe_unretained *keys, NSUInteger cnt), FWSwizzleCode({
        NSDictionary *result;
        @try {
            result = FWSwizzleOriginal(objects, keys, cnt);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark(object_getClass((id)NSDictionary.class), @selector(dictionaryWithObjects:forKeys:count:))];
            
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
            result = FWSwizzleOriginal(newObjects, newKeys, newCnt);
        } @finally {
            return result;
        }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKey:), nil, NSMutableDictionary *, FWSwizzleReturn(void), FWSwizzleArgs(id object, id key), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKey:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(removeObjectForKey:), nil, NSMutableDictionary *, FWSwizzleReturn(void), FWSwizzleArgs(id key), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableDictionary class], @selector(removeObjectForKey:))];
        } @finally { }
    }));
    
    FWSwizzleMethod(NSClassFromString(@"__NSDictionaryM"), @selector(setObject:forKeyedSubscript:), nil, NSMutableDictionary *, FWSwizzleReturn(void), FWSwizzleArgs(id object, id<NSCopying> key), FWSwizzleCode({
        @try {
            FWSwizzleOriginal(object, key);
        } @catch (NSException *exception) {
            [self captureException:exception remark:FWExceptionRemark([NSMutableDictionary class], @selector(setObject:forKeyedSubscript:))];
        } @finally { }
    }));
}

@end
