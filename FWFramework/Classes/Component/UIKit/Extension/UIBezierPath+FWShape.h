/*!
 @header     UIBezierPath+FWShape.h
 @indexgroup FWFramework
 @brief      UIBezierPath+FWShape
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/7/9
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIBezierPath+FWShape
 */
@interface UIBezierPath (FWShape)

// "🔴" 圆的形状，0~1，degree为起始角度，如-90度
+ (UIBezierPath *)fwShapeCircle:(CGRect)frame percent:(float)percent degree:(CGFloat)degree;

// "❤️" 心的形状
+ (UIBezierPath *)fwShapeHeart:(CGRect)frame;

// "⭐" 星星的形状
+ (UIBezierPath *)fwShapeStar:(CGRect)frame;

// "⭐⭐⭐⭐⭐" 几颗星星的形状
+ (UIBezierPath *)fwShapeStars:(NSUInteger)count frame:(CGRect)frame spacing:(CGFloat)spacing;

// "➕" 加号形状
+ (UIBezierPath *)fwShapePlus:(CGRect)frame;

// "➖" 减号形状
+ (UIBezierPath *)fwShapeMinus:(CGRect)frame;

// "✖" 叉叉形状(错误)
+ (UIBezierPath *)fwShapeCross:(CGRect)frame;

// "✔" 检查形状(正确)
+ (UIBezierPath *)fwShapeCheck:(CGRect)frame;

// "<" 折叠形状，可指定方向
+ (UIBezierPath *)fwShapeFold:(CGRect)frame direction:(UISwipeGestureRecognizerDirection)direction;

// "⬅" 箭头形状，可指定方向
+ (UIBezierPath *)fwShapeArrow:(CGRect)frame direction:(UISwipeGestureRecognizerDirection)direction;

// "🔺" 三角形形状，可指定方向
+ (UIBezierPath *)fwShapeTriangle:(CGRect)frame direction:(UISwipeGestureRecognizerDirection)direction;

// "💬" 标签形状，可指定方向
+ (UIBezierPath *)fwShapeLabel:(CGRect)frame arrow:(CGSize)arrow direction:(UISwipeGestureRecognizerDirection)direction;

@end

NS_ASSUME_NONNULL_END
