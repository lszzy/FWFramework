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

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) FWInfiniteScrollState state;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

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
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
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
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, FWInfiniteScrollViewHeight);
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != FWInfiniteScrollStateLoading && self.enabled) {
        CGFloat scrollViewContentHeight = self.scrollView.contentSize.height;
        CGFloat scrollOffsetThreshold = scrollViewContentHeight-self.scrollView.bounds.size.height;
        
        if(!self.scrollView.isDragging && self.state == FWInfiniteScrollStateTriggered)
            self.state = FWInfiniteScrollStateLoading;
        else if(contentOffset.y > scrollOffsetThreshold && self.state == FWInfiniteScrollStateStopped && self.scrollView.isDragging)
            self.state = FWInfiniteScrollStateTriggered;
        else if(contentOffset.y < scrollOffsetThreshold  && self.state != FWInfiniteScrollStateStopped)
            self.state = FWInfiniteScrollStateStopped;
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

- (void)triggerRefresh {
    self.state = FWInfiniteScrollStateTriggered;
    self.state = FWInfiniteScrollStateLoading;
}

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
    
    for(id otherView in self.viewForState) {
        if([otherView isKindOfClass:[UIView class]])
            [otherView removeFromSuperview];
    }
    
    id customView = [self.viewForState objectAtIndex:newState];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    
    if(hasCustomView) {
        [self addSubview:customView];
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        CGRect viewBounds = [self.activityIndicatorView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [self.activityIndicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case FWInfiniteScrollStateStopped:
                [self.activityIndicatorView stopAnimating];
                break;
                
            case FWInfiniteScrollStateTriggered:
                [self.activityIndicatorView startAnimating];
                break;
                
            case FWInfiniteScrollStateLoading:
                [self.activityIndicatorView startAnimating];
                break;
        }
    }
    
    if(previousState == FWInfiniteScrollStateTriggered && newState == FWInfiniteScrollStateLoading && self.infiniteScrollBlock && self.enabled)
        self.infiniteScrollBlock();
}

@end

#pragma mark - UIScrollView+FWInfiniteScroll

static char UIScrollViewFWInfiniteScrollView;

@implementation UIScrollView (FWInfiniteScroll)

@dynamic fwInfiniteScrollView;

- (void)fwAddInfiniteScrollWithBlock:(void (^)(void))block {
    
    if(!self.fwInfiniteScrollView) {
        FWInfiniteScrollView *view = [[FWInfiniteScrollView alloc] initWithFrame:CGRectMake(0, self.contentSize.height, self.bounds.size.width, FWInfiniteScrollViewHeight)];
        view.infiniteScrollBlock = block;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalBottomInset = self.contentInset.bottom;
        self.fwInfiniteScrollView = view;
        self.fwShowInfiniteScroll = YES;
    }
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
    self.fwInfiniteScrollView.hidden = !fwShowInfiniteScroll;
    
    if(!fwShowInfiniteScroll) {
        if (self.fwInfiniteScrollView.isObserving) {
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize"];
            [self.fwInfiniteScrollView resetScrollViewContentInset];
            self.fwInfiniteScrollView.isObserving = NO;
        }
    }
    else {
        if (!self.fwInfiniteScrollView.isObserving) {
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self.fwInfiniteScrollView setScrollViewContentInsetForInfiniteScrolling];
            self.fwInfiniteScrollView.isObserving = YES;
            
            [self.fwInfiniteScrollView setNeedsLayout];
            self.fwInfiniteScrollView.frame = CGRectMake(0, self.contentSize.height, self.fwInfiniteScrollView.bounds.size.width, FWInfiniteScrollViewHeight);
        }
    }
}

- (BOOL)fwShowInfiniteScroll {
    return !self.fwInfiniteScrollView.hidden;
}

@end
