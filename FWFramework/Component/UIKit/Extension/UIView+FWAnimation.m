//
//  UIView+FWAnimation.m
//  FWFramework
//
//  Created by wuyong on 2017/5/27.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIView+FWAnimation.h"
#import <objc/runtime.h>

#pragma mark - FWInnerAnimationTarget

@interface FWInnerAnimationTarget : NSObject <CAAnimationDelegate>

@property (nonatomic, copy) void (^startBlock)(CAAnimation *animation);

@property (nonatomic, copy) void (^stopBlock)(CAAnimation *animation, BOOL finished);

@end

@implementation FWInnerAnimationTarget

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim
{
    if (self.startBlock) {
        self.startBlock(anim);
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.stopBlock) {
        self.stopBlock(anim, flag);
    }
}

@end

#pragma mark - CAAnimation+FWAnimation

@implementation CAAnimation (FWAnimation)

- (FWInnerAnimationTarget *)fwInnerAnimationTarget:(BOOL)lazyload
{
    FWInnerAnimationTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target && lazyload) {
        target = [[FWInnerAnimationTarget alloc] init];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (void (^)(CAAnimation * _Nonnull))fwStartBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.startBlock;
}

- (void)setFwStartBlock:(void (^)(CAAnimation * _Nonnull))startBlock
{
    // 初始化事件代理
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.startBlock = startBlock;
    
    // 设置代理对象(默认强引用)
    self.delegate = target;
}

- (void (^)(CAAnimation * _Nonnull, BOOL))fwStopBlock
{
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:NO];
    return target.stopBlock;
}

- (void)setFwStopBlock:(void (^)(CAAnimation * _Nonnull, BOOL))stopBlock
{
    // 初始化事件代理
    FWInnerAnimationTarget *target = [self fwInnerAnimationTarget:YES];
    target.stopBlock = stopBlock;
    
    // 设置代理对象(默认强引用)
    self.delegate = target;
}

@end

#pragma mark - UIView+FWAnimation

@implementation UIView (FWAnimation)

#pragma mark - Block

+ (void)fwAnimateNoneWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block
{
    [UIView performWithoutAnimation:block];
}

+ (void)fwAnimateNoneWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion
{
    [UIView animateWithDuration:0 animations:block completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

+ (void)fwAnimateWithBlock:(nonnull __attribute__((noescape)) void (^)(void))block completion:(nullable __attribute__((noescape)) void (^)(void))completion
{
    if (!block) {
        return;
    }
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    block();
    [CATransaction commit];
}

#pragma mark - Animation

- (void)fwAddAnimationWithBlock:(void (^)(void))block
                     completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:(7<<16)
                     animations:block
                     completion:completion];
}

- (void)fwAddAnimationWithBlock:(void (^)(void))block
                       duration:(NSTimeInterval)duration
                     completion:(void (^)(BOOL finished))completion
{
    // 注意：AutoLayout动画需要调用父视图(如控制器self.view)的layoutIfNeeded更新布局才能生效
    [UIView animateWithDuration:duration
                     animations:block
                     completion:completion];
}

- (void)fwAddAnimationWithCurve:(UIViewAnimationCurve)curve
                     transition:(UIViewAnimationTransition)transition
                       duration:(NSTimeInterval)duration
                     completion:(void (^)(BOOL finished))completion
{
    [UIView beginAnimations:@"FWAnimation" context:NULL];
    [UIView setAnimationCurve:curve];
    // 默认值0.2
    [UIView setAnimationDuration:duration];
    [UIView setAnimationTransition:transition forView:self cache:NO];
    
    // 设置完成事件
    if (completion) {
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(fwInnerAnimationDidStop:finished:context:)];
        objc_setAssociatedObject(self, @selector(fwInnerAnimationDidStop:finished:context:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    
    [UIView commitAnimations];
}

- (void)fwInnerAnimationDidStop:(NSString *)animationId finished:(NSNumber *)finished context:(void *)context
{
    void (^completion)(BOOL finished) = objc_getAssociatedObject(self, @selector(fwInnerAnimationDidStop:finished:context:));
    if (completion) {
        completion([finished boolValue]);
    }
}

- (CABasicAnimation *)fwAddAnimationWithKeyPath:(NSString *)keyPath
                                      fromValue:(id)fromValue
                                        toValue:(id)toValue
                                       duration:(CFTimeInterval)duration
                                     completion:(void (^)(BOOL))completion
{
    // keyPath支持值如下：
    // transform.rotation[.(x|y|z)]: 轴旋转动画
    // transform.scale[.(x|y|z)]: 轴缩放动画
    // transform.translation[.(x|y|z)]: 轴平移动画
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue = fromValue;
    animation.toValue = toValue;
    // 默认值0.25
    animation.duration = duration;
    
    // 设置完成事件，需要在add之前设置才能生效，因为add时会copy动画对象
    if (completion) {
        animation.fwStopBlock = ^(CAAnimation *animation, BOOL finished) {
            completion(finished);
        };
    }
    
    [self.layer addAnimation:animation forKey:@"FWAnimation"];
    return animation;
}

- (void)fwAddTransitionWithOption:(UIViewAnimationOptions)option
                            block:(void (^)(void))block
                         duration:(NSTimeInterval)duration
                       completion:(void (^)(BOOL finished))completion
{
    [UIView transitionWithView:self
                      duration:duration
                       options:option
                    animations:block
                    completion:completion];
}

- (void)fwAddTransitionToView:(UIView *)toView
                   withOption:(UIViewAnimationOptions)option
                     duration:(NSTimeInterval)duration
                   completion:(void (^)(BOOL finished))completion
{
    [UIView transitionFromView:self
                        toView:toView
                      duration:duration
                       options:option
                    completion:completion];
}

- (CATransition *)fwAddTransitionWithType:(NSString *)type
                                  subtype:(NSString *)subtype
                           timingFunction:(NSString *)timingFunction
                                 duration:(CFTimeInterval)duration
                               completion:(void (^)(BOOL finished))completion
{
    // 默认动画完成后自动移除，removedOnCompletion为YES
    CATransition *transition = [CATransition new];
    
    /** type
     *
     *  各种动画效果
     *  kCATransitionFade           交叉淡化过渡(不支持过渡方向)，同fade，默认效果
     *  kCATransitionMoveIn         新视图移到旧视图上面
     *  kCATransitionPush           新视图把旧视图推出去
     *  kCATransitionReveal         显露效果(将旧视图移开,显示下面的新视图)
     *
     *  @"fade"                     交叉淡化过渡(不支持过渡方向)，默认效果
     *  @"moveIn"                   新视图移到旧视图上面
     *  @"push"                     新视图把旧视图推出去
     *  @"reveal"                   显露效果(将旧视图移开,显示下面的新视图)
     *
     *  @"cube"                     立方体翻滚效果
     *  @"pageCurl"                 向上翻一页
     *  @"pageUnCurl"               向下翻一页
     *  @"suckEffect"               收缩效果，类似系统最小化窗口时的神奇效果(不支持过渡方向)
     *  @"rippleEffect"             滴水效果,(不支持过渡方向)
     *  @"oglFlip"                  上下左右翻转效果
     *  @"rotate"                   旋转效果
     *  @"cameraIrisHollowOpen"     相机镜头打开效果(不支持过渡方向)
     *  @"cameraIrisHollowClose"    相机镜头关上效果(不支持过渡方向)
     */
    transition.type = type;
    
    /** subtype
     *
     *  各种动画方向
     *
     *  kCATransitionFromRight;      同字面意思(下同)
     *  kCATransitionFromLeft;
     *  kCATransitionFromTop;
     *  kCATransitionFromBottom;
     *
     *  当type为@"rotate"(旋转)的时候,它也有几个对应的subtype,分别为:
     *  90cw    逆时针旋转90°
     *  90ccw   顺时针旋转90°
     *  180cw   逆时针旋转180°
     *  180ccw  顺时针旋转180°
      *
     *  type与subtype的对应关系(必看),如果对应错误,动画不会显现.
     *  http://iphonedevwiki.net/index.php/CATransition
     */
    if (subtype) transition.subtype = subtype;
    
    /** timingFunction
     *
     *  用于变化起点和终点之间的插值计算,形象点说它决定了动画运行的节奏,比如是均匀变化(相同时间变化量相同)还是
     *  先快后慢,先慢后快还是先慢再快再慢.
     *
     *  动画的开始与结束的快慢,有五个预置分别为(下同):
     *  kCAMediaTimingFunctionLinear            线性,即匀速
     *  kCAMediaTimingFunctionEaseIn            先慢后快
     *  kCAMediaTimingFunctionEaseOut           先快后慢
     *  kCAMediaTimingFunctionEaseInEaseOut     先慢后快再慢
     *  kCAMediaTimingFunctionDefault           实际效果是动画中间比较快.
      */
    if (timingFunction) transition.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    
    // 动画持续时间，默认为0.25秒，传0即可
    transition.duration = duration;
    
    // 设置完成事件
    if (completion) {
        transition.fwStopBlock = ^(CAAnimation *animation, BOOL finished) {
            completion(finished);
        };
    }
    
    // 所有核心动画和特效都是基于CAAnimation(作用于CALayer)
    [self.layer addAnimation:transition forKey:@"FWAnimation"];
    return transition;
}

- (void)fwRemoveAnimation
{
    [self.layer removeAnimationForKey:@"FWAnimation"];
}

- (void)fwRemoveAllAnimations
{
    [self.layer removeAllAnimations];
}

#pragma mark - Custom

- (CABasicAnimation *)fwStrokeWithLayer:(CAShapeLayer *)layer
                               duration:(NSTimeInterval)duration
                             completion:(void (^)(BOOL finished))completion
{
    // strokeEnd动画，仅CAShapeLayer支持
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = duration;
    animation.fromValue = [NSNumber numberWithFloat:0.0];
    animation.toValue = [NSNumber numberWithFloat:1.0];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.autoreverses = NO;
    
    // 设置完成事件
    if (completion) {
        animation.fwStopBlock = ^(CAAnimation *animation, BOOL finished) {
            completion(finished);
        };
    }
    
    [layer addAnimation:animation forKey:@"FWAnimation"];
    return animation;
}

- (void)fwShakeWithTimes:(int)times
                   delta:(CGFloat)delta
                duration:(NSTimeInterval)duration
              completion:(void (^)(BOOL finished))completion
{
    [self fwShakeWithTimes:(times > 0 ? times : 10)
                     delta:(delta > 0 ? delta : 5)
                  duration:(duration > 0 ? duration : 0.03)
                 direction:1
              currentTimes:0
                completion:completion];
}

- (void)fwShakeWithTimes:(int)times
                   delta:(CGFloat)delta
                duration:(NSTimeInterval)duration
               direction:(NSInteger)direction
            currentTimes:(int)currentTimes
              completion:(void (^)(BOOL finished))completion
{
    // 是否是文本输入框
    BOOL isTextField = [self isKindOfClass:[UITextField class]];
    
    [UIView animateWithDuration:duration animations:^{
        if (isTextField) {
            // 水平摇摆
            self.transform = CGAffineTransformMakeTranslation(delta * direction, 0);
            // 垂直摇摆
            // self.transform = CGAffineTransformMakeTranslation(0, delta * direction);
        } else {
            // 水平摇摆
            self.layer.affineTransform = CGAffineTransformMakeTranslation(delta * direction, 0);
            // 垂直摇摆
            // self.layer.affineTransform = CGAffineTransformMakeTranslation(0, delta * direction);
        }
    } completion:^(BOOL finished) {
        if (currentTimes >= times) {
            [UIView animateWithDuration:duration animations:^{
                if (isTextField) {
                    self.transform = CGAffineTransformIdentity;
                } else {
                    self.layer.affineTransform = CGAffineTransformIdentity;
                }
            } completion:^(BOOL finished) {
                if (completion) {
                    completion(finished);
                }
            }];
            return;
        }
        [self fwShakeWithTimes:(times - 1)
                         delta:delta
                      duration:duration
                     direction:direction * -1
                  currentTimes:currentTimes + 1
                    completion:completion];
    }];
}

- (void)fwFadeWithAlpha:(float)alpha
               duration:(NSTimeInterval)duration
             completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.alpha = alpha;
                     }
                     completion:completion];
}

- (void)fwFadeWithBlock:(void (^)(void))block
               duration:(NSTimeInterval)duration
             completion:(void (^)(BOOL))completion
{
    [UIView transitionWithView:self
                      duration:duration
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:block
                    completion:completion];
}

- (void)fwRotateWithDegree:(CGFloat)degree
                  duration:(NSTimeInterval)duration
                completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.transform = CGAffineTransformRotate(self.transform, (degree * M_PI / 180.f));
                     }
                     completion:completion];
}

- (void)fwScaleWithScaleX:(float)scaleX
                   scaleY:(float)scaleY
                 duration:(NSTimeInterval)duration
               completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.transform = CGAffineTransformScale(self.transform, scaleX, scaleY);
                     } completion:completion];
}

- (void)fwMoveWithPoint:(CGPoint)point
               duration:(NSTimeInterval)duration
             completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.frame = CGRectMake(point.x, point.y, self.frame.size.width, self.frame.size.height);
                     } completion:completion];
}

- (void)fwMoveWithFrame:(CGRect)frame
               duration:(NSTimeInterval)duration
             completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.frame = frame;
                     } completion:completion];
}

@end
