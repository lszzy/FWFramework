//
//  IndicatorView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "IndicatorView.h"
#import <FWFramework/FWFramework-Swift.h>

#pragma mark - __FWIndicatorViewAnimation

@interface __FWIndicatorViewAnimationLineSpin : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationLineSpin

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
    CGFloat lineSpacing = 2;
    CGSize lineSize = CGSizeMake((size.width - lineSpacing * 4) / 5, (size.height - lineSpacing * 2) / 3);
    CGFloat x = (layer.bounds.size.width - size.width) / 2;
    CGFloat y = (layer.bounds.size.height - size.height) / 2;
    CFTimeInterval duration = 1.2;
    CFTimeInterval beginTime = CACurrentMediaTime();
    NSArray<NSNumber *> *beginTimes = @[@0.12, @0.24, @0.36, @0.48, @0.6, @0.72, @0.84, @0.96];
    CAMediaTimingFunction *timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.keyTimes = @[@0, @0.5, @1];
    animation.timingFunctions = @[timingFunction, timingFunction];
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

- (CALayer *)createLayer:(CGFloat)angle size:(CGSize)size origin:(CGPoint)origin containerSize:(CGSize)containerSize color:(UIColor *)color {
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

@interface __FWIndicatorViewAnimationLinePulse : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationLinePulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
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

@interface __FWIndicatorViewAnimationBallSpin : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationBallSpin

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
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

- (CALayer *)circleLayer:(CGFloat)angle size:(CGFloat)size origin:(CGPoint)origin containerSize:(CGSize)containerSize color:(UIColor *)color {
    CGFloat radius = containerSize.width / 2 - size / 2;
    CALayer *circle = [self createLayerWith:CGSizeMake(size, size) color:color];
    CGRect frame = CGRectMake(origin.x + radius * (cos(angle) + 1), origin.y + radius * (sin(angle) + 1), size, size);
    circle.frame = frame;
    return circle;
}

- (CALayer *)createLayerWith:(CGSize)size color:(UIColor *)color {
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointMake(size.width / 2,size.height / 2) radius:(size.width / 2) startAngle:0 endAngle:2 * M_PI clockwise:NO];
    layer.fillColor = color.CGColor;
    layer.backgroundColor = nil;
    layer.path = path.CGPath;
    return layer;
}

@end

@interface __FWIndicatorViewAnimationCircleSpin : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationCircleSpin

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
    CGFloat lineWidth = 3;
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width / 2, size.height / 2) radius:(size.width - lineWidth) / 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = nil;
    shapeLayer.strokeColor = color.CGColor;
    shapeLayer.lineWidth = lineWidth;
    shapeLayer.strokeStart = 0;
    shapeLayer.strokeEnd = 1;
    shapeLayer.lineCap = kCALineCapRound;
    shapeLayer.lineDashPhase = 0.8;
    shapeLayer.path = bezierPath.CGPath;
    [layer setMask:shapeLayer];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.shadowPath = bezierPath.CGPath;
    gradientLayer.frame = CGRectMake(0, 0, size.width / 2, size.height);
    gradientLayer.startPoint = CGPointMake(1, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    gradientLayer.colors = @[(id)color.CGColor, (id)[color colorWithAlphaComponent:0.5].CGColor];
    [layer addSublayer:gradientLayer];
    
    gradientLayer = [CAGradientLayer layer];
    gradientLayer.shadowPath = bezierPath.CGPath;
    gradientLayer.frame = CGRectMake(size.width / 2, 0, size.width / 2, size.height);
    gradientLayer.startPoint = CGPointMake(0, 1);
    gradientLayer.endPoint = CGPointMake(0, 0);
    gradientLayer.colors = @[(id)[color colorWithAlphaComponent:0.5].CGColor, (id)[color colorWithAlphaComponent:0].CGColor];
    [layer addSublayer:gradientLayer];
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.removedOnCompletion = NO;
    animation.fromValue = @(0);
    animation.toValue = @(M_PI * 2);
    animation.repeatCount = HUGE_VALF;
    animation.duration = 1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fillMode = kCAFillModeForwards;
    [layer addAnimation:animation forKey:@"animation"];
}

@end

@interface __FWIndicatorViewAnimationBallPulse : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationBallPulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
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

@interface __FWIndicatorViewAnimationBallTriangle : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationBallTriangle

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
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

- (CALayer *)createCircleWithSize:(CGFloat)size color:(UIColor *)color {
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size, size) cornerRadius:size / 2];
    circle.fillColor = nil;
    circle.strokeColor = color.CGColor;
    circle.lineWidth = 1;
    circle.path = circlePath.CGPath;
    return circle;
}

- (CAAnimation *)changeAnimation:(CAKeyframeAnimation *)animation values:(NSArray *)rawValues deltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY {
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:5];
    for (NSString *rawValue in rawValues) {
        CGPoint point = CGPointFromString([self translate:rawValue withDeltaX:deltaX deltaY:deltaY]);
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(point.x, point.y, 0)]];
    }
    animation.values = values;
    return animation;
}

- (NSString *)translate:(NSString *)valueString withDeltaX:(CGFloat)deltaX deltaY:(CGFloat)deltaY {
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

@interface __FWIndicatorViewAnimationTriplePulse : NSObject <__FWIndicatorViewAnimationProtocol>

@end

@implementation __FWIndicatorViewAnimationTriplePulse

- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color {
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

#pragma mark - __FWIndicatorView

@interface __FWIndicatorView () <__FWIndicatorViewPlugin, __FWProgressViewPlugin>

@property (nonatomic, strong) CALayer *animationLayer;

@end

@implementation __FWIndicatorView

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 37.f, 37.f)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _type = __FWIndicatorViewAnimationTypeLineSpin;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _type = __FWIndicatorViewAnimationTypeLineSpin;
        [self setupLayer];
    }
    return self;
}

- (instancetype)initWithType:(__FWIndicatorViewAnimationType)type {
    self = [super initWithFrame:CGRectMake(0, 0, 37.f, 37.f)];
    if (self) {
        _type = type;
        [self setupLayer];
    }
    return self;
}

- (void)setupLayer {
    _indicatorColor = [UIColor whiteColor];
    _hidesWhenStopped = YES;
    self.userInteractionEnabled = NO;
    self.hidden = YES;
    
    _animationLayer = [[CALayer alloc] init];
    [self.layer addSublayer:_animationLayer];
    [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
}

- (void)setupAnimation {
    _animationLayer.sublayers = nil;
    
    id<__FWIndicatorViewAnimationProtocol> animation = [self animation];
    if ([animation respondsToSelector:@selector(setupAnimation:size:color:)]) {
        [animation setupAnimation:_animationLayer size:self.bounds.size color:_indicatorColor];
        _animationLayer.speed = 0.0f;
    }
}

- (void)setType:(__FWIndicatorViewAnimationType)type {
    if (_type != type) {
        _type = type;
        [self setupAnimation];
    }
}

- (void)setIndicatorColor:(UIColor *)color {
    if (![_indicatorColor isEqual:color]) {
        _indicatorColor = color;
        [self setupAnimation];
    }
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    _progress = progress;
    if (0 < progress && progress < 1) {
        if (!self.isAnimating) [self startAnimating];
    } else {
        if (self.isAnimating) [self stopAnimating];
    }
}

- (CGSize)indicatorSize {
    return self.bounds.size;
}

- (void)setIndicatorSize:(CGSize)size {
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

- (void)startAnimating {
    if (_isAnimating) return;
    if (!_animationLayer.sublayers) [self setupAnimation];
    self.hidden = NO;
    _animationLayer.speed = 1.0f;
    _isAnimating = YES;
}

- (void)stopAnimating {
    _animationLayer.speed = 0.0f;
    _isAnimating = NO;
    if (self.hidesWhenStopped) self.hidden = YES;
}

- (id<__FWIndicatorViewAnimationProtocol>)animation {
    switch (_type) {
        case __FWIndicatorViewAnimationTypeLinePulse:
            return [[__FWIndicatorViewAnimationLinePulse alloc] init];
        case __FWIndicatorViewAnimationTypeBallSpin:
            return [[__FWIndicatorViewAnimationBallSpin alloc] init];
        case __FWIndicatorViewAnimationTypeCircleSpin:
            return [[__FWIndicatorViewAnimationCircleSpin alloc] init];
        case __FWIndicatorViewAnimationTypeBallPulse:
            return [[__FWIndicatorViewAnimationBallPulse alloc] init];
        case __FWIndicatorViewAnimationTypeBallTriangle:
            return [[__FWIndicatorViewAnimationBallTriangle alloc] init];
        case __FWIndicatorViewAnimationTypeTriplePulse:
            return [[__FWIndicatorViewAnimationTriplePulse alloc] init];
        case __FWIndicatorViewAnimationTypeLineSpin:
        default:
            return [[__FWIndicatorViewAnimationLineSpin alloc] init];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _animationLayer.frame = self.bounds;
    BOOL isAnimating = _isAnimating;
    if (isAnimating) [self stopAnimating];
    [self setupAnimation];
    if (isAnimating) [self startAnimating];
}

- (CGSize)intrinsicContentSize {
    return self.bounds.size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return self.bounds.size;
}

@end
