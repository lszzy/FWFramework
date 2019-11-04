/*!
 @header     UIGestureRecognizer+FWFramework.m
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import "UIGestureRecognizer+FWFramework.h"

@implementation UIGestureRecognizer (FWFramework)

- (BOOL)fwIsTracking
{
    return self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged;
}

- (BOOL)fwIsActive
{
    return self.isEnabled && (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged);
}

@end

@implementation UIPanGestureRecognizer (FWFramework)

- (UISwipeGestureRecognizerDirection)fwSwipeDirection
{
    CGPoint transition = [self translationInView:self.view];
    if (fabs(transition.x) > fabs(transition.y)) {
        if (transition.x < 0.0f) {
            return UISwipeGestureRecognizerDirectionLeft;
        } else if (transition.x > 0.0f) {
            return UISwipeGestureRecognizerDirectionRight;
        }
    } else {
        if (transition.y > 0.0f) {
            return UISwipeGestureRecognizerDirectionDown;
        } else if (transition.y < 0.0f) {
            return UISwipeGestureRecognizerDirectionUp;
        }
    }
    return 0;
}

- (CGFloat)fwSwipePercent
{
    CGPoint transition = [self translationInView:self.view];
    if (fabs(transition.x) > fabs(transition.y)) {
        return self.view.bounds.size.width > 0 ? fabs(transition.x) / self.view.bounds.size.width : 0;
    } else {
        return self.view.bounds.size.height > 0 ? fabs(transition.y) / self.view.bounds.size.height : 0;
    }
}

@end
