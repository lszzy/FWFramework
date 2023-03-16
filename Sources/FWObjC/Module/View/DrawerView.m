//
//  DrawerView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "DrawerView.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

@property (nonatomic, strong, nullable) __FWDrawerView *__fw_drawerView;

@end

@interface UIScrollView ()

@property (nonatomic, assign, readonly) BOOL __fw_canScrollVertical;
@property (nonatomic, assign, readonly) BOOL __fw_canScrollHorizontal;
- (BOOL)__fw_isScrollTo:(UIRectEdge)edge;
- (void)__fw_scrollTo:(UIRectEdge)edge animated:(BOOL)animated;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWDrawerView

@interface __FWDrawerView () <UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat position;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL panDisabled;
@property (nonatomic, assign) CGFloat originPosition;
@property (nonatomic, assign) CGPoint originOffset;
@property (nonatomic, assign) BOOL isOriginDraggable;
@property (nonatomic, assign) BOOL isOriginScrollable;
@property (nonatomic, assign) BOOL isOriginScrollView;
@property (nonatomic, assign) BOOL isOriginDirection;

@end

@implementation __FWDrawerView

#pragma mark - Lifecycle

- (instancetype)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        _autoDetected = YES;
        _kickbackHeight = 0;
        _positions = @[];
        _direction = UISwipeGestureRecognizerDirectionUp;
        _position = self.isVertical ? view.frame.origin.y : view.frame.origin.x;
        if ([view isKindOfClass:[UIScrollView class]]) {
            self.scrollView = (UIScrollView *)view;
        }
        
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerAction:)];
        _gestureRecognizer = gestureRecognizer;
        gestureRecognizer.delegate = self;
        [view addGestureRecognizer:gestureRecognizer];
        view.__fw_drawerView = self;
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

- (CGFloat)middlePosition
{
    return [self positionAtIndex:self.positions.count / 2];
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

- (BOOL)isDirection:(UIPanGestureRecognizer *)gestureRecognizer
{
    UISwipeGestureRecognizerDirection direction = gestureRecognizer.__fw_swipeDirection;
    switch (self.direction) {
        case UISwipeGestureRecognizerDirectionUp:
            return direction == UISwipeGestureRecognizerDirectionDown;
        case UISwipeGestureRecognizerDirectionDown:
            return direction == UISwipeGestureRecognizerDirectionUp;
        case UISwipeGestureRecognizerDirectionLeft:
            return direction == UISwipeGestureRecognizerDirectionRight;
        case UISwipeGestureRecognizerDirectionRight:
            return direction == UISwipeGestureRecognizerDirectionLeft;
        default:
            return NO;
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
    if (self.scrollViewFilter) return self.scrollViewFilter(scrollView);
    if (!scrollView.__fw_isViewVisible || !scrollView.scrollEnabled) return NO;
    if (self.isVertical) {
        if (![scrollView __fw_canScrollVertical]) return NO;
    } else {
        if (![scrollView __fw_canScrollHorizontal]) return NO;
    }
    return YES;
}

- (void)togglePosition:(CGFloat)position
{
    self.view.frame = CGRectMake(
        self.isVertical ? self.view.frame.origin.x : position,
        self.isVertical ? position : self.view.frame.origin.y,
        self.view.frame.size.width,
        self.view.frame.size.height
    );
}

- (void)notifyPosition:(BOOL)finished
{
    [self adjustScrollInset];
    
    if (self.positionChanged) {
        self.positionChanged(self.position, finished);
    }
    if ([self.delegate respondsToSelector:@selector(drawerView:positionChanged:finished:)]) {
        [self.delegate drawerView:self positionChanged:self.position finished:finished];
    }
}

- (void)adjustScrollInset
{
    NSArray *insets = self.scrollViewInsets && self.scrollView ? self.scrollViewInsets(self.scrollView) : nil;
    if (insets.count > 0 && insets.count == self.positions.count) {
        [self.positions enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSNumber *next = idx < (self.positions.count - 1) ? self.positions[idx + 1] : nil;
            if ((next && self.position < next.doubleValue) || !next) {
                UIEdgeInsets inset = [insets[idx] UIEdgeInsetsValue];
                if (!UIEdgeInsetsEqualToEdgeInsets(self.scrollView.contentInset, inset)) {
                    self.scrollView.contentInset = inset;
                }
                *stop = YES;
            }
        }];
    }
}

- (void)animateComplete:(CGFloat)position
{
    // 动画完成时需释放displayLink
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    [self togglePosition:position];
    self.position = position;
    [self notifyPosition:YES];
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
    if (self.animationBlock) {
        __weak __typeof__(self) self_weak_ = self;
        self.animationBlock(^{
            __typeof__(self) self = self_weak_;
            [self togglePosition:position];
        }, ^(BOOL finished) {
            __typeof__(self) self = self_weak_;
            [self animateComplete:position];
        });
    } else {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            [self togglePosition:position];
        } completion:^(BOOL finished) {
            [self animateComplete:position];
        }];
    }
}

- (CGFloat)positionAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.positions.count) return 0;
    return [self.positions[index] doubleValue];
}

- (BOOL)isPositionIndex:(NSInteger)index
{
    if (index < 0 || index >= self.positions.count) return NO;
    return self.position == [self.positions[index] doubleValue];
}

- (void)setPositionIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0 || index >= self.positions.count) return;
    [self setPosition:[self.positions[index] doubleValue] animated:animated];
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
        // 拖动开始时记录起始位置信息
        case UIGestureRecognizerStateBegan: {
            self.position = self.isVertical ? self.view.frame.origin.y : self.view.frame.origin.x;
            self.originPosition = self.position;
            
            self.isOriginScrollView = [gestureRecognizer __fw_hitTestWithView:self.scrollView];
            self.isOriginDirection = [self isDirection:gestureRecognizer] || [self isDirection:self.scrollView.panGestureRecognizer];
            self.originOffset = self.scrollView.contentOffset;
            self.isOriginDraggable = self.isOriginDirection && [self.scrollView __fw_isScrollTo:self.scrollEdge];
            NSArray *positions = self.scrollViewPositions && self.scrollView ? self.scrollViewPositions(self.scrollView) : nil;
            self.isOriginScrollable = self.originPosition == self.openPosition || [positions containsObject:@(self.originPosition)];
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
    if (scrollView != self.scrollView || !self.gestureRecognizer.__fw_isActive) return;
    if (![self canScroll:self.scrollView]) return;
    
    NSArray *positions = self.scrollViewPositions ? self.scrollViewPositions(self.scrollView) : nil;
    if (positions.count > 0) {
        self.panDisabled = NO;
        if (self.isOriginScrollable) {
            if (self.isOriginDraggable) {
                [self.scrollView __fw_scrollTo:self.scrollEdge animated:NO];
            } else {
                [self togglePosition:self.originPosition];
                self.position = self.originPosition;
            }
        } else {
            self.scrollView.contentOffset = self.originOffset;
        }
        return;
    }
    
    if ([self.scrollView __fw_isScrollTo:self.scrollEdge]) {
        self.panDisabled = NO;
    }
    if (!self.panDisabled) {
        [self.scrollView __fw_scrollTo:self.scrollEdge animated:NO];
    }
}

- (void)gestureRecognizerDidScroll
{
    if (!self.scrollView || !self.gestureRecognizer.enabled) return;
    if (![self canScroll:self.scrollView]) return;
    
    NSArray *positions = self.scrollViewPositions ? self.scrollViewPositions(self.scrollView) : nil;
    if (positions.count > 0) {
        self.panDisabled = NO;
        if (self.isOriginScrollable) {
            if (!self.isOriginDraggable && self.isOriginScrollView) {
                [self togglePosition:self.originPosition];
                self.position = self.originPosition;
            }
        }
        return;
    }
    
    if (self.position == self.openPosition) {
        self.panDisabled = !self.isOriginDraggable && (self.isOriginScrollView || !self.isOriginDirection);
    }
    if (self.panDisabled) {
        [self togglePosition:self.openPosition];
        self.position = self.openPosition;
    } else {
        [self.scrollView __fw_scrollTo:self.scrollEdge animated:NO];
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
            if (self.scrollView && self.scrollView == otherGestureRecognizer.view &&
                [self canScroll:self.scrollView]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
