/*!
 @header     UIControl+FWFramework.m
 @indexgroup FWFramework
 @brief      UIControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/21
 */

#import "UIControl+FWFramework.h"
#import "NSObject+FWSwizzle.h"
#import <objc/runtime.h>

@implementation UIControl (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject fwSwizzleInstanceMethod:@selector(sendAction:to:forEvent:) in:[UIControl class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(UIControl *selfObject, SEL action, id target, UIEvent *event) {
                // 仅拦截Touch事件，且配置了间隔时间的Event
                if (event.type == UIEventTypeTouches && event.subtype == UIEventSubtypeNone && selfObject.fwTouchEventInterval > 0) {
                    if (event.timestamp - selfObject.fwTouchEventTimestamp < selfObject.fwTouchEventInterval) {
                        return;
                    }
                    selfObject.fwTouchEventTimestamp = event.timestamp;
                }
                
                ((void (*)(id, SEL, SEL, id, UIEvent *))originalIMP())(selfObject, originalCMD, action, target, event);
            };
        }];
    });
}

- (NSTimeInterval)fwTouchEventInterval
{
    return [objc_getAssociatedObject(self, @selector(fwTouchEventInterval)) doubleValue];
}

- (void)setFwTouchEventInterval:(NSTimeInterval)interval
{
    objc_setAssociatedObject(self, @selector(fwTouchEventInterval), @(interval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)fwTouchEventTimestamp
{
    return [objc_getAssociatedObject(self, @selector(fwTouchEventTimestamp)) doubleValue];
}

- (void)setFwTouchEventTimestamp:(NSTimeInterval)timestamp
{
    objc_setAssociatedObject(self, @selector(fwTouchEventTimestamp), @(timestamp), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
