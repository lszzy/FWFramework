//
//  FWQuartzCore.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIView+FWQuartzCore

@interface UIView (FWQuartzCore)

#pragma mark - Animation

/**
 添加UIView动画，使用默认动画参数
 @note 如果动画过程中需要获取进度，可通过添加CADisplayLink访问self.layer.presentationLayer获取，下同
 
 @param block      动画代码块
 @param duration   持续时间，一般0.25
 @param completion 完成事件
 */
- (void)fw_addAnimationWithBlock:(void (^)(void))block
                       duration:(NSTimeInterval)duration
                     completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 添加UIView动画
 
 @param curve      动画速度
 @param transition 动画类型
 @param duration   持续时间，默认0.2
 @param completion 完成事件
 */
- (void)fw_addAnimationWithCurve:(UIViewAnimationCurve)curve
                     transition:(UIViewAnimationTransition)transition
                       duration:(NSTimeInterval)duration
                     completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 添加CABasicAnimation动画
 
 @param keyPath    动画路径
 @param fromValue  开始值
 @param toValue    结束值
 @param duration   持续时间，0为默认(0.25秒)
 @param completion 完成事件
 @return CABasicAnimation
 */
- (CABasicAnimation *)fw_addAnimationWithKeyPath:(NSString *)keyPath
                                      fromValue:(id)fromValue
                                        toValue:(id)toValue
                                       duration:(CFTimeInterval)duration
                                     completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 添加转场动画，可指定animationsEnabled，一般用于window切换rootViewController
 
 @param option     动画选项
 @param block      动画代码块
 @param duration   持续时间
 @param animationsEnabled 是否启用动画
 @param completion 完成事件
 */
- (void)fw_addTransitionWithOption:(UIViewAnimationOptions)option
                            block:(void (^)(void))block
                         duration:(NSTimeInterval)duration
                animationsEnabled:(BOOL)animationsEnabled
                       completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 添加CATransition转场动画
 备注：移除动画可调用[self fw_removeAnimation]
 
 @param type           动画类型
 @param subtype        子类型
 @param timingFunction 动画速度
 @param duration       持续时间，0为默认(0.25秒)
 @param completion     完成事件
 @return CATransition
 */
- (CATransition *)fw_addTransitionWithType:(NSString *)type
                                  subtype:(nullable NSString *)subtype
                           timingFunction:(nullable NSString *)timingFunction
                                 duration:(CFTimeInterval)duration
                               completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 移除单个框架视图动画
 */
- (void)fw_removeAnimation NS_REFINED_FOR_SWIFT;

/**
 移除所有视图动画
 */
- (void)fw_removeAllAnimations NS_REFINED_FOR_SWIFT;

/**
 *  绘制动画
 *
 *  @param layer      CAShapeLayer层
 *  @param duration   持续时间
 *  @param completion 完成回调
 *  @return CABasicAnimation
 */
- (CABasicAnimation *)fw_strokeWithLayer:(CAShapeLayer *)layer
                               duration:(NSTimeInterval)duration
                             completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  水平摇摆动画
 *
 *  @param times      摇摆次数，默认10
 *  @param delta      摇摆宽度，默认5
 *  @param duration   单次时间，默认0.03
 *  @param completion 完成回调
 */
- (void)fw_shakeWithTimes:(NSInteger)times
                   delta:(CGFloat)delta
                duration:(NSTimeInterval)duration
              completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  渐显隐动画
 *
 *  @param alpha      透明度
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fw_fadeWithAlpha:(float)alpha
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  渐变代码块动画
 *
 *  @param block      动画代码块，比如调用imageView.setImage:方法
 *  @param duration   持续时长，建议0.5
 *  @param completion 完成回调
 */
- (void)fw_fadeWithBlock:(void (^)(void))block
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  旋转动画
 *
 *  @param degree     旋转度数，备注：逆时针需设置-179.99。使用CAAnimation无此问题
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fw_rotateWithDegree:(CGFloat)degree
                  duration:(NSTimeInterval)duration
                completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  缩放动画
 *
 *  @param scaleX     X轴缩放率
 *  @param scaleY     Y轴缩放率
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fw_scaleWithScaleX:(float)scaleX
                   scaleY:(float)scaleY
                 duration:(NSTimeInterval)duration
               completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  移动动画
 *
 *  @param point      目标点
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fw_moveWithPoint:(CGPoint)point
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 *  移动变化动画
 *
 *  @param frame      目标区域
 *  @param duration   持续时长
 *  @param completion 完成回调
 */
- (void)fw_moveWithFrame:(CGRect)frame
               duration:(NSTimeInterval)duration
             completion:(nullable void (^)(BOOL finished))completion NS_REFINED_FOR_SWIFT;

/**
 取消动画效果执行block
 
 @param block 动画代码块
 @param completion 完成事件
 */
+ (void)fw_animateNoneWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 执行block动画完成后执行指定回调
 
 @param block 动画代码块
 @param completion 完成事件
 */
+ (void)fw_animateWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion NS_REFINED_FOR_SWIFT;

#pragma mark - Drag

/// 是否启用拖动，默认NO
@property (nonatomic, assign) BOOL fw_dragEnabled NS_REFINED_FOR_SWIFT;

/// 拖动手势，延迟加载
@property (nonatomic, readonly) UIPanGestureRecognizer *fw_dragGesture NS_REFINED_FOR_SWIFT;

/// 设置拖动限制区域，默认CGRectZero，无限制
@property (nonatomic, assign) CGRect fw_dragLimit NS_REFINED_FOR_SWIFT;

/// 设置拖动动作有效区域，默认self.frame
@property (nonatomic, assign) CGRect fw_dragArea NS_REFINED_FOR_SWIFT;

/// 是否允许横向拖动(X)，默认YES
@property (nonatomic, assign) BOOL fw_dragHorizontal NS_REFINED_FOR_SWIFT;

/// 是否允许纵向拖动(Y)，默认YES
@property (nonatomic, assign) BOOL fw_dragVertical NS_REFINED_FOR_SWIFT;

/// 开始拖动回调
@property (nullable, nonatomic, copy) void (^fw_dragStartedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

/// 拖动移动回调
@property (nullable, nonatomic, copy) void (^fw_dragMovedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

/// 结束拖动回调
@property (nullable, nonatomic, copy) void (^fw_dragEndedBlock)(UIView *) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWGradientView

/// 渐变View，无需设置渐变Layer的frame等，支持自动布局
NS_SWIFT_NAME(GradientView)
@interface FWGradientView : UIView

@property (nonatomic, strong, readonly) CAGradientLayer *gradientLayer;

@property (nullable, copy) NSArray *colors;

@property (nullable, copy) NSArray<NSNumber *> *locations;

@property CGPoint startPoint;

@property CGPoint endPoint;

- (instancetype)initWithColors:(nullable NSArray<UIColor *> *)colors locations:(nullable NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

- (void)setColors:(nullable NSArray<UIColor *> *)colors locations:(nullable NSArray<NSNumber *> *)locations startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

@end

NS_ASSUME_NONNULL_END
