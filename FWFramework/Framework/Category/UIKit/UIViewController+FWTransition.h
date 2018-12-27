//
//  UIViewController+FWTransition.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - FWViewTransition

@class FWViewTransition;

// 视图转场动画代理
@protocol FWViewTransitionDelegate <NSObject>

@optional

// 动画持续时间(如果小于等于0，使用默认时间0.25)
- (NSTimeInterval)fwViewDuration:(FWViewTransition *)transtion;

// present转场动画
- (void)fwPresent:(FWViewTransition *)transition;

// dismiss转场动画
- (void)fwDismiss:(FWViewTransition *)transition;

@end

// 视图转场动画
@interface FWViewTransition : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

#pragma mark - Delegate

// 代理方式：动画代理
@property (nonatomic, weak) id<FWViewTransitionDelegate> delegate;

#pragma mark - Block

// 句柄方式：动画持续时间(如果小于等于0，使用默认时间0.25)
@property (nonatomic, assign) NSTimeInterval duration;

// 句柄方式：present转场动画
@property (nonatomic, copy) void (^presentBlock)(FWViewTransition *transition);

// 句柄方式：dismiss转场动画
@property (nonatomic, copy) void (^dismissBlock)(FWViewTransition *transition);

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

#pragma mark - UINavigationController+FWTransition

// 视图控制器转场动画分类
@interface UIViewController (FWTransition)

/**
 *  视图控制器转场动画，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
 */
@property (nonatomic, strong) FWViewTransition *fwViewTransition;

@end
