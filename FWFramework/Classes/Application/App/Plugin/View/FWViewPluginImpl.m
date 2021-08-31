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

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)setBackgroundTintColor:(UIColor *)backgroundTintColor
{
    _backgroundTintColor = backgroundTintColor;
    [self setNeedsDisplay];
}

- (void)setProgressBackgroundColor:(UIColor *)progressBackgroundColor
{
    _progressBackgroundColor = progressBackgroundColor;
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setPercentShow:(BOOL)percentShow
{
    _percentShow = percentShow;
    self.percentLabel.hidden = !percentShow;
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

- (void)setAnnular:(BOOL)annular
{
    _annular = annular;
    [self setNeedsDisplay];
}

- (void)setAnnularLineCapStyle:(CGLineCap)annularLineCapStyle
{
    _annularLineCapStyle = annularLineCapStyle;
    [self setNeedsDisplay];
}

- (void)setAnnularLineWidth:(CGFloat)annularLineWidth
{
    _annularLineWidth = annularLineWidth;
    [self setNeedsDisplay];
}

- (void)renderView
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    _progress = 0.f;
    _color = [UIColor colorWithWhite:1.f alpha:1.f];
    _progressBackgroundColor = [UIColor colorWithWhite:1.f alpha:0.1f];;
    _backgroundTintColor = [UIColor colorWithWhite:1.f alpha:0.1f];;
    
    _percentShow = NO;
    _percentTextColor =[UIColor whiteColor];
    _percentFont = [UIFont systemFontOfSize:12.f];
    
    _annular = YES;
    _annularLineCapStyle = kCGLineCapRound;
    _annularLineWidth = 3.f;
    
    _percentLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _percentLabel.adjustsFontSizeToFitWidth = NO;
    _percentLabel.textAlignment = NSTextAlignmentCenter;
    _percentLabel.opaque = NO;
    _percentLabel.backgroundColor = [UIColor clearColor];
    _percentLabel.textColor = _percentTextColor;
    _percentLabel.font = _percentFont;
    _percentLabel.text = @"0%";
    _percentLabel.hidden = !_percentShow;
    [self addSubview:_percentLabel];
}

- (void)drawRect:(CGRect)rect
{
    if (self.percentShow) {
        self.percentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.progress > 1.0f ? 100.f : self.progress * 100.f];
        self.percentLabel.textColor = self.percentTextColor;
        self.percentLabel.font = self.percentFont;
    }
    
    if (self.annular) {
        // 绘制背景
        CGFloat lineWidth = self.annularLineWidth;
        UIBezierPath *processBackgroundPath = [UIBezierPath bezierPath];
        processBackgroundPath.lineWidth = lineWidth;
        processBackgroundPath.lineCapStyle = kCGLineCapRound;
        CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
        CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) - lineWidth) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        [processBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [self.backgroundTintColor set];
        [processBackgroundPath stroke];
        
        // 绘制进度
        UIBezierPath *processPath = [UIBezierPath bezierPath];
        processPath.lineCapStyle = self.annularLineCapStyle;
        processPath.lineWidth = lineWidth;
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [processPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [self.color set];
        [processPath stroke];
    } else {
        CGRect allRect = self.bounds;
        CGRect circleRect = CGRectInset(allRect, 2.0f, 2.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // 绘制背景
        [self.color setStroke];
        [self.backgroundTintColor setFill];
        CGContextSetLineWidth(context, 2.0f);
        CGContextFillEllipseInRect(context, circleRect);
        CGContextStrokeEllipseInRect(context, circleRect);
        
        // 绘制进度
        CGPoint center = CGPointMake(allRect.size.width / 2.f, allRect.size.height / 2.f);
        CGFloat radius = (MIN(allRect.size.width, allRect.size.height) - 4) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        CGContextSetFillColorWithColor(context, self.progressBackgroundColor.CGColor);
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
