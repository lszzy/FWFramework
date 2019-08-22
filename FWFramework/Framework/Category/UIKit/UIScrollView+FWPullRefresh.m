/*!
 @header     UIScrollView+FWPullRefresh.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWPullRefresh
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import "UIScrollView+FWPullRefresh.h"
#import "UIScrollView+FWInfiniteScroll.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

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

// fequal() and fequalzro() from http://stackoverflow.com/a/1614761/184130
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

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

@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, strong) NSMutableArray *viewForState;
@property (nonatomic, weak) UIView *currentCustomView;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat pullingPercent;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
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
        self.wasTriggeredByUser = YES;
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
    [self setScrollViewContentInset:currentInsets pullingPercent:0 animated:YES];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
    [self setScrollViewContentInset:currentInsets pullingPercent:1 animated:YES];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset pullingPercent:(CGFloat)pullingPercent animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.3 : 0.0
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
        
        CGFloat yOrigin = -FWPullRefreshViewHeight;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, FWPullRefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
    
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != FWPullRefreshStateLoading) {
        if(self.progressBlock) {
            CGFloat progress = 1.f - (FWPullRefreshViewHeight + contentOffset.y) / FWPullRefreshViewHeight;
            self.progressBlock(self, MAX(MIN(progress, 1.f), 0.f));
        }
        
        CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
        if(!self.scrollView.isDragging && self.state == FWPullRefreshStateTriggered)
            self.state = FWPullRefreshStateLoading;
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == FWPullRefreshStateStopped)
            self.state = FWPullRefreshStateTriggered;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != FWPullRefreshStateStopped)
            self.state = FWPullRefreshStateStopped;
        else if(contentOffset.y >= scrollOffsetThreshold && self.state == FWPullRefreshStateStopped)
            self.pullingPercent = MAX(MIN(1.f - (FWPullRefreshViewHeight + contentOffset.y) / FWPullRefreshViewHeight, 1.f), 0.f);
    } else {
        CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
        offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
        UIEdgeInsets contentInset = self.scrollView.contentInset;
        self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
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
    self.state = FWPullRefreshStateLoading;
    
    if(fequalzero(self.scrollView.contentOffset.y + self.originalTopInset)) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -(self.frame.size.height + self.originalTopInset)) animated:YES];
        self.wasTriggeredByUser = NO;
    }
    else
        self.wasTriggeredByUser = YES;
}

- (void)stopAnimating {
    self.state = FWPullRefreshStateStopped;
    
    if(!self.wasTriggeredByUser)
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
    
    CGFloat yOrigin = -FWPullRefreshViewHeight;
    FWPullRefreshView *view = [[FWPullRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, FWPullRefreshViewHeight)];
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
            
            CGFloat yOrigin = -FWPullRefreshViewHeight;
            [self.fwPullRefreshView setNeedsLayout];
            [self.fwPullRefreshView layoutIfNeeded];
            self.fwPullRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, FWPullRefreshViewHeight);
        }
    }
}

- (BOOL)fwShowPullRefresh {
    return !self.fwPullRefreshView.hidden;
}

@end
