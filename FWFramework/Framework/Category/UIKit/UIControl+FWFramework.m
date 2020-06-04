/*!
 @header     UIControl+FWFramework.m
 @indexgroup FWFramework
 @brief      UIControl+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/21
 */

#import "UIControl+FWFramework.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation UIControl (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleMethod([UIControl class], @selector(sendAction:to:forEvent:), nil, UIControl *, void, FWSwizzleArguments(SEL action, id target, UIEvent *event), FWSwizzleCode({
            // 仅拦截Touch事件，且配置了间隔时间的Event
            if (event.type == UIEventTypeTouches && event.subtype == UIEventSubtypeNone && selfObject.fwTouchEventInterval > 0) {
                if (event.timestamp - selfObject.fwTouchEventTimestamp < selfObject.fwTouchEventInterval) {
                    return;
                }
                selfObject.fwTouchEventTimestamp = event.timestamp;
            }
            
            FWSwizzleOriginal(action, target, event);
        }));
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
