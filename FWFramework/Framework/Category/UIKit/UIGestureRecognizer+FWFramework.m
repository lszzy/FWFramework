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

- (void)fwDrawerView:(UIView *)view
         topPosition:(CGFloat)topPosition
      bottomPosition:(CGFloat)bottomPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat))callback
{
    // 默认self.view
    if (!view) {
        view = self.view;
    }
    
    // 拖动开始时记录起始位置
    if (self.state == UIGestureRecognizerStateBegan) {
        objc_setAssociatedObject(view, @selector(fwPositionWithDrawerView:), @(view.frame.origin.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // 记录并清空相对父视图的移动距离
    CGPoint transition = [self translationInView:view.superview];
    [self setTranslation:CGPointZero inView:view.superview];
    
    // 视图跟随拖动移动指定距离，如果是滚动视图，还需计算contentOffset.y
    CGFloat targetY = view.frame.origin.y + transition.y;
    if ([view isKindOfClass:[UIScrollView class]]) {
        targetY -= ((UIScrollView *)view).contentOffset.y;
    }
    if (targetY < topPosition) {
        targetY = topPosition;
    }
    view.frame = CGRectMake(view.frame.origin.x, targetY, view.frame.size.width, view.frame.size.height);
    
    // 执行位移回调
    if (callback) {
        callback(targetY);
    }
    
    // 拖动结束时停留指定位置
    if (self.state == UIGestureRecognizerStateEnded) {
        CGFloat baselineY = ([self fwPositionWithDrawerView:view] == topPosition) ? (topPosition + kickbackHeight) : (bottomPosition - kickbackHeight);
        targetY = view.frame.origin.y < baselineY ? topPosition : bottomPosition;
        
        // 执行动画移动到指定位置，动画完成标记拖拽位置
        [UIView animateWithDuration:0.2 animations:^{
            view.frame = CGRectMake(view.frame.origin.x, targetY, view.frame.size.width, view.frame.size.height);
        } completion:^(BOOL finished) {
            objc_setAssociatedObject(view, @selector(fwPositionWithDrawerView:), @(targetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            // 执行位移回调
            if (callback) {
                callback(targetY);
            }
        }];
    }
}

- (CGFloat)fwPositionWithDrawerView:(UIView *)view
{
    // 默认self.view
    if (!view) {
        view = self.view;
    }
    
    // 获取抽屉视图拖拽的位置，没有则初始化
    NSNumber *position = objc_getAssociatedObject(view, @selector(fwPositionWithDrawerView:));
    if (!position) {
        position = @(view.frame.origin.y);
        objc_setAssociatedObject(view, @selector(fwPositionWithDrawerView:), position, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return [position doubleValue];
}

@end
