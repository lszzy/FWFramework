/*!
 @header     FWDrawerView.m
 @indexgroup FWFramework
 @brief      FWDrawerView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/7/20
 */

#import "FWDrawerView.h"
#import "UIView+FWAutoLayout.h"

@interface FWDrawerViewScrollInfo : NSObject

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL scrollWasEnabled;
@property (nonatomic, strong) NSMutableArray<UIGestureRecognizer *> *gestureRecognizers;

@end

@implementation FWDrawerViewScrollInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _gestureRecognizers = [NSMutableArray array];
    }
    return self;
}

@end

#pragma mark - FWDrawerView

@interface FWDrawerView ()

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, assign) CGFloat panOrigin;

@property (nonatomic, assign) BOOL startedDragging;

@property (nonatomic, strong) UIViewPropertyAnimator *previousAnimator NS_AVAILABLE_IOS(10_0);

@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@property (nonatomic, strong) NSMutableArray<FWDrawerViewScrollInfo *> *childScrollViews;

@end

@implementation FWDrawerView

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithEmbedView:(UIView *)embedView
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setup];
        [self setEmbedView:embedView];
    }
    return self;
}

- (void)setup
{
    _topMargin = 68;
    _collapsedHeight = 68;
    _partiallyOpenHeight = 264;
    _position = FWDrawerViewPositionCollapsed;
    _snapPositions = @[@(FWDrawerViewPositionCollapsed), @(FWDrawerViewPositionPartiallyOpen), @(FWDrawerViewPositionOpen)];
    _enabled = YES;
    _childScrollViews = [NSMutableArray array];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGestureRecognizer.maximumNumberOfTouches = 2;
    self.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.panGestureRecognizer];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self updateVisuals];
}

#pragma mark - Accessor

- (void)setEmbedView:(UIView *)embedView
{
    _embedView = embedView;
    
    if (embedView) {
        embedView.frame = self.bounds;
        // embedView.backgroundColor = [UIColor clearColor];
        embedView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:embedView];
        [embedView fwPinEdgesToSuperview];
    }
}

- (void)setContainerView:(UIView *)containerView
{
    [self attachTo:containerView];
}

- (CGFloat)drawerOffset
{
    if (!self.superview) return 0;
    
    if (self.isConcealed) {
        CGFloat closedSnapPosition = [self snapPositionFor:FWDrawerViewPositionClosed inSuperview:self.superview];
        return [self convertScrollPositionToOffset:closedSnapPosition];
    } else {
        CGFloat currentSnapPosition = self.topConstraint.constant;
        return [self convertScrollPositionToOffset:currentSnapPosition];
    }
}

- (CGFloat)topSpace
{
    NSArray<NSNumber *> *openPositions = @[@(FWDrawerViewPositionOpen), @(FWDrawerViewPositionPartiallyOpen)];
    // 目标从大到小
    openPositions = [openPositions sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if (self.superview) {
            return [self snapPositionFor:[obj1 integerValue] inSuperview:self.superview] > [self snapPositionFor:[obj2 integerValue] inSuperview:self.superview];
        } else {
            return obj1.integerValue > obj2.integerValue;
        }
    }];
    
    __block FWDrawerViewPosition topPosition = FWDrawerViewPositionOpen;
    [openPositions enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        if ([self.snapPositions containsObject:obj]) {
            topPosition = [obj integerValue];
            *stop = YES;
        }
    }];
    
    if (self.superview != nil) {
        return [self snapPositionFor:topPosition inSuperview:self.superview];
    }
    return 0;
}

- (CGFloat)bottomInset
{
    return 0;
}

- (NSArray<NSNumber *> *)snapPositionsSorted
{
    // 目标从小到大
    return [self.snapPositions sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if (self.superview) {
            return [self snapPositionFor:[obj1 integerValue] inSuperview:self.superview] < [self snapPositionFor:[obj2 integerValue] inSuperview:self.superview];
        } else {
            return obj1.integerValue < obj2.integerValue;
        }
    }];
}

- (void)setTopMargin:(CGFloat)topMargin
{
    _topMargin = topMargin;
    [self updateSnapPositionAnimated:false];
}

- (void)setCollapsedHeight:(CGFloat)collapsedHeight
{
    _collapsedHeight = collapsedHeight;
    [self updateSnapPositionAnimated:false];
}

- (void)setPartiallyOpenHeight:(CGFloat)partiallyOpenHeight
{
    _partiallyOpenHeight = partiallyOpenHeight;
    [self updateSnapPositionAnimated:false];
}

- (void)setPosition:(FWDrawerViewPosition)position
{
    [self setPosition:position animated:NO];
}

- (void)setSnapPositions:(NSArray<NSNumber *> *)snapPositions
{
    _snapPositions = snapPositions;
    if (![snapPositions containsObject:@(self.position)]) {
        NSNumber *position = self.snapPositionsSorted.firstObject;
        self.position = position ? [position integerValue] : FWDrawerViewPositionCollapsed;
    }
}

- (void)setConcealed:(BOOL)concealed
{
    [self setConcealed:concealed animated:NO];
}

#pragma mark - Public

- (void)attachTo:(UIView *)containerView
{
    if (self.superview != nil) return;
    
    _containerView = containerView;
    if (!containerView) return;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self];
    if (@available(iOS 9.0, *)) {
        self.topConstraint = [self.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:self.topMargin];
        self.topConstraint.active = YES;
        self.heightConstraint = [self.heightAnchor constraintEqualToAnchor:containerView.heightAnchor constant:-self.topSpace];
        self.heightConstraint = [self.heightAnchor constraintGreaterThanOrEqualToAnchor:containerView.heightAnchor multiplier:1 constant:-self.topSpace];
        self.heightConstraint.active = YES;
        [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:containerView.bottomAnchor].active = YES;
        [self.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor].active = YES;
        [self.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor].active = YES;
    } else {
        
    }
    
    [self updateVisuals];
    [self updateSnapPositionAnimated:false];
}

- (void)setPosition:(FWDrawerViewPosition)position animated:(BOOL)animated
{
    if (!self.superview) return;
    
    FWDrawerViewPosition visiblePosition = self.isConcealed ? FWDrawerViewPositionClosed : position;
    BOOL notifyPosition = !self.isConcealed && self.position != visiblePosition;
    if (notifyPosition) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(drawerView:willTransitionFrom:to:)]) {
            [self.delegate drawerView:self willTransitionFrom:self.position to:position];
        }
    }
    
    _position = position;
    
    CGFloat nextSnapPosition = [self snapPositionFor:visiblePosition inSuperview:self.superview];
    [self scrollToPosition:nextSnapPosition animated:animated notifyDelegate:YES completion:^(BOOL finished) {
        if (notifyPosition) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(drawerView:didTransitionTo:)]) {
                [self.delegate drawerView:self didTransitionTo:visiblePosition];
            }
        }
    }];
}

- (FWDrawerViewPosition)getPositionWithOffset:(NSInteger)offset
{
    return [self advance:self.position offset:offset];
}

- (void)setConcealed:(BOOL)concealed animated:(BOOL)animated
{
    _concealed = concealed;
    [self setPosition:self.position animated:animated];
}

- (void)removeFromSuperviewAnimated:(BOOL)animated
{
    if (!self.superview) return;
    
    CGFloat pos = [self snapPositionFor:FWDrawerViewPositionClosed inSuperview:self.superview];
    [self scrollToPosition:pos animated:animated notifyDelegate:YES completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Private

- (void)handlePan:(UIPanGestureRecognizer *)sender
{
    BOOL isFullyOpen = [self.snapPositionsSorted.lastObject integerValue] == self.position;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(drawerViewWillBeginDragging:)]) {
                [self.delegate drawerViewWillBeginDragging:self];
            }
            
            if (@available(iOS 10.0, *)) {
                if (self.previousAnimator != nil) {
                    [self.previousAnimator stopAnimation:YES];
                }
            } else {
                
            }
            
            CGRect frame = self.layer.presentationLayer ? self.layer.presentationLayer.frame : self.frame;
            self.panOrigin = frame.origin.y;
            
            [self updateScrollPositionWhileDraggingAtPoint:self.panOrigin notifyDelegate:YES];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [sender translationInView:self];
            CGPoint velocity = [sender velocityInView:self];
            if (velocity.y == 0) {
                break;
            }
            
            if (self.childScrollViews.count > 0) {
                NSMutableArray *activeScrollViews = [NSMutableArray array];
                [self.childScrollViews enumerateObjectsUsingBlock:^(FWDrawerViewScrollInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.scrollWasEnabled) {
                        for (UIGestureRecognizer *gesture in obj.gestureRecognizers) {
                            if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && [gesture.view isKindOfClass:[UIScrollView class]] ) {
                                UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
                                if (panGesture.isEnabled && (panGesture.state == UIGestureRecognizerStateBegan || panGesture.state == UIGestureRecognizerStateChanged)) {
                                    if (![activeScrollViews containsObject:gesture.view]) {
                                        [activeScrollViews addObject:gesture.view];
                                    }
                                }
                            }
                        }
                    }
                }];
                
                BOOL childReachedTheTop = NO;
                for (UIScrollView *scrollView in activeScrollViews) {
                    if (scrollView.contentOffset.y <= 0) {
                        childReachedTheTop = YES;
                        break;
                    }
                }
                BOOL childScrollEnabled = NO;
                for (UIScrollView *scrollView in activeScrollViews) {
                    if (scrollView.isScrollEnabled) {
                        childScrollEnabled = YES;
                        break;
                    }
                }
                BOOL scrollingToBottom = velocity.y < 0;
                
                BOOL shouldScrollChildView = NO;
                if (!childScrollEnabled) {
                    shouldScrollChildView = NO;
                } else if (!childReachedTheTop && !scrollingToBottom) {
                    shouldScrollChildView = YES;
                } else if (childReachedTheTop && !scrollingToBottom) {
                    shouldScrollChildView = NO;
                } else if (!isFullyOpen) {
                    shouldScrollChildView = NO;
                } else {
                    shouldScrollChildView = YES;
                }
                
                if (!shouldScrollChildView && childScrollEnabled) {
                    self.startedDragging = YES;
                    [sender setTranslation:CGPointZero inView:self];
                    
                    CGRect frame = self.layer.presentationLayer ? self.layer.presentationLayer.frame : self.frame;
                    NSNumber *minContentOffsetValue = nil;
                    for (UIScrollView *scrollView in activeScrollViews) {
                        CGFloat y = scrollView.contentOffset.y;
                        if (!minContentOffsetValue) {
                            minContentOffsetValue = @(y);
                        } else if (y < [minContentOffsetValue doubleValue]) {
                            minContentOffsetValue = @(y);
                        }
                    }
                    
                    CGFloat minContentOffset = minContentOffsetValue ? [minContentOffsetValue doubleValue] : 0;
                    if (minContentOffset < 0) {
                        self.panOrigin = frame.origin.y - minContentOffset;
                    } else {
                        self.panOrigin = frame.origin.y;
                    }
                    
                    if (@available(iOS 10.0, *)) {
                        [self.previousAnimator stopAnimation:YES];
                        self.previousAnimator = [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                            for (UIScrollView *scrollView in activeScrollViews) {
                                scrollView.scrollEnabled = NO;
                            }
                            [self updateScrollPositionWhileDraggingAtPoint:self.panOrigin notifyDelegate:YES];
                        } completion:nil];
                    } else {
                        
                    }
                } else if (!shouldScrollChildView) {
                    self.startedDragging = YES;
                    CGFloat pos = self.panOrigin + translation.y;
                    [self updateScrollPositionWhileDraggingAtPoint:pos notifyDelegate:YES];
                }
            } else {
                self.startedDragging = YES;
                CGFloat pos = self.panOrigin + translation.y;
                [self updateScrollPositionWhileDraggingAtPoint:pos notifyDelegate:YES];
            }
            
            break;
        }
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            CGPoint velocity = [sender velocityInView:self];
            
            __block BOOL childScroll = NO;
            [self.childScrollViews enumerateObjectsUsingBlock:^(FWDrawerViewScrollInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.scrollView.isScrollEnabled) {
                    BOOL scrollValid = NO;
                    for (UIGestureRecognizer *gesture in obj.scrollView.gestureRecognizers) {
                        if (gesture.isEnabled && (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged)) {
                            scrollValid = YES;
                            break;
                        }
                    }
                    if (scrollValid) {
                        if (obj.scrollView.contentOffset.y > 0) {
                            childScroll = YES;
                            *stop = YES;
                        }
                    }
                }
            }];
            
            if (childScroll) {
                // 子视图滚动
            } else if (self.startedDragging) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(drawerViewWillEndDragging:)]) {
                    [self.delegate drawerViewWillEndDragging:self];
                }
                
                CGFloat targetOffset = self.frame.origin.y + velocity.y / 100;
                FWDrawerViewPosition targetPosition = [self positionFor:targetOffset];
                
                NSInteger advancement = velocity.y > 0 ? -1 : 1;
                FWDrawerViewPosition nextPosition;
                FWDrawerViewPosition advanced = [self advance:targetPosition offset:advancement];
                if (targetPosition == self.position && fabs(velocity.y) > 0 && advancement != NSNotFound) {
                    nextPosition = advanced;
                } else {
                    nextPosition = targetPosition;
                }
                [self setPosition:nextPosition animated:YES];
            }
            
            for (FWDrawerViewScrollInfo *scrollInfo in self.childScrollViews) {
                scrollInfo.scrollView.scrollEnabled = scrollInfo.scrollWasEnabled;
            }
            [self.childScrollViews removeAllObjects];
            
            self.startedDragging = NO;
            break;
        }
        default:
            break;
    }
}

- (void)scrollToPosition:(CGFloat)scrollPosition animated:(BOOL)animated notifyDelegate:(BOOL)notifyDelegate completion:(void (^)(BOOL))completion
{
    if (@available(iOS 10.0, *)) {
        if (self.previousAnimator != nil && self.previousAnimator.isRunning) {
            [self.previousAnimator stopAnimation:NO];
            if (self.previousAnimator.state == UIViewAnimatingStateStopped) {
                [self.previousAnimator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
            }
            self.previousAnimator = nil;
        }
        
        if (animated) {
            UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5 timingParameters:[[UISpringTimingParameters alloc] initWithDampingRatio:0.8]];
            [animator addAnimations:^{
                [self setScrollPosition:scrollPosition notifyDelegate:notifyDelegate];
            }];
            [animator addCompletion:^(UIViewAnimatingPosition pos) {
                if (pos == UIViewAnimatingPositionEnd) {
                    [self.superview layoutIfNeeded];
                    [self layoutIfNeeded];
                    [self setNeedsUpdateConstraints];
                } else if (pos == UIViewAnimatingPositionCurrent) {
                    if (self.layer.presentationLayer) {
                        CGRect frame = self.layer.presentationLayer.frame;
                        [self setScrollPosition:CGRectGetMinY(frame) notifyDelegate:NO];
                    }
                }
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(pos == UIViewAnimatingPositionEnd);
                    });
                }
            }];
            
            [self.superview layoutIfNeeded];
            
            [animator startAnimation];
            self.previousAnimator = animator;
        } else {
            [self setScrollPosition:scrollPosition notifyDelegate:notifyDelegate];
        }
    } else {
        
    }
}

- (void)updateScrollPositionWhileDraggingAtPoint:(CGFloat)dragPoint notifyDelegate:(BOOL)notifyDelegate
{
    if (!self.superview) return;
    
    NSMutableArray<NSNumber *> *positions = [NSMutableArray array];
    [self.snapPositions enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        CGFloat position = [self snapPositionFor:[obj integerValue] inSuperview:self.superview];
        [positions addObject:@(position)];
    }];
    [positions sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }];
    
    CGFloat position;
    CGFloat lowerBound = [positions.firstObject doubleValue];
    CGFloat upperBound = [positions.lastObject doubleValue];
    if (positions.firstObject && dragPoint < lowerBound) {
        position = lowerBound - [self damp:lowerBound - dragPoint factor:50];
    } else if (positions.lastObject && dragPoint > upperBound) {
        position = upperBound + [self damp:dragPoint - upperBound factor:50];
    } else {
        position = dragPoint;
    }
    
    [self setScrollPosition:position notifyDelegate:notifyDelegate];
}

- (void)setScrollPosition:(CGFloat)scrollPosition notifyDelegate:(BOOL)notifyDelegate
{
    self.topConstraint.constant = scrollPosition;
    
    if (notifyDelegate) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(drawerView:didMoveTo:)]) {
            CGFloat drawerOffset = [self convertScrollPositionToOffset:scrollPosition];
            [self.delegate drawerView:self didMoveTo:drawerOffset];
        }
    }
    
    [self.superview layoutIfNeeded];
}

- (FWDrawerViewPosition)advance:(FWDrawerViewPosition)position offset:(NSInteger)offset
{
    NSArray<NSNumber *> *snapPositionsSorted = self.snapPositionsSorted;
    NSInteger index = [snapPositionsSorted indexOfObject:@(position)];
    if (index != NSNotFound) {
        NSInteger nextIndex = index + offset;
        if (nextIndex < 0 || nextIndex >= snapPositionsSorted.count) {
            return NSNotFound;
        }
        return [[snapPositionsSorted objectAtIndex:nextIndex] integerValue];
    } else {
        return NSNotFound;
    }
}

- (void)updateVisuals
{
    self.heightConstraint.constant = -self.topSpace;
    [self setNeedsDisplay];
}

- (void)updateSnapPositionAnimated:(BOOL)animated
{
    BOOL isTracking = self.panGestureRecognizer.state == UIGestureRecognizerStateBegan || self.panGestureRecognizer.state == UIGestureRecognizerStateChanged;
    if (!isTracking) {
        [self setPosition:self.position animated:animated];
    }
}

- (CGFloat)snapPositionFor:(FWDrawerViewPosition)position inSuperview:(UIView *)superview
{
    switch (position) {
        case FWDrawerViewPositionOpen:
            return self.topMargin;
        case FWDrawerViewPositionPartiallyOpen:
            return self.superview.bounds.size.height - self.bottomInset - self.partiallyOpenHeight;
        case FWDrawerViewPositionCollapsed:
            return self.superview.bounds.size.height - self.bottomInset - self.collapsedHeight;
        case FWDrawerViewPositionClosed:
            return self.superview.bounds.size.height;
        default:
            return 0;
    }
}

- (FWDrawerViewPosition)positionFor:(CGFloat)offset
{
    if (!self.superview) return FWDrawerViewPositionCollapsed;
    
    NSMutableArray<NSArray *> *distances = [NSMutableArray array];
    [self.snapPositions enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        CGFloat distance = [self snapPositionFor:[obj integerValue] inSuperview:self.superview];
        [distances addObject:@[obj, @(distance)]];
    }];
    [distances sortUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
        return [@(fabs([obj1.lastObject doubleValue] - offset)) compare:@(fabs([obj2.lastObject doubleValue] - offset))];
    }];
    return distances.firstObject ? [distances.firstObject.firstObject integerValue] : FWDrawerViewPositionCollapsed;
}

- (CGFloat)convertScrollPositionToOffset:(CGFloat)position
{
    if (!self.superview) return 0;
    
    return self.superview.bounds.size.height - position;
}

- (CGFloat)damp:(CGFloat)value factor:(CGFloat)factor
{
    return factor * (log10(value + factor / log(10)) - log10(factor / log(10)));
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        return self.enabled;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        UIScrollView *scrollView = [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)otherGestureRecognizer.view : nil;
        if (scrollView) {
            __block FWDrawerViewScrollInfo *scrollInfo = nil;
            [self.childScrollViews enumerateObjectsUsingBlock:^(FWDrawerViewScrollInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.scrollView == scrollView) {
                    scrollInfo = obj;
                    *stop = YES;
                }
            }];
            if (scrollInfo != nil) {
                if (![scrollInfo.gestureRecognizers containsObject:otherGestureRecognizer]) {
                    [scrollInfo.gestureRecognizers addObject:otherGestureRecognizer];
                }
            } else {
                scrollInfo = [FWDrawerViewScrollInfo new];
                scrollInfo.scrollView = scrollView;
                scrollInfo.scrollWasEnabled = scrollView.scrollEnabled;
                [self.childScrollViews addObject:scrollInfo];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
            return NO;
        }
    }
    return YES;
}

@end

#pragma mark - UIViewController+FWDrawerView

@implementation UIViewController (FWDrawerView)

- (FWDrawerView *)fwAddDrawerViewController:(UIViewController *)viewController
{
    return [self fwAddDrawerViewController:viewController toView:self.view];
}

- (FWDrawerView *)fwAddDrawerViewController:(UIViewController *)viewController toView:(UIView *)parentView
{
    [self addChildViewController:viewController];
    FWDrawerView *drawerView = [[FWDrawerView alloc] initWithEmbedView:viewController.view];
    [drawerView attachTo:parentView ?: self.view];
    return drawerView;
}

@end
