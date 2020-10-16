/*!
 @header     FWRefreshPlugin.m
 @indexgroup FWFramework
 @brief      FWRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWRefreshPlugin.h"
#import "FWPlugin.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#pragma mark - UIScrollView+FWRefreshPlugin

@implementation UIScrollView (FWRefreshPlugin)

@end

#pragma mark - FWInfiniteScrollView

static CGFloat FWInfiniteScrollViewHeight = 60;

@interface FWInfiniteScrollView ()

@property (nonatomic, copy) void (^infiniteScrollBlock)(void);
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, readwrite) FWInfiniteScrollState state;
@property (nonatomic, assign) BOOL userTriggered;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;

@end

@implementation FWInfiniteScrollView

// public properties
@synthesize infiniteScrollBlock, activityIndicatorViewStyle;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark - Lifecycle

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
                [scrollView.panGestureRecognizer removeTarget:self action:@selector(scrollViewPanAction:)];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.activityIndicatorView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma mark - Static

+ (CGFloat)height {
    return FWInfiniteScrollViewHeight;
}

+ (void)setHeight:(CGFloat)height {
    FWInfiniteScrollViewHeight = height;
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalBottomInset + self.scrollView.fwInfiniteScrollHeight;
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
        CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        if (contentOffset.y >= 0) {
            if (!self.scrollView.fwPullRefreshView || !self.scrollView.fwPullRefreshView.isAnimating) {
                [self scrollViewDidScroll:contentOffset];
            }
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, self.scrollView.fwInfiniteScrollHeight);
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != FWInfiniteScrollStateLoading && self.enabled) {
        if(self.progressBlock) {
            CGFloat scrollHeight = self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom;
            CGFloat progress = (self.scrollView.fwInfiniteScrollHeight + contentOffset.y - scrollHeight) / self.scrollView.fwInfiniteScrollHeight;
            self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
        }
        
        CGFloat scrollOffsetThreshold = self.scrollView.contentSize.height - self.scrollView.bounds.size.height - self.preloadHeight;
        if(!self.scrollView.isDragging && self.state == FWInfiniteScrollStateTriggered)
            self.state = FWInfiniteScrollStateLoading;
        else if(contentOffset.y > scrollOffsetThreshold && self.state == FWInfiniteScrollStateStopped && self.scrollView.isDragging) {
            self.state = FWInfiniteScrollStateTriggered;
            self.userTriggered = YES;
        } else if(contentOffset.y < scrollOffsetThreshold  && self.state != FWInfiniteScrollStateStopped)
            self.state = FWInfiniteScrollStateStopped;
    }
}

- (void)scrollViewPanAction:(UIPanGestureRecognizer *)gesture
{
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

- (BOOL)isAnimating {
    return self.state != FWInfiniteScrollStateStopped;
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
                // remove current custom view if not changed
                if (!customViewChanged) {
                    [self.currentCustomView removeFromSuperview];
                    self.currentCustomView = nil;
                }
                break;
                
            case FWInfiniteScrollStateTriggered:
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
                [self.activityIndicatorView stopAnimating];
                break;
                
            case FWInfiniteScrollStateTriggered:
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
    
    if(self.stateBlock) {
        self.stateBlock(self, newState);
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
    
    FWInfiniteScrollView *view = [[FWInfiniteScrollView alloc] initWithFrame:CGRectMake(0, self.contentSize.height, self.bounds.size.width, self.fwInfiniteScrollHeight)];
    view.infiniteScrollBlock = block;
    view.target = target;
    view.action = action;
    view.scrollView = self;
    [self addSubview:view];
    
    view.originalBottomInset = self.contentInset.bottom;
    self.fwInfiniteScrollView = view;
    self.fwShowInfiniteScroll = YES;
}

- (void)fwTriggerInfiniteScroll {
    if ([self.fwInfiniteScrollView isAnimating]) return;
    
    self.fwInfiniteScrollView.state = FWInfiniteScrollStateTriggered;
    self.fwInfiniteScrollView.userTriggered = NO;
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

- (void)setFwInfiniteScrollHeight:(CGFloat)fwInfiniteScrollHeight {
    objc_setAssociatedObject(self, @selector(fwInfiniteScrollHeight), @(fwInfiniteScrollHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwInfiniteScrollHeight {
#if CGFLOAT_IS_DOUBLE
    CGFloat height = [objc_getAssociatedObject(self, @selector(fwInfiniteScrollHeight)) doubleValue];
#else
    CGFloat height = [objc_getAssociatedObject(self, @selector(fwInfiniteScrollHeight)) floatValue];
#endif
    return height > 0 ? height : FWInfiniteScrollViewHeight;
}

- (void)setFwShowInfiniteScroll:(BOOL)fwShowInfiniteScroll {
    if(!self.fwInfiniteScrollView)return;
    
    self.fwInfiniteScrollView.hidden = !fwShowInfiniteScroll;
    if(!fwShowInfiniteScroll) {
        if (self.fwInfiniteScrollView.isObserving) {
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize"];
            [self.panGestureRecognizer removeTarget:self.fwInfiniteScrollView action:@selector(scrollViewPanAction:)];
            [self.fwInfiniteScrollView resetScrollViewContentInset];
            self.fwInfiniteScrollView.isObserving = NO;
        }
    }
    else {
        if (!self.fwInfiniteScrollView.isObserving) {
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fwInfiniteScrollView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self.panGestureRecognizer addTarget:self.fwInfiniteScrollView action:@selector(scrollViewPanAction:)];
            [self.fwInfiniteScrollView setScrollViewContentInsetForInfiniteScrolling];
            self.fwInfiniteScrollView.isObserving = YES;
            
            [self.fwInfiniteScrollView setNeedsLayout];
            [self.fwInfiniteScrollView layoutIfNeeded];
            self.fwInfiniteScrollView.frame = CGRectMake(0, self.contentSize.height, self.fwInfiniteScrollView.bounds.size.width, self.fwInfiniteScrollHeight);
        }
    }
}

- (BOOL)fwShowInfiniteScroll {
    return !self.fwInfiniteScrollView.hidden;
}

@end

#pragma mark - FWPullRefreshArrow

@interface FWPullRefreshArrow : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end

@implementation FWPullRefreshArrow

@synthesize arrowColor;

- (UIColor *)arrowColor {
    if (arrowColor) return arrowColor;
    return [UIColor grayColor]; // default Color
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSaveGState(c);
    
    // the arrow
    CGContextMoveToPoint(c, 7.5, 8.5);
    CGContextAddLineToPoint(c, 7.5, 31.5);
    CGContextMoveToPoint(c, 0, 24);
    CGContextAddLineToPoint(c, 7.5, 31.5);
    CGContextAddLineToPoint(c, 15, 24);
    CGContextSetLineWidth(c, 1.5);
    [[self arrowColor] setStroke];
    CGContextStrokePath(c);
    
    CGContextRestoreGState(c);
}

@end

#pragma mark - FWPullRefreshView

static CGFloat FWPullRefreshViewHeight = 60;

@interface FWPullRefreshView ()

@property (nonatomic, copy) void (^pullRefreshBlock)(void);
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic, strong) FWPullRefreshArrow *arrow;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, readwrite) FWPullRefreshState state;
@property (nonatomic, assign) BOOL userTriggered;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat pullingPercent;

@property (nonatomic, assign) BOOL showsPullToRefresh;
@property(nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;

@end

@implementation FWPullRefreshView

// public properties
@synthesize pullRefreshBlock, arrowColor, textColor, activityIndicatorViewColor, activityIndicatorViewStyle;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize arrow = _arrow;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize titleLabel = _titleLabel;

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.textColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = FWPullRefreshStateStopped;
        self.pullingPercent = 0;
        
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"下拉可以刷新   ",),
                       NSLocalizedString(@"松开立即刷新   ",),
                       NSLocalizedString(@"正在刷新数据...",),
                       nil];
        
        self.subtitles = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.fwShowPullRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    id customView = [self.viewForState objectAtIndex:self.state];
    BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
    BOOL customViewChanged = customView != self.currentCustomView;
    if (customViewChanged || !hasCustomView) {
        [self.currentCustomView removeFromSuperview];
        self.currentCustomView = nil;
    }
    
    self.titleLabel.hidden = hasCustomView;
    self.subtitleLabel.hidden = hasCustomView;
    self.arrow.hidden = hasCustomView;
    
    if(hasCustomView) {
        if (customViewChanged) {
            self.currentCustomView = customView;
            [self addSubview:customView];
        }
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case FWPullRefreshStateAll:
            case FWPullRefreshStateStopped:
                self.arrow.alpha = 1;
                [self.activityIndicatorView stopAnimating];
                [self rotateArrow:0 hide:NO];
                break;
                
            case FWPullRefreshStateTriggered:
                [self rotateArrow:(float)M_PI hide:NO];
                break;
                
            case FWPullRefreshStateLoading:
                [self.activityIndicatorView startAnimating];
                [self rotateArrow:0 hide:YES];
                break;
        }
        
        CGFloat leftViewWidth = MAX(self.arrow.bounds.size.width,self.activityIndicatorView.bounds.size.width);
        
        CGFloat margin = 10;
        CGFloat marginY = 2;
        CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
        
        self.titleLabel.text = [self.titles objectAtIndex:self.state];
        
        NSString *subtitle = [self.subtitles objectAtIndex:self.state];
        self.subtitleLabel.text = subtitle.length > 0 ? subtitle : nil;
        
        CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(labelMaxWidth,self.titleLabel.font.lineHeight)
                                                              options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                                           attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                              context:nil].size;
        
        CGSize subtitleSize = [self.subtitleLabel.text boundingRectWithSize:CGSizeMake(labelMaxWidth,self.subtitleLabel.font.lineHeight)
                                                                    options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
                                                                 attributes:@{NSFontAttributeName: self.subtitleLabel.font}
                                                                    context:nil].size;
        
        CGFloat maxLabelWidth = MAX(titleSize.width,subtitleSize.width);
        
        CGFloat totalMaxWidth;
        if (maxLabelWidth) {
            totalMaxWidth = leftViewWidth + margin + maxLabelWidth;
        } else {
            totalMaxWidth = leftViewWidth + maxLabelWidth;
        }
        
        CGFloat labelX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + leftViewWidth + margin;
        
        if(subtitleSize.height > 0){
            CGFloat totalHeight = titleSize.height + subtitleSize.height + marginY;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }else{
            CGFloat totalHeight = titleSize.height;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }
        
        CGFloat arrowX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - self.arrow.bounds.size.width) / 2;
        self.arrow.frame = CGRectMake(arrowX,
                                      (self.bounds.size.height / 2) - (self.arrow.bounds.size.height / 2),
                                      self.arrow.bounds.size.width,
                                      self.arrow.bounds.size.height);
        self.activityIndicatorView.center = self.arrow.center;
    }
}

#pragma mark - Static

+ (CGFloat)height {
    return FWPullRefreshViewHeight;
}

+ (void)setHeight:(CGFloat)height {
    FWPullRefreshViewHeight = height;
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets pullingPercent:0];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset + self.bounds.size.height;
    [self setScrollViewContentInset:currentInsets pullingPercent:1];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset pullingPercent:(CGFloat)pullingPercent {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:^(BOOL finished) {
                         self.pullingPercent = pullingPercent;
                     }];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        if(contentOffset.y <= 0) {
            if (!self.scrollView.fwInfiniteScrollView || !self.scrollView.fwInfiniteScrollView.isAnimating) {
                [self scrollViewDidScroll:contentOffset];
            } else {
                // 修复滚动视图不够高时，快速下拉上拉再下拉刷新是否不消失的问题
                if (self.pullingPercent > 0 && self.scrollView.isDragging && self.state == FWPullRefreshStateStopped) {
                    self.pullingPercent = 0;
                }
            }
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, -self.scrollView.fwPullRefreshHeight, self.bounds.size.width, self.scrollView.fwPullRefreshHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != FWPullRefreshStateLoading) {
        if(self.progressBlock) {
            CGFloat progress = 1.f - (self.scrollView.fwPullRefreshHeight + contentOffset.y) / self.scrollView.fwPullRefreshHeight;
            self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
        }
        
        CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
        if(!self.scrollView.isDragging && self.state == FWPullRefreshStateTriggered)
            self.state = FWPullRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == FWPullRefreshStateStopped) {
            self.state = FWPullRefreshStateTriggered;
            self.userTriggered = YES;
        } else if(contentOffset.y >= scrollOffsetThreshold && self.state != FWPullRefreshStateStopped)
            self.state = FWPullRefreshStateStopped;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state == FWPullRefreshStateStopped)
            self.pullingPercent = MAX(MIN(1.f - (self.scrollView.fwPullRefreshHeight + contentOffset.y) / self.scrollView.fwPullRefreshHeight, 1.f), 0.f);
    } else {
        UIEdgeInsets currentInset = self.scrollView.contentInset;
        currentInset.top = self.originalTopInset + self.bounds.size.height;
        self.scrollView.contentInset = currentInset;
    }
}

#pragma mark - Getters

- (FWPullRefreshArrow *)arrow {
    if(!_arrow) {
        _arrow = [[FWPullRefreshArrow alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-47, 15, 40)];
        _arrow.backgroundColor = [UIColor clearColor];
        [self addSubview:_arrow];
    }
    return _arrow;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = textColor;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if(!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 210, 20)];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.backgroundColor = [UIColor clearColor];
        _subtitleLabel.textColor = textColor;
        [self addSubview:_subtitleLabel];
    }
    return _subtitleLabel;
}

- (UIColor *)arrowColor {
    return self.arrow.arrowColor; // pass through
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIColor *)activityIndicatorViewColor {
    return self.activityIndicatorView.color;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return self.activityIndicatorView.activityIndicatorViewStyle;
}

#pragma mark - Setters

- (void)setArrowColor:(UIColor *)newArrowColor {
    self.arrow.arrowColor = newArrowColor; // pass through
    [self.arrow setNeedsDisplay];
}

- (void)setTitle:(NSString *)title forState:(FWPullRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == FWPullRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSubtitle:(NSString *)subtitle forState:(FWPullRefreshState)state {
    if(!subtitle)
        subtitle = @"";
    
    if(state == FWPullRefreshStateAll)
        [self.subtitles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[subtitle, subtitle, subtitle]];
    else
        [self.subtitles replaceObjectAtIndex:state withObject:subtitle];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setCustomView:(UIView *)view forState:(FWPullRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == FWPullRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
    self.subtitleLabel.textColor = newTextColor;
}

- (void)setActivityIndicatorViewColor:(UIColor *)color {
    self.activityIndicatorView.color = color;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)viewStyle {
    self.activityIndicatorView.activityIndicatorViewStyle = viewStyle;
}

- (void)setPullingPercent:(CGFloat)pullingPercent
{
    _pullingPercent = pullingPercent;
    self.alpha = pullingPercent;
}

#pragma mark -

- (void)startAnimating{
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -(self.frame.size.height + self.originalTopInset)) animated:YES];
    
    self.state = FWPullRefreshStateLoading;
}

- (void)stopAnimating {
    if (!self.isAnimating) return;
    
    self.state = FWPullRefreshStateStopped;
    
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
}

- (BOOL)isAnimating {
    return self.state != FWPullRefreshStateStopped;
}

- (void)setState:(FWPullRefreshState)newState {
    
    if(_state == newState)
        return;
    
    FWPullRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case FWPullRefreshStateAll:
        case FWPullRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case FWPullRefreshStateTriggered:
            break;
            
        case FWPullRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == FWPullRefreshStateTriggered) {
                if(pullRefreshBlock) {
                    pullRefreshBlock();
                }else if(self.target && self.action && [self.target respondsToSelector:self.action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [self.target performSelector:self.action];
#pragma clang diagnostic pop
                }
            }
            
            break;
    }
    
    if (self.stateBlock) {
        self.stateBlock(self, newState);
    }
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrow.layer.opacity = !hide;
    } completion:NULL];
}

@end

#pragma mark - UIScrollView+FWPullRefresh

static char UIScrollViewFWPullRefreshView;

@implementation UIScrollView (FWPullRefresh)

@dynamic fwPullRefreshView, fwShowPullRefresh;

- (void)fwAddPullRefreshWithBlock:(void (^)(void))block {
    [self fwAddPullRefreshWithBlock:block target:nil action:NULL];
}

- (void)fwAddPullRefreshWithTarget:(id)target action:(SEL)action {
    [self fwAddPullRefreshWithBlock:nil target:target action:action];
}

- (void)fwAddPullRefreshWithBlock:(void (^)(void))block target:(id)target action:(SEL)action {
    [self.fwPullRefreshView removeFromSuperview];
    
    FWPullRefreshView *view = [[FWPullRefreshView alloc] initWithFrame:CGRectMake(0, -self.fwPullRefreshHeight, self.bounds.size.width, self.fwPullRefreshHeight)];
    view.pullRefreshBlock = block;
    view.target = target;
    view.action = action;
    view.scrollView = self;
    [self addSubview:view];
    
    view.originalTopInset = self.contentInset.top;
    self.fwPullRefreshView = view;
    self.fwShowPullRefresh = YES;
}

- (void)fwTriggerPullRefresh {
    if ([self.fwPullRefreshView isAnimating]) return;
    
    self.fwPullRefreshView.state = FWPullRefreshStateTriggered;
    self.fwPullRefreshView.userTriggered = NO;
    [self.fwPullRefreshView startAnimating];
}

- (void)setFwPullRefreshView:(FWPullRefreshView *)fwPullRefreshView {
    [self willChangeValueForKey:@"fwPullRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewFWPullRefreshView,
                             fwPullRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"fwPullRefreshView"];
}

- (FWPullRefreshView *)fwPullRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewFWPullRefreshView);
}

- (void)setFwPullRefreshHeight:(CGFloat)fwPullRefreshHeight {
    objc_setAssociatedObject(self, @selector(fwPullRefreshHeight), @(fwPullRefreshHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fwPullRefreshHeight {
#if CGFLOAT_IS_DOUBLE
    CGFloat height = [objc_getAssociatedObject(self, @selector(fwPullRefreshHeight)) doubleValue];
#else
    CGFloat height = [objc_getAssociatedObject(self, @selector(fwPullRefreshHeight)) floatValue];
#endif
    return height > 0 ? height : FWPullRefreshViewHeight;
}

- (void)setFwShowPullRefresh:(BOOL)fwShowPullRefresh {
    if(!self.fwPullRefreshView)return;
    
    self.fwPullRefreshView.hidden = !fwShowPullRefresh;
    if(!fwShowPullRefresh) {
        if (self.fwPullRefreshView.isObserving) {
            [self removeObserver:self.fwPullRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fwPullRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.fwPullRefreshView forKeyPath:@"frame"];
            [self.fwPullRefreshView resetScrollViewContentInset];
            self.fwPullRefreshView.isObserving = NO;
        }
    }
    else {
        if (!self.fwPullRefreshView.isObserving) {
            [self addObserver:self.fwPullRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fwPullRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fwPullRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.fwPullRefreshView.isObserving = YES;
            
            [self.fwPullRefreshView setNeedsLayout];
            [self.fwPullRefreshView layoutIfNeeded];
            self.fwPullRefreshView.frame = CGRectMake(0, -self.fwPullRefreshHeight, self.bounds.size.width, self.fwPullRefreshHeight);
        }
    }
}

- (BOOL)fwShowPullRefresh {
    return !self.fwPullRefreshView.hidden;
}

@end
