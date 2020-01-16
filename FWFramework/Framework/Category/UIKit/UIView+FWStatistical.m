/*!
 @header     UIView+FWStatistical.m
 @indexgroup FWFramework
 @brief      UIView+FWStatistical
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/1/16
 */

#import "UIView+FWStatistical.h"
#import "UIView+FWBlock.h"

@implementation UIView (FWStatistical)

#pragma mark - Click

- (void)fwTrackTappedWithBlock:(void (^)(id))block
{
    [self fwTrackGesture:[UITapGestureRecognizer class] withBlock:block];
}

- (void)fwTrackGesture:(Class)clazz withBlock:(void (^)(id))block
{
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:clazz]) {
            [gesture fwAddBlock:block];
        }
    }
}

@end

@implementation UIControl (FWStatistical)

#pragma mark - Click

- (void)fwTrackTouchedWithBlock:(void (^)(id))block
{
    [self fwTrackEvent:UIControlEventTouchUpInside withBlock:block];
}

- (void)fwTrackChangedWithBlock:(void (^)(id))block
{
    [self fwTrackEvent:UIControlEventValueChanged withBlock:block];
}

- (void)fwTrackEvent:(UIControlEvents)event withBlock:(void (^)(id))block
{
    [self fwAddBlock:block forControlEvents:event];
}

@end

@implementation UITableView (FWStatistical)

#pragma mark - Click

- (void)fwTrackSelectWithBlock:(void (^)(UITableView *, NSIndexPath *))block
{
    
}

@end
