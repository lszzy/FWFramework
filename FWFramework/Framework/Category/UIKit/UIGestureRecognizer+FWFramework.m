/*!
 @header     UIGestureRecognizer+FWFramework.m
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import "UIGestureRecognizer+FWFramework.h"
#import "UIScrollView+FWFramework.h"

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
    CGFloat percent = 0;
    CGPoint transition = [self translationInView:self.view];
    if (fabs(transition.x) > fabs(transition.y)) {
        percent = fabs(transition.x) / self.view.bounds.size.width;
    } else {
        percent = fabs(transition.y) / self.view.bounds.size.height;
    }
    return MAX(0, MIN(1, percent));
}

- (CGFloat)fwSwipePercentOfDirection:(UISwipeGestureRecognizerDirection)direction
{
    CGFloat percent = 0;
    CGPoint transition = [self translationInView:self.view];
    switch (direction) {
        case UISwipeGestureRecognizerDirectionLeft:
            percent = -transition.x / self.view.bounds.size.width;
            break;
        case UISwipeGestureRecognizerDirectionRight:
            percent = transition.x / self.view.bounds.size.width;
            break;
        case UISwipeGestureRecognizerDirectionUp:
            percent = -transition.y / self.view.bounds.size.height;
            break;
        case UISwipeGestureRecognizerDirectionDown:
        default:
            percent = transition.y / self.view.bounds.size.height;
            break;
    }
    return MAX(0, MIN(1, percent));
}

@end

#pragma mark - FWPanGestureRecognizer

@interface FWPanGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSNumber *isFailed;

@end

@implementation FWPanGestureRecognizer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _direction = UISwipeGestureRecognizerDirectionDown;
        _autoDetected = YES;
        self.delegate = self;
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        _direction = UISwipeGestureRecognizerDirectionDown;
        _autoDetected = YES;
        self.delegate = self;
    }
    return self;
}

- (void)reset
{
    [super reset];
    self.isFailed = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (!self.scrollView || !self.scrollView.scrollEnabled) return;
    
    if (self.direction == UISwipeGestureRecognizerDirectionUp | self.direction == UISwipeGestureRecognizerDirectionDown) {
        if (![self.scrollView fwCanScrollVertical]) return;
    } else {
        if (![self.scrollView fwCanScrollHorizontal]) return;
    }

    if (self.state == UIGestureRecognizerStateFailed) return;
    if (self.isFailed) {
        if (self.isFailed.boolValue) {
            self.state = UIGestureRecognizerStateFailed;
        }
        return;
    }

    CGPoint velocity = [self velocityInView:self.view];
    CGPoint location = [touches.anyObject locationInView:self.view];
    CGPoint prevLocation = [touches.anyObject previousLocationInView:self.view];
    if (CGPointEqualToPoint(velocity, CGPointZero) && CGPointEqualToPoint(location, prevLocation)) return;
    
    BOOL isFailed = NO;
    switch (self.direction) {
        case UISwipeGestureRecognizerDirectionDown: {
            CGFloat edgeOffset = [self.scrollView fwContentOffsetOfEdge:UIRectEdgeTop].y;
            if ((fabs(velocity.x) < fabs(velocity.y)) && (location.y > prevLocation.y) && (self.scrollView.contentOffset.y <= edgeOffset)) {
                isFailed = NO;
            } else if (self.scrollView.contentOffset.y >= edgeOffset) {
                isFailed = YES;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionUp: {
            CGFloat edgeOffset = [self.scrollView fwContentOffsetOfEdge:UIRectEdgeBottom].y;
            if ((fabs(velocity.x) < fabs(velocity.y)) && (location.y < prevLocation.y) && (self.scrollView.contentOffset.y >= edgeOffset)) {
                isFailed = NO;
            } else if (self.scrollView.contentOffset.y <= edgeOffset) {
                isFailed = YES;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionRight: {
            CGFloat edgeOffset = [self.scrollView fwContentOffsetOfEdge:UIRectEdgeLeft].x;
            if ((fabs(velocity.y) < fabs(velocity.x)) && (location.x > prevLocation.x) && (self.scrollView.contentOffset.x <= edgeOffset)) {
                isFailed = NO;
            } else if (self.scrollView.contentOffset.x >= edgeOffset) {
                isFailed = YES;
            }
            break;
        }
        case UISwipeGestureRecognizerDirectionLeft: {
            CGFloat edgeOffset = [self.scrollView fwContentOffsetOfEdge:UIRectEdgeRight].x;
            if ((fabs(velocity.y) < fabs(velocity.x)) && (location.x < prevLocation.x) && (self.scrollView.contentOffset.x >= edgeOffset)) {
                isFailed = NO;
            } else if (self.scrollView.contentOffset.x <= edgeOffset) {
                isFailed = YES;
            }
            break;
        }
        default:
            break;
    }
    
    if (isFailed && self.shouldFailed) {
        isFailed = self.shouldFailed(self);
    }
    
    if (isFailed) {
        self.state = UIGestureRecognizerStateFailed;
        self.isFailed = @YES;
    } else {
        self.isFailed = @NO;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (self.autoDetected) {
            UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
            if (scrollView != self.scrollView) self.scrollView = scrollView;
            return YES;
        } else {
            if (self.scrollView && self.scrollView == otherGestureRecognizer.view) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.shouldBeRequiredToFail) {
        return self.shouldBeRequiredToFail(otherGestureRecognizer);
    }
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        if (self.autoDetected) {
            UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
            if (scrollView != self.scrollView) self.scrollView = scrollView;
            return YES;
        } else {
            if (self.scrollView && self.scrollView == otherGestureRecognizer.view) {
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.shouldRequireFailure) {
        return self.shouldRequireFailure(otherGestureRecognizer);
    }
    return NO;
}

@end
