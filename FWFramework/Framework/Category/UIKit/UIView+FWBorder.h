//
//  UIView+FWBorder.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FWBorder)

#pragma mark - Default

/**
 * 绘制四边边框
 *
 * @param color 边框颜色
 * @param width 边框宽度
 */
- (void)fwSetBorderColor:(UIColor *)color width:(CGFloat)width;

/**
 * 绘制四边边框和四角圆角
 *
 * @param color  边框颜色
 * @param width  边框宽度
 * @param radius 圆角半径
 */
- (void)fwSetBorderColor:(UIColor *)color width:(CGFloat)width cornerRadius:(CGFloat)radius;

/**
 * 绘制四角圆角
 *
 * @param radius 圆角半径
 */
- (void)fwSetCornerRadius:(CGFloat)radius;

#pragma mark - Layer

/**
 * 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
 *
 * @param edge   边框类型，示例：UIRectEdgeTop | UIRectEdgeBottom
 * @param color  边框颜色
 * @param width  边框宽度
 */
- (void)fwSetBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width;

/**
 * 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
 *
 * @param edge       边框类型，示例：UIRectEdgeTop | UIRectEdgeBottom
 * @param color      边框颜色
 * @param width      边框宽度
 * @param leftInset  左内边距
 * @param rightInset 右内边距
 */
- (void)fwSetBorderLayer:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset;

/**
 * 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
 *
 * @param corner 圆角类型
 * @param radius 圆角半径
 */
- (void)fwSetCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius;

/**
 * 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
 *
 * @param corner 圆角类型
 * @param radius 圆角半径
 * @param color  边框宽度
 * @param width  边框颜色
 */
- (void)fwSetCornerLayer:(UIRectCorner)corner radius:(CGFloat)radius borderColor:(UIColor *)color width:(CGFloat)width;

#pragma mark - View

/**
 * 绘制单边或多边边框视图。使用AutoLayout
 *
 * @param edge   边框类型，示例：UIRectEdgeTop | UIRectEdgeBottom
 * @param color  边框颜色
 * @param width  边框宽度
 */
- (void)fwSetBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width;

/**
 * 绘制单边或多边边框。使用AutoLayout
 *
 * @param edge       边框类型，示例：UIRectEdgeTop | UIRectEdgeBottom
 * @param color      边框颜色
 * @param width      边框宽度
 * @param leftInset  左内边距
 * @param rightInset 右内边距
 */
- (void)fwSetBorderView:(UIRectEdge)edge color:(UIColor *)color width:(CGFloat)width leftInset:(CGFloat)leftInset rightInset:(CGFloat)rightInset;

@end
