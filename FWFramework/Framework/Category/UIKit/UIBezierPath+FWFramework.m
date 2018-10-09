/*!
 @header     UIBezierPath+FWFramework.m
 @indexgroup FWFramework
 @brief      UIBezierPath+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import "UIBezierPath+FWFramework.h"

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

+ (CGFloat)fwDegreeToRadian:(CGFloat)degree
{
    return (M_PI * degree) / 180.f;
}

+ (CGFloat)fwRadianToDegree:(CGFloat)radian
{
    return (180.f * radian) / M_PI;
}

#pragma mark - Shape

+ (CGRect)fwInnerSquareFrame:(CGRect)frame;
{
    CGFloat a = MIN(frame.size.width, frame.size.height);
    return CGRectMake(frame.size.width / 2 - a / 2, frame.size.height / 2 - a / 2, a, a);
}

+ (UIBezierPath *)fwShapeCircle:(CGRect)aFrame percent:(float)percent degree:(CGFloat)degree
{
    CGRect frame = [self fwInnerSquareFrame:aFrame];
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(frame.origin.x + frame.size.width / 2.0, frame.origin.y + frame.size.height / 2.0)
                                                              radius:frame.size.width / 2.0
                                                          startAngle:(degree) * M_PI / 180.f
                                                            endAngle:(degree + 360.f * percent) * M_PI / 180.f
                                                           clockwise:YES];
    return bezierPath;
}

+ (UIBezierPath *)fwShapeHeart:(CGRect)aFrame
{
    CGRect frame = [self fwInnerSquareFrame:aFrame];
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.74182 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.04948 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.49986 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.24129 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.64732 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05022 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.55044 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.11201 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.33067 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.06393 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.46023 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.14682 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.39785 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.08864 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.25304 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05011 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.30516 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05454 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.27896 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.04999 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.00841 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.36081 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.12805 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05067 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.00977 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.15998 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.29627 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.70379 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.00709 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.55420 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.18069 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.62648 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50061 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.92498 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.40835 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.77876 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.48812 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.88133 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.70195 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.70407 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.50990 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.88158 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.59821 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.77912 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.99177 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.35870 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.81539 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.62200 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.99308 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.55208 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.74182 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.04948 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.99040 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.15672 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.86824 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.04848 * CGRectGetHeight(frame))];
    [bezierPath closePath];
    bezierPath.miterLimit = 4;
    
    return bezierPath;
}

+ (UIBezierPath *)fwShapeAvatar:(CGRect)aFrame
{
    CGRect frame = [self fwInnerSquareFrame:aFrame];
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.59723 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.53216 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.63225 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.46466 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.61268 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.51696 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.61807 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.47851 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.68031 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39072 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.65233 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.44503 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.67410 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.42087 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.67176 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.33167 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.68857 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.35062 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.67176 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.34552 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.66244 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.22404 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.67176 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.30267 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.67152 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.25499 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.64114 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.15016 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.66195 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.18321 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.65526 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.16545 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.57835 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.12980 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.62793 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.13586 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.59533 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.13924 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50277 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10892 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.55205 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.11518 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.53038 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10965 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50277 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10878 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50036 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10887 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.50197 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10878 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.50116 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10886 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.49633 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10878 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.49901 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10885 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.49772 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10878 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.49639 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.10902 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.33297 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.22218 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.42912 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.11156 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.35757 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.15397 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.32734 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.33167 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.32385 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.24746 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.32734 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.30267 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.31879 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39072 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.32734 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.34552 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.31053 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.35062 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.36685 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.46466 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.32500 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.42087 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.34677 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.44503 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.40188 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.53216 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.38103 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.47851 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.38642 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.51696 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.40552 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.56864 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.40525 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.55453 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.40565 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.54816 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.39466 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.59685 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.40548 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.57555 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.40570 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.58629 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.28634 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.65952 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.37374 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.61687 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.32572 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.64261 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.13051 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.71866 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.23439 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.68183 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.14996 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.70863 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.05796 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.77326 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.11105 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.72870 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.05796 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.75592 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.05796 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.05796 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.79061 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.05796 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.49475 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50470 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.94992 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.94992 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.78465 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.94992 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.87769 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.94992 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.80199 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.86894 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.73004 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.94992 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.76730 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.88839 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.74008 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.71311 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.66711 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.84948 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.72001 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.76505 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.68941 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.60650 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.59849 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.67477 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.65065 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.62824 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.61915 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.59391 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.56652 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.59918 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.59153 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.59399 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.58424 * CGRectGetHeight(frame))];
    [bezierPath addCurveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.59757 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.53216 * CGRectGetHeight(frame)) controlPoint1: CGPointMake(CGRectGetMinX(frame) + 0.59383 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.54590 * CGRectGetHeight(frame)) controlPoint2: CGPointMake(CGRectGetMinX(frame) + 0.59430 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.55378 * CGRectGetHeight(frame))];
    [bezierPath closePath];
    bezierPath.miterLimit = 4;
    
    return bezierPath;
}

+ (UIBezierPath *)fwShapeStar:(CGRect)aFrame
{
    CGRect frame = [self fwInnerSquareFrame:aFrame];
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.05000 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.67634 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.30729 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.97553 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39549 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.78532 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.64271 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.79389 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.95451 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.50000 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.85000 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.20611 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.95451 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.21468 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.64271 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.02447 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.39549 * CGRectGetHeight(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMinX(frame) + 0.32366 * CGRectGetWidth(frame), CGRectGetMinY(frame) + 0.30729 * CGRectGetHeight(frame))];
    [bezierPath closePath];
    
    return bezierPath;
}

+ (UIBezierPath *)fwShapeStars:(NSUInteger)count frame:(CGRect)aFrame
{
    CGFloat w = aFrame.size.width / count;
    CGRect babyFrame = CGRectMake(0, 0, w, aFrame.size.height);
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    for (int i = 0; i < count; i++) {
        UIBezierPath *startPath = [UIBezierPath fwShapeStar:babyFrame];
        [startPath applyTransform:CGAffineTransformTranslate(CGAffineTransformIdentity, i * w, 0)];
        [bezierPath appendPath:startPath];
    }
    return bezierPath;
}

#pragma mark - Image

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

@end
