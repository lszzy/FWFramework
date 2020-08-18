//
//  UIView+FWLayer.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIView+FWLayer.h"
#import "UIView+FWAutoLayout.h"
#import "UIView+FWAnimation.h"
#import "UIBezierPath+FWFramework.h"

#pragma mark - FWGradientView

@implementation FWGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (instancetype)initWithColors:(NSArray<UIColor *> *)colors locations:(NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    self = [super init];
    if (self) {
        [self setColors:colors locations:locations startPoint:startPoint endPoint:endPoint];
    }
    return self;
}

- (void)setColors:(NSArray<UIColor *> *)colors locations:(NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }
    self.gradientLayer.colors = [cgColors copy];
    self.gradientLayer.locations = locations;
    self.gradientLayer.startPoint = startPoint;
    self.gradientLayer.endPoint = endPoint;
}

- (CAGradientLayer *)gradientLayer
{
    return (CAGradientLayer *)self.layer;
}

- (NSArray *)colors
{
    return self.gradientLayer.colors;
}

- (void)setColors:(NSArray *)colors
{
    self.gradientLayer.colors = colors;
}

- (NSArray<NSNumber *> *)locations
{
    return self.gradientLayer.locations;
}

- (void)setLocations:(NSArray<NSNumber *> *)locations
{
    self.gradientLayer.locations = locations;
}

- (CGPoint)startPoint
{
    return self.gradientLayer.startPoint;
}

- (void)setStartPoint:(CGPoint)startPoint
{
    self.gradientLayer.startPoint = startPoint;
}

- (CGPoint)endPoint
{
    return self.gradientLayer.endPoint;
}

- (void)setEndPoint:(CGPoint)endPoint
{
    self.gradientLayer.endPoint = endPoint;
}

@end

#pragma mark - CALayer+FWLayer

@implementation CALayer (FWLayer)

- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    self.shadowColor = color.CGColor;
    self.shadowOffset = offset;
    self.shadowRadius = radius;
    self.shadowOpacity = 1.0;
    // self.shouldRasterize = YES;
    // self.rasterizationScale = [UIScreen mainScreen].scale;
}

@end

#pragma mark - CAGradientLayer+FWLayer

@implementation CAGradientLayer (FWLayer)

+ (CAGradientLayer *)fwGradientLayer:(CGRect)frame
                              colors:(NSArray *)colors
                           locations:(NSArray<NSNumber *> *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    // 渐变区域
    gradientLayer.frame = frame;
    // CGColor颜色
    gradientLayer.colors = colors;
    // 颜色变化点，取值范围0~1
    gradientLayer.locations = locations;
    // 渐变颜色方向，左上点为(0,0), 右下点为(1,1)
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    return gradientLayer;
}

@end

#pragma mark - UIView+FWLayer

@implementation UIView (FWLayer)

#pragma mark - Effect

- (void)fwSetBlurEffect:(UIBlurEffectStyle)style
{
    // 移除旧毛玻璃视图
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIVisualEffectView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    // 设置新毛玻璃效果，清空为-1
    if (((NSInteger)style) > -1) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        [effectView fwSetAutoLayout:YES];
        [self addSubview:effectView];
        [effectView fwPinEdgesToSuperview];
    }
}

#pragma mark - Shadow

- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius
{
    [self.layer fwSetShadowColor:color offset:offset radius:radius];
}

#pragma mark - Bezier

- (void)fwDrawBezierPath:(UIBezierPath *)bezierPath
             strokeWidth:(CGFloat)strokeWidth
             strokeColor:(UIColor *)strokeColor
               fillColor:(UIColor *)fillColor
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextSetLineWidth(ctx, strokeWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    [strokeColor setStroke];
    CGContextAddPath(ctx, bezierPath.CGPath);
    CGContextStrokePath(ctx);
    
    if (fillColor) {
        [fillColor setFill];
        CGContextAddPath(ctx, bezierPath.CGPath);
        CGContextFillPath(ctx);
    }
    
    CGContextRestoreGState(ctx);
}

#pragma mark - Gradient

- (void)fwDrawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(const CGFloat *)locations
                   direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fwLinePointsWithRect:rect direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    [self fwDrawLinearGradient:rect colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

- (void)fwDrawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(const CGFloat *)locations
                  startPoint:(CGPoint)startPoint
                    endPoint:(CGPoint)endPoint
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextAddRect(ctx, rect);
    CGContextClip(ctx);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextRestoreGState(ctx);
}

- (CAGradientLayer *)fwAddGradientLayer:(CGRect)frame
                                 colors:(NSArray *)colors
                              locations:(NSArray<NSNumber *> *)locations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    // 渐变区域
    gradientLayer.frame = frame;
    // CGColor颜色
    gradientLayer.colors = colors;
    // 颜色变化点，取值范围0~1
    gradientLayer.locations = locations;
    // 渐变颜色方向，左上点为(0,0), 右下点为(1,1)
    gradientLayer.startPoint = startPoint;
    gradientLayer.endPoint = endPoint;
    
    [self.layer addSublayer:gradientLayer];
    return gradientLayer;
}

#pragma mark - Circle

- (CAShapeLayer *)fwAddCircleLayer:(CGRect)rect
                            degree:(CGFloat)degree
                          progress:(CGFloat)progress
                       strokeColor:(UIColor *)strokeColor
                       strokeWidth:(CGFloat)strokeWidth
{
    // 创建背景圆环
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = rect;
    // 清空填充色
    layer.fillColor = [UIColor clearColor].CGColor;
    // 设置画笔颜色，即圆环背景色
    layer.strokeColor = strokeColor.CGColor;
    layer.lineWidth = strokeWidth;
    layer.lineCap = kCALineCapRound;
    
    // 设置画笔路径
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0)
                                                        radius:(rect.size.width / 2.0 - strokeWidth / 2.0)
                                                    startAngle:(degree) * M_PI / 180.f
                                                      endAngle:(degree + 360.f * progress) * M_PI / 180.f
                                                     clockwise:YES];
    // path决定layer将被渲染成何种形状
    layer.path = path.CGPath;
    
    [self.layer addSublayer:layer];
    return layer;
}

- (CAShapeLayer *)fwAddCircleLayer:(CGRect)rect
                            degree:(CGFloat)degree
                          progress:(CGFloat)progress
                     progressColor:(UIColor *)progressColor
                       strokeColor:(UIColor *)strokeColor
                       strokeWidth:(CGFloat)strokeWidth
{
    // 绘制底色圆
    [self fwAddCircleLayer:rect degree:degree progress:1.0 strokeColor:strokeColor strokeWidth:strokeWidth];
    
    // 绘制进度圆
    CAShapeLayer *layer = [self fwAddCircleLayer:rect degree:degree progress:progress strokeColor:progressColor strokeWidth:strokeWidth];
    return layer;
}

- (CALayer *)fwAddCircleLayer:(CGRect)rect
                       degree:(CGFloat)degree
                     progress:(CGFloat)progress
                gradientBlock:(void (^)(CALayer *layer))gradientBlock
                  strokeColor:(UIColor *)strokeColor
                  strokeWidth:(CGFloat)strokeWidth
{
    // 添加渐变容器层
    CALayer *gradientLayer = [CALayer layer];
    gradientLayer.frame = rect;
    [self.layer addSublayer:gradientLayer];
    
    // 创建渐变子层，可单个渐变，左右区域，上下区域等
    if (gradientBlock) {
        gradientBlock(gradientLayer);
    }
    
    /*
    // 示例渐变
    CAGradientLayer *subLayer = [CAGradientLayer layer];
    subLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    [subLayer setColors:[NSArray arrayWithObjects:(id)[[UIColor redColor] CGColor],(id)[[UIColor blueColor] CGColor], nil]];
    [subLayer setLocations:@[@0, @1]];
    [subLayer setStartPoint:CGPointMake(0, 0)];
    [subLayer setEndPoint:CGPointMake(0, 1)];
    [gradientLayer addSublayer:subLayer];
    */
    
    // 创建遮罩frame，相对于父视图，所以从0开始
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
    progressLayer.fillColor = [[UIColor clearColor] CGColor];
    progressLayer.strokeColor = strokeColor.CGColor;
    progressLayer.lineWidth = strokeWidth;
    progressLayer.lineCap = kCALineCapRound;
    
    // 设置贝塞尔曲线
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0)
                                                        radius:(rect.size.width - strokeWidth) / 2.0
                                                    startAngle:(degree) * M_PI / 180.f
                                                      endAngle:(degree + 360.f * progress) * M_PI / 180.f
                                                     clockwise:YES];
    progressLayer.path = path.CGPath;
    
    // 用progressLayer来截取渐变层，从而实现圆形效果
    [gradientLayer setMask:progressLayer];

    // 可用mask实现strokeEnd动画
    return gradientLayer;
}

#pragma mark - Dash

- (CALayer *)fwAddDashLayer:(CGRect)rect
                 lineLength:(CGFloat)lineLength
                lineSpacing:(CGFloat)lineSpacing
                  lineColor:(UIColor *)lineColor
{
    CAShapeLayer *dashLayer = [CAShapeLayer layer];
    dashLayer.frame = rect;
    dashLayer.fillColor = [UIColor clearColor].CGColor;
    dashLayer.strokeColor = lineColor.CGColor;
    
    // 自动根据尺寸计算虚线方向
    BOOL isVertical = (lineLength + lineSpacing > rect.size.width) ? YES : NO;
    dashLayer.lineWidth = isVertical ? CGRectGetWidth(rect) : CGRectGetHeight(rect);
    dashLayer.lineJoin = kCALineJoinRound;
    dashLayer.lineDashPattern = @[@(lineLength), @(lineSpacing)];
    
    // 设置虚线路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (isVertical) {
        [path moveToPoint:CGPointMake(CGRectGetWidth(rect) / 2, 0)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect))];
    } else {
        [path moveToPoint:CGPointMake(0, CGRectGetHeight(rect) / 2)];
        [path addLineToPoint:CGPointMake(CGRectGetWidth(rect), CGRectGetHeight(rect) / 2)];
    }
    dashLayer.path = path.CGPath;
    [self.layer addSublayer:dashLayer];
    return dashLayer;
}

@end
