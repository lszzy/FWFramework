/*!
 @header     UIBezierPath+FWFramework.h
 @indexgroup FWFramework
 @brief      UIBezierPath+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

// 将角度(0~360)转换为弧度，周长为2*M_PI*r
FOUNDATION_EXPORT CGFloat FWRadianWithDegree(CGFloat degree);

// 将弧度转换为角度(0~360)
FOUNDATION_EXPORT CGFloat FWDegreeWithRadian(CGFloat radian);

/*!
 @brief UIBezierPath+FWFramework
 */
@interface UIBezierPath (FWFramework)

#pragma mark - Bezier

// 根据点计算折线路径(NSValue点)
+ (UIBezierPath *)fwLinesWithPoints:(NSArray *)points;

// 根据点计算贝塞尔曲线路径
+ (UIBezierPath *)fwQuadCurvedPathWithPoints:(NSArray *)points;

// 计算两点的中心点
+ (CGPoint)fwMiddlePoint:(CGPoint)p1 withPoint:(CGPoint)p2;

// 计算两点的贝塞尔曲线控制点
+ (CGPoint)fwControlPoint:(CGPoint)p1 withPoint:(CGPoint)p2;

// 将角度(0~360)转换为弧度，周长为2*M_PI*r
+ (CGFloat)fwRadianWithDegree:(CGFloat)degree;

// 将弧度转换为角度(0~360)
+ (CGFloat)fwDegreeWithRadian:(CGFloat)radian;

// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
+ (NSArray<NSValue *> *)fwLinePointsWithRect:(CGRect)rect direction:(UISwipeGestureRecognizerDirection)direction;

#pragma mark - Shape

// 圆的形状，0~1，degree为起始角度，如-90度
+ (UIBezierPath *)fwShapeCircle:(CGRect)frame percent:(float)percent degree:(CGFloat)degree;

// 心的形状
+ (UIBezierPath *)fwShapeHeart:(CGRect)frame;

// 头像的形状
+ (UIBezierPath *)fwShapeAvatar:(CGRect)frame;

// 星星的形状
+ (UIBezierPath *)fwShapeStar:(CGRect)frame;

// 几颗星星的形状
+ (UIBezierPath *)fwShapeStars:(NSUInteger)count frame:(CGRect)frame;

#pragma mark - Image

// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
- (UIImage *)fwShapeImage:(CGSize)size
              strokeWidth:(CGFloat)strokeWidth
              strokeColor:(UIColor *)strokeColor
                fillColor:(UIColor *)fillColor;

@end
