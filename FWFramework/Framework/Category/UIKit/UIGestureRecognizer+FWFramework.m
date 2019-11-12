/*!
 @header     UIGestureRecognizer+FWFramework.m
 @indexgroup FWFramework
 @brief      UIGestureRecognizer+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/12
 */

#import "UIGestureRecognizer+FWFramework.h"

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

@interface FWPanGestureRecognizer () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSNumber *isFailed;

@end

@implementation FWPanGestureRecognizer

- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    
    if (scrollView) {
        if (!self.delegate) self.delegate = self;
    } else {
        if (self.delegate == self) self.delegate = nil;
    }
}

- (void)reset
{
    [super reset];
    self.isFailed = nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (!self.scrollView) return;

    if (self.state == UIGestureRecognizerStateFailed) return;
    CGPoint velocity = [self velocityInView:self.view];
    CGPoint nowPoint = [touches.anyObject locationInView:self.view];
    CGPoint prevPoint = [touches.anyObject previousLocationInView:self.view];

    if (self.isFailed) {
        if (self.isFailed.boolValue) {
            self.state = UIGestureRecognizerStateFailed;
        }
        return;
    }

    CGFloat topOffset = -self.scrollView.contentInset.top;
    if ((fabs(velocity.x) < fabs(velocity.y)) &&
        (nowPoint.y > prevPoint.y) &&
        (self.scrollView.contentOffset.y <= topOffset)) {
        self.isFailed = @NO;
    } else if (self.scrollView.contentOffset.y >= topOffset) {
        self.state = UIGestureRecognizerStateFailed;
        self.isFailed = @YES;
    } else {
        self.isFailed = @NO;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.scrollView) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.scrollView) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.scrollView && self.requireFailureGestureRecognizer && self.requireFailureGestureRecognizer == otherGestureRecognizer) {
        return YES;
    }
    return NO;
}

@end
