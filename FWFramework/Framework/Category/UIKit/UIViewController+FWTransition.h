//
//  UIViewController+FWTransition.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - FWAnimatedTransitionType

/*!
 @brief 转场动画类型
 
 @const FWAnimatedTransitionTypeNone 转场未开始
 @const FWAnimatedTransitionTypePush push转场
 @const FWAnimatedTransitionTypePop pop转场
 @const FWAnimatedTransitionTypePresent present转场
 @const FWAnimatedTransitionTypeDismiss dismiss转场
 */
typedef NS_ENUM(NSInteger, FWAnimatedTransitionType) {
    FWAnimatedTransitionTypeNone = 0,
    FWAnimatedTransitionTypePush,
    FWAnimatedTransitionTypePop,
    FWAnimatedTransitionTypePresent,
    FWAnimatedTransitionTypeDismiss,
};

#pragma mark - FWAnimatedTransitionDelegate

@class FWAnimatedTransition;

// 转场动画代理
@protocol FWAnimatedTransitionDelegate <NSObject>

@optional

// 执行转场动画
- (void)fwAnimatedTransition:(FWAnimatedTransition *)transition;

// 转场动画持续时间
- (NSTimeInterval)fwAnimatedTransitionDuration:(FWAnimatedTransition *)transtion;

@end

#pragma mark - FWAnimatedTransition

// 转场动画类。实现任一转场方式即可：delegate|block|inherit
@interface FWAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning>

#pragma mark - Factory

// 1. 创建转场：代理方式
+ (instancetype)transitionWithDelegate:(id<FWAnimatedTransitionDelegate>)delegate;

// 2. 创建转场：句柄方式
+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *transition))block;

// 3. 创建转场：继承方式
+ (instancetype)transition;

#pragma mark - Public

// 设置动画代理
@property (nonatomic, weak) id<FWAnimatedTransitionDelegate> delegate;

// 设置动画句柄
@property (nonatomic, copy) void (^block)(FWAnimatedTransition *transition);

// 动画持续时间。默认使用系统时间(大约0.25秒)
@property (nonatomic, assign) NSTimeInterval duration;

// 转场动画类型，只读
@property (nonatomic, assign, readonly) FWAnimatedTransitionType type;

// 转场上下文，只读
@property (nonatomic, weak, readonly) id<UIViewControllerContextTransitioning> transitionContext;

// 转场来源视图控制器，只读
@property (nonatomic, weak, readonly) UIViewController *fromViewController;

// 转场目标视图控制器，只读
@property (nonatomic, weak, readonly) UIViewController *toViewController;

// 转场来源视图，只读
@property (nonatomic, weak, readonly) UIView *fromView;

// 转场目标视图，只读
@property (nonatomic, weak, readonly) UIView *toView;

// 标记动画开始(自动添加视图到容器)
- (void)start;

// 执行转场动画，子类重写
- (void)transition;

// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

@end

#pragma mark - FWSwipeAnimationTransition

// 滑动转场动画类
@interface FWSwipeAnimationTransition : FWAnimatedTransition

// 创建滑动转场，指定in(push|present)和out(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection outDirection:(UISwipeGestureRecognizerDirection)outDirection;

// 指定in(push|present)方向，默认Left
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;

// 指定out(pop|dismiss)方向，默认Right
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end
