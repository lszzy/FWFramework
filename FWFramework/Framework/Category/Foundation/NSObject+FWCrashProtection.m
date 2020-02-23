/*!
 @header     NSObject+FWCrashProtection.m
 @indexgroup FWFramework
 @brief      NSObject+FWCrashProtection
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/22
 */

#import "NSObject+FWCrashProtection.h"
#import "NSObject+FWRuntime.h"

#pragma mark - NSNull+FWCrashProtection

// NSNull分类，解决值为NSNull时调用不存在方法崩溃问题，如JSON中包含null。参考：https://github.com/nicklockwood/NullSafe
@interface NSNull (FWCrashProtection)

+ (void)fwCrashProtection;

@end

@implementation NSNull (FWCrashProtection)

+ (void)fwCrashProtection
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerNullMethodSignatureForSelector:)];
        [self fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerNullForwardInvocation:)];
    });
}

- (NSMethodSignature *)fwInnerNullMethodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [self fwInnerNullMethodSignatureForSelector:selector];
    if (!signature) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    return signature;
}

- (void)fwInnerNullForwardInvocation:(NSInvocation *)invocation
{
    invocation.target = nil;
    [invocation invoke];
}

@end

#pragma mark - NSObject+FWCrashProtection

// 调试模式不生效，仅正式模式生效
@implementation NSObject (FWCrashProtection)

+ (void)fwEnableCrashProtection
{
#ifndef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSNull fwCrashProtection];
    });
#endif
}

@end
