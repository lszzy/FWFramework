/*!
 @header     FWViewPluginImpl.m
 @indexgroup FWFramework
 @brief      FWViewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWViewPluginImpl.h"

#pragma mark - FWProgressView

@interface FWProgressView ()

@property (nonatomic, readonly) UILabel *percentLabel;

@end

@implementation FWProgressView

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0.f, 0.f, 37.f, 37.f)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self renderView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self renderView];
    }
    return self;
}

- (void)renderView
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    _annular = YES;
    _progress = 0.f;
    _color = [UIColor colorWithWhite:1.f alpha:1.f];
    _lineColor = nil;
    _lineWidth = 0;
    _lineCap = kCGLineCapRound;
    _fillColor = nil;
    _fillInset = 0;
    _showsPercentText = NO;
    _percentTextColor =[UIColor whiteColor];
    _percentFont = [UIFont systemFontOfSize:12.f];
    
    _percentLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _percentLabel.adjustsFontSizeToFitWidth = NO;
    _percentLabel.textAlignment = NSTextAlignmentCenter;
    _percentLabel.opaque = NO;
    _percentLabel.backgroundColor = [UIColor clearColor];
    _percentLabel.textColor = _percentTextColor;
    _percentLabel.font = _percentFont;
    _percentLabel.text = @"0%";
    _percentLabel.hidden = !_showsPercentText;
    [self addSubview:_percentLabel];
}

- (void)setAnnular:(BOOL)annular
{
    _annular = annular;
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = MAX(0.0, MIN(progress, 1.0));
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = lineColor;
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setLineCap:(CGLineCap)lineCap
{
    _lineCap = lineCap;
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)setFillInset:(CGFloat)fillInset
{
    _fillInset = fillInset;
    [self setNeedsDisplay];
}

- (void)setShowsPercentText:(BOOL)showsPercentText
{
    _showsPercentText = showsPercentText;
    self.percentLabel.hidden = !showsPercentText;
}

- (void)setPercentTextColor:(UIColor *)percentTextColor
{
    _percentTextColor = percentTextColor;
    [self setNeedsDisplay];
}

- (void)setPercentFont:(UIFont *)percentFont
{
    _percentFont = percentFont;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (self.showsPercentText) {
        self.percentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.progress * 100.f];
        self.percentLabel.textColor = self.percentTextColor;
        self.percentLabel.font = self.percentFont;
    }
    
    if (self.annular) {
        UIColor *lineColor = self.lineColor ? self.lineColor : [self.color colorWithAlphaComponent:0.1];
        CGFloat lineWidth = self.lineWidth > 0 ? self.lineWidth : 3;
        UIBezierPath *backgroundPath = [UIBezierPath bezierPath];
        backgroundPath.lineWidth = lineWidth;
        backgroundPath.lineCapStyle = kCGLineCapRound;
        CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
        CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) - lineWidth) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        [backgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [lineColor set];
        [backgroundPath stroke];
        
        if (self.fillColor) {
            UIBezierPath *fillPath = [UIBezierPath bezierPath];
            CGFloat fillRadius = (MIN(self.bounds.size.width, self.bounds.size.height) - (lineWidth + self.fillInset) * 2) / 2.f;
            [fillPath addArcWithCenter:center radius:fillRadius startAngle:startAngle endAngle:endAngle clockwise:YES];
            [self.fillColor setFill];
            [fillPath fill];
        }
        
        UIBezierPath *progessPath = [UIBezierPath bezierPath];
        progessPath.lineCapStyle = self.lineCap;
        progessPath.lineWidth = lineWidth;
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [progessPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [self.color set];
        [progessPath stroke];
    } else {
        UIColor *lineColor = self.lineColor ?: self.color;
        CGFloat lineWidth = self.lineWidth > 0 ? self.lineWidth : 1;
        CGRect allRect = self.bounds;
        CGFloat circleInset = lineWidth + self.fillInset;
        CGContextRef context = UIGraphicsGetCurrentContext();
        [lineColor setStroke];
        CGContextSetLineWidth(context, lineWidth);
        CGContextStrokeEllipseInRect(context, CGRectInset(allRect, lineWidth / 2.0, lineWidth / 2.0));
        
        if (self.fillColor) {
            [self.fillColor setFill];
            CGContextFillEllipseInRect(context, CGRectInset(allRect, circleInset, circleInset));
        }
        
        CGPoint center = CGPointMake(allRect.size.width / 2.f, allRect.size.height / 2.f);
        CGFloat radius = (MIN(allRect.size.width, allRect.size.height) - circleInset * 2) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        CGContextSetFillColorWithColor(context, self.color.CGColor);
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
        CGContextClosePath(context);
        CGContextFillPath(context);
    }
}

@end

#pragma mark - FWIndicatorView

@implementation UIActivityIndicatorView (FWIndicatorView)

@end

@interface FWIndicatorView ()

@property (nonatomic, strong) CALayer *animationLayer;

@end

@implementation FWIndicatorView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _type = FWIndicatorViewAnimationTypeDefault;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _type = FWIndicatorViewAnimationTypeDefault;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithType:(FWIndicatorViewAnimationType)type
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _type = type;
        [self setupLayer];
    }
    return self;
}

- (void)setupLayer
{
    _color = [UIColor whiteColor];
    _size = 37.f;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    
    _animationLayer = [[CALayer alloc] init];
    [self.layer addSublayer:_animationLayer];
    [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
}

- (void)setupAnimation
{
    _animationLayer.sublayers = nil;
    
    id<FWIndicatorViewAnimationProtocol> animation = [self animation];
    if ([animation respondsToSelector:@selector(setupAnimation:size:color:)]) {
        [animation setupAnimation:_animationLayer size:CGSizeMake(_size, _size) color:_color];
        _animationLayer.speed = 0.0f;
    }
}

- (void)setType:(FWIndicatorViewAnimationType)type
{
    if (_type != type) {
        _type = type;
        [self setupAnimation];
    }
}

- (void)setSize:(CGFloat)size
{
    if (_size != size) {
        _size = size;
        
        [self setupAnimation];
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        _color = color;
        [self setupAnimation];
    }
}

- (void)startAnimating
{
    if (!_animationLayer.sublayers) {
        [self setupAnimation];
    }
    self.hidden = NO;
    _animationLayer.speed = 1.0f;
    _isAnimating = YES;
}

- (void)stopAnimating
{
    _animationLayer.speed = 0.0f;
    _isAnimating = NO;
    self.hidden = YES;
}

- (id<FWIndicatorViewAnimationProtocol>)animation
{
    switch (_type) {
        case FWIndicatorViewAnimationTypeDefault:
            return nil;
        default:
            return nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _animationLayer.frame = self.bounds;
    BOOL isAnimating = _isAnimating;
    if (isAnimating) [self stopAnimating];
    [self setupAnimation];
    if (isAnimating) [self startAnimating];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(_size, _size);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(_size, _size);
}

@end

#pragma mark - FWViewPluginImpl

@implementation FWViewPluginImpl

+ (FWViewPluginImpl *)sharedInstance
{
    static FWViewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWViewPluginImpl alloc] init];
    });
    return instance;
}

- (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style
{
    if (self.progressViewCreator) {
        return self.progressViewCreator(style);
    }
    
    FWProgressView *progressView = [[FWProgressView alloc] init];
    return progressView;
}

- (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style
{
    if (self.indicatorViewCreator) {
        return self.indicatorViewCreator(style);
    }
    
    UIActivityIndicatorViewStyle indicatorStyle;
    if (@available(iOS 13.0, *)) {
        indicatorStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicatorStyle = UIActivityIndicatorViewStyleWhite;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    indicatorView.color = UIColor.whiteColor;
    indicatorView.hidesWhenStopped = YES;
    return indicatorView;
}

@end
