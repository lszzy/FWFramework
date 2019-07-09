/*!
 @header     UIBezierPath+FWFramework.m
 @indexgroup FWFramework
 @brief      UIBezierPath+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIBezierPath+FWFramework.h"

CGFloat FWRadianWithDegree(CGFloat degree) {
    return ((M_PI * degree) / 180.f);
}

CGFloat FWDegreeWithRadian(CGFloat radian) {
    return ((180.f * radian) / M_PI);
}

@implementation UIBezierPath (FWFramework)

#pragma mark - Bezier

+ (UIBezierPath *)fwLinesWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
    }
    return path;
}

+ (UIBezierPath *)fwQuadCurvedPathWithPoints:(NSArray *)points
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSValue *value = points[0];
    CGPoint p1 = [value CGPointValue];
    [path moveToPoint:p1];
    
    if (points.count == 2) {
        value = points[1];
        CGPoint p2 = [value CGPointValue];
        [path addLineToPoint:p2];
        return path;
    }
    
    for (NSUInteger i = 1; i < points.count; i++) {
        value = points[i];
        CGPoint p2 = [value CGPointValue];
        
        CGPoint midPoint = [self fwMiddlePoint:p1 withPoint:p2];
        [path addQuadCurveToPoint:midPoint controlPoint:[self fwControlPoint:midPoint withPoint:p1]];
        [path addQuadCurveToPoint:p2 controlPoint:[self fwControlPoint:midPoint withPoint:p2]];
        
        p1 = p2;
    }
    return path;
}

+ (CGPoint)fwMiddlePoint:(CGPoint)p1 withPoint:(CGPoint)p2
{
    return CGPointMake((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
}

+ (CGPoint)fwControlPoint:(CGPoint)p1 withPoint:(CGPoint)p2
{
    CGPoint controlPoint = [self fwMiddlePoint:p1 withPoint:p2];
    CGFloat diffY = fabs(p2.y - controlPoint.y);
    
    if (p1.y < p2.y)
        controlPoint.y += diffY;
    else if (p1.y > p2.y)
        controlPoint.y -= diffY;
    
    return controlPoint;
}

+ (CGFloat)fwRadianWithDegree:(CGFloat)degree
{
    return (M_PI * degree) / 180.f;
}

+ (CGFloat)fwDegreeWithRadian:(CGFloat)radian
{
    return (180.f * radian) / M_PI;
}

+ (NSArray<NSValue *> *)fwLinePointsWithRect:(CGRect)rect direction:(UISwipeGestureRecognizerDirection)direction
{
    CGPoint startPoint;
    CGPoint endPoint;
    switch (direction) {
        // 从左到右
        case UISwipeGestureRecognizerDirectionRight: {
            startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
            endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
            break;
        }
        // 从下到上
        case UISwipeGestureRecognizerDirectionUp: {
            startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
            endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
            break;
        }
        // 从右到左
        case UISwipeGestureRecognizerDirectionLeft: {
            startPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
            endPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
            break;
        }
        // 从上到下
        case UISwipeGestureRecognizerDirectionDown:
        default: {
            startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
            endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
            break;
        }
    }
    return [NSArray arrayWithObjects:[NSValue valueWithCGPoint:startPoint], [NSValue valueWithCGPoint:endPoint], nil];
}

#pragma mark - Shape

- (UIImage *)fwShapeImage:(CGSize)size
              strokeWidth:(CGFloat)strokeWidth
              strokeColor:(UIColor *)strokeColor
                fillColor:(UIColor *)fillColor
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    
    CGContextSetLineWidth(context, strokeWidth);
    [strokeColor setStroke];
    CGContextAddPath(context, self.CGPath);
    CGContextStrokePath(context);
    
    if (fillColor) {
        [fillColor setFill];
        CGContextAddPath(context, self.CGPath);
        CGContextFillPath(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (CAShapeLayer *)fwShapeLayer:(CGRect)rect
                   strokeWidth:(CGFloat)strokeWidth
                   strokeColor:(UIColor *)strokeColor
                     fillColor:(UIColor *)fillColor
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = rect;
    layer.lineWidth = strokeWidth;
    layer.lineCap = kCALineCapRound;
    layer.strokeColor = strokeColor.CGColor;
    if (fillColor) {
        layer.fillColor = fillColor.CGColor;
    }
    layer.path = self.CGPath;
    return layer;
}

@end
