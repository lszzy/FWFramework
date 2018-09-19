/*!
 @header     NSNull+FWFramework.m
 @indexgroup FWFramework
 @brief      NSNull分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import "NSNull+FWFramework.h"
#import <objc/runtime.h>

#pragma GCC diagnostic ignored "-Wgnu-conditional-omitted-operand"

@implementation NSNull (FWFramework)

#if FWNullEnabled

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
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
    invocation.target = nil;
    [invocation invoke];
}

#endif

@end
