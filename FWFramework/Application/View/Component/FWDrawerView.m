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
#import "UIScreen+FWFramework.h"
#import "UIGestureRecognizer+FWFramework.h"

#pragma mark - FWDrawerView

@interface FWDrawerView ()

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGFloat panOrigin;
@property (nonatomic, assign) BOOL startedDragging;

@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;

@property (nonatomic, strong) UIViewPropertyAnimator *previousAnimator NS_AVAILABLE_IOS(10_0);

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL scrollWasEnabled;

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
    _topMargin = 0;
    _collapsedHeight = FWTabBarHeight;
    _partiallyOpenHeight = FWScreenHeight / 3;
    _position = FWDrawerViewPositionCollapsed;
    _snapPositions = @[@(FWDrawerViewPositionCollapsed), @(FWDrawerViewPositionPartiallyOpen), @(FWDrawerViewPositionOpen)];
    _enabled = YES;
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGestureRecognizer.maximumNumberOfTouches = 2;
    self.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.panGestureRecognizer];
}

#pragma mark - Accessor

- (void)setEmbedView:(UIView *)embedView
{
    if (!embedView) return;
    _embedView = embedView;
    
    embedView.frame = self.bounds;
    [self addSubview:embedView];
    [embedView fwPinEdgesToSuperview];
}

- (void)setContainerView:(UIView *)containerView
{
    [self attachTo:containerView];
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
    // 自动从小到大排序
    _snapPositions = [snapPositions sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return obj1.integerValue > obj2.integerValue;
    }];
    
    if (![_snapPositions containsObject:@(self.position)]) {
        self.position = [_snapPositions.firstObject integerValue];
    }
}

- (void)setConcealed:(BOOL)concealed
{
    [self setConcealed:concealed animated:NO];
}

- (CGFloat)openHeight
{
    if (!self.superview) return 0;
    
    CGFloat snapPosition = [self snapPositionFor:FWDrawerViewPositionOpen inSuperview:self.superview];
    return [self convertScrollPositionToOffset:snapPosition];
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
    if (!self.superview) return 0;
    
    FWDrawerViewPosition topPosition = [self.snapPositions.lastObject integerValue];
    return [self snapPositionFor:topPosition inSuperview:self.superview];
}

#pragma mark - Public

- (void)attachTo:(UIView *)containerView
{
    if (self.superview != nil || !containerView) return;
    _containerView = containerView;
    
    [containerView addSubview:self];
    [self fwPinEdgeToSuperview:NSLayoutAttributeLeft];
    [self fwPinEdgeToSuperview:NSLayoutAttributeRight];
    [self fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:0 relation:NSLayoutRelationLessThanOrEqual];
    self.topConstraint = [self fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.topMargin];
    self.heightConstraint = [self fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:containerView withOffset:-self.topSpace relation:NSLayoutRelationGreaterThanOrEqual];
    
    [self setPosition:self.position animated:NO];
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
    [self scrollToPosition:nextSnapPosition animated:animated notifyDelegate:notifyPosition completion:^(BOOL finished) {
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
    BOOL isFullyOpen = [self.snapPositions.lastObject integerValue] == self.position;
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
            
            if (self.scrollView != nil) {
                UIScrollView *activeScrollView = nil;
                if (self.scrollWasEnabled && [self.scrollView.panGestureRecognizer fwIsActive]) {
                    activeScrollView = self.scrollView;
                }
                
                BOOL childReachedTheTop = activeScrollView ? (activeScrollView.contentOffset.y <= 0 - activeScrollView.contentInset.top) : NO;
                BOOL childScrollEnabled = activeScrollView ? activeScrollView.scrollEnabled : NO;
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
                    CGFloat minContentOffset = activeScrollView ? (activeScrollView.contentOffset.y + activeScrollView.contentInset.top) : 0;
                    if (minContentOffset < 0) {
                        self.panOrigin = frame.origin.y - minContentOffset;
                    } else {
                        self.panOrigin = frame.origin.y;
                    }
                    
                    if (@available(iOS 10.0, *)) {
                        [self.previousAnimator stopAnimation:YES];
                        self.previousAnimator = [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                            activeScrollView.scrollEnabled = NO;
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
            
            BOOL shouldScrollChildView = NO;
            if (self.scrollView.scrollEnabled && [self.scrollView.panGestureRecognizer fwIsActive] &&
                (self.scrollView.contentOffset.y > 0 - self.scrollView.contentInset.top)) {
                shouldScrollChildView = YES;
            }
            
            if (shouldScrollChildView) {
                // 子视图滚动
            } else if (self.startedDragging) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(drawerViewWillEndDragging:)]) {
                    [self.delegate drawerViewWillEndDragging:self];
                }
                
                CGFloat targetOffset = self.frame.origin.y + velocity.y / 100;
                FWDrawerViewPosition targetPosition = [self positionFor:targetOffset];
                FWDrawerViewPosition advancePosition = [self advance:targetPosition offset:(velocity.y > 0 ? -1 : 1)];
                
                FWDrawerViewPosition nextPosition;
                if (targetPosition == self.position && fabs(velocity.y) > 0 && advancePosition != NSNotFound) {
                    nextPosition = advancePosition;
                } else {
                    nextPosition = targetPosition;
                }
                [self setPosition:nextPosition animated:YES];
            }
            
            self.scrollView.scrollEnabled = self.scrollWasEnabled;
            self.scrollView = nil;
            self.scrollWasEnabled = NO;
            
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
                        [self setScrollPosition:CGRectGetMinY(frame) notifyDelegate:notifyDelegate];
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

- (void)updateScrollPositionWhileDraggingAtPoint:(CGFloat)dragPoint notifyDelegate:(BOOL)notifyDelegate
{
    if (!self.superview) return;
    
    CGFloat position;
    CGFloat lowerBound = [self snapPositionFor:[self.snapPositions.lastObject integerValue] inSuperview:self.superview];
    CGFloat upperBound = [self snapPositionFor:[self.snapPositions.firstObject integerValue] inSuperview:self.superview];
    if (dragPoint < lowerBound) {
        position = lowerBound - [self damp:lowerBound - dragPoint factor:50];
    } else if (dragPoint > upperBound) {
        position = upperBound + [self damp:dragPoint - upperBound factor:50];
    } else {
        position = dragPoint;
    }
    
    [self setScrollPosition:position notifyDelegate:notifyDelegate];
}

- (void)updateSnapPositionAnimated:(BOOL)animated
{
    if (!self.panGestureRecognizer.fwIsTracking) {
        [self setPosition:self.position animated:animated];
    }
}

- (CGFloat)snapPositionFor:(FWDrawerViewPosition)position inSuperview:(UIView *)superview
{
    switch (position) {
        case FWDrawerViewPositionOpen:
            return self.topMargin;
        case FWDrawerViewPositionPartiallyOpen:
            return self.superview.bounds.size.height - self.partiallyOpenHeight;
        case FWDrawerViewPositionCollapsed:
            return self.superview.bounds.size.height - self.collapsedHeight;
        case FWDrawerViewPositionClosed:
            return self.superview.bounds.size.height;
        default:
            return 0;
    }
}

- (FWDrawerViewPosition)positionFor:(CGFloat)offset
{
    if (!self.superview) return self.position;
    
    NSArray *positions = [self.snapPositions sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        CGFloat dis1 = [self snapPositionFor:[obj1 integerValue] inSuperview:self.superview];
        CGFloat dis2 = [self snapPositionFor:[obj2 integerValue] inSuperview:self.superview];
        return fabs(dis1 - offset) > fabs(dis2 - offset);
    }];
    return [positions.firstObject integerValue];
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

- (FWDrawerViewPosition)advance:(FWDrawerViewPosition)position offset:(NSInteger)offset
{
    NSInteger index = [self.snapPositions indexOfObject:@(position)];
    if (index != NSNotFound) {
        NSInteger nextIndex = index + offset;
        if (nextIndex < 0 || nextIndex >= self.snapPositions.count) {
            return NSNotFound;
        }
        return [[self.snapPositions objectAtIndex:nextIndex] integerValue];
    } else {
        return NSNotFound;
    }
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
        if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
            [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
            if (scrollView != self.scrollView) {
                self.scrollView = scrollView;
                self.scrollWasEnabled = scrollView.scrollEnabled;
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
            [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
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
