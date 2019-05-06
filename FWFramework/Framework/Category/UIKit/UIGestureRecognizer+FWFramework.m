/*!
 @header     UIGestureRecognizer+FWFramework.m
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import "UIGestureRecognizer+FWFramework.h"
#import <objc/runtime.h>

@implementation UIPanGestureRecognizer (FWFramework)

- (UISwipeGestureRecognizerDirection)fwSwipeDirection
{
    if ([self translationInView:self.view.superview].y > 0.0f) {
        return UISwipeGestureRecognizerDirectionUp;
    } else if ([self translationInView:self.view.superview].y < 0.0f) {
        return UISwipeGestureRecognizerDirectionDown;
    } else if ([self translationInView:self.view].x < 0.0f) {
        return UISwipeGestureRecognizerDirectionLeft;
    } else if ([self translationInView:self.view].x > 0.0f) {
        return UISwipeGestureRecognizerDirectionRight;
    }
    return 0;
}

- (CGFloat)fwDrawerView:(UIView *)view
           fromPosition:(CGFloat)fromPosition
             toPosition:(CGFloat)toPosition
         kickbackHeight:(CGFloat)kickbackHeight
{
    // 默认self.view
    if (!view) {
        view = self.view;
    }
    
    // 拖动开始时记录起始位置
    if (self.state == UIGestureRecognizerStateBegan) {
        objc_setAssociatedObject(self, _cmd, @(view.frame.origin.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // 记录并清空相对父视图的移动距离
    CGPoint transition = [self translationInView:view.superview];
    [self setTranslation:CGPointZero inView:view.superview];
    
    // 视图跟随拖动移动指定距离
    CGFloat targetY = view.frame.origin.y + transition.y;
    if (targetY < fromPosition) {
        targetY = fromPosition;
    }
    view.frame = CGRectMake(view.frame.origin.x, targetY, view.frame.size.width, view.frame.size.height);
    
    // 拖动结束时停留指定位置
    if (self.state == UIGestureRecognizerStateEnded) {
        CGFloat beganY = [objc_getAssociatedObject(self, _cmd) doubleValue];
        CGFloat baselineY = (beganY == fromPosition) ? (fromPosition + kickbackHeight) : (toPosition - kickbackHeight);
        targetY = view.frame.origin.y < baselineY ? fromPosition : toPosition;
        
        // 执行动画移动到指定位置
        [UIView animateWithDuration:0.2 animations:^{
            view.frame = CGRectMake(view.frame.origin.x, targetY, view.frame.size.width, view.frame.size.height);
        } completion:nil];
    }
    return targetY;
}

@end
