//
//  FWIndicatorControl.m
//  FWFramework
//
//  Created by wuyong on 17/3/24.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWIndicatorControl.h"
#import "UIView+FWAutoLayout.h"
#import "UIImageView+FWFramework.h"
#import "FWProxy.h"

@interface FWIndicatorProgressView : UIView

@property (nonatomic, strong) UIColor *progressColor;

@property (nonatomic, assign) float progress;

@end

@implementation FWIndicatorProgressView

- (void)drawRect:(CGRect)rect
{
    // Draw background
    CGFloat lineWidth = 2.f;
    UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
    processBackgroundPath.lineWidth = lineWidth;
    processBackgroundPath.lineCapStyle = kCGLineCapButt;
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat radius = (self.bounds.size.width - lineWidth)/2;
    CGFloat startAngle = - ((float)M_PI / 2); // 90 degrees
    CGFloat endAngle = (2 * (float)M_PI) + startAngle;
    [processBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [[self.progressColor colorWithAlphaComponent:0.1] set];
    [processBackgroundPath stroke];
    // Draw progress
    UIBezierPath *processPath = [UIBezierPath bezierPath];
    processPath.lineCapStyle = kCGLineCapSquare;
    processPath.lineWidth = lineWidth;
    endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
    [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [self.progressColor set];
    [processPath stroke];
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

@end

@interface FWIndicatorControl ()

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@property (nonatomic, strong) FWIndicatorProgressView *progressView;

@property (nonatomic, weak) NSTimer *hideTimer;

@property (nonatomic, assign) BOOL isShow;

@end

@implementation FWIndicatorControl

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithType:FWIndicatorControlTypeCustom];
}

- (instancetype)initWithType:(FWIndicatorControlType)type
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // 屏蔽视图点击事件
        self.userInteractionEnabled = YES;
        // 默认透明，如果需要遮住子视图，设置此颜色
        self.backgroundColor = [UIColor clearColor];
        // 默认透明度，需调用show显示
        self.alpha = 0.0f;
        
        // 初始化内容视图
        _contentView = [UIView fwAutoLayoutView];
        _contentView.userInteractionEnabled = NO;
        _contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
        _contentView.layer.cornerRadius = 5.f;
        _contentView.layer.masksToBounds = YES;
        [self addSubview:_contentView];
        [_contentView fwAlignCenterToSuperview];
        
        // 设置默认参数
        _type = type;
        _paddingWidth = 10.f;
        _contentInsets = UIEdgeInsetsMake(10.f, 20.f, 10.f, 20.f);
        _contentSpacing = 5.f;
        _indicatorSize = CGSizeMake(37.f, 37.f);
        _indicatorColor = [UIColor whiteColor];
        _indicatorStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _progress = 0.f;
    }
    return self;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = attributedTitle;
    if (self.titleLabel) {
        [self updateTitleLabel];
    }
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    if (self.progressView) {
        self.progressView.progress = progress;
    }
}

#pragma mark - Public

- (void)show:(BOOL)animated
{
    if (self.isShow) {
        return;
    }
    
    self.isShow = YES;
    [self setupTypeView];
    
    if (self.superview) {
        [self fwPinEdgesToSuperview];
    }
    
    [self setNeedsDisplay];
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.30];
        self.alpha = 1.0f;
        self.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    } else {
        self.alpha = 1.0f;
    }
}

- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay
{
    NSTimer *hideTimer = [NSTimer timerWithTimeInterval:delay target:[FWWeakProxy proxyWithTarget:self] selector:@selector(hideAfterDelay:) userInfo:@(animated) repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:hideTimer forMode:NSRunLoopCommonModes];
    self.hideTimer = hideTimer;
}

- (void)hideAfterDelay:(NSTimer *)timer
{
    [self hide:[timer.userInfo boolValue]];
}

- (void)hide:(BOOL)animated
{
    if (!self.isShow) {
        return;
    }
    
    self.isShow = NO;
    if (self.hideTimer) {
        [self.hideTimer invalidate];
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.30];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        self.transform = CGAffineTransformIdentity;
        self.alpha = 0.02f;
        [UIView commitAnimations];
    } else {
        self.alpha = 0.0f;
        [self completion];
    }
}

#pragma mark - Private

- (void)setupTypeView
{
    // 设置左右最小间距
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    [self.contentView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:self.paddingWidth relation:NSLayoutRelationGreaterThanOrEqual];
    
    // 根据类型创建子视图
    switch (self.type) {
        case FWIndicatorControlTypeText: {
            self.titleLabel = [UILabel fwAutoLayoutView];
            self.titleLabel.textColor = self.indicatorColor;
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.numberOfLines = 0;
            [self.contentView addSubview:self.titleLabel];
            [self.titleLabel fwPinEdgesToSuperviewWithInsets:self.contentInsets];
            [self updateTitleLabel];
            break;
        }
        case FWIndicatorControlTypeImage: {
            UIView *centerView = [UIView fwAutoLayoutView];
            centerView.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:centerView];
            [centerView fwPinEdgesToSuperviewWithInsets:self.contentInsets];
            
            self.imageView = [UIImageView fwAutoLayoutView];
            self.imageView.userInteractionEnabled = NO;
            self.imageView.backgroundColor = [UIColor clearColor];
            self.imageView.fwImage = self.indicatorImage;
            [centerView addSubview:self.imageView];
            [self.imageView fwSetDimensionsToSize:self.indicatorSize];
            [self.imageView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.imageView fwPinEdgeToSuperview:NSLayoutAttributeTop];
            [self.imageView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            [self.imageView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            
            self.titleLabel = [UILabel fwAutoLayoutView];
            self.titleLabel.textColor = self.indicatorColor;
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.numberOfLines = 0;
            [centerView addSubview:self.titleLabel];
            [self.titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            NSLayoutConstraint *heightConstraint = [self.titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.imageView withOffset:self.contentSpacing];
            [self.titleLabel fwSetConstraint:heightConstraint forKey:@(NSLayoutAttributeHeight)];
            
            [self updateTitleLabel];
            break;
        }
        case FWIndicatorControlTypeActivity: {
            UIView *centerView = [UIView fwAutoLayoutView];
            centerView.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:centerView];
            [centerView fwPinEdgesToSuperviewWithInsets:self.contentInsets];
            
            self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.indicatorStyle];
            self.activityView.userInteractionEnabled = NO;
            self.activityView.color = self.indicatorColor;
            [centerView addSubview:self.activityView];
            [self.activityView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.activityView fwPinEdgeToSuperview:NSLayoutAttributeTop];
            
            self.titleLabel = [UILabel fwAutoLayoutView];
            self.titleLabel.textColor = self.indicatorColor;
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.numberOfLines = 0;
            [centerView addSubview:self.titleLabel];
            [self.titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.titleLabel fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeTop];
            [self.titleLabel fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:self.activityView withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            NSLayoutConstraint *heightConstraint = [self.titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.activityView withOffset:self.contentSpacing];
            [self.titleLabel fwSetConstraint:heightConstraint forKey:@(NSLayoutAttributeHeight)];
            
            [self updateTitleLabel];
            [self.activityView startAnimating];
            break;
        }
        case FWIndicatorControlTypeProgress: {
            UIView *centerView = [UIView fwAutoLayoutView];
            centerView.backgroundColor = [UIColor clearColor];
            [self.contentView addSubview:centerView];
            [centerView fwPinEdgesToSuperviewWithInsets:self.contentInsets];
            
            self.progressView = [FWIndicatorProgressView fwAutoLayoutView];
            self.progressView.backgroundColor = [UIColor clearColor];
            self.progressView.userInteractionEnabled = NO;
            self.progressView.progressColor = self.indicatorColor;
            [centerView addSubview:self.progressView];
            [self.progressView fwSetDimensionsToSize:self.indicatorSize];
            [self.progressView fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.progressView fwPinEdgeToSuperview:NSLayoutAttributeTop];
            [self.progressView fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            [self.progressView fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            
            self.titleLabel = [UILabel fwAutoLayoutView];
            self.titleLabel.textColor = self.indicatorColor;
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.numberOfLines = 0;
            [centerView addSubview:self.titleLabel];
            [self.titleLabel fwAlignAxisToSuperview:NSLayoutAttributeCenterX];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeBottom];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            [self.titleLabel fwPinEdgeToSuperview:NSLayoutAttributeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
            NSLayoutConstraint *heightConstraint = [self.titleLabel fwPinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.progressView withOffset:self.contentSpacing];
            [self.titleLabel fwSetConstraint:heightConstraint forKey:@(NSLayoutAttributeHeight)];
            
            [self updateTitleLabel];
            break;
        }
        case FWIndicatorControlTypeCustom:
        default: {
            break;
        }
    }
}

- (void)updateTitleLabel
{
    self.titleLabel.attributedText = self.attributedTitle;
    
    NSLayoutConstraint *heightConstraint = [self.titleLabel fwConstraintForKey:@(NSLayoutAttributeHeight)];
    if (heightConstraint) {
        heightConstraint.constant = self.attributedTitle.length > 0 ? self.contentSpacing : 0;
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self completion];
}

- (void)completion
{
    self.alpha = 0.0;
    [self removeFromSuperview];
    
    if (self.completionBlock) {
        self.completionBlock();
    }
}

@end

#pragma mark - UIView+FWIndicatorControl

@implementation UIView (FWIndicatorControl)

@dynamic fwIndicatorControl;

- (FWIndicatorControl *)fwIndicatorControl
{
    // 返回最新添加的指示器
    NSEnumerator *subviews = [self.subviews reverseObjectEnumerator];
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[FWIndicatorControl class]]) {
            return (FWIndicatorControl *)subview;
        }
    }
    return nil;
}

- (void)setFwIndicatorControl:(FWIndicatorControl *)fwIndicatorControl
{
    if (fwIndicatorControl) {
        [self addSubview:fwIndicatorControl];
    }
}

@end
