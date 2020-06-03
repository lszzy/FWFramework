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
        [NSObject fwSwizzleInstanceMethod:@selector(methodSignatureForSelector:) in:[NSNull class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^NSMethodSignature *(NSNull *selfObject, SEL selector) {
                NSMethodSignature *signature = ((NSMethodSignature *(*)(id, SEL, SEL))originalIMP())(selfObject, originalCMD, selector);
                if (!signature) {
                    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
                }
                return signature;
            };
        }];
        [NSObject fwSwizzleInstanceMethod:@selector(forwardInvocation:) in:[NSNull class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(NSNull *selfObject, NSInvocation *invocation) {
                invocation.target = nil;
                [invocation invoke];
            };
        }];
    });
#endif
}

@end
