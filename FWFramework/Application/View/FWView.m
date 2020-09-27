/*!
 @header     FWView.m
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWView.h"
#import "FWProxy.h"
#import <objc/runtime.h>

@implementation UIView (FWView)

- (id)fwViewModel
{
    return objc_getAssociatedObject(self, @selector(fwViewModel));
}

- (void)setFwViewModel:(id)fwViewModel
{
    // 仅当值发生改变才触发KVO，下同
    if (fwViewModel != [self fwViewModel]) {
        [self willChangeValueForKey:@"fwViewModel"];
        objc_setAssociatedObject(self, @selector(fwViewModel), fwViewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewModel"];
    }
}

- (id<FWViewDelegate>)fwViewDelegate
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwViewDelegate));
    return value.object;
}

- (void)setFwViewDelegate:(id<FWViewDelegate>)fwViewDelegate
{
    // 仅当值发生改变才触发KVO，下同
    if (fwViewDelegate != [self fwViewDelegate]) {
        [self willChangeValueForKey:@"fwViewDelegate"];
        objc_setAssociatedObject(self, @selector(fwViewDelegate), [[FWWeakObject alloc] initWithObject:fwViewDelegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewDelegate"];
    }
}

- (void)fwTouchEvent:(NSNotification *)event
{
    if (self.fwViewDelegate && [self.fwViewDelegate respondsToSelector:@selector(onTouchView:withEvent:)]) {
        [self.fwViewDelegate onTouchView:self withEvent:event];
    }
}

@end
