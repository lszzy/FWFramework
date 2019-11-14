/*!
 @header     UIView+FWDrawerView.m
 @indexgroup FWFramework
 @brief      UIView+FWDrawerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/11/14
 */

#import "UIView+FWDrawerView.h"
#import <objc/runtime.h>

#pragma mark - FWDrawerView

@interface FWDrawerView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat originPosition;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation FWDrawerView

#pragma mark - Lifecycle

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        _direction = UISwipeGestureRecognizerDirectionUp;
        _kickbackHeight = 0;
        _autoDetected = YES;
        _position = self.isVertical ? view.frame.origin.y : view.frame.origin.x;
        _scrollView = [view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)view : nil;
        
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerAction:)];
        _gestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [view addGestureRecognizer:gestureRecognizer];
        view.fwDrawerView = self;
    }
    return self;
}

#pragma mark - Accessor

- (void)setPositions:(NSArray<NSNumber *> *)positions
{
    if (positions.count < 2) return;
    
    _positions = [positions sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }];
}

- (void)setScrollView:(UIScrollView *)scrollView
{
    if (scrollView != _scrollView) {
        _scrollView = scrollView;
    }
}

- (CGFloat)openPosition
{
    // 计算打开位置，正向拖动时终点位置，反向拖动时起始位置
    return self.isReverse ? self.positions.firstObject.doubleValue : self.positions.lastObject.doubleValue;
}

- (CGFloat)closePosition
{
    // 计算关闭位置，正向拖动时起始位置，反向拖动时终点位置
    return self.isReverse ? self.positions.lastObject.doubleValue : self.positions.firstObject.doubleValue;
}

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

- (CGFloat)nextPosition
{
    __block CGFloat position;
    // 根绝拖动方向和回弹高度计算停留位置
    if (self.position > self.originPosition) {
        [self.positions enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            CGFloat maxKickback = (obj.doubleValue == self.positions.lastObject.doubleValue) ? obj.doubleValue : obj.doubleValue + self.kickbackHeight;
            if (self.position <= maxKickback) {
                position = obj.doubleValue;
                *stop = YES;
            }
        }];
    } else {
        [self.positions enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
            CGFloat minKickback = (obj.doubleValue == self.positions.firstObject.doubleValue) ? obj.doubleValue : obj.doubleValue - self.kickbackHeight;
            if (self.position >= minKickback) {
                position = obj.doubleValue;
                *stop = YES;
            }
        }];
    }
    return position;
}

#pragma mark - Public

- (void)setPosition:(CGFloat)position animated:(BOOL)animated
{
    if (self.position == position) return;
    
    // 不执行动画
    if (!animated) {
        self.view.frame = CGRectMake(
                                     self.isVertical ? self.view.frame.origin.x : position,
                                     self.isVertical ? position : self.view.frame.origin.y,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
        self.position = position;
        if (self.callback) {
            self.callback(self.position, YES);
        }
        return;
    }
    
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

- (void)gestureRecognizerAction:(UIPanGestureRecognizer *)gestureRecognizer
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
            
            /*
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
            }*/
                
            // 移动时限制不超过范围
            if (self.position < self.positions.firstObject.doubleValue) {
                self.position = self.positions.firstObject.doubleValue;
            } else if (self.position > self.positions.lastObject.doubleValue) {
                self.position = self.positions.lastObject.doubleValue;
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
                CGFloat position = [self nextPosition];
                [self setPosition:position animated:YES];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (self.autoDetected) {
            self.scrollView = (UIScrollView *)otherGestureRecognizer.view;
            return YES;
        } else {
            if (self.scrollView && self.scrollView == otherGestureRecognizer.view) {
                return YES;
            }
        }
    }
    return NO;
}

@end

#pragma mark - UIView+FWDrawerView

@implementation UIView (FWDrawerView)

- (FWDrawerView *)fwDrawerView
{
    return objc_getAssociatedObject(self, @selector(fwDrawerView));
}

- (void)setFwDrawerView:(FWDrawerView *)fwDrawerView
{
    objc_setAssociatedObject(self, @selector(fwDrawerView), fwDrawerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWDrawerView *)fwDrawerView:(UISwipeGestureRecognizerDirection)direction
                     positions:(NSArray<NSNumber *> *)positions
                kickbackHeight:(CGFloat)kickbackHeight
                      callback:(void (^)(CGFloat, BOOL))callback
{
    FWDrawerView *drawerView = [[FWDrawerView alloc] initWithView:self];
    if (direction > 0) drawerView.direction = direction;
    drawerView.positions = positions;
    drawerView.kickbackHeight = kickbackHeight;
    drawerView.callback = callback;
    return drawerView;
}

@end

#pragma mark - UIScrollView+FWDrawerView

@implementation UIScrollView (FWDrawerView)

- (BOOL)fwDrawerSuperviewFixed
{
    return [objc_getAssociatedObject(self, @selector(fwDrawerSuperviewFixed)) boolValue];
}

- (void)setFwDrawerSuperviewFixed:(BOOL)fixed
{
    objc_setAssociatedObject(self, @selector(fwDrawerSuperviewFixed), @(fixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwDrawerSuperviewDidScroll:(CGFloat)position
{
    if (self.contentOffset.y >= position) {
        self.fwDrawerSuperviewFixed = YES;
    }
    if (self.fwDrawerSuperviewFixed) {
        self.contentOffset = CGPointMake(self.contentOffset.x, position);
    }
}

- (void)fwDrawerSubviewDidScroll:(UIScrollView *)superview
{
    if (self.contentOffset.y <= 0) {
        superview.fwDrawerSuperviewFixed = NO;
    }
    if (!superview.fwDrawerSuperviewFixed) {
        self.contentOffset = CGPointMake(self.contentOffset.x, 0);
    }
}

@end
