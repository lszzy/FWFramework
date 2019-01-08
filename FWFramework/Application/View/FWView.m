/*!
 @header     FWView.m
 @indexgroup FWFramework
 @brief      FWView
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWView.h"
#import <objc/runtime.h>

@implementation FWViewEvent

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _object = object;
        _userInfo = [userInfo copy];
    }
    return self;
}

+ (instancetype)eventWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    return [[self alloc] initWithName:name object:object userInfo:userInfo];
}

@end

@implementation UIView (FWEvent)

- (id<FWViewDelegate>)fwViewDelegate
{
    return objc_getAssociatedObject(self, @selector(fwViewDelegate));
}

- (void)setFwViewDelegate:(id<FWViewDelegate>)fwViewDelegate
{
    // 仅当值发生改变才触发KVO，下同
    if (fwViewDelegate != [self fwViewDelegate]) {
        [self willChangeValueForKey:@"fwViewDelegate"];
        objc_setAssociatedObject(self, @selector(fwViewDelegate), fwViewDelegate, OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"fwViewDelegate"];
    }
}

- (void)fwTouchEvent:(FWViewEvent *)event
{
    if (self.fwViewDelegate && [self.fwViewDelegate respondsToSelector:@selector(onTouchView:withEvent:)]) {
        [self.fwViewDelegate onTouchView:self withEvent:event];
    }
}

- (id)fwViewData
{
    return objc_getAssociatedObject(self, @selector(fwViewData));
}

- (void)setFwViewData:(id)fwViewData
{
    // 仅当值发生改变才触发KVO，下同
    if (fwViewData != [self fwViewData]) {
        [self willChangeValueForKey:@"fwViewData"];
        objc_setAssociatedObject(self, @selector(fwViewData), fwViewData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwViewData"];
    }
}

- (void)fwRenderData
{
    // 子类重写
}

@end
