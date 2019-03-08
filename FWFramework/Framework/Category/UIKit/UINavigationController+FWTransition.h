//
//  UINavigationController+FWTransition.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - FWNavigationTransition

@class FWNavigationTransition;

// 导航转场动画代理
@protocol FWNavigationTransitionDelegate <NSObject>

@optional

// 动画持续时间(如果小于等于0，使用默认时间0.25)
- (NSTimeInterval)fwNavigationDuration:(FWNavigationTransition *)transtion;

// push转场动画
- (void)fwPush:(FWNavigationTransition *)transition;

// pop转场动画
- (void)fwPop:(FWNavigationTransition *)transition;

@end

// 导航转场动画
@interface FWNavigationTransition : NSObject <UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning>

#pragma mark - Delegate

// 代理方式：动画代理
@property (nonatomic, weak) id<FWNavigationTransitionDelegate> delegate;

#pragma mark - Block

// 句柄方式：动画持续时间(如果小于等于0，使用默认时间0.25)
@property (nonatomic, assign) NSTimeInterval duration;

// 句柄方式：push转场动画
@property (nonatomic, copy) void (^pushBlock)(FWNavigationTransition *transition);

// 句柄方式：pop转场动画
@property (nonatomic, copy) void (^popBlock)(FWNavigationTransition *transition);

#pragma mark - Public

// 转场上下文
@property (nonatomic, weak, readonly) id<UIViewControllerContextTransitioning> transitionContext;

// 转场来源视图
@property (nonatomic, weak, readonly) UIView *fromView;

// 转场目标视图
@property (nonatomic, weak, readonly) UIView *toView;

// 标记动画开始(自动添加视图到容器)
- (void)start;

// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

// 手工标记动画完成
- (void)complete:(BOOL)completed;

@end

#pragma mark - FWProxyNavigationTransition

// 导航控制器转场代理类，代理到视图控制器
@interface FWProxyNavigationTransition : NSObject <UINavigationControllerDelegate>

@end

@interface UIViewController (FWProxyNavigationTransition)

// 导航控制器转场代理，仅控制器生效
@property (nonatomic, strong) FWNavigationTransition *fwProxyNavigationTransition;

@end

#pragma mark - UINavigationController+FWTransition

// 导航控制器转场动画分类
@interface UINavigationController (FWTransition)

// 导航控制器转场动画，一直生效直到设置为nil
@property (nonatomic, strong) id<UINavigationControllerDelegate> fwNavigationTransition;

@end
