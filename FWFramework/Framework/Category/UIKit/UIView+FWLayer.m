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
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = offset;
    self.layer.shadowRadius = radius;
    self.layer.shadowOpacity = 1.0;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

#pragma mark - Gradient

- (CAGradientLayer *)fwGradientLayer:(CGRect)frame
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

- (void)fwDrawGradient:(CGRect)rect
                colors:(NSArray *)colors
             locations:(const CGFloat *)locations
             direction:(UISwipeGestureRecognizerDirection)direction
{
    NSArray<NSValue *> *linePoints = [UIBezierPath fwLinePointsWithRect:rect direction:direction];
    CGPoint startPoint = [linePoints.firstObject CGPointValue];
    CGPoint endPoint = [linePoints.lastObject CGPointValue];
    [self fwDrawGradient:rect colors:colors locations:locations startPoint:startPoint endPoint:endPoint];
}

- (void)fwDrawGradient:(CGRect)rect
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

@end
