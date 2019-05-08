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

@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat topPosition;
@property (nonatomic, assign) CGFloat bottomPosition;
@property (nonatomic, assign) CGFloat kickbackHeight;

@property (nonatomic, copy) void (^callback)(CGFloat position);

@end

@implementation FWInnerDrawerViewTarget

- (void)panAction:(UIPanGestureRecognizer *)gestureRecognizer
{
    // 拖动开始时记录起始位置
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.position = self.view.frame.origin.y;
    }
    
    // 记录并清空相对父视图的移动距离
    CGPoint transition = [gestureRecognizer translationInView:self.view.superview];
    [gestureRecognizer setTranslation:CGPointZero inView:self.view.superview];
    
    // 视图跟随拖动移动指定距离，如果是滚动视图，还需计算contentOffset.y
    CGFloat targetY = self.view.frame.origin.y + transition.y;
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        targetY -= ((UIScrollView *)self.view).contentOffset.y;
    }
    if (targetY < self.topPosition) {
        targetY = self.topPosition;
    }
    self.view.frame = CGRectMake(self.view.frame.origin.x, targetY, self.view.frame.size.width, self.view.frame.size.height);
    
    // 执行位移回调
    if (self.callback) {
        self.callback(targetY);
    }
    
    // 拖动结束时停留指定位置
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat baselineY = (self.position == self.topPosition) ? (self.topPosition + self.kickbackHeight) : (self.bottomPosition - self.kickbackHeight);
        targetY = self.view.frame.origin.y < baselineY ? self.topPosition : self.bottomPosition;
        
        // 执行动画移动到指定位置，动画完成标记拖拽位置
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = CGRectMake(self.view.frame.origin.x, targetY, self.view.frame.size.width, self.view.frame.size.height);
        } completion:^(BOOL finished) {
            self.position = targetY;
            
            // 执行位移回调
            if (self.callback) {
                self.callback(targetY);
            }
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // 视图在顶部时允许同时识别滚动视图pan手势
    if ([self.view isKindOfClass:[UIScrollView class]] &&
        [otherGestureRecognizer isEqual:((UIScrollView *)self.view).panGestureRecognizer]) {
        if (self.position == self.topPosition) {
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
         topPosition:(CGFloat)topPosition
      bottomPosition:(CGFloat)bottomPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat))callback
{
    // 生成内部事件绑定target
    FWInnerDrawerViewTarget *target = [[FWInnerDrawerViewTarget alloc] init];
    target.view = view ?: self.view;
    target.position = target.view.frame.origin.y;
    target.topPosition = topPosition;
    target.bottomPosition = bottomPosition;
    target.kickbackHeight = kickbackHeight;
    target.callback = callback;
    
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
