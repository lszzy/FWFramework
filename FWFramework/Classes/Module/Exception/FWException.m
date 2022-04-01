/**
 @header     FWException.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2022/04/01
 */

#import "FWException.h"
#import "FWLogger.h"

NSNotificationName const FWExceptionCapturedNotification = @"FWExceptionCapturedNotification";

@implementation FWException

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    });
}

#pragma mark - Capture

+ (void)captureException:(NSException *)exception remark:(NSString *)remark {
    NSArray *callStackSymbols = [NSThread callStackSymbols];

    __block NSString *callStackMethod = nil;
    NSString *regularPattern = @"[-\\+]\\[.+\\]";
    NSRegularExpression *regularExpression = [[NSRegularExpression alloc] initWithPattern:regularPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    for (int index = 2; index < callStackSymbols.count; index++) {
        NSString *callStackSymbol = callStackSymbols[index];
        [regularExpression enumerateMatchesInString:callStackSymbol options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbol.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                NSString *callStackMessage = [callStackSymbol substringWithRange:result.range];
                NSString *className = [callStackMessage componentsSeparatedByString:@" "].firstObject;
                className = [className componentsSeparatedByString:@"["].lastObject;
                NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(className)];
                if (![className hasSuffix:@")"] && bundle == [NSBundle mainBundle]) {
                    callStackMethod = callStackMessage;
                }
                *stop = YES;
            }
        }];
        if (callStackMethod.length) break;
    }
    
#ifdef DEBUG
    NSString *errorMessage = [NSString stringWithFormat:@"\n========== EXCEPTION ==========\n  name: %@\nreason: %@\nmethod: %@\nremark: %@\n========== EXCEPTION ==========", exception.name, exception.reason ?: @"-", callStackMethod ?: @"-", remark ?: @"-"];
    FWLogGroup(@"FWFramework", FWLogTypeDebug, @"%@", errorMessage);
#endif
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"name"] = exception.name;
    userInfo[@"reason"] = exception.reason;
    userInfo[@"method"] = callStackMethod;
    userInfo[@"remark"] = remark;
    userInfo[@"callStackSymbols"] = callStackSymbols;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FWExceptionCapturedNotification object:exception userInfo:userInfo.copy];
    });
}

@end
