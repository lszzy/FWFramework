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

#pragma mark - UIGestureRecognizer+FWFramework

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

#pragma mark - FWInnerDrawerViewTarget

@interface FWInnerDrawerViewTarget : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak, readonly) UIView *view;
@property (nonatomic, assign, readonly) UISwipeGestureRecognizerDirection direction;
@property (nonatomic, assign, readonly) CGFloat fromPosition;
@property (nonatomic, assign, readonly) CGFloat toPosition;
@property (nonatomic, assign, readonly) CGFloat kickbackHeight;
@property (nonatomic, copy, readonly) void (^callback)(CGFloat position, BOOL finished);

@property (nonatomic, weak, readonly) UIScrollView *scrollView;
@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat originPosition;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation FWInnerDrawerViewTarget

#pragma mark - Lifecycle

- (instancetype)initWithView:(UIView *)view
                   direction:(UISwipeGestureRecognizerDirection)direction
                fromPosition:(CGFloat)fromPosition
                  toPosition:(CGFloat)toPosition
              kickbackHeight:(CGFloat)kickbackHeight
                    callback:(void (^)(CGFloat, BOOL))callback
{
    self = [super init];
    if (self) {
        _view = view;
        _direction = direction;
        _fromPosition = fromPosition;
        _toPosition = toPosition;
        _kickbackHeight = kickbackHeight;
        _callback = callback;
        
        _scrollView = [view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)view : nil;
        _position = self.isVertical ? view.frame.origin.y : view.frame.origin.x;
    }
    return self;
}

#pragma mark - Accessor

- (BOOL)isVertical
{
    // 是否纵向拖动，Up|Down时纵向，Right|Left时横向
    return self.direction == UISwipeGestureRecognizerDirectionUp || self.direction == UISwipeGestureRecognizerDirectionDown;
}

- (BOOL)isReverse
{
    // 是否反向拖动，Down|Right时正向，Up|Left时反向
    return self.direction == UISwipeGestureRecognizerDirectionUp || self.direction == UISwipeGestureRecognizerDirectionLeft;
}

- (CGFloat)openPosition
{
    // 计算打开位置，正向拖动时toPosition，反向拖动时fromPosition
    return self.isReverse ? self.fromPosition : self.toPosition;
}

#pragma mark - Public

- (void)panAction:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        // 拖动开始时记录起始位置
        case UIGestureRecognizerStateBegan: {
            self.position = self.isVertical ? self.view.frame.origin.y : self.view.frame.origin.x;
            self.originPosition = self.position;
            break;
        }
        // 拖动改变时更新视图位置
        case UIGestureRecognizerStateChanged: {
            // 记录并清空相对父视图的移动距离
            CGPoint transition = [gestureRecognizer translationInView:self.view.superview];
            [gestureRecognizer setTranslation:CGPointZero inView:self.view.superview];
                
            // 视图跟随拖动移动指定距离
            self.position = self.isVertical ? (self.view.frame.origin.y + transition.y) : (self.view.frame.origin.x + transition.x);
            
            // 如果是滚动视图，还需计算contentOffset
            if (self.scrollView) {
                // 计算滚动视图的contentOffset(包含contentInset)
                CGFloat contentOffset = 0;
                switch (self.direction) {
                    case UISwipeGestureRecognizerDirectionUp:
                        contentOffset = self.scrollView.contentOffset.y + self.scrollView.contentInset.top;
                        break;
                    case UISwipeGestureRecognizerDirectionDown:
                        contentOffset = self.scrollView.contentSize.height - self.scrollView.frame.size.height - self.scrollView.contentOffset.y + self.scrollView.contentInset.bottom;
                        break;
                    case UISwipeGestureRecognizerDirectionLeft:
                        contentOffset = self.scrollView.contentOffset.x + self.scrollView.contentInset.left;
                        break;
                    case UISwipeGestureRecognizerDirectionRight:
                        contentOffset = self.scrollView.contentSize.width - self.scrollView.frame.size.width - self.scrollView.contentOffset.x + self.scrollView.contentInset.right;
                        break;
                    default:
                        break;
                }
                
                // 只处理contentOffset大于0的情况
                if (contentOffset > 0) {
                    self.position = self.isReverse ? (self.position - contentOffset) : (self.position + contentOffset);
                }
            }
                
            // 移动时限制不超过范围
            if (self.position < self.fromPosition) {
                self.position = self.fromPosition;
            } else if (self.position > self.toPosition) {
                self.position = self.toPosition;
            }
                
            // 执行位移并回调
            self.view.frame = CGRectMake(self.isVertical ? self.view.frame.origin.x : self.position,
                                         self.isVertical ? self.position : self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height);
            if (self.callback) {
                self.callback(self.position, NO);
            }
            break;
        }
        // 拖动结束时停留指定位置
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            // 停留位置未发生改变时不执行动画，直接回调
            if (self.position == self.originPosition) {
                if (self.callback) {
                    self.callback(self.position, YES);
                }
            // 停留位置发生改变时执行动画，动画完成后回调
            } else {
                CGFloat baseline = (self.originPosition == self.fromPosition) ? (self.fromPosition + self.kickbackHeight) : (self.toPosition - self.kickbackHeight);
                CGFloat position = (self.position < baseline) ? self.fromPosition : self.toPosition;
                [self togglePosition:position];
            }
            break;
        }
        default:
            break;
    }
}

- (void)togglePosition:(CGFloat)position
{
    // 使用CADisplayLink监听动画过程中的位置
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    // 执行动画移动到指定位置，动画完成标记拖拽位置并回调
    [UIView animateWithDuration:0.2 animations:^{
        self.view.frame = CGRectMake(
                                     self.isVertical ? self.view.frame.origin.x : position,
                                     self.isVertical ? position : self.view.frame.origin.y,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
    } completion:^(BOOL finished) {
        // 动画完成时需释放displayLink
        if (self.displayLink) {
            [self.displayLink invalidate];
            self.displayLink = nil;
        }
        
        self.position = position;
        if (self.callback) {
            self.callback(self.position, YES);
        }
    }];
}

- (void)displayLinkAction
{
    // 监听动画过程中的位置，访问view.layer.presentationLayer即可
    self.position = self.isVertical ? self.view.layer.presentationLayer.frame.origin.y : self.view.layer.presentationLayer.frame.origin.x;
    if (self.callback) {
        self.callback(self.position, NO);
    }
}

#pragma mark - UIGestureRecognizerDelegate

// 视图在打开位置时允许同时识别滚动视图pan手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer == self.scrollView.panGestureRecognizer) {
        if (self.position == self.openPosition) {
            return YES;
        }
    }
    return NO;
}

// 视图不在打开位置时不允许识别滚动视图pan手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (otherGestureRecognizer == self.scrollView.panGestureRecognizer) {
        if (self.position != self.openPosition) {
            return YES;
        }
    }
    return NO;
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

- (void)fwDrawerView:(UIView *)view
           direction:(UISwipeGestureRecognizerDirection)direction
        fromPosition:(CGFloat)fromPosition
          toPosition:(CGFloat)toPosition
      kickbackHeight:(CGFloat)kickbackHeight
            callback:(void (^)(CGFloat, BOOL))callback
{
    // 生成内部强引用target，并添加事件绑定
    FWInnerDrawerViewTarget *target = [[FWInnerDrawerViewTarget alloc] initWithView:(view ?: self.view) direction:direction fromPosition:fromPosition toPosition:toPosition kickbackHeight:kickbackHeight callback:callback];
    objc_setAssociatedObject(self, @selector(fwDrawerView:direction:fromPosition:toPosition:kickbackHeight:callback:), target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addTarget:target action:@selector(panAction:)];
    
    // view为滚动视图时自动设置手势delegate处理内部滚动
    if (target.scrollView && !self.delegate) {
        self.delegate = target;
    }
}

- (BOOL)fwDrawerViewIsOpen
{
    FWInnerDrawerViewTarget *target = objc_getAssociatedObject(self, @selector(fwDrawerView:direction:fromPosition:toPosition:kickbackHeight:callback:));
    if (!target) {
        return NO;
    }
    
    return target.position == target.openPosition;
}

- (void)fwDrawerViewToggleOpen:(BOOL)open
{
    FWInnerDrawerViewTarget *target = objc_getAssociatedObject(self, @selector(fwDrawerView:direction:fromPosition:toPosition:kickbackHeight:callback:));
    if (!target) {
        return;
    }
    
    CGFloat position = open ? target.openPosition : (target.isReverse ? target.toPosition : target.fromPosition);
    if (target.position != position) {
        [target togglePosition:position];
    }
}

@end
