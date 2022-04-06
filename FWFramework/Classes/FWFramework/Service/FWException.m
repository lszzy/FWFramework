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

NSNotificationName const FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

static NSArray<Class> *fwStaticCaptureClasses = nil;

@implementation FWException

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
        [self captureUnrecognizedSelectorException];
    });
}

#pragma mark - Capture

+ (void)captureException:(NSException *)exception remark:(NSString *)remark {
    NSArray *callStackSymbols = [NSThread callStackSymbols];
    __block NSString *callStackMethod = nil;
    for (NSUInteger index = 1; index < callStackSymbols.count; index++) {
        NSString *callStackSymbol = callStackSymbols[index];
        if ([callStackSymbol containsString:@"FWException"]) continue;
        
        NSString *regularPattern = @"[-\\+]\\[.+\\]";
        NSRegularExpression *regularExpression = [[NSRegularExpression alloc] initWithPattern:regularPattern options:NSRegularExpressionCaseInsensitive error:nil];
        [regularExpression enumerateMatchesInString:callStackSymbol options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbol.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                callStackMethod = [callStackSymbol substringWithRange:result.range];
                *stop = YES;
            }
        }];
        break;
    }
    
    if (!remark) remark = @"FWException captured this exception to avoid crash";
    
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

#pragma mark - Selector

+ (void)captureUnrecognizedSelectorException {
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
                [self captureException:exception remark:nil];
            } @finally { }
        } else {
            FWSwizzleOriginal(invocation);
        }
    }));
}

@end
