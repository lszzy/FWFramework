/*!
 @header     NSNull+FWFramework.m
 @indexgroup FWFramework
 @brief      NSNull+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/23
 */

#import "NSNull+FWFramework.h"
#import "NSObject+FWRuntime.h"

@implementation NSNull (FWFramework)

+ (void)load
{
#ifndef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) with:@selector(fwInnerNullMethodSignatureForSelector:)];
        [self fwSwizzleInstanceMethod:@selector(forwardInvocation:) with:@selector(fwInnerNullForwardInvocation:)];
    });
#endif
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
