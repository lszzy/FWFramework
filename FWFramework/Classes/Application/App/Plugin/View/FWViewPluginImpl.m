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
    
    _progress = 0.f;
    _color = [UIColor colorWithWhite:1.f alpha:1.f];
    _annular = YES;
    _lineWidth = 3;
    _lineColor = [UIColor colorWithWhite:1.f alpha:0.1f];
    _lineCapStyle = kCGLineCapRound;
    _borderWidth = 1;
    _borderColor = [UIColor colorWithWhite:1.f alpha:1.f];
    _borderInset = 0;
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

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)setAnnular:(BOOL)annular
{
    _annular = annular;
    [self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    [self setNeedsDisplay];
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = lineColor;
    [self setNeedsDisplay];
}

- (void)setLineCapStyle:(CGLineCap)lineCapStyle
{
    _lineCapStyle = lineCapStyle;
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    [self setNeedsDisplay];
}

- (void)setBorderInset:(CGFloat)borderInset
{
    _borderInset = borderInset;
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
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
        self.percentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.progress > 1.0f ? 100.f : self.progress * 100.f];
        self.percentLabel.textColor = self.percentTextColor;
        self.percentLabel.font = self.percentFont;
    }
    
    if (self.annular) {
        CGFloat lineWidth = self.lineWidth;
        UIBezierPath *progessBackgroundPath = [UIBezierPath bezierPath];
        progessBackgroundPath.lineWidth = lineWidth;
        progessBackgroundPath.lineCapStyle = kCGLineCapRound;
        CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
        CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) - lineWidth) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        [progessBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [self.lineColor set];
        [progessBackgroundPath stroke];
        
        if (self.fillColor) {
            UIBezierPath *progessFillPath = [UIBezierPath bezierPath];
            CGFloat fillRadius = (MIN(self.bounds.size.width, self.bounds.size.height) - lineWidth * 2) / 2.f;
            [progessFillPath addArcWithCenter:center radius:fillRadius startAngle:startAngle endAngle:endAngle clockwise:YES];
            [self.fillColor setFill];
            [progessFillPath fill];
        }
        
        UIBezierPath *progessPath = [UIBezierPath bezierPath];
        progessPath.lineCapStyle = self.lineCapStyle;
        progessPath.lineWidth = lineWidth;
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [progessPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [self.color set];
        [progessPath stroke];
    } else {
        CGRect allRect = self.bounds;
        CGFloat circleInset = self.borderWidth + self.borderInset;
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self.borderColor setStroke];
        CGContextSetLineWidth(context, self.borderWidth);
        CGContextStrokeEllipseInRect(context, CGRectInset(allRect, self.borderWidth, self.borderWidth));
        
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
