/*!
 @header     UIScrollView+FWInfiniteScroll.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWInfiniteScroll
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import "UIScrollView+FWInfiniteScroll.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - FWInfiniteScrollView

static CGFloat const FWInfiniteScrollViewHeight = 44;

@interface FWInfiniteScrollView ()

@property (nonatomic, copy) void (^infiniteScrollBlock)(void);
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) FWInfiniteScrollState state;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;
- (void)scrollViewPanGestureUpdate:(UIPanGestureRecognizer *)gesture;

@end

@implementation FWInfiniteScrollView

// public properties
@synthesize infiniteScrollBlock, activityIndicatorViewStyle;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = FWInfiniteScrollStateStopped;
        self.enabled = YES;
        
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.fwShowInfiniteScroll) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView.panGestureRecognizer removeTarget:self action:@selector(scrollViewPanGestureUpdate:)];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.activityIndicatorView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset + FWInfiniteScrollViewHeight;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        if (newPoint.y >= 0) {
            [self scrollViewDidScroll:newPoint];
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, FWInfiniteScrollViewHeight);
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != FWInfiniteScrollStateLoading && self.enabled) {
        CGFloat scrollViewContentHeight = self.scrollView.contentSize.height;
        CGFloat scrollOffsetThreshold = scrollViewContentHeight-self.scrollView.bounds.size.height;
        CGFloat yVelocity = [self.scrollView.panGestureRecognizer velocityInView:self.scrollView].y;
        
        if(yVelocity < 0 && contentOffset.y > scrollOffsetThreshold && self.state == FWInfiniteScrollStateStopped && self.scrollView.isDragging)
            self.state = FWInfiniteScrollStateTriggered;
        else if(contentOffset.y < scrollOffsetThreshold  && self.state != FWInfiniteScrollStateStopped)
            self.state = FWInfiniteScrollStateStopped;
    }
}

- (void)scrollViewPanGestureUpdate:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded && self.state == FWInfiniteScrollStateTriggered) {
        self.state = FWInfiniteScrollStateLoading;
    }
}

#pragma mark - Getters

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)view forState:(FWInfiniteScrollState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == FWInfiniteScrollStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    self.state = self.state;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

#pragma mark -

- (void)startAnimating{
    self.state = FWInfiniteScrollStateLoading;
}

- (void)stopAnimating {
    self.state = FWInfiniteScrollStateStopped;
}

- (void)setState:(FWInfiniteScrollState)newState {
    
    if(_state == newState)
        return;
    
    FWInfiniteScrollState previousState = _state;
    _state = newState;
    
    id customView = [self.viewForState objectAtIndex:newState];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    BOOL customViewChanged = customView != self.currentCustomView;
    if (customViewChanged || !hasCustomView) {
        [self.currentCustomView removeFromSuperview];
        self.currentCustomView = nil;
    }
    
    if(hasCustomView) {
        if (customViewChanged) {
            self.currentCustomView = customView;
            [self addSubview:customView];
        }
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case FWInfiniteScrollStateStopped:
                [self resetScrollViewContentInset];
                // remove current custom view if not changed
                if (!customViewChanged) {
                    [self.currentCustomView removeFromSuperview];
                    self.currentCustomView = nil;
                }
                break;
                
            case FWInfiniteScrollStateTriggered:
                [self setScrollViewContentInsetForInfiniteScrolling];
                break;
                
            case FWInfiniteScrollStateLoading:
            default:
                break;
        }
    }
    else {
        CGRect viewBounds = [self.activityIndicatorView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [self.activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case FWInfiniteScrollStateStopped:
                [self resetScrollViewContentInset];
                [self.activityIndicatorView stopAnimating];
                break;
                
            case FWInfiniteScrollStateTriggered:
                [self setScrollViewContentInsetForInfiniteScrolling];
                [self.activityIndicatorView startAnimating];
                break;
                
            case FWInfiniteScrollStateLoading:
                [self.activityIndicatorView startAnimating];
                break;
                
            default:
                break;
        }
    }
    
    if(previousState == FWInfiniteScrollStateTriggered && newState == FWInfiniteScrollStateLoading && self.enabled) {
        if(self.infiniteScrollBlock) {
            self.infiniteScrollBlock();
        }
        else if(self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.target performSelector:self.action];
#pragma clang diagnostic pop
        }
    }
}

@end

#pragma mark - UIScrollView+FWInfiniteScroll

static char UIScrollViewFWInfiniteScrollView;

@implementation UIScrollView (FWInfiniteScroll)

@dynamic fwInfiniteScrollView;

- (void)fwAddInfiniteScrollWithBlock:(void (^)(void))block {
    [self fwAddInfiniteScrollWithBlock:block target:nil action:NULL];
}

- (void)fwAddInfiniteScrollWithTarget:(id)target action:(SEL)action {
    [self fwAddInfiniteScrollWithBlock:nil target:target action:action];
}

- (void)fwAddInfiniteScrollWithBlock:(void (^)(void))block target:(id)target action:(SEL)action {
    [self.fwInfiniteScrollView removeFromSuperview];
    
    FWInfiniteScrollView *view = [[FWInfiniteScrollView alloc] initWithFrame:CGRectMake(0, self.contentSize.height, self.bounds.size.width, FWInfiniteScrollViewHeight)];
    view.infiniteScrollBlock = block;
    view.target = target;
    view.action = action;
    view.scrollView = self;
    [self addSubview:view];
    
    view.originalBottomInset = self.contentInset.bottom;
    self.fwInfiniteScrollView = view;
    self.fwShowInfiniteScroll = YES;
    [view resetScrollViewContentInset];
}

- (void)fwTriggerInfiniteScroll {
    self.fwInfiniteScrollView.state = FWInfiniteScrollStateTriggered;
    [self.fwInfiniteScrollView startAnimating];
}

- (void)setFwInfiniteScrollView:(FWInfiniteScrollView *)fwInfiniteScrollView {
    [self willChangeValueForKey:@"fwInfiniteScrollView"];
    objc_setAssociatedObject(self, &UIScrollViewFWInfiniteScrollView,
                             fwInfiniteScrollView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"fwInfiniteScrollView"];
}

- (FWInfiniteScrollView *)fwInfiniteScrollView {
    return objc_getAssociatedObject(self, &UIScrollViewFWInfiniteScrollView);
}

- (void)setFwShowInfiniteScroll:(BOOL)fwShowInfiniteScroll {
    if(!self.fwInfiniteScrollView)return;
    
    self.fwInfiniteScrollView.hidden = !fwShowInfiniteScroll;
    if(!fwShowInfiniteScroll) {
        if (self.fwInfiniteScrollView.isObserving) {
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize"];
            [self.panGestureRecognizer removeTarget:self.fwInfiniteScrollView action:NSSelectorFromString(@"scrollViewPanGestureUpdate:")];
            [self.fwInfiniteScrollView resetScrollViewContentInset];
            self.fwInfiniteScrollView.isObserving = NO;
        }
    }
    else {
        if (!self.fwInfiniteScrollView.isObserving) {
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self.panGestureRecognizer addTarget:self.fwInfiniteScrollView action:NSSelectorFromString(@"scrollViewPanGestureUpdate:")];
            [self.fwInfiniteScrollView setScrollViewContentInsetForInfiniteScrolling];
            self.fwInfiniteScrollView.isObserving = YES;
            
            [self.fwInfiniteScrollView setNeedsLayout];
            [self.fwInfiniteScrollView layoutIfNeeded];
            self.fwInfiniteScrollView.frame = CGRectMake(0, self.contentSize.height, self.fwInfiniteScrollView.bounds.size.width, FWInfiniteScrollViewHeight);
        }
    }
}

- (BOOL)fwShowInfiniteScroll {
    return !self.fwInfiniteScrollView.hidden;
}

@end
