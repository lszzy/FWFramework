/*!
 @header     UIView+FWDrawerView.m
 @indexgroup FWFramework
 @brief      UIView+FWDrawerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/11/14
 */

#import "UIView+FWDrawerView.h"
#import "UIScrollView+FWFramework.h"
#import <objc/runtime.h>

#pragma mark - FWDrawerView

@interface FWDrawerView () <UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat position;
@property (nonatomic, assign) CGFloat originPosition;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL panDisabled;

@end

@implementation FWDrawerView

#pragma mark - Lifecycle

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        _autoDetected = YES;
        _kickbackHeight = 0;
        _direction = UISwipeGestureRecognizerDirectionUp;
        _position = self.isVertical ? view.frame.origin.y : view.frame.origin.x;
        if ([view isKindOfClass:[UIScrollView class]]) {
            self.scrollView = (UIScrollView *)view;
        }
        
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerAction:)];
        _gestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [view addGestureRecognizer:gestureRecognizer];
        view.fwDrawerView = self;
    }
    return self;
}

#pragma mark - Accessor

- (void)setDirection:(UISwipeGestureRecognizerDirection)direction
{
    _direction = direction;
    _position = self.isVertical ? self.view.frame.origin.y : self.view.frame.origin.x;
}

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
        if (_scrollView && _scrollView.delegate == self) {
            _scrollView.delegate = nil;
        }
        _scrollView = scrollView;
        if (scrollView && !scrollView.delegate) {
            scrollView.delegate = self;
        }
    }
}

- (BOOL)enabled
{
    return self.gestureRecognizer.enabled;
}

- (void)setEnabled:(BOOL)enabled
{
    self.gestureRecognizer.enabled = enabled;
}

- (CGFloat)openPosition
{
    return self.isReverse ? self.positions.firstObject.doubleValue : self.positions.lastObject.doubleValue;
}

- (CGFloat)closePosition
{
    return self.isReverse ? self.positions.lastObject.doubleValue : self.positions.firstObject.doubleValue;
}

#pragma mark - Private

- (BOOL)isVertical
{
    return self.direction == UISwipeGestureRecognizerDirectionUp || self.direction == UISwipeGestureRecognizerDirectionDown;
}

- (BOOL)isReverse
{
    return self.direction == UISwipeGestureRecognizerDirectionUp || self.direction == UISwipeGestureRecognizerDirectionLeft;
}

- (UIRectEdge)scrollEdge
{
    switch (self.direction) {
        case UISwipeGestureRecognizerDirectionUp:
            return UIRectEdgeTop;
        case UISwipeGestureRecognizerDirectionDown:
            return UIRectEdgeBottom;
        case UISwipeGestureRecognizerDirectionLeft:
            return UIRectEdgeLeft;
        case UISwipeGestureRecognizerDirectionRight:
            return UIRectEdgeRight;
        default:
            return UIRectEdgeNone;
    }
}

- (CGFloat)nextPosition
{
    __block CGFloat position;
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

- (BOOL)canScroll:(UIScrollView *)scrollView
{
    if (!scrollView.scrollEnabled) return NO;
    if (self.isVertical) {
        if (![scrollView fwCanScrollVertical]) return NO;
    } else {
        if (![scrollView fwCanScrollHorizontal]) return NO;
    }
    return YES;
}

- (void)togglePosition:(CGFloat)position
{
    self.view.frame = CGRectMake(
                                 self.isVertical ? self.view.frame.origin.x : position,
                                 self.isVertical ? position : self.view.frame.origin.y,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
}

- (void)notifyPosition:(BOOL)finished
{
    if (finished) {
        [self gestureRecognizerDidScroll];
    }
    
    if (self.callback) {
        self.callback(self.position, finished);
    }
}

#pragma mark - Public

- (void)setPosition:(CGFloat)position animated:(BOOL)animated
{
    if (self.position == position) return;
    
    // 不执行动画
    if (!animated) {
        [self togglePosition:position];
        self.position = position;
        [self notifyPosition:YES];
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
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self togglePosition:position];
    } completion:^(BOOL finished) {
        // 动画完成时需释放displayLink
        if (self.displayLink) {
            [self.displayLink invalidate];
            self.displayLink = nil;
        }
        
        self.position = position;
        [self notifyPosition:YES];
    }];
}

- (void)displayLinkAction
{
    // 监听动画过程中的位置，访问view.layer.presentationLayer即可
    self.position = self.isVertical ? self.view.layer.presentationLayer.frame.origin.y : self.view.layer.presentationLayer.frame.origin.x;
    [self notifyPosition:NO];
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
                
            // 视图跟随拖动移动指定距离，且移动时限制不超过范围
            CGFloat position = self.isVertical ? (self.view.frame.origin.y + transition.y) : (self.view.frame.origin.x + transition.x);
            if (position < self.positions.firstObject.doubleValue) {
                position = self.positions.firstObject.doubleValue;
            } else if (position > self.positions.lastObject.doubleValue) {
                position = self.positions.lastObject.doubleValue;
            }
                
            // 执行位移并回调
            [self togglePosition:position];
            self.position = position;
            [self gestureRecognizerDidScroll];
            [self notifyPosition:NO];
            break;
        }
        // 拖动结束时停留指定位置
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            // 停留位置未发生改变时不执行动画，直接回调
            if (self.position == self.originPosition) {
                [self notifyPosition:YES];
            // 停留位置发生改变时执行动画，动画完成后回调
            } else {
                [self setPosition:self.nextPosition animated:YES];
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.scrollView || !self.gestureRecognizer.enabled) return;
    if (![self canScroll:self.scrollView]) return;
    
    if ([self.scrollView fwIsScrollToEdge:self.scrollEdge]) {
        self.panDisabled = NO;
    }
    if (!self.panDisabled) {
        [self.scrollView fwScrollToEdge:self.scrollEdge animated:NO];
    }
}

- (void)gestureRecognizerDidScroll
{
    if (!self.scrollView || !self.gestureRecognizer.enabled) return;
    if (![self canScroll:self.scrollView]) return;
    
    if (self.position == self.openPosition) {
        self.panDisabled = YES;
    }
    if (self.panDisabled) {
        [self setPosition:self.openPosition animated:NO];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (self.autoDetected) {
            UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
            if ([self canScroll:scrollView]) {
                self.scrollView = scrollView;
                return YES;
            }
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
