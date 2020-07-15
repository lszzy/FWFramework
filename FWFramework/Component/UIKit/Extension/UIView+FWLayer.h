//
//  UIView+FWLayer.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CALayer+FWLayer

/*!
@brief CALayer+FWLayer
*/
@interface CALayer (FWLayer)

// 设置阴影颜色、偏移和半径
- (void)fwSetShadowColor:(nullable UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius;

@end

#pragma mark - CAGradientLayer+FWLayer

/*!
 @brief CAGradientLayer+FWLayer
 */
@interface CAGradientLayer (FWLayer)

/**
 *  创建渐变层，需手工addLayer
 *
 *  @param frame      渐变区域
 *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
 *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
 *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
 *  @param endPoint   渐变结束点
 *  @return 渐变Layer
 */
+ (CAGradientLayer *)fwGradientLayer:(CGRect)frame
                              colors:(NSArray *)colors
                           locations:(nullable NSArray<NSNumber *> *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint;

@end

#pragma mark - UIView+FWLayer

/*!
 @brief UIView+FWLayer
 */
@interface UIView (FWLayer)

#pragma mark - Effect

/**
 *  设置毛玻璃效果，使用UIVisualEffectView
 *
 *  @param style 毛玻璃效果样式
 */
- (void)fwSetBlurEffect:(UIBlurEffectStyle)style;

#pragma mark - Shadow

// 设置阴影颜色、偏移和半径
- (void)fwSetShadowColor:(nullable UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius;

#pragma mark - Bezier

/*!
 @brief 绘制形状路径，需要在drawRect中调用
 
 @param bezierPath 绘制路径
 @param strokeWidth 绘制宽度
 @param strokeColor 绘制颜色
 @param fillColor 填充颜色
 */
- (void)fwDrawBezierPath:(UIBezierPath *)bezierPath
             strokeWidth:(CGFloat)strokeWidth
             strokeColor:(UIColor *)strokeColor
               fillColor:(nullable UIColor *)fillColor;

#pragma mark - Gradient

/*!
 @brief 绘制渐变颜色，需要在drawRect中调用，支持四个方向，默认向下Down
 
 @param rect 绘制区域
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
 */
- (void)fwDrawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(nullable const CGFloat *)locations
                   direction:(UISwipeGestureRecognizerDirection)direction;

/*!
 @brief 绘制渐变颜色，需要在drawRect中调用
 
 @param rect 绘制区域
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param startPoint 渐变开始点，需要根据rect计算
 @param endPoint 渐变结束点，需要根据rect计算
 */
- (void)fwDrawLinearGradient:(CGRect)rect
                      colors:(NSArray *)colors
                   locations:(nullable const CGFloat *)locations
                  startPoint:(CGPoint)startPoint
                    endPoint:(CGPoint)endPoint;

/**
 *  添加渐变Layer
 *
 *  @param frame      渐变区域
 *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
 *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
 *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
 *  @param endPoint   渐变结束点
 *  @return 渐变Layer
 */
- (CAGradientLayer *)fwAddGradientLayer:(CGRect)frame
                                 colors:(NSArray *)colors
                              locations:(nullable NSArray<NSNumber *> *)locations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint;

#pragma mark - Circle

// 添加进度圆形Layer，可设置绘制颜色和宽度，返回进度CAShapeLayer用于动画，degree为起始角度，如-90
- (CAShapeLayer *)fwAddCircleLayer:(CGRect)rect
                            degree:(CGFloat)degree
                          progress:(CGFloat)progress
                       strokeColor:(UIColor *)strokeColor
                       strokeWidth:(CGFloat)strokeWidth;

// 添加进度圆形Layer，可设置绘制底色和进度颜色，返回进度CAShapeLayer用于动画，degree为起始角度，如-90
- (CAShapeLayer *)fwAddCircleLayer:(CGRect)rect
                            degree:(CGFloat)degree
                          progress:(CGFloat)progress
                     progressColor:(UIColor *)progressColor
                       strokeColor:(UIColor *)strokeColor
                       strokeWidth:(CGFloat)strokeWidth;

// 添加渐变进度圆形Layer，返回渐变Layer容器，添加strokeEnd动画请使用layer.mask即可
- (CALayer *)fwAddCircleLayer:(CGRect)rect
                       degree:(CGFloat)degree
                     progress:(CGFloat)progress
                gradientBlock:(nullable void (^)(CALayer *layer))gradientBlock
                  strokeColor:(UIColor *)strokeColor
                  strokeWidth:(CGFloat)strokeWidth;

#pragma mark - Dash

/*!
 @brief 添加虚线Layer
 
 @param rect 虚线区域，从中心绘制
 @param lineLength 虚线的宽度
 @param lineSpacing 虚线的间距
 @param lineColor 虚线的颜色
 @return 虚线Layer
 */
- (CALayer *)fwAddDashLayer:(CGRect)rect
                 lineLength:(CGFloat)lineLength
                lineSpacing:(CGFloat)lineSpacing
                  lineColor:(UIColor *)lineColor;

@end

NS_ASSUME_NONNULL_END
