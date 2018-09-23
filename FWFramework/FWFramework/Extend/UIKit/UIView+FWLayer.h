//
//  UIView+FWLayer.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

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
- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius;

#pragma mark - Gradient

/**
 *  创建渐变层，需手工addLayer
 *
 *  @param frame      渐变渔区
 *  @param colors     渐变颜色，CGColor数组，如[黑，白，黑]
 *  @param locations  渐变位置，0~1，如[0.25, 0.5, 0.75]对应颜色为[0-0.25黑,0.25-0.5黑渐变白,0.5-0.75白渐变黑,0.75-1黑]
 *  @param startPoint 渐变开始点，设置渐变方向，左上点为(0,0)，右下点为(1,1)
 *  @param endPoint   渐变结束点
 *
 *  @return 渐变Layer
 */
- (CAGradientLayer *)fwGradientLayer:(CGRect)frame
                              colors:(NSArray *)colors
                           locations:(NSArray<NSNumber *> *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint;

// 绘制渐变颜色，需要在drawRect中调用，只支持四个方向，默认从上到下
- (void)fwDrawGradient:(CGRect)rect
             startEdge:(UIRectEdge)startEdge
            startColor:(UIColor *)startColor
              endColor:(UIColor *)endColor;

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
                gradientBlock:(void (^)(CALayer *layer))gradientBlock
                  strokeColor:(UIColor *)strokeColor
                  strokeWidth:(CGFloat)strokeWidth;

@end
