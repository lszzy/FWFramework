//
//  FWRefreshView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWRefreshView.h"
#import "FWEmptyPlugin.h"
#import "FWViewPlugin.h"
#import "FWAppBundle.h"
#import "FWMessage.h"
#import <objc/runtime.h>

#pragma mark - FWPullRefreshArrowView

@interface FWPullRefreshArrowView : UIView

@property (nonatomic, strong) UIColor *arrowColor;

@end

@implementation FWPullRefreshArrowView

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

@property (nonatomic, strong) FWPullRefreshArrowView *arrowView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, readwrite) FWPullRefreshState state;
@property (nonatomic, assign) BOOL userTriggered;

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, copy) void (^animationStateBlock)(FWPullRefreshView *view, FWPullRefreshState state);
@property (nonatomic, copy) void (^animationProgressBlock)(FWPullRefreshView *view, CGFloat progress);

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat pullingPercent;

@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) BOOL isActive;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;

@end

#pragma mark - FWInfiniteScrollView

static CGFloat FWInfiniteScrollViewHeight = 60;

@interface FWInfiniteScrollView ()

@property (nonatomic, copy) void (^infiniteScrollBlock)(void);
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic, readwrite) FWInfiniteScrollState state;
@property (nonatomic, assign) BOOL userTriggered;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;
@property (nonatomic, copy) void (^animationStateBlock)(FWInfiniteScrollView *view, FWInfiniteScrollState state);
@property (nonatomic, copy) void (^animationProgressBlock)(FWInfiniteScrollView *view, CGFloat progress);

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) BOOL isActive;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;

@end

#pragma mark - FWPullRefreshView

@implementation FWPullRefreshView

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
        self.state = FWPullRefreshStateIdle;
        self.pullingPercent = 0;
        
        self.titles = [NSMutableArray arrayWithObjects:FWAppBundle.refreshIdleTitle,
                       FWAppBundle.refreshTriggeredTitle,
                       FWAppBundle.refreshLoadingTitle,
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
        if (scrollView.fw_showPullRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                [scrollView.panGestureRecognizer fw_unobserveProperty:@"state" target:self action:@selector(gestureRecognizer:stateChanged:)];
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
        CGFloat paddingY = self.indicatorPadding / 2;
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), paddingY + roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
    }
    else {
        switch (self.state) {
            case FWPullRefreshStateAll:
            case FWPullRefreshStateIdle: {
                [self.indicatorView stopAnimating];
                if (self.showsArrowView) {
                    [self rotateArrow:0 hide:NO];
                }
                break;
            }
            case FWPullRefreshStateTriggered: {
                if (self.showsArrowView) {
                    [self rotateArrow:(float)M_PI hide:NO];
                } else {
                    if (!self.indicatorView.isAnimating) {
                        [self.indicatorView startAnimating];
                    }
                }
                break;
            }
            case FWPullRefreshStateLoading: {
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
        CGFloat paddingY = self.indicatorPadding / 2;
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
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, paddingY + titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, paddingY + titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }else{
            CGFloat totalHeight = titleSize.height;
            CGFloat minY = (self.bounds.size.height / 2)  - (totalHeight / 2);
            
            CGFloat titleY = minY;
            self.titleLabel.frame = CGRectIntegral(CGRectMake(labelX, paddingY + titleY, titleSize.width, titleSize.height));
            self.subtitleLabel.frame = CGRectIntegral(CGRectMake(labelX, paddingY + titleY + titleSize.height + marginY, subtitleSize.width, subtitleSize.height));
        }
        
        CGFloat arrowX = (self.bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - self.arrowView.bounds.size.width) / 2;
        self.arrowView.frame = CGRectMake(arrowX, paddingY + (self.bounds.size.height / 2) - (self.arrowView.bounds.size.height / 2), self.arrowView.bounds.size.width, self.arrowView.bounds.size.height);
        
        if (self.showsArrowView) {
            self.indicatorView.center = self.arrowView.center;
        } else {
            CGPoint indicatorOrigin = CGPointMake(self.bounds.size.width / 2 - self.indicatorView.bounds.size.width / 2, paddingY + (self.bounds.size.height / 2 - self.indicatorView.bounds.size.height / 2));
            self.indicatorView.frame = CGRectMake(indicatorOrigin.x, indicatorOrigin.y, self.indicatorView.bounds.size.width, self.indicatorView.bounds.size.height);
        }
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
    [self resetScrollViewContentInsetAnimated:YES];
}

- (void)resetScrollViewContentInsetAnimated:(BOOL)animated {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalInset.top;
    [self setScrollViewContentInset:currentInsets pullingPercent:0 animated:animated];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalInset.top + self.bounds.size.height;
    [self setScrollViewContentInset:currentInsets pullingPercent:1 animated:YES];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset pullingPercent:(CGFloat)pullingPercent animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.3 : 0
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
        if (self.scrollView.fw_infiniteScrollView.isActive ||
            (contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) > 0) {
            if (self.pullingPercent > 0) self.pullingPercent = 0;
            if (self.state != FWPullRefreshStateIdle) {
                self.state = FWPullRefreshStateIdle;
            }
        } else if (self.state != FWPullRefreshStateLoading) {
            [self scrollViewDidScroll:contentOffset];
        } else {
            UIEdgeInsets currentInset = self.scrollView.contentInset;
            currentInset.top = self.originalInset.top + self.bounds.size.height;
            self.scrollView.contentInset = currentInset;
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, -self.scrollView.fw_pullRefreshHeight, self.bounds.size.width, self.scrollView.fw_pullRefreshHeight);
    }else if([keyPath isEqualToString:@"frame"]) {
        [self layoutSubviews];
    }
}

- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change {
    UIGestureRecognizerState state = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
    if (state == UIGestureRecognizerStateBegan) {
        self.isActive = NO;
        self.scrollView.fw_infiniteScrollView.isActive = NO;
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat adjustedContentOffsetY = contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top;
    CGFloat progress = -adjustedContentOffsetY / self.scrollView.fw_pullRefreshHeight;
    if(progress > 0) self.isActive = YES;
    if(self.animationProgressBlock) self.animationProgressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    if(self.progressBlock) self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    
    CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalInset.top;
    if(!self.scrollView.isDragging && self.state == FWPullRefreshStateTriggered)
        self.state = FWPullRefreshStateLoading;
    else if(adjustedContentOffsetY < scrollOffsetThreshold && self.scrollView.isDragging && self.state == FWPullRefreshStateIdle) {
        self.state = FWPullRefreshStateTriggered;
        self.userTriggered = YES;
    } else if(adjustedContentOffsetY >= scrollOffsetThreshold && self.state != FWPullRefreshStateIdle)
        self.state = FWPullRefreshStateIdle;
    else if(adjustedContentOffsetY >= scrollOffsetThreshold && self.state == FWPullRefreshStateIdle)
        self.pullingPercent = MAX(MIN(-adjustedContentOffsetY / self.scrollView.fw_pullRefreshHeight, 1.f), 0.f);
}

#pragma mark - Getters

- (FWPullRefreshArrowView *)arrowView {
    if(!_arrowView) {
        _arrowView = [[FWPullRefreshArrowView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-47, 15, 40)];
        _arrowView.backgroundColor = [UIColor clearColor];
        [self addSubview:_arrowView];
    }
    return _arrowView;
}

- (UIView<FWIndicatorViewPlugin> *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [UIView fw_indicatorViewWithStyle:FWIndicatorViewStyleRefresh];
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

- (void)setAnimationView:(UIView<FWProgressViewPlugin,FWIndicatorViewPlugin> *)animationView {
    [self setCustomView:animationView forState:FWPullRefreshStateAll];
    [self setAnimationProgressBlock:^(FWPullRefreshView *view, CGFloat progress) {
        if (view.state == FWPullRefreshStateLoading) return;
        animationView.progress = progress;
    }];
    [self setAnimationStateBlock:^(FWPullRefreshView *view, FWPullRefreshState state) {
        if (state == FWPullRefreshStateIdle) {
            [animationView stopAnimating];
        } else if (state == FWPullRefreshStateLoading) {
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

- (void)setIndicatorView:(UIView<FWIndicatorViewPlugin> *)indicatorView {
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
    
    self.state = FWPullRefreshStateLoading;
}

- (void)stopAnimating {
    if (!self.isAnimating) return;
    
    self.state = FWPullRefreshStateIdle;
    
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalInset.top) animated:YES];
}

- (BOOL)isAnimating {
    return self.state != FWPullRefreshStateIdle;
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
        case FWPullRefreshStateIdle:
            [self resetScrollViewContentInset];
            break;
            
        case FWPullRefreshStateTriggered:
            self.isActive = YES;
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

#pragma mark - UIScrollView+FWPullRefresh

static char UIScrollViewFWPullRefreshView;

@implementation UIScrollView (FWPullRefresh)

- (void)fw_addPullRefreshWithBlock:(void (^)(void))block {
    [self fw_addPullRefreshWithBlock:block target:nil action:NULL];
}

- (void)fw_addPullRefreshWithTarget:(id)target action:(SEL)action {
    [self fw_addPullRefreshWithBlock:nil target:target action:action];
}

- (void)fw_addPullRefreshWithBlock:(void (^)(void))block target:(id)target action:(SEL)action {
    [self.fw_pullRefreshView removeFromSuperview];
    
    FWPullRefreshView *view = [[FWPullRefreshView alloc] initWithFrame:CGRectMake(0, -self.fw_pullRefreshHeight, self.bounds.size.width, self.fw_pullRefreshHeight)];
    view.pullRefreshBlock = block;
    view.target = target;
    view.action = action;
    view.scrollView = self;
    [self addSubview:view];
    
    view.originalInset = self.contentInset;
    self.fw_pullRefreshView = view;
    self.fw_showPullRefresh = YES;
}

- (void)fw_triggerPullRefresh {
    if ([self.fw_pullRefreshView isAnimating]) return;
    
    self.fw_pullRefreshView.state = FWPullRefreshStateTriggered;
    self.fw_pullRefreshView.userTriggered = NO;
    [self.fw_pullRefreshView startAnimating];
}

- (void)setFw_pullRefreshView:(FWPullRefreshView *)pullRefreshView {
    objc_setAssociatedObject(self, &UIScrollViewFWPullRefreshView,
                             pullRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
}

- (FWPullRefreshView *)fw_pullRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewFWPullRefreshView);
}

- (void)setFw_pullRefreshHeight:(CGFloat)pullRefreshHeight {
    objc_setAssociatedObject(self, @selector(fw_pullRefreshHeight), @(pullRefreshHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_pullRefreshHeight {
#if CGFLOAT_IS_DOUBLE
    CGFloat height = [objc_getAssociatedObject(self, @selector(fw_pullRefreshHeight)) doubleValue];
#else
    CGFloat height = [objc_getAssociatedObject(self, @selector(fw_pullRefreshHeight)) floatValue];
#endif
    return height > 0 ? height : FWPullRefreshViewHeight;
}

- (void)setFw_showPullRefresh:(BOOL)showPullRefresh {
    if(!self.fw_pullRefreshView)return;
    
    self.fw_pullRefreshView.hidden = !showPullRefresh;
    if(!showPullRefresh) {
        if (self.fw_pullRefreshView.isObserving) {
            [self removeObserver:self.fw_pullRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fw_pullRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.fw_pullRefreshView forKeyPath:@"frame"];
            [self.panGestureRecognizer fw_unobserveProperty:@"state" target:self.fw_pullRefreshView action:@selector(gestureRecognizer:stateChanged:)];
            [self.fw_pullRefreshView resetScrollViewContentInsetAnimated:NO];
            self.fw_pullRefreshView.isObserving = NO;
        }
    }
    else {
        if (!self.fw_pullRefreshView.isObserving) {
            [self addObserver:self.fw_pullRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fw_pullRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fw_pullRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            [self.panGestureRecognizer fw_observeProperty:@"state" target:self.fw_pullRefreshView action:@selector(gestureRecognizer:stateChanged:)];
            self.fw_pullRefreshView.isObserving = YES;
            
            [self.fw_pullRefreshView setNeedsLayout];
            [self.fw_pullRefreshView layoutIfNeeded];
            self.fw_pullRefreshView.frame = CGRectMake(0, -self.fw_pullRefreshHeight, self.bounds.size.width, self.fw_pullRefreshHeight);
        }
    }
}

- (BOOL)fw_showPullRefresh {
    return !self.fw_pullRefreshView.hidden;
}

@end

#pragma mark - FWInfiniteScrollView

@implementation FWInfiniteScrollView

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
        self.state = FWInfiniteScrollStateIdle;
        self.enabled = YES;
        self.showsFinishedView = YES;
        
        self.viewForState = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.fw_showInfiniteScroll) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView.panGestureRecognizer fw_unobserveProperty:@"state" target:self action:@selector(gestureRecognizer:stateChanged:)];
                self.isObserving = NO;
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat paddingY = self.indicatorPadding / 2;
    CGPoint indicatorOrigin = CGPointMake(self.bounds.size.width / 2 - self.indicatorView.bounds.size.width / 2, paddingY + (self.bounds.size.height / 2 - self.indicatorView.bounds.size.height / 2));
    self.indicatorView.frame = CGRectMake(indicatorOrigin.x, indicatorOrigin.y, self.indicatorView.bounds.size.width, self.indicatorView.bounds.size.height);
    
    CGFloat finishedPaddingY = self.finishedPadding / 2;
    CGPoint finishedOrigin = CGPointMake(self.bounds.size.width / 2 - self.finishedView.bounds.size.width / 2, finishedPaddingY + (self.bounds.size.height / 2 - self.finishedView.bounds.size.height / 2));
    self.finishedView.frame = CGRectMake(finishedOrigin.x, finishedOrigin.y, self.finishedView.bounds.size.width, self.finishedView.bounds.size.height);
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
    [self resetScrollViewContentInsetAnimated:YES];
}

- (void)resetScrollViewContentInsetAnimated:(BOOL)animated {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalInset.bottom;
    [self setScrollViewContentInset:currentInsets animated:animated];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    [self setScrollViewContentInsetForInfiniteScrollingAnimated:YES];
}

- (void)setScrollViewContentInsetForInfiniteScrollingAnimated:(BOOL)animated {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.bottom = self.originalInset.bottom + self.scrollView.fw_infiniteScrollHeight;
    [self setScrollViewContentInset:currentInsets animated:animated];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset animated:(BOOL)animated {
    if (UIEdgeInsetsEqualToEdgeInsets(contentInset, self.scrollView.contentInset)) return;
    [UIView animateWithDuration:animated ? 0.3 : 0
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
        if (self.scrollView.fw_pullRefreshView.isActive ||
            (contentOffset.y + ceil(self.scrollView.adjustedContentInset.top) - self.scrollView.contentInset.top) < 0) {
            if (self.state != FWInfiniteScrollStateIdle) {
                self.state = FWInfiniteScrollStateIdle;
            }
        } else if (self.state != FWInfiniteScrollStateLoading && self.enabled) {
            [self scrollViewDidScroll:contentOffset];
        }
    }else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        self.frame = CGRectMake(0, self.scrollView.contentSize.height, self.bounds.size.width, self.scrollView.fw_infiniteScrollHeight);
    }
}

- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change {
    if (self.finished) return;
    
    UIGestureRecognizerState state = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
    if (state == UIGestureRecognizerStateBegan) {
        self.isActive = NO;
        self.scrollView.fw_pullRefreshView.isActive = NO;
    } else if (state == UIGestureRecognizerStateEnded && self.state == FWInfiniteScrollStateTriggered) {
        if ((self.scrollView.contentOffset.y + self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) >= 0) {
            self.state = FWInfiniteScrollStateLoading;
        } else {
            self.state = FWInfiniteScrollStateIdle;
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat adjustedContentOffsetY = contentOffset.y + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top);
    if(self.animationProgressBlock || self.progressBlock) {
        CGFloat scrollHeight = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) + self.scrollView.contentInset.bottom, self.scrollView.fw_infiniteScrollHeight);
        CGFloat progress = (self.scrollView.fw_infiniteScrollHeight + adjustedContentOffsetY - scrollHeight) / self.scrollView.fw_infiniteScrollHeight;
        if(self.animationProgressBlock) self.animationProgressBlock(self, MAX(MIN(progress, 1.f), 0.f));
        if(self.progressBlock) self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
    }
    
    CGFloat scrollOffsetThreshold = MAX(self.scrollView.contentSize.height - self.scrollView.bounds.size.height + (self.scrollView.adjustedContentInset.top - self.scrollView.contentInset.top) - self.preloadHeight, 0);
    if(!self.scrollView.isDragging && self.state == FWInfiniteScrollStateTriggered)
        self.state = FWInfiniteScrollStateLoading;
    else if(adjustedContentOffsetY > scrollOffsetThreshold && self.state == FWInfiniteScrollStateIdle && self.scrollView.isDragging) {
        self.state = FWInfiniteScrollStateTriggered;
        self.userTriggered = YES;
    } else if(adjustedContentOffsetY < scrollOffsetThreshold && self.state != FWInfiniteScrollStateIdle)
        self.state = FWInfiniteScrollStateIdle;
}

#pragma mark - Getters

- (UIView<FWIndicatorViewPlugin> *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [UIView fw_indicatorViewWithStyle:FWIndicatorViewStyleRefresh];
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
        _finishedLabel.text = FWAppBundle.refreshFinishedTitle;
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

- (void)setAnimationView:(UIView<FWProgressViewPlugin,FWIndicatorViewPlugin> *)animationView {
    [self setCustomView:animationView forState:FWInfiniteScrollStateAll];
    [self setAnimationProgressBlock:^(FWInfiniteScrollView *view, CGFloat progress) {
        if (view.state == FWInfiniteScrollStateLoading) return;
        animationView.progress = progress;
    }];
    [self setAnimationStateBlock:^(FWInfiniteScrollView *view, FWInfiniteScrollState state) {
        if (state == FWInfiniteScrollStateIdle) {
            [animationView stopAnimating];
        } else if (state == FWInfiniteScrollStateLoading) {
            [animationView startAnimating];
        }
    }];
}

- (void)setIndicatorView:(UIView<FWIndicatorViewPlugin> *)indicatorView {
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
    if (self.showsFinishedView) {
        if (_finished != finished) _finished = finished;
        self.finishedView.hidden = !finished || self.isDataEmpty;
        if (self.finishedBlock) self.finishedBlock(self, finished);
        return;
    }
    
    if (_finished == finished) return;
    _finished = finished;
    if (finished) {
        [self resetScrollViewContentInset];
    } else {
        [self setScrollViewContentInsetForInfiniteScrolling];
    }
    if (self.finishedBlock) self.finishedBlock(self, finished);
}

- (BOOL)isDataEmpty {
    if (!self.scrollView) return YES;
    if (self.emptyDataBlock) {
        return self.emptyDataBlock(self.scrollView);
    }
    return self.scrollView.fw_totalDataCount <= 0;
}

#pragma mark -

- (void)startAnimating{
    self.state = FWInfiniteScrollStateLoading;
}

- (void)stopAnimating {
    self.state = FWInfiniteScrollStateIdle;
}

- (BOOL)isAnimating {
    return self.state != FWInfiniteScrollStateIdle;
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
        CGFloat paddingY = self.indicatorPadding / 2;
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), paddingY + roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [customView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case FWInfiniteScrollStateIdle:
                // remove current custom view if not changed
                if (!customViewChanged) {
                    [self.currentCustomView removeFromSuperview];
                    self.currentCustomView = nil;
                }
                break;
            case FWInfiniteScrollStateTriggered:
                self.isActive = YES;
                break;
            case FWInfiniteScrollStateLoading:
            default:
                break;
        }
    }
    else {
        CGRect viewBounds = [self.indicatorView bounds];
        CGFloat paddingY = self.indicatorPadding / 2;
        CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), paddingY + roundf((self.bounds.size.height-viewBounds.size.height)/2));
        [self.indicatorView setFrame:CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height)];
        
        switch (newState) {
            case FWInfiniteScrollStateIdle:
                [self.indicatorView stopAnimating];
                break;
                
            case FWInfiniteScrollStateTriggered:
                self.isActive = YES;
                [self.indicatorView startAnimating];
                break;
                
            case FWInfiniteScrollStateLoading:
                [self.indicatorView startAnimating];
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
    
    if(self.animationStateBlock) self.animationStateBlock(self, newState);
    if(self.stateBlock) self.stateBlock(self, newState);
}

@end

#pragma mark - UIScrollView+FWInfiniteScroll

static char UIScrollViewFWInfiniteScrollView;

@implementation UIScrollView (FWInfiniteScroll)

- (void)fw_addInfiniteScrollWithBlock:(void (^)(void))block {
    [self fw_addInfiniteScrollWithBlock:block target:nil action:NULL];
}

- (void)fw_addInfiniteScrollWithTarget:(id)target action:(SEL)action {
    [self fw_addInfiniteScrollWithBlock:nil target:target action:action];
}

- (void)fw_addInfiniteScrollWithBlock:(void (^)(void))block target:(id)target action:(SEL)action {
    [self.fw_infiniteScrollView removeFromSuperview];
    
    FWInfiniteScrollView *view = [[FWInfiniteScrollView alloc] initWithFrame:CGRectMake(0, self.contentSize.height, self.bounds.size.width, self.fw_infiniteScrollHeight)];
    view.infiniteScrollBlock = block;
    view.target = target;
    view.action = action;
    view.scrollView = self;
    [self addSubview:view];
    
    view.originalInset = self.contentInset;
    self.fw_infiniteScrollView = view;
    self.fw_showInfiniteScroll = YES;
}

- (void)fw_triggerInfiniteScroll {
    if ([self.fw_infiniteScrollView isAnimating]) return;
    if (self.fw_infiniteScrollView.finished) return;
    
    self.fw_infiniteScrollView.state = FWInfiniteScrollStateTriggered;
    self.fw_infiniteScrollView.userTriggered = NO;
    [self.fw_infiniteScrollView startAnimating];
}

- (void)setFw_infiniteScrollView:(FWInfiniteScrollView *)infiniteScrollView {
    objc_setAssociatedObject(self, &UIScrollViewFWInfiniteScrollView,
                             infiniteScrollView,
                             OBJC_ASSOCIATION_ASSIGN);
}

- (FWInfiniteScrollView *)fw_infiniteScrollView {
    return objc_getAssociatedObject(self, &UIScrollViewFWInfiniteScrollView);
}

- (void)setFw_infiniteScrollHeight:(CGFloat)infiniteScrollHeight {
    objc_setAssociatedObject(self, @selector(fw_infiniteScrollHeight), @(infiniteScrollHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)fw_infiniteScrollHeight {
#if CGFLOAT_IS_DOUBLE
    CGFloat height = [objc_getAssociatedObject(self, @selector(fw_infiniteScrollHeight)) doubleValue];
#else
    CGFloat height = [objc_getAssociatedObject(self, @selector(fw_infiniteScrollHeight)) floatValue];
#endif
    return height > 0 ? height : FWInfiniteScrollViewHeight;
}

- (void)setFw_showInfiniteScroll:(BOOL)showInfiniteScroll {
    if(!self.fw_infiniteScrollView)return;
    
    self.fw_infiniteScrollView.hidden = !showInfiniteScroll;
    if(!showInfiniteScroll) {
        if (self.fw_infiniteScrollView.isObserving) {
            [self removeObserver:self.fw_infiniteScrollView forKeyPath:@"contentOffset"];
            [self removeObserver:self.fw_infiniteScrollView forKeyPath:@"contentSize"];
            [self.panGestureRecognizer fw_unobserveProperty:@"state" target:self.fw_infiniteScrollView action:@selector(gestureRecognizer:stateChanged:)];
            [self.fw_infiniteScrollView resetScrollViewContentInsetAnimated:NO];
            self.fw_infiniteScrollView.isObserving = NO;
        }
    }
    else {
        if (!self.fw_infiniteScrollView.isObserving) {
            [self addObserver:self.fw_infiniteScrollView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.fw_infiniteScrollView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self.panGestureRecognizer fw_observeProperty:@"state" target:self.fw_infiniteScrollView action:@selector(gestureRecognizer:stateChanged:)];
            [self.fw_infiniteScrollView setScrollViewContentInsetForInfiniteScrollingAnimated:NO];
            self.fw_infiniteScrollView.isObserving = YES;
            
            [self.fw_infiniteScrollView setNeedsLayout];
            [self.fw_infiniteScrollView layoutIfNeeded];
            self.fw_infiniteScrollView.frame = CGRectMake(0, self.contentSize.height, self.fw_infiniteScrollView.bounds.size.width, self.fw_infiniteScrollHeight);
        }
    }
}

- (BOOL)fw_showInfiniteScroll {
    return !self.fw_infiniteScrollView.hidden;
}

- (void)setFw_infiniteScrollFinished:(BOOL)finished {
    self.fw_infiniteScrollView.finished = finished;
}

- (BOOL)fw_infiniteScrollFinished {
    return self.fw_infiniteScrollView.finished;
}

- (void)fw_reloadInfiniteScroll {
    if (!self.fw_infiniteScrollView.showsFinishedView) return;
    
    BOOL finished = self.fw_infiniteScrollView.finished;
    self.fw_infiniteScrollView.finished = finished;
}

@end
