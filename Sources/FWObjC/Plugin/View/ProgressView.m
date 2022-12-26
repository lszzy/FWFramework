//
//  ProgressView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "ProgressView.h"

#pragma mark - __FWProgressLayer

@interface __FWProgressLayer : CALayer

@property (nonatomic, assign) BOOL annular;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGLineCap lineCap;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) CGFloat fillInset;
@property (nonatomic, assign) CFTimeInterval animationDuration;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL animated;

@end

@implementation __FWProgressLayer

@dynamic annular;
@dynamic color;
@dynamic lineColor;
@dynamic lineWidth;
@dynamic lineCap;
@dynamic fillColor;
@dynamic fillInset;
@dynamic progress;

+ (BOOL)needsDisplayForKey:(NSString *)key {
    return [key isEqualToString:@"progress"] || [super needsDisplayForKey:key];
}

- (id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"progress"] && self.animated) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:event];
        animation.fromValue = [self.presentationLayer valueForKey:event];
        animation.duration = self.animationDuration;
        return animation;
    }
    return [super actionForKey:event];
}

- (void)drawInContext:(CGContextRef)context {
    if (CGRectIsEmpty(self.bounds)) return;
    
    if (self.annular) {
        UIColor *lineColor = self.lineColor ?: [self.color colorWithAlphaComponent:0.1];
        CGFloat lineWidth = self.lineWidth > 0 ? self.lineWidth : 3;
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGPoint center = CGPointMake(self.bounds.size.width / 2.f, self.bounds.size.height / 2.f);
        CGFloat radius = (MIN(self.bounds.size.width, self.bounds.size.height) - lineWidth) / 2.f;
        CGFloat startAngle = - ((float)M_PI / 2);
        CGFloat endAngle = (2 * (float)M_PI) + startAngle;
        CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 1);
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextStrokePath(context);
        
        if (self.fillColor) {
            CGFloat fillRadius = (MIN(self.bounds.size.width, self.bounds.size.height) - (lineWidth + self.fillInset) * 2) / 2.f;
            CGContextAddArc(context, center.x, center.y, fillRadius, startAngle, endAngle, 1);
            CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
            CGContextFillPath(context);
        }
        
        UIBezierPath *bezierPath = [UIBezierPath bezierPath];
        bezierPath.lineWidth = lineWidth;
        bezierPath.lineCapStyle = self.lineCap;
        endAngle = (self.progress * 2 * (float)M_PI) + startAngle;
        [bezierPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        CGContextSetStrokeColorWithColor(context, self.color.CGColor);
        CGContextAddPath(context, bezierPath.CGPath);
        CGContextStrokePath(context);
    } else {
        UIColor *lineColor = self.lineColor ?: self.color;
        CGFloat lineWidth = self.lineWidth > 0 ? self.lineWidth : 1;
        CGRect allRect = self.bounds;
        CGFloat circleInset = lineWidth + self.fillInset;
        CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
        CGContextSetLineWidth(context, lineWidth);
        CGContextStrokeEllipseInRect(context, CGRectInset(allRect, lineWidth / 2.0, lineWidth / 2.0));
        
        if (self.fillColor) {
            CGContextSetFillColorWithColor(context, self.fillColor.CGColor);
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
    
    [super drawInContext:context];
}

- (void)layoutSublayers {
    [super layoutSublayers];
    self.cornerRadius = CGRectGetHeight(self.bounds) / 2;
}

@end

#pragma mark - __FWProgressView

@implementation __FWProgressView

+ (Class)layerClass {
    return [__FWProgressLayer class];
}

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 37.f, 37.f)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize {
    self.annular = YES;
    self.color = [UIColor colorWithWhite:1.f alpha:1.f];
    self.lineColor = nil;
    self.lineWidth = 0;
    self.lineCap = kCGLineCapRound;
    self.fillColor = nil;
    self.fillInset = 0;
    self.progress = 0.f;
    self.animationDuration = 0.5;
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.contentsScale = UIScreen.mainScreen.scale;
    [self.layer setNeedsDisplay];
}

- (__FWProgressLayer *)progressLayer {
    return (__FWProgressLayer *)self.layer;
}

- (void)setAnnular:(BOOL)annular {
    _annular = annular;
    self.progressLayer.annular = annular;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    self.progressLayer.color = color;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    self.progressLayer.lineColor = lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.progressLayer.lineWidth = lineWidth;
}

- (void)setLineCap:(CGLineCap)lineCap {
    _lineCap = lineCap;
    self.progressLayer.lineCap = lineCap;
}

- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    self.progressLayer.fillColor = fillColor;
}

- (void)setFillInset:(CGFloat)fillInset {
    _fillInset = fillInset;
    self.progressLayer.fillInset = fillInset;
}

- (void)setAnimationDuration:(CFTimeInterval)animationDuration {
    _animationDuration = animationDuration;
    self.progressLayer.animationDuration = animationDuration;
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    _progress = MAX(0.0, MIN(progress, 1.0));
    self.progressLayer.animated = animated;
    self.progressLayer.progress = _progress;
}

- (CGSize)size {
    return self.bounds.size;
}

- (void)setSize:(CGSize)size {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, size.height);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self invalidateIntrinsicContentSize];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
    return self.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.bounds.size;
}

@end
