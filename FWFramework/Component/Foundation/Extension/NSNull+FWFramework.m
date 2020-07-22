/*!
 @header     NSNull+FWFramework.m
 @indexgroup FWFramework
 @brief      NSNull+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/23
 */

#import "NSNull+FWFramework.h"
#import "FWSwizzle.h"

@implementation NSNull (FWFramework)

+ (void)load
{
#ifndef DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(NSNull, @selector(methodSignatureForSelector:), FWSwizzleReturn(NSMethodSignature *), FWSwizzleArgs(SEL selector), FWSwizzleCode({
            NSMethodSignature *signature = FWSwizzleOriginal(selector);
            if (!signature) {
                return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
            }
            return signature;
        }));
        FWSwizzleClass(NSNull, @selector(forwardInvocation:), FWSwizzleReturn(void), FWSwizzleArgs(NSInvocation *invocation), FWSwizzleCode({
            invocation.target = nil;
            [invocation invoke];
        }));
    });
#endif
}

@end
