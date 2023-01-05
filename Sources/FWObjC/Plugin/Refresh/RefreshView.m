//
//  RefreshView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "RefreshView.h"
#import "ViewPlugin.h"
#import "AppBundle.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

- (NSString *)fw_observeProperty:(NSString *)property target:(nullable id)target action:(SEL)action;
- (void)fw_unobserveProperty:(NSString *)property target:(nullable id)target action:(nullable SEL)action;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWPullRefreshArrowView

@interface __FWPullRefreshArrowView : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end

@implementation __FWPullRefreshArrowView

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

#pragma mark - __FWPullRefreshView

static CGFloat __FWPullRefreshViewHeight = 60;

@interface __FWPullRefreshView ()

@property (nonatomic, strong) __FWPullRefreshArrowView *arrowView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, copy) void (^animationStateBlock)(__FWPullRefreshView *view, __FWPullRefreshState state);
@property (nonatomic, copy) void (^animationProgressBlock)(__FWPullRefreshView *view, CGFloat progress);

@property (nonatomic, readwrite) CGFloat pullingPercent;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isActive;

- (void)setScrollViewContentInsetForLoading;

@end

#pragma mark - __FWInfiniteScrollView

static CGFloat __FWInfiniteScrollViewHeight = 60;

@interface __FWInfiniteScrollView ()

@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, copy) void (^animationStateBlock)(__FWInfiniteScrollView *view, __FWInfiniteScrollState state);
@property (nonatomic, copy) void (^animationProgressBlock)(__FWInfiniteScrollView *view, CGFloat progress);
@property (nonatomic, assign) BOOL isActive;

@end

#pragma mark - __FWPullRefreshView

@implementation __FWPullRefreshView

// public properties
@synthesize pullRefreshBlock, arrowColor, textColor, indicatorColor;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize arrowView = _arrowView;
@synthesize indicatorView = _indicatorView;
@synthesize titleLabel = _titleLabel;

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.textColor = [UIColor darkGrayColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.showsTitleLabel = [self.indicatorView isKindOfClass:[UIActivityIndicatorView class]];
        self.showsArrowView = self.showsTitleLabel;
        self.shouldChangeAlpha = YES;
        self.state = __FWPullRefreshStateIdle;
        self.pullingPercent = 0;
        
        self.titles = [NSMutableArray arrayWithObjects:__FWAppBundle.refreshIdleTitle,
                       __FWAppBundle.refreshTriggeredTitle,
                       __FWAppBundle.refreshLoadingTitle,
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
        if (scrollView.__fw_showPullRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                [scrollView.panGestureRecognizer __fw_unobserveProperty:@"state" target:self action:@selector(gestureRecognizer:stateChanged:)];
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
    
    self.titleLabel.hidden = hasCustomView || !self.showsTitleLabel;
    self.subtitleLabel.hidden = hasCustomView || !self.showsTitleLabel;
    self.arrowView.hidden = hasCustomView || !self.showsArrowView;
    
    if(hasCustomView) {
        if (customViewChanged) {
            self.currentCustomView = customView;
            [self addSubview:customView];
        }
        CGRect viewBounds = [customView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), self.indicatorPadding > 0 ? self.indicatorPadding : roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case __FWPullRefreshStateAll:
            case __FWPullRefreshStateIdle: {
                [self.indicatorView stopAnimating];
                if (self.showsArrowView) {
                    [self rotateArrow:0 hide:NO];
                }
                break;
            }
            case __FWPullRefreshStateTriggered: {
                if (self.showsArrowView) {
                    [self rotateArrow:(float)M_PI hide:NO];
                } else {
                    if (!self.indicatorView.isAnimating) {
                        [self.indicatorView startAnimating];
                    }
                }
                break;
            }
            case __FWPullRefreshStateLoading: {
                [self.indicatorView startAnimating];
                if (self.showsArrowView) {
                    [self rotateArrow:0 hide:YES];
                }
                break;
            }
        }
        
        CGFloat leftViewWidth = MAX(self.arrowView.bounds.size.width, self.indicatorView.bounds.size.width);
        
        CGFloat margin = 10;
        CGFloat marginY = 2;
        CGFloat labelMaxWidth = self.bounds.size.width - margin - leftViewWidth;
        
        self.titleLabel.text = self.showsTitleLabel ? [self.titles objectAtIndex:self.state] : nil;
        
        NSString *subtitle = self.showsTitleLabel ? [self.subtitles objectAtIndex:self.state] : nil;
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
        
        CGFloat arrowX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - self.arrowView.bounds.size.width) / 2;
        self.arrowView.frame = CGRectMake(arrowX,
                                      (self.bounds.size.height / 2) - (self.arrowView.bounds.size.height / 2),
                                      self.arrowView.bounds.size.width,
                                      self.arrowView.bounds.size.height);
        
        if (self.showsArrowView) {
            self.indicatorView.center = self.arrowView.center;
        } else {
            CGPoint indicatorOrigin = CGPointMake(self.bounds.size.width / 2 - self.indicatorView.bounds.size.width / 2, self.indicatorPadding > 0 ? self.indicatorPadding : (self.bounds.size.height / 2 - self.indicatorView.bounds.size.height / 2));
            self.indicatorView.frame = CGRectMake(indicatorOrigin.x, indicatorOrigin.y, self.indicatorView.bounds.size.width, self.indicatorView.bounds.size.height);
        }
    }
}

#pragma mark - Static

+ (CGFloat)height {
    return __FWPullRefreshViewHeight;
}

+ (void)setHeight:(CGFloat)height {
    __FWPullRefreshViewHeight = height;
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalInset.top;
    [self setScrollViewContentInset:currentInsets pullingPercent:0];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalInset.top + self.bounds.size.height;
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
        if (self.scrollView.__fw_infiniteScrollView.isActive ||
            (contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) > 0) {
            if (self.pullingPercent > 0) self.pullingPercent = 0;
            if (self.state != __FWPullRefreshStateIdle) {
                self.state = __FWPullRefreshStateIdle;
            }
        } else if (self.state != __FWPullRefreshStateLoading) {
            [self scrollViewDidScroll:contentOffset];
        } else {
            UIEdgeInsets currentInset = self.scrollView.contentInset;
            currentInset.top = self.originalInset.top + self.bounds.size.height;
            self.scrollView.contentInset = currentInset;
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, -self.scrollView.__fw_pullRefreshHeight, self.bounds.size.width, self.scrollView.__fw_pullRefreshHeight);
    }else if([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change {
    UIGestureRecognizerState state = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
    if (state == UIGestureRecognizerStateBegan) {
        self.isActive = NO;
        self.scrollView.__fw_infiniteScrollView.isActive = NO;
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat adjustedContentOffsetY = contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top;
    CGFloat progress = -adjustedContentOffsetY / self.scrollView.__fw_pullRefreshHeight;
    if(progress > 0) self.isActive = YES;
    if(self.animationProgressBlock) self.animationProgressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    if(self.progressBlock) self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    
    CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalInset.top;
    if(!self.scrollView.isDragging && self.state == __FWPullRefreshStateTriggered)
        self.state = __FWPullRefreshStateLoading;
    else if(adjustedContentOffsetY < scrollOffsetThreshold && self.scrollView.isDragging && self.state == __FWPullRefreshStateIdle) {
        self.state = __FWPullRefreshStateTriggered;
        self.userTriggered = YES;
    } else if(adjustedContentOffsetY >= scrollOffsetThreshold && self.state != __FWPullRefreshStateIdle)
        self.state = __FWPullRefreshStateIdle;
    else if(adjustedContentOffsetY >= scrollOffsetThreshold && self.state == __FWPullRefreshStateIdle)
        self.pullingPercent = MAX(MIN(-adjustedContentOffsetY / self.scrollView.__fw_pullRefreshHeight, 1.f), 0.f);
}

#pragma mark - Getters

- (__FWPullRefreshArrowView *)arrowView {
    if(!_arrowView) {
        _arrowView = [[__FWPullRefreshArrowView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-47, 15, 40)];
        _arrowView.backgroundColor = [UIColor clearColor];
        [self addSubview:_arrowView];
    }
    return _arrowView;
}

- (UIView<__FWIndicatorViewPlugin> *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [UIView __fw_indicatorViewWithStyle:__FWIndicatorViewStyleRefresh];
        _indicatorView.color = UIColor.grayColor;
        [self addSubview:_indicatorView];
    }
    return _indicatorView;
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
    return self.arrowView.arrowColor; // pass through
}

- (UIColor *)textColor {
    return self.titleLabel.textColor;
}

- (UIColor *)indicatorColor {
    return self.indicatorView.color;
}

#pragma mark - Setters

- (void)setArrowColor:(UIColor *)newArrowColor {
    self.arrowView.arrowColor = newArrowColor; // pass through
    [self.arrowView setNeedsDisplay];
}

- (void)setTitle:(NSString *)title forState:(__FWPullRefreshState)state {
    if(!title)
        title = @"";
    
    if(state == __FWPullRefreshStateAll)
        [self.titles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[title, title, title]];
    else
        [self.titles replaceObjectAtIndex:state withObject:title];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSubtitle:(NSString *)subtitle forState:(__FWPullRefreshState)state {
    if(!subtitle)
        subtitle = @"";
    
    if(state == __FWPullRefreshStateAll)
        [self.subtitles replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[subtitle, subtitle, subtitle]];
    else
        [self.subtitles replaceObjectAtIndex:state withObject:subtitle];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setCustomView:(UIView *)view forState:(__FWPullRefreshState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == __FWPullRefreshStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setAnimationView:(UIView<__FWProgressViewPlugin,__FWIndicatorViewPlugin> *)animationView {
    [self setCustomView:animationView forState:__FWPullRefreshStateAll];
    [self setAnimationProgressBlock:^(__FWPullRefreshView *view, CGFloat progress) {
        if (view.state == __FWPullRefreshStateLoading) return;
        animationView.progress = progress;
    }];
    [self setAnimationStateBlock:^(__FWPullRefreshView *view, __FWPullRefreshState state) {
        if (state == __FWPullRefreshStateIdle) {
            [animationView stopAnimating];
        } else if (state == __FWPullRefreshStateLoading) {
            [animationView startAnimating];
        }
    }];
}

- (void)setShowsTitleLabel:(BOOL)showsTitleLabel {
    _showsTitleLabel = showsTitleLabel;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setShowsArrowView:(BOOL)showsArrowView {
    _showsArrowView = showsArrowView;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setTextColor:(UIColor *)newTextColor {
    textColor = newTextColor;
    self.titleLabel.textColor = newTextColor;
    self.subtitleLabel.textColor = newTextColor;
}

- (void)setIndicatorView:(UIView<__FWIndicatorViewPlugin> *)indicatorView {
    UIColor *indicatorColor = self.indicatorView.color;
    [_indicatorView removeFromSuperview];
    _indicatorView = indicatorView;
    _indicatorView.color = indicatorColor;
    [self addSubview:_indicatorView];
    
    if (![_indicatorView isKindOfClass:[UIActivityIndicatorView class]]) {
        _showsTitleLabel = NO;
        _showsArrowView = NO;
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    self.indicatorView.color = indicatorColor;
}

- (void)setIndicatorPadding:(CGFloat)indicatorPadding {
    _indicatorPadding = indicatorPadding;
    [self setNeedsLayout];
}

- (void)setPullingPercent:(CGFloat)pullingPercent {
    _pullingPercent = pullingPercent;
    self.alpha = self.shouldChangeAlpha ? pullingPercent : 1;
    
    if (pullingPercent > 0 && !self.showsArrowView) {
        id customView = [self.viewForState objectAtIndex:self.state];
        BOOL hasCustomView = [customView isKindOfClass:[UIView class]];
        if (!hasCustomView && !self.indicatorView.isAnimating) {
            [self.indicatorView startAnimating];
        }
    }
}

#pragma mark -

- (void)startAnimating{
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -(self.frame.size.height + self.originalInset.top)) animated:YES];
    
    self.state = __FWPullRefreshStateLoading;
}

- (void)stopAnimating {
    if (!self.isAnimating) return;
    
    self.state = __FWPullRefreshStateIdle;
    
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalInset.top) animated:YES];
}

- (BOOL)isAnimating {
    return self.state != __FWPullRefreshStateIdle;
}

- (void)setState:(__FWPullRefreshState)newState {
    
    if(_state == newState)
        return;
    
    __FWPullRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case __FWPullRefreshStateAll:
        case __FWPullRefreshStateIdle:
            [self resetScrollViewContentInset];
            break;
            
        case __FWPullRefreshStateTriggered:
            self.isActive = YES;
            break;
            
        case __FWPullRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == __FWPullRefreshStateTriggered) {
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
    
    if(self.animationStateBlock) self.animationStateBlock(self, newState);
    if(self.stateBlock) self.stateBlock(self, newState);
}

- (void)rotateArrow:(float)degrees hide:(BOOL)hide {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.arrowView.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
        self.arrowView.layer.opacity = !hide;
    } completion:NULL];
}

@end

#pragma mark - __FWInfiniteScrollView

@implementation __FWInfiniteScrollView

// public properties
@synthesize infiniteScrollBlock, indicatorColor;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize indicatorView = _indicatorView;
@synthesize finishedLabel = _finishedLabel;
@synthesize finishedView = _finishedView;

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = __FWInfiniteScrollStateIdle;
        self.enabled = YES;
        
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.__fw_showInfiniteScroll) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView.panGestureRecognizer __fw_unobserveProperty:@"state" target:self action:@selector(gestureRecognizer:stateChanged:)];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGPoint indicatorOrigin = CGPointMake(self.bounds.size.width / 2 - self.indicatorView.bounds.size.width / 2, self.indicatorPadding > 0 ? self.indicatorPadding : (self.bounds.size.height / 2 - self.indicatorView.bounds.size.height / 2));
    self.indicatorView.frame = CGRectMake(indicatorOrigin.x, indicatorOrigin.y, self.indicatorView.bounds.size.width, self.indicatorView.bounds.size.height);
    
    CGPoint finishedOrigin = CGPointMake(self.bounds.size.width / 2 - self.finishedView.bounds.size.width / 2, self.finishedPadding > 0 ? self.finishedPadding : (self.bounds.size.height / 2 - self.finishedView.bounds.size.height / 2));
    self.finishedView.frame = CGRectMake(finishedOrigin.x, finishedOrigin.y, self.finishedView.bounds.size.width, self.finishedView.bounds.size.height);
}

#pragma mark - Static

+ (CGFloat)height {
    return __FWInfiniteScrollViewHeight;
}

+ (void)setHeight:(CGFloat)height {
    __FWInfiniteScrollViewHeight = height;
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalInset.bottom;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalInset.bottom + self.scrollView.__fw_infiniteScrollHeight;
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
        if (self.finished) return;
        
        CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
        if (self.scrollView.__fw_pullRefreshView.isActive ||
            (contentOffset.y + ceil(self.scrollView.adjustedContentInset.top) - self.scrollView.contentInset.top) < 0) {
            if (self.state != __FWInfiniteScrollStateIdle) {
                self.state = __FWInfiniteScrollStateIdle;
            }
        } else if (self.state != __FWInfiniteScrollStateLoading && self.enabled) {
            [self scrollViewDidScroll:contentOffset];
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, self.scrollView.__fw_infiniteScrollHeight);
    }
}

- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change {
    if (self.finished) return;
    
    UIGestureRecognizerState state = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
    if (state == UIGestureRecognizerStateBegan) {
        self.isActive = NO;
        self.scrollView.__fw_pullRefreshView.isActive = NO;
    } else if (state == UIGestureRecognizerStateEnded && self.state == __FWInfiniteScrollStateTriggered) {
        if ((self.scrollView.contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) >= 0) {
            self.state = __FWInfiniteScrollStateLoading;
        } else {
            self.state = __FWInfiniteScrollStateIdle;
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat adjustedContentOffsetY = contentOffset.y + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top);
    if(self.animationProgressBlock || self.progressBlock) {
        CGFloat scrollHeight = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) + self.scrollView.contentInset.bottom, self.scrollView.__fw_infiniteScrollHeight);
        CGFloat progress = (self.scrollView.__fw_infiniteScrollHeight + adjustedContentOffsetY - scrollHeight) / self.scrollView.__fw_infiniteScrollHeight;
        if(self.animationProgressBlock) self.animationProgressBlock(self, MAX(MIN(progress, 1.f), 0.f));
        if(self.progressBlock) self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    }
    
    CGFloat scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) - self.preloadHeight, 0);
    if(!self.scrollView.isDragging && self.state == __FWInfiniteScrollStateTriggered)
        self.state = __FWInfiniteScrollStateLoading;
    else if(adjustedContentOffsetY > scrollOffsetThreshold && self.state == __FWInfiniteScrollStateIdle && self.scrollView.isDragging) {
        self.state = __FWInfiniteScrollStateTriggered;
        self.userTriggered = YES;
    } else if(adjustedContentOffsetY < scrollOffsetThreshold && self.state != __FWInfiniteScrollStateIdle)
        self.state = __FWInfiniteScrollStateIdle;
}

#pragma mark - Getters

- (UIView<__FWIndicatorViewPlugin> *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [UIView __fw_indicatorViewWithStyle:__FWIndicatorViewStyleRefresh];
        _indicatorView.color = UIColor.grayColor;
        [self addSubview:_indicatorView];
    }
    return _indicatorView;
}

- (UIColor *)indicatorColor {
    return self.indicatorView.color;
}

- (UILabel *)finishedLabel {
    if (!_finishedLabel) {
        _finishedLabel = [[UILabel alloc] init];
        _finishedLabel.font = [UIFont systemFontOfSize:14];
        _finishedLabel.textAlignment = NSTextAlignmentCenter;
        _finishedLabel.textColor = [UIColor grayColor];
        _finishedLabel.text = __FWAppBundle.refreshFinishedTitle;
        [_finishedLabel sizeToFit];
    }
    return _finishedLabel;
}

- (UIView *)finishedView {
    if (!_finishedView) {
        _finishedView = self.finishedLabel;
        _finishedView.hidden = YES;
        [self addSubview:_finishedView];
    }
    return _finishedView;
}

#pragma mark - Setters

- (void)setCustomView:(UIView *)view forState:(__FWInfiniteScrollState)state {
    id viewPlaceholder = view;
    
    if(!viewPlaceholder)
        viewPlaceholder = @"";
    
    if(state == __FWInfiniteScrollStateAll)
        [self.viewForState replaceObjectsInRange:NSMakeRange(0, 3) withObjectsFromArray:@[viewPlaceholder, viewPlaceholder, viewPlaceholder]];
    else
        [self.viewForState replaceObjectAtIndex:state withObject:viewPlaceholder];
    
    self.state = self.state;
}

- (void)setAnimationView:(UIView<__FWProgressViewPlugin,__FWIndicatorViewPlugin> *)animationView {
    [self setCustomView:animationView forState:__FWInfiniteScrollStateAll];
    [self setAnimationProgressBlock:^(__FWInfiniteScrollView *view, CGFloat progress) {
        if (view.state == __FWInfiniteScrollStateLoading) return;
        animationView.progress = progress;
    }];
    [self setAnimationStateBlock:^(__FWInfiniteScrollView *view, __FWInfiniteScrollState state) {
        if (state == __FWInfiniteScrollStateIdle) {
            [animationView stopAnimating];
        } else if (state == __FWInfiniteScrollStateLoading) {
            [animationView startAnimating];
        }
    }];
}

- (void)setIndicatorView:(UIView<__FWIndicatorViewPlugin> *)indicatorView {
    UIColor *indicatorColor = self.indicatorView.color;
    [_indicatorView removeFromSuperview];
    _indicatorView = indicatorView;
    _indicatorView.color = indicatorColor;
    [self addSubview:_indicatorView];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    self.indicatorView.color = indicatorColor;
}

- (void)setIndicatorPadding:(CGFloat)indicatorPadding {
    _indicatorPadding = indicatorPadding;
    [self setNeedsLayout];
}

- (void)setFinishedView:(UIView *)finishedView {
    [_finishedView removeFromSuperview];
    _finishedView = finishedView;
    _finishedView.hidden = YES;
    [self addSubview:_finishedView];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setFinishedPadding:(CGFloat)finishedPadding {
    _finishedPadding = finishedPadding;
    [self setNeedsLayout];
}

- (void)setFinished:(BOOL)finished {
    _finished = finished;
    self.finishedView.hidden = !finished;
}

#pragma mark -

- (void)startAnimating{
    self.state = __FWInfiniteScrollStateLoading;
}

- (void)stopAnimating {
    self.state = __FWInfiniteScrollStateIdle;
}

- (BOOL)isAnimating {
    return self.state != __FWInfiniteScrollStateIdle;
}

- (void)setState:(__FWInfiniteScrollState)newState {
    
    if(_state == newState)
        return;
    
    __FWInfiniteScrollState previousState = _state;
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
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), self.indicatorPadding > 0 ? self.indicatorPadding : roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case __FWInfiniteScrollStateIdle:
                // remove current custom view if not changed
                if (!customViewChanged) {
                    [self.currentCustomView removeFromSuperview];
                    self.currentCustomView = nil;
                }
                break;
            case __FWInfiniteScrollStateTriggered:
                self.isActive = YES;
                break;
            case __FWInfiniteScrollStateLoading:
            default:
                break;
        }
    }
    else {
        CGRect viewBounds = [self.indicatorView bounds];
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), self.indicatorPadding > 0 ? self.indicatorPadding : roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [self.indicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case __FWInfiniteScrollStateIdle:
                [self.indicatorView stopAnimating];
                break;
                
            case __FWInfiniteScrollStateTriggered:
                self.isActive = YES;
                [self.indicatorView startAnimating];
                break;
                
            case __FWInfiniteScrollStateLoading:
                [self.indicatorView startAnimating];
                break;
                
            default:
                break;
        }
    }
    
    if(previousState == __FWInfiniteScrollStateTriggered && newState == __FWInfiniteScrollStateLoading && self.enabled) {
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
    
    if(self.animationStateBlock) self.animationStateBlock(self, newState);
    if(self.stateBlock) self.stateBlock(self, newState);
}

@end
