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

+ (void)startCaptureExceptions {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    });
}

#pragma mark - Capture

+ (void)captureException:(NSException *)exception remark:(NSString *)remark {
    NSArray *callStackSymbols = [NSThread callStackSymbols];

    __block NSString *callStackPlace = nil;
    NSString *regularPattern = @"[-\\+]\\[.+\\]";
    NSRegularExpression *regularExpression = [[NSRegularExpression alloc] initWithPattern:regularPattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    if (callStackSymbols.count > 2) {
        NSString *callStackSymbol = callStackSymbols[2];
        [regularExpression enumerateMatchesInString:callStackSymbol options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbol.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                callStackPlace = [callStackSymbol substringWithRange:result.range];
                *stop = YES;
            }
        }];
    }
    
#ifdef DEBUG
    NSString *errorMessage = [NSString stringWithFormat:@"\n========== EXCEPTION ==========\nexceptionName: %@\nexceptionReason: %@\nexceptionPlace: %@\nexceptionRemark: %@\n========== EXCEPTION ==========", exception.name, exception.reason ?: @"-", callStackPlace ?: @"-", remark ?: @"-"];
    FWLogGroup(@"FWFramework", FWLogTypeDebug, @"%@", errorMessage);
#endif
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[@"exceptionName"] = exception.name;
    userInfo[@"exceptionReason"] = exception.reason;
    userInfo[@"exceptionPlace"] = callStackPlace;
    userInfo[@"exceptionRemark"] = remark;
    userInfo[@"callStackSymbols"] = callStackSymbols;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FWExceptionCapturedNotification object:exception userInfo:userInfo.copy];
    });
}

@end
