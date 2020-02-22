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
#import <objc/runtime.h>

#pragma mark - NSNull+FWCrashProtection

/*!
@brief NSNull分类，解决值为NSNull时调用不存在方法崩溃问题(如JSON中包含null)
@discussion 默认调试环境不处理崩溃，正式环境才处理崩溃，尽量开发阶段避免此问题

@see https://github.com/nicklockwood/NullSafe
*/
@interface NSNull (FWCrashProtection)

+ (void)fwCrashProtection;

@end

static BOOL fwStaticNullEnabled = NO;

@implementation NSNull (FWCrashProtection)

+ (void)fwCrashProtection
{
    fwStaticNullEnabled = YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    if (!fwStaticNullEnabled) {
        return [super methodSignatureForSelector:selector];
    }
    
    @synchronized([self class]) {
        // 查找方法签名
        NSMethodSignature *signature = [super methodSignatureForSelector:selector];
        if (!signature) {
            // NSNull不支持，查找其它类
            static NSMutableSet *classList = nil;
            static NSMutableDictionary *signatureCache = nil;
            if (signatureCache == nil) {
                classList = [[NSMutableSet alloc] init];
                signatureCache = [[NSMutableDictionary alloc] init];
                
                // 获取类列表
                int numClasses = objc_getClassList(NULL, 0);
                Class *classes = (Class *)malloc(sizeof(Class) * (unsigned long)numClasses);
                numClasses = objc_getClassList(classes, numClasses);
                
                // 添加到检查列表
                NSMutableSet *excluded = [NSMutableSet set];
                for (int i = 0; i < numClasses; i++) {
                    // 检查类是否有父类
                    Class someClass = classes[i];
                    Class superclass = class_getSuperclass(someClass);
                    while (superclass) {
                        if (superclass == [NSObject class]) {
                            [classList addObject:someClass];
                            break;
                        }
                        [excluded addObject:NSStringFromClass(superclass)];
                        superclass = class_getSuperclass(superclass);
                    }
                }
                
                // 移除所有有子类的类
                for (Class someClass in excluded) {
                    [classList removeObject:someClass];
                }
                
                // 释放类列表
                free(classes);
            }
            
            // 先检查实现缓存
            NSString *selectorString = NSStringFromSelector(selector);
            signature = signatureCache[selectorString];
            if (!signature) {
                // 查找实现
                for (Class someClass in classList) {
                    if ([someClass instancesRespondToSelector:selector]) {
                        signature = [someClass instanceMethodSignatureForSelector:selector];
                        break;
                    }
                }
                
                // 加入缓存
                signatureCache[selectorString] = signature ?: [NSNull null];
            } else if ([signature isKindOfClass:[NSNull class]]) {
                signature = nil;
            }
        }
        return signature;
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (!fwStaticNullEnabled) {
        return [super forwardInvocation:invocation];
    }
    
    invocation.target = nil;
    [invocation invoke];
}

@end

#pragma mark - NSObject+FWCrashProtection

@implementation NSObject (FWCrashProtection)

+ (void)fwEnableCrashProtection
{
#ifndef DEBUG
    // 调试模式不生效
#else
    // 正式模式生效
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSNull fwCrashProtection];
    });
#endif
}

@end
