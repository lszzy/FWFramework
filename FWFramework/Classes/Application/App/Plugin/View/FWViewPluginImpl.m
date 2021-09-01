/*!
 @header     FWViewPluginImpl.m
 @indexgroup FWFramework
 @brief      FWViewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWViewPluginImpl.h"
#import <objc/runtime.h>

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

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self invalidateIntrinsicContentSize];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self invalidateIntrinsicContentSize];
}

- (void)drawRect:(CGRect)rect
{
    if (rect.size.width < 1 || rect.size.height < 1) return;
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

- (CGSize)intrinsicContentSize
{
    return self.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return self.bounds.size;
}

@end

#pragma mark - UIActivityIndicatorView+FWIndicatorView

@implementation UIActivityIndicatorView (FWIndicatorView)

- (CGFloat)progress
{
    return [objc_getAssociatedObject(self, @selector(progress)) doubleValue];
}

- (void)setProgress:(CGFloat)progress
{
    objc_setAssociatedObject(self, @selector(progress), @(progress), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (0 < progress && progress < 1) {
        if (!self.isAnimating) [self startAnimating];
    } else {
        if (self.isAnimating) [self stopAnimating];
    }
}

@end

#pragma mark - FWIndicatorViewAnimation

@interface FWIndicatorViewAnimationLineSpin : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationLineSpin

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat lineSpacing = 2;
    CGSize lineSize = CGSizeMake((size.width - lineSpacing * 4) / 5, (size.height - lineSpacing * 2) / 3);
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - size.height) / 2;
    CFTimeInterval duration = 1.2;
    CFTimeInterval beginTime = CACurrentMediaTime();
    NSArray<NSNumber *> *beginTimes = @[@0.12, @0.24, @0.36, @0.48, @0.6, @0.72, @0.84, @0.96];
    CAMediaTimingFunction *timingFuncation = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.keyTimes = @[@0, @0.5, @1];
    animation.timingFunctions = @[timingFuncation, timingFuncation];
    animation.values = @[@1, @0.3, @1];
    animation.duration = duration;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    
    for (int i = 0; i < 8; i++) {
        CALayer *containerLayer = [self createLayer:M_PI / 4 * ((double)i) size:lineSize origin:CGPointMake(x, y) containerSize:size color:color];
        animation.beginTime = beginTime + beginTimes[i].doubleValue;
        [containerLayer addAnimation:animation forKey:@"animation"];
        [layer addSublayer:containerLayer];
    }
}

- (CALayer *)createLayer:(CGFloat)angle size:(CGSize)size origin:(CGPoint)origin containerSize:(CGSize)containerSize color:(UIColor *)color
{
    CGFloat radius = containerSize.width / 2 - MAX(size.width, size.height) / 2;
    CGSize layerSize = CGSizeMake(MAX(size.width, size.height), MAX(size.width, size.height));
    CALayer *layer = [[CALayer alloc] init];
    CGRect layerFrame = CGRectMake(origin.x + radius * (cos(angle) + 1), origin.y + radius * (sin(angle) + 1), layerSize.width, layerSize.height);
    layer.frame = layerFrame;
    
    CAShapeLayer *lineLayer = [[CAShapeLayer alloc] init];
    UIBezierPath *linePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:size.width / 2];
    lineLayer.fillColor = color.CGColor;
    lineLayer.backgroundColor = nil;
    lineLayer.path = linePath.CGPath;
    lineLayer.frame = CGRectMake((layerSize.width - size.width) / 2, (layerSize.height - size.height) / 2, size.width, size.height);
    [layer addSublayer:lineLayer];
    layer.sublayerTransform = CATransform3DMakeRotation(M_PI / 2 + angle, 0, 0, 1);
    return layer;
}

@end

@interface FWIndicatorViewAnimationLinePulse : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationLinePulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat duration = 1.0f;
    NSArray *beginTimes = @[@0.4f, @0.2f, @0.0f, @0.2f, @0.4f];
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.85f :0.25f :0.37f :0.85f];
    CGFloat lineSize = size.width / 9;
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - size.height) / 2;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    animation.removedOnCompletion = NO;
    animation.keyTimes = @[@0.0f, @0.5f, @1.0f];
    animation.values = @[@1.0f, @0.4f, @1.0f];
    animation.timingFunctions = @[timingFunction, timingFunction];
    animation.repeatCount = HUGE_VALF;
    animation.duration = duration;
    
    for (int i = 0; i < 5; i++) {
        CAShapeLayer *line = [CAShapeLayer layer];
        UIBezierPath *linePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, lineSize, size.height) cornerRadius:lineSize / 2];
        animation.beginTime = [beginTimes[i] floatValue];
        line.fillColor = color.CGColor;
        line.path = linePath.CGPath;
        [line addAnimation:animation forKey:@"animation"];
        line.frame = CGRectMake(x + lineSize * 2 * i, y, lineSize, size.height);
        [layer addSublayer:line];
    }
}

@end

@interface FWIndicatorViewAnimationBallSpin : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationBallSpin

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat circleSpacing = -2;
    CGFloat circleSize = (size.width - 4 * circleSpacing) / 5;
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - size.height) / 2;
    CFTimeInterval duration = 1;
    NSTimeInterval beginTime = CACurrentMediaTime();
    NSArray *beginTimes = @[@0, @0.12, @0.24, @0.36, @0.48, @0.6, @0.72, @0.84];
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.keyTimes = @[@0, @0.5, @1];
    scaleAnimation.values = @[@1, @0.4, @1];
    scaleAnimation.duration = duration;
    
    CAKeyframeAnimation *opacityAnimaton = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimaton.removedOnCompletion = NO;
    opacityAnimaton.keyTimes = @[@0, @0.5, @1];
    opacityAnimaton.values = @[@1, @0.3, @1];
    opacityAnimaton.duration = duration;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.removedOnCompletion = NO;
    animationGroup.animations = @[scaleAnimation, opacityAnimaton];
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animationGroup.duration = duration;
    animationGroup.repeatCount = HUGE;
    
    for (int i = 0; i < 8; i++) {
        CALayer *circle = [self circleLayer:(M_PI_4 * i) size:circleSize origin:CGPointMake(x, y) containerSize:size color:color];
        animationGroup.beginTime = beginTime + [beginTimes[i] doubleValue];
        [layer addSublayer:circle];
        [circle addAnimation:animationGroup forKey:@"animation"];
    }
}

- (CALayer *)circleLayer:(CGFloat)angle size:(CGFloat)size origin:(CGPoint)origin containerSize:(CGSize)containerSize color:(UIColor *)color
{
    CGFloat radius = containerSize.width / 2;
    CALayer *circle = [self createLayerWith:CGSizeMake(size, size) color:color];
    CGRect frame = CGRectMake((origin.x + radius * (cos(angle) + 1) - size / 2), origin.y + radius * (sin(angle) + 1) - size / 2, size, size);
    circle.frame = frame;
    return circle;
}

- (CALayer *)createLayerWith:(CGSize)size color:(UIColor *)color
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointMake(size.width / 2,size.height / 2) radius:(size.width / 2) startAngle:0 endAngle:2 * M_PI clockwise:NO];
    layer.fillColor = color.CGColor;
    layer.backgroundColor = nil;
    layer.path = path.CGPath;
    return layer;
}

@end

@interface FWIndicatorViewAnimationBallRotate : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationBallRotate

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat duration = 0.75f;
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.6f, 0.6f, 1.0f)],
                              [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)]];
    scaleAnimation.keyTimes = @[@0.0f, @0.5f, @1.0f];
    
    CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.removedOnCompletion = NO;
    rotateAnimation.values = @[@0, @M_PI, @(2 * M_PI)];
    rotateAnimation.keyTimes = scaleAnimation.keyTimes;
    
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.removedOnCompletion = NO;
    animation.animations = @[scaleAnimation, rotateAnimation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.duration = duration;
    animation.repeatCount = HUGE_VALF;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width / 2, size.height / 2) radius:size.width / 2 startAngle:1.5 * M_PI endAngle:M_PI clockwise:true];
    circle.path = circlePath.CGPath;
    circle.lineWidth = 2;
    circle.fillColor = nil;
    circle.strokeColor = color.CGColor;
    circle.frame = CGRectMake((layer.bounds.size.width - size.width) / 2, (layer.bounds.size.height - size.height) / 2, size.width, size.height);
    [circle addAnimation:animation forKey:@"animation"];
    [layer addSublayer:circle];
}

@end

@interface FWIndicatorViewAnimationBallPulse : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationBallPulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat circlePadding = 5.0f;
    CGFloat circleSize = (size.width - 2 * circlePadding) / 3;
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - circleSize) / 2;
    CGFloat duration = 0.75f;
    NSArray *timeBegins = @[@0.12f, @0.24f, @0.36f];
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2f :0.68f :0.18f :1.08f];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.removedOnCompletion = NO;
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)],
                                [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.3f, 0.3f, 1.0f)],
                                [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)]];
    animation.keyTimes = @[@0.0f, @0.3f, @1.0f];
    animation.timingFunctions = @[timingFunction, timingFunction];
    animation.duration = duration;
    animation.repeatCount = HUGE_VALF;
    
    for (int i = 0; i < 3; i++) {
        CALayer *circle = [CALayer layer];
        circle.frame = CGRectMake(x + i * circleSize + i * circlePadding, y, circleSize, circleSize);
        circle.backgroundColor = color.CGColor;
        circle.cornerRadius = circle.bounds.size.width / 2;
        animation.beginTime = [timeBegins[i] floatValue];
        [circle addAnimation:animation forKey:@"animation"];
        [layer addSublayer:circle];
    }
}

@end

@interface FWIndicatorViewAnimationBallTriangle : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationBallTriangle

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CGFloat duration = 2.0f;
    CGFloat circleSize = size.width / 5;
    CGFloat deltaX = size.width / 2 - circleSize / 2;
    CGFloat deltaY = size.height / 2 - circleSize / 2;
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - size.height) / 2;
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.removedOnCompletion = NO;
    animation.keyTimes = @[@0.0f, @0.33f, @0.66f, @1.0f];
    animation.duration = duration;
    animation.timingFunctions = @[timingFunction, timingFunction, timingFunction];
    animation.repeatCount = HUGE_VALF;
    
    CALayer *topCenterCircle = [self createCircleWithSize:circleSize color:color];
    [self changeAnimation:animation values:@[@"{0,0}", @"{hx,fy}", @"{-hx,fy}", @"{0,0}"] deltaX:deltaX deltaY:deltaY];
    topCenterCircle.frame = CGRectMake(x + size.width / 2 - circleSize / 2, y, circleSize, circleSize);
    [topCenterCircle addAnimation:animation forKey:@"animation"];
    [layer addSublayer:topCenterCircle];
    
    CALayer *bottomLeftCircle = [self createCircleWithSize:circleSize color:color];
    [self changeAnimation:animation values:@[@"{0,0}", @"{hx,-fy}", @"{fx,0}", @"{0,0}"] deltaX:deltaX deltaY:deltaY];
    bottomLeftCircle.frame = CGRectMake(x, y + size.height - circleSize, circleSize, circleSize);
    [bottomLeftCircle addAnimation:animation forKey:@"animation"];
    [layer addSublayer:bottomLeftCircle];
    
    CALayer *bottomRigthCircle = [self createCircleWithSize:circleSize color:color];
    [self changeAnimation:animation values:@[@"{0,0}", @"{-fx,0}", @"{-hx,-fy}", @"{0,0}"] deltaX:deltaX deltaY:deltaY];
    bottomRigthCircle.frame = CGRectMake(x + size.width - circleSize, y + size.height - circleSize, circleSize, circleSize);
    [bottomRigthCircle addAnimation:animation forKey:@"animation"];
    [layer addSublayer:bottomRigthCircle];
}

- (CALayer *)createCircleWithSize:(CGFloat)size color:(UIColor *)color
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size, size) cornerRadius:size / 2];
    circle.fillColor = nil;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = 1;
    circle.path = circlePath.CGPath;
    return circle;
}

- (CAAnimation *)changeAnimation:(CAKeyframeAnimation *)animation values:(NSArray *)rawValues deltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY
{
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:5];
    for (NSString *rawValue in rawValues) {
        CGPoint point = CGPointFromString([self translate:rawValue withDeltaX:deltaX deltaY:deltaY]);
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(point.x, point.y, 0)]];
    }
    animation.values = values;
    return animation;
}

- (NSString *)translate:(NSString *)valueString withDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY
{
    NSMutableString *valueMutableString = [NSMutableString stringWithString:valueString];
    CGFloat fullDeltaX = 2 * deltaX;
    CGFloat fullDeltaY = 2 * deltaY;
    NSRange range;
    range.location = 0;
    range.length = valueString.length;
    
    [valueMutableString replaceOccurrencesOfString:@"hx" withString:[NSString stringWithFormat:@"%f", deltaX] options:NSCaseInsensitiveSearch range:range];
    range.length = valueMutableString.length;
    [valueMutableString replaceOccurrencesOfString:@"fx" withString:[NSString stringWithFormat:@"%f", fullDeltaX] options:NSCaseInsensitiveSearch range:range];
    range.length = valueMutableString.length;
    [valueMutableString replaceOccurrencesOfString:@"hy" withString:[NSString stringWithFormat:@"%f", deltaY] options:NSCaseInsensitiveSearch range:range];
    range.length = valueMutableString.length;
    [valueMutableString replaceOccurrencesOfString:@"fy" withString:[NSString stringWithFormat:@"%f", fullDeltaY] options:NSCaseInsensitiveSearch range:range];
    return valueMutableString;
}

@end

@interface FWIndicatorViewAnimationTriplePulse : NSObject <FWIndicatorViewAnimationProtocol>

@end

@implementation FWIndicatorViewAnimationTriplePulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color
{
    CFTimeInterval duration = 1;
    CFTimeInterval beginTime = CACurrentMediaTime();
    NSArray *beginTimes = @[@0, @0.2, @0.4];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.duration = duration;
    scaleAnimation.fromValue = @0;
    scaleAnimation.toValue = @1;
    
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = duration;
    opacityAnimation.keyTimes = @[@0, @0.05, @1];
    opacityAnimation.values = @[@0, @1, @0];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.removedOnCompletion = NO;
    animationGroup.animations = @[scaleAnimation, opacityAnimation];
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animationGroup.duration = duration;
    animationGroup.repeatCount = HUGE_VALF;
    
    for (int i = 0; i < 3; i++) {
        CAShapeLayer *circle = [[CAShapeLayer alloc] init];
        UIBezierPath *circlePath = [UIBezierPath bezierPath];
        [circlePath addArcWithCenter:CGPointMake(size.width / 2, size.height / 2) radius:size.width / 2 startAngle:0 endAngle:2 * M_PI clockwise:NO];
        circle.fillColor = color.CGColor;
        circle.backgroundColor = nil;
        circle.path = circlePath.CGPath;
        circle.frame = CGRectMake((layer.bounds.size.width - size.width) / 2.0f, (layer.bounds.size.height - size.height) / 2.0f, size.width, size.height);
        circle.opacity = 0;
        animationGroup.beginTime = beginTime + [beginTimes[i] doubleValue];
        [circle addAnimation:animationGroup forKey:@"animation"];
        [layer addSublayer:circle];
    }
}

@end

#pragma mark - FWIndicatorView

@interface FWIndicatorView ()

@property (nonatomic, strong) CALayer *animationLayer;

@end

@implementation FWIndicatorView

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, 0, 37.f, 37.f)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _type = FWIndicatorViewAnimationTypeLineSpin;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _type = FWIndicatorViewAnimationTypeLineSpin;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithType:(FWIndicatorViewAnimationType)type
{
    self = [super initWithFrame:CGRectMake(0, 0, 37.f, 37.f)];
    if (self) {
        _type = type;
        [self setupLayer];
    }
    return self;
}

- (void)setupLayer
{
    _color = [UIColor whiteColor];
    _hidesWhenStopped = YES;
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
        [animation setupAnimation:_animationLayer size:self.bounds.size color:_color];
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

- (void)setColor:(UIColor *)color
{
    if (![_color isEqual:color]) {
        _color = color;
        [self setupAnimation];
    }
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    if (0 < progress && progress < 1) {
        if (!self.isAnimating) [self startAnimating];
    } else {
        if (self.isAnimating) [self stopAnimating];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self invalidateIntrinsicContentSize];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self invalidateIntrinsicContentSize];
}

- (void)startAnimating
{
    if (!_animationLayer.sublayers) [self setupAnimation];
    self.hidden = NO;
    _animationLayer.speed = 1.0f;
    _isAnimating = YES;
}

- (void)stopAnimating
{
    _animationLayer.speed = 0.0f;
    _isAnimating = NO;
    if (self.hidesWhenStopped) self.hidden = YES;
}

- (id<FWIndicatorViewAnimationProtocol>)animation
{
    switch (_type) {
        case FWIndicatorViewAnimationTypeLinePulse:
            return [[FWIndicatorViewAnimationLinePulse alloc] init];
        case FWIndicatorViewAnimationTypeBallSpin:
            return [[FWIndicatorViewAnimationBallSpin alloc] init];
        case FWIndicatorViewAnimationTypeBallRotate:
            return [[FWIndicatorViewAnimationBallRotate alloc] init];
        case FWIndicatorViewAnimationTypeBallPulse:
            return [[FWIndicatorViewAnimationBallPulse alloc] init];
        case FWIndicatorViewAnimationTypeBallTriangle:
            return [[FWIndicatorViewAnimationBallTriangle alloc] init];
        case FWIndicatorViewAnimationTypeTriplePulse:
            return [[FWIndicatorViewAnimationTriplePulse alloc] init];
        case FWIndicatorViewAnimationTypeLineSpin:
        default:
            return [[FWIndicatorViewAnimationLineSpin alloc] init];
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
    return self.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return self.bounds.size;
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

- (UIView<FWProgressViewPlugin> *)progressViewWithStyle:(FWProgressViewStyle)style
{
    if (self.customProgressView) {
        return self.customProgressView(style);
    }
    
    FWProgressView *progressView = [[FWProgressView alloc] init];
    return progressView;
}

- (UIView<FWIndicatorViewPlugin> *)indicatorViewWithStyle:(FWIndicatorViewStyle)style
{
    if (self.customIndicatorView) {
        return self.customIndicatorView(style);
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
