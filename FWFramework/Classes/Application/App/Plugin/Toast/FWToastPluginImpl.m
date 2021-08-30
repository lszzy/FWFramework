/*!
 @header     FWToastPluginImpl.m
 @indexgroup FWFramework
 @brief      FWToastPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPluginImpl.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
#import "FWPlugin.h"
#import "FWProxy.h"
#import <objc/runtime.h>

#pragma mark - FWToastView

@interface FWToastView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *firstView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) FWProgressView *progressView;

@property (nonatomic, strong) NSTimer *hideTimer;

@end

@implementation FWToastView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithType:FWToastViewTypeCustom];
}

- (instancetype)initWithType:(FWToastViewType)type
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _type = type;
        _contentBackgroundColor = [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
        _contentMarginInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        _contentInsets = UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f);
        _contentSpacing = 5.f;
        _contentCornerRadius = 5.f;
        _verticalOffset = -30;
        if (@available(iOS 13.0, *)) {
            _indicatorStyle = UIActivityIndicatorViewStyleMedium;
        } else {
            _indicatorStyle = UIActivityIndicatorViewStyleWhite;
        }
        _indicatorColor = [UIColor whiteColor];
        if (type == FWToastViewTypeProgress) {
            _indicatorSize = CGSizeMake(37.f, 37.f);
        } else {
            _indicatorSize = CGSizeZero;
        }
        _titleFont = [UIFont systemFontOfSize:16];
        _titleColor = [UIColor whiteColor];
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        [self setupTypeView];
    }
    return self;
}

- (void)setupTypeView
{
    _contentView = [UIView fwAutoLayoutView];
    _contentView.userInteractionEnabled = NO;
    _contentView.layer.masksToBounds = YES;
    [self addSubview:_contentView];
    
    _titleLabel = [UILabel fwAutoLayoutView];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 0;
    [_contentView addSubview:_titleLabel];
    
    switch (self.type) {
        case FWToastViewTypeImage: {
            _imageView = [UIImageView fwAutoLayoutView];
            _imageView.userInteractionEnabled = NO;
            _imageView.backgroundColor = [UIColor clearColor];
            [_contentView addSubview:_imageView];
            break;
        }
        case FWToastViewTypeIndicator: {
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:_indicatorStyle];
            _indicatorView.userInteractionEnabled = NO;
            [_contentView addSubview:_indicatorView];
            break;
        }
        case FWToastViewTypeProgress: {
            _progressView = [FWProgressView fwAutoLayoutView];
            _progressView.backgroundColor = [UIColor clearColor];
            _progressView.userInteractionEnabled = NO;
            [_contentView addSubview:_progressView];
            break;
        }
        case FWToastViewTypeText:
        case FWToastViewTypeCustom:
        default: {
            break;
        }
    }
}

- (void)updateTypeView
{
    self.contentView.backgroundColor = self.contentBackgroundColor;
    self.contentView.layer.cornerRadius = self.contentCornerRadius;
    [self.contentView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
    [self.contentView fwAlignAxisToSuperview:NSLayoutAttributeCenterY withOffset:self.verticalOffset];
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentMarginInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentMarginInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentMarginInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentMarginInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
    
    self.titleLabel.font = self.titleFont;
    self.titleLabel.textColor = self.titleColor;
    self.titleLabel.attributedText = self.attributedTitle;
    
    switch (self.type) {
        case FWToastViewTypeCustom: {
            self.firstView = self.customView;
            if (self.customView && !self.customView.superview) {
                [self.contentView addSubview:self.customView];
            }
            break;
        }
        case FWToastViewTypeImage: {
            self.firstView = self.imageView;
            self.imageView.image = self.indicatorImage;
            break;
        }
        case FWToastViewTypeIndicator: {
            self.firstView = self.indicatorView;
            self.indicatorView.activityIndicatorViewStyle = self.indicatorStyle;
            self.indicatorView.color = self.indicatorColor;
            break;
        }
        case FWToastViewTypeProgress: {
            self.firstView = self.progressView;
            self.progressView.progressTintColor = self.indicatorColor;
            break;
        }
        case FWToastViewTypeText:
        default: {
            break;
        }
    }
    
    if (!self.firstView) {
        [self.titleLabel fwPinEdgesToSuperviewWithInsets:self.contentInsets];
        return;
    }
    
    if (self.indicatorSize.width > 0 && self.indicatorSize.height > 0) {
        [self.firstView fwSetDimensionsToSize:self.indicatorSize];
    }
    if (self.firstView && [self.firstView respondsToSelector:@selector(startAnimating)]) {
        [(UIView<FWToastLoadingViewProtocol> *)self.firstView startAnimating];
    }
    
    if (self.horizontalAlignment) {
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left];
        [self.firstView fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right];
        [self.titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterY];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top relation:NSLayoutRelationGreaterThanOrEqual];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom relation:NSLayoutRelationGreaterThanOrEqual];
        self.titleLabel.fwAutoCollapse = YES;
        NSLayoutConstraint *collapseConstraint = [self.titleLabel fwPinEdge:NSLayoutAttributeLeft toEdge:NSLayoutAttributeRight ofView:self.firstView withOffset:self.contentSpacing];
        [self.titleLabel fwAddCollapseConstraint:collapseConstraint];
    // 上下布局
    } else {
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeTop withInset:self.contentInsets.top];
        [self.firstView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [self.firstView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom withInset:self.contentInsets.bottom];
        [self.titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.contentInsets.left relation:NSLayoutRelationGreaterThanOrEqual];
        [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.contentInsets.right relation:NSLayoutRelationGreaterThanOrEqual];
        self.titleLabel.fwAutoCollapse = YES;
        NSLayoutConstraint *collapseConstraint = [self.titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.firstView withOffset:self.contentSpacing];
        [self.titleLabel fwAddCollapseConstraint:collapseConstraint];
    }
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = attributedTitle;
    self.titleLabel.attributedText = attributedTitle;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    UIView *progressView = self.progressView ?: self.customView;
    if (progressView && [progressView respondsToSelector:@selector(setProgress:)]) {
        [(UIView<FWProgressViewProtocol> *)progressView setProgress:progress];
    }
}

#pragma mark - Public

- (void)show
{
    [self showAnimated:NO];
}

- (void)showAnimated:(BOOL)animated
{
    [self updateTypeView];
    
    if (animated) {
        self.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1.0;
        } completion:NULL];
    }
}

- (BOOL)hide
{
    if (self.superview != nil) {
        [self removeFromSuperview];
        [self invalidateTimer];
        
        return YES;
    }
    return NO;
}

- (BOOL)hideAfterDelay:(NSTimeInterval)delay completion:(void (^)(void))completion
{
    if (self.superview != nil) {
        [self invalidateTimer];
        __weak __typeof__(self) self_weak_ = self;
        self.hideTimer = [NSTimer fwCommonTimerWithTimeInterval:delay block:^(NSTimer *timer) {
            __typeof__(self) self = self_weak_;
            BOOL hideSuccess = [self hide];
            if (hideSuccess && completion) {
                completion();
            }
        } repeats:NO];
    }
    return NO;
}

- (void)invalidateTimer
{
    if (self.hideTimer) {
        [self.hideTimer invalidate];
        self.hideTimer = nil;
    }
}

@end

#pragma mark - FWToastPluginImpl

@implementation FWToastPluginImpl

+ (FWToastPluginImpl *)sharedInstance
{
    static FWToastPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWToastPluginImpl alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fadeAnimated = YES;
        _delayTime = 2.0;
    }
    return self;
}

- (void)fwShowLoadingWithAttributedText:(NSAttributedString *)attributedText inView:(UIView *)view
{
    NSAttributedString *loadingText = attributedText;
    if (!loadingText && self.defaultLoadingText) {
        loadingText = self.defaultLoadingText();
    }
    
    FWToastView *toastView = [view viewWithTag:2011];
    if (toastView) {
        [toastView invalidateTimer];
        [view bringSubviewToFront:toastView];
        toastView.attributedTitle = loadingText;
        return;
    }
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeIndicator];
    toastView.tag = 2011;
    toastView.attributedTitle = loadingText;
    [view addSubview:toastView];
    [toastView fwPinEdgesToSuperviewWithInsets:view.fwToastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)fwHideLoading:(UIView *)view
{
    FWToastView *toastView = [view viewWithTag:2011];
    if (toastView) [toastView hide];
}

- (void)fwShowProgressWithAttributedText:(NSAttributedString *)attributedText progress:(CGFloat)progress inView:(UIView *)view
{
    NSAttributedString *progressText = attributedText;
    if (!progressText && self.defaultProgressText) {
        progressText = self.defaultProgressText();
    }
    
    FWToastView *toastView = [view viewWithTag:2012];
    if (toastView) {
        [toastView invalidateTimer];
        [view bringSubviewToFront:toastView];
        toastView.attributedTitle = progressText;
        toastView.progress = progress;
        return;
    }
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeProgress];
    toastView.tag = 2012;
    toastView.attributedTitle = progressText;
    toastView.progress = progress;
    [view addSubview:toastView];
    [toastView fwPinEdgesToSuperviewWithInsets:view.fwToastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:self.fadeAnimated];
}

- (void)fwHideProgress:(UIView *)view
{
    FWToastView *toastView = [view viewWithTag:2012];
    if (toastView) [toastView hide];
}

- (void)fwShowMessageWithAttributedText:(NSAttributedString *)attributedText style:(FWToastStyle)style completion:(void (^)(void))completion inView:(UIView *)view
{
    NSAttributedString *messageText = attributedText;
    if (!messageText && self.defaultMessageText) {
        messageText = self.defaultMessageText(style);
    }
    
    FWToastView *toastView = [view viewWithTag:2013];
    BOOL fadeAnimated = self.fadeAnimated && !toastView;
    if (toastView) [toastView hide];
    
    toastView = [[FWToastView alloc] initWithType:FWToastViewTypeText];
    toastView.tag = 2013;
    toastView.userInteractionEnabled = completion ? YES : NO;
    toastView.attributedTitle = messageText;
    [view addSubview:toastView];
    [toastView fwPinEdgesToSuperviewWithInsets:view.fwToastInsets];
    
    if (self.customBlock) {
        self.customBlock(toastView);
    }
    [toastView showAnimated:fadeAnimated];
    [toastView hideAfterDelay:self.delayTime completion:completion];
}

- (void)fwHideMessage:(UIView *)view
{
    FWToastView *toastView = [view viewWithTag:2013];
    if (toastView) [toastView hide];
}

@end
