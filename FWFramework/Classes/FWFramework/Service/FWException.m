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
#import <objc/message.h>

NSNotificationName const FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

#define FWExceptionRemark(clazz, selector) \
    [NSString stringWithFormat:@"-[%@ %@]", NSStringFromClass(clazz), NSStringFromSelector(selector)]

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
    NSArray<NSString *> *stringClasses = @[@"__NSCFConstantString", @"NSTaggedPointerString"];
    for (NSString *stringClass in stringClasses) {
        FWSwizzleMethod(NSClassFromString(stringClass), @selector(characterAtIndex:), nil, NSString *, FWSwizzleReturn(unichar), FWSwizzleArgs(NSUInteger index), FWSwizzleCode({
            unichar result;
            @try {
                result = FWSwizzleOriginal(index);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(NSString.class, @selector(characterAtIndex:))];
            } @finally {
                return result;
            }
        }));
        
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
        
        FWSwizzleMethod(NSClassFromString(stringClass), @selector(rangeOfString:options:range:locale:), nil, NSString *, FWSwizzleReturn(NSRange), FWSwizzleArgs(NSString *searchString, NSStringCompareOptions options, NSRange range, NSLocale *locale), FWSwizzleCode({
            NSRange result;
            @try {
                result = FWSwizzleOriginal(searchString, options, range, locale);
            } @catch (NSException *exception) {
                [self captureException:exception remark:FWExceptionRemark(NSString.class, @selector(rangeOfString:options:range:locale:))];
            } @finally {
                return result;
            }
        }));
    }
}

#pragma mark - NSArray

+ (void)captureArrayException {
    
}

@end
