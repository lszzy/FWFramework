//
//  UIView+FWAnimation.h
//  FWFramework
//
//  Created by wuyong on 2017/5/27.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAAnimation (FWAnimation)

// 设置动画开始回调，需要在add之前添加，因为add时会自动拷贝一份对象
- (void)fwSetStartBlock:(void (^)(CAAnimation *animation))startBlock;

// 设置动画停止回调
- (void)fwSetStopBlock:(void (^)(CAAnimation *animation, BOOL finished))stopBlock;

@end

#pragma mark - UIView+FWAnimation

@interface UIView (FWAnimation)

#pragma mark - Block

/*!
 @brief 取消动画效果执行block
 
 @param block 动画代码块
 */
+ (void)fwAnimateNoneWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block;

/*!
 @brief 取消动画效果执行block
 
 @param block 动画代码块
 @param completion 完成事件
 */
+ (void)fwAnimateNoneWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion;

/*!
 @brief 执行block动画完成后执行指定回调
 
 @param block 动画代码块
 @param completion 完成事件
 */
+ (void)fwAnimateWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion;

#pragma mark - Animation

/**
 @brief 添加UIView动画
 @discussion 如果动画过程中需要获取进度，可通过添加CADisplayLink访问self.layer.presentationLayer获取
 
 @param block      动画代码块
 @param duration   持续时间
 @param completion 完成事件
 */
- (void)fwAddAnimationWithBlock:(void (^)(void))block
                       duration:(NSTimeInterval)duration
                     completion:(nullable void (^)(BOOL finished))completion;

/**
 添加UIView动画
 
 @param curve      动画速度
 @param transition 动画类型
 @param duration   持续时间，默认0.2
 @param completion 完成事件
 */
- (void)fwAddAnimationWithCurve:(UIViewAnimationCurve)curve
                     transition:(UIViewAnimationTransition)transition
                       duration:(NSTimeInterval)duration
                     completion:(nullable void (^)(BOOL finished))completion;

/**
 添加CABasicAnimation动画
 
 @param keyPath    动画路径
 @param fromValue  开始值
 @param toValue    结束值
 @param duration   持续时间，0为默认(0.25秒)
 @param completion 完成事件
 @return CABasicAnimation
 */
- (CABasicAnimation *)fwAddAnimationWithKeyPath:(NSString *)keyPath
                                      fromValue:(id)fromValue
                                        toValue:(id)toValue
                                       duration:(CFTimeInterval)duration
                                     completion:(nullable void (^)(BOOL finished))completion;

/**
 添加转场动画
 
 @param option     动画选项
 @param block      动画代码块
 @param duration   持续时间
 @param completion 完成事件
 */
- (void)fwAddTransitionWithOption:(UIViewAnimationOptions)option
                            block:(void (^)(void))block
                         duration:(NSTimeInterval)duration
                       completion:(nullable void (^)(BOOL finished))completion;

/**
 添加转场动画
 
 @param toView     目标视图
 @param option     动画选项
 @param duration   持续时间
 @param completion 完成事件
 */
- (void)fwAddTransitionToView:(UIView *)toView
                   withOption:(UIViewAnimationOptions)option
                     duration:(NSTimeInterval)duration
                   completion:(nullable void (^)(BOOL finished))completion;

/**
 添加CATransition转场动画
 备注：移除动画调用[self.layer removeAllAnimations]
 
 @param type           动画类型
 @param subtype        子类型
 @param timingFunction 动画速度
 @param duration       持续时间，0为默认(0.25秒)
 @param completion     完成事件
 @return CATransition
 */
- (CATransition *)fwAddTransitionWithType:(NSString *)type
                                  subtype:(NSString *)subtype
                           timingFunction:(NSString *)timingFunction
                                 duration:(CFTimeInterval)duration
                               completion:(nullable void (^)(BOOL finished))completion;

/**
 移除所有视图动画
 */
- (void)fwRemoveAllAnimations;

#pragma mark - Custom

/**
 *  绘制动画
 *
 *  @param layer      CAShapeLayer层
 *  @param duration   持续时间
 *  @param completion 完成回调
 *  @return CABasicAnimation
 */
- (CABasicAnimation *)fwStrokeWithLayer:(CAShapeLayer *)layer
                               duration:(NSTimeInterval)duration
                             completion:(nullable void (^)(BOOL finished))completion;

/**
 *  水平摇摆动画
 *
 *  @param times      摇摆次数，默认10
 *  @param delta      摇摆宽度，默认5
 *  @param duration   单次时间，默认0.03
 *  @param completion 完成回调
 */
- (void)fwShakeWithTimes:(int)times
                   delta:(CGFloat)delta
                duration:(NSTimeInterval)duration
              completion:(nullable void (^)(BOOL finished))completion;

/**
 *  渐显隐动画
 *
 *  @param alpha      透明度
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fwFadeWithAlpha:(float)alpha
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion;

/**
 *  旋转动画
 *
 *  @param degree     旋转度数，备注：逆时针需设置-179.99。使用CAAnimation无此问题
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fwRotateWithDegree:(CGFloat)degree
                  duration:(NSTimeInterval)duration
                completion:(nullable void (^)(BOOL finished))completion;

/**
 *  缩放动画
 *
 *  @param scaleX     X轴缩放率
 *  @param scaleY     Y轴缩放率
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fwScaleWithScaleX:(float)scaleX
                   scaleY:(float)scaleY
                 duration:(NSTimeInterval)duration
               completion:(nullable void (^)(BOOL finished))completion;

/**
 *  移动动画
 *
 *  @param point      目标点
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fwMoveWithPoint:(CGPoint)point
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion;

/**
 *  移动变化动画
 *
 *  @param frame      目标区域
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fwMoveWithFrame:(CGRect)frame
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
