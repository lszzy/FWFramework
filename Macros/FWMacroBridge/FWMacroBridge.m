//
//  FWMacroBridge.m
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import "FWMacroBridge.h"

@implementation FWMacroBridge

+ (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (NS_NOESCAPE ^)(NSException * _Nonnull))exceptionHandler {
    @try {
        if (block) block();
    } @catch (NSException *exception) {
        if (exceptionHandler) exceptionHandler(exception);
    }
}

@end
