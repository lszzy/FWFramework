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

@interface FWInnerDrawerViewTarget : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *view;
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;
@property (nonatomic, assign) CGFloat fromPosition;
@property (nonatomic, assign) CGFloat toPosition;
@property (nonatomic, assign) CGFloat kickbackHeight;
@property (nonatomic, copy) void (^callback)(CGFloat position);

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL vertical;
@property (nonatomic, assign) CGFloat position;

@end

@implementation FWInnerDrawerViewTarget

- (void)panAction:(UIPanGestureRecognizer *)gestureRecognizer
{
    // 拖动开始时记录起始位置
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.position = self.vertical ? self.view.frame.origin.y : self.view.frame.origin.x;
    }
    
    // 记录并清空相对父视图的移动距离
    CGPoint transition = [gestureRecognizer translationInView:self.view.superview];
    [gestureRecognizer setTranslation:CGPointZero inView:self.view.superview];
    
    // 视图跟随拖动移动指定距离，如果是滚动视图且可滚动，还需计算contentOffset和contentInset
    CGFloat target;
    switch (self.direction) {
        case UISwipeGestureRecognizerDirectionLeft: {
            target = self.view.frame.origin.x + transition.x;
            if (self.scrollView && (self.scrollView.contentSize.width + self.scrollView.contentInset.left + self.scrollView.contentInset.right > self.scrollView.frame.size.width)) {
                target -= (self.scrollView.contentOffset.x + self.scrollView.contentInset.left);
            }
            if (target < self.fromPosition) {
                target = self.fromPosition;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionRight: {
            target = self.view.frame.origin.x + transition.x;
            if (self.scrollView && (self.scrollView.contentSize.width + self.scrollView.contentInset.left + self.scrollView.contentInset.right > self.scrollView.frame.size.width)) {
                target += (self.scrollView.contentSize.width - self.scrollView.frame.size.width - self.scrollView.contentOffset.x + self.scrollView.contentInset.right);
            }
            if (target > self.toPosition) {
                target = self.toPosition;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionDown: {
            target = self.view.frame.origin.y + transition.y;
            if (self.scrollView && (self.scrollView.contentSize.height + self.scrollView.contentInset.top + self.scrollView.contentInset.bottom > self.scrollView.frame.size.height)) {
                target += (self.scrollView.contentSize.height - self.scrollView.frame.size.height - self.scrollView.contentOffset.y + self.scrollView.contentInset.bottom);
            }
            if (target > self.toPosition) {
                target = self.toPosition;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionUp:
        default: {
            target = self.view.frame.origin.y + transition.y;
            if (self.scrollView && (self.scrollView.contentSize.height + self.scrollView.contentInset.top + self.scrollView.contentInset.bottom > self.scrollView.frame.size.height)) {
                target -= (self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
            }
            if (target < self.fromPosition) {
                target = self.fromPosition;
            }
            break;
        }
    }
    
    // 执行位移并回调
    self.view.frame = CGRectMake(self.vertical ? self.view.frame.origin.x : target,
                                 self.vertical ? target : self.view.frame.origin.y,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    if (self.callback) {
        self.callback(target);
    }
    
    // 拖动结束时停留指定位置
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        switch (self.direction) {
            case UISwipeGestureRecognizerDirectionLeft: {
                CGFloat baseline = (self.position == self.fromPosition) ? (self.fromPosition + self.kickbackHeight) : (self.toPosition - self.kickbackHeight);
                target = self.view.frame.origin.x < baseline ? self.fromPosition : self.toPosition;
                break;
            }
            case UISwipeGestureRecognizerDirectionRight: {
                CGFloat baseline = (self.position == self.fromPosition) ? (self.fromPosition + self.kickbackHeight) : (self.toPosition - self.kickbackHeight);
                target = self.view.frame.origin.x < baseline ? self.fromPosition : self.toPosition;
                break;
            }
            case UISwipeGestureRecognizerDirectionDown: {
                CGFloat baseline = (self.position == self.fromPosition) ? (self.fromPosition + self.kickbackHeight) : (self.toPosition - self.kickbackHeight);
                target = self.view.frame.origin.y < baseline ? self.fromPosition : self.toPosition;
                break;
            }
            case UISwipeGestureRecognizerDirectionUp:
            default: {
                CGFloat baseline = (self.position == self.fromPosition) ? (self.fromPosition + self.kickbackHeight) : (self.toPosition - self.kickbackHeight);
                target = self.view.frame.origin.y < baseline ? self.fromPosition : self.toPosition;
                break;
            }
        }
        
        // 执行动画移动到指定位置，动画完成标记拖拽位置并回调
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = CGRectMake(
                                         self.vertical ? self.view.frame.origin.x : target,
                                         self.vertical ? target : self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height);
        } completion:^(BOOL finished) {
            self.position = target;
            if (self.callback) {
                self.callback(target);
            }
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // 视图在终点时允许同时识别滚动视图pan手势
    if ([otherGestureRecognizer isEqual:self.scrollView.panGestureRecognizer]) {
        CGFloat targetPosition;
        if (self.direction == UISwipeGestureRecognizerDirectionLeft || self.direction == UISwipeGestureRecognizerDirectionUp) {
            targetPosition = self.fromPosition;
        } else {
            targetPosition = self.toPosition;
        }
        if (self.position == targetPosition) {
            return YES;
        }
    }
    return NO;
}

@end

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
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat))callback
{
    // 生成内部事件绑定target
    FWInnerDrawerViewTarget *target = [[FWInnerDrawerViewTarget alloc] init];
    target.view = view ?: self.view;
    target.direction = direction;
    target.fromPosition = fromPosition;
    target.toPosition = toPosition;
    target.kickbackHeight = kickbackHeight;
    target.callback = callback;
    target.scrollView = [target.view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)target.view : nil;
    target.vertical = (direction == UISwipeGestureRecognizerDirectionUp || direction == UISwipeGestureRecognizerDirectionDown);
    target.position = target.vertical ? target.view.frame.origin.y : target.view.frame.origin.x;
    
    // 强引用target并添加事件绑定
    NSMutableArray *targets = objc_getAssociatedObject(self, _cmd);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, _cmd, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [targets addObject:target];
    [self addTarget:target action:@selector(panAction:)];
    
    // view为滚动视图时自动设置手势delegate处理内部滚动
    if ([target.view isKindOfClass:[UIScrollView class]] && !self.delegate) {
        self.delegate = target;
    }
}

@end
