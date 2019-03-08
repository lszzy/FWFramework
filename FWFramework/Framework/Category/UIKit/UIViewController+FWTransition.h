//
//  UIViewController+FWTransition.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - FWAnimatedTransition

/*!
 @brief 转场动画类型
 
 @const FWAnimatedTransitionTypePush push转场
 @const FWAnimatedTransitionTypePop pop转场
 @const FWAnimatedTransitionTypePresent present转场
 @const FWAnimatedTransitionTypeDismiss dismiss转场
 */
typedef NS_ENUM(NSInteger, FWAnimatedTransitionType) {
    FWAnimatedTransitionTypePush = 0,
    FWAnimatedTransitionTypePop,
    FWAnimatedTransitionTypePresent,
    FWAnimatedTransitionTypeDismiss,
};

@class FWAnimatedTransition;

// 转场动画代理
@protocol FWAnimatedTransitionDelegate <NSObject>

@optional

// 转场动画持续时间(如果小于等于0，使用默认时间0.25)
- (NSTimeInterval)fwAnimatedTransitionDuration:(FWAnimatedTransition *)transtion;

// 执行转场动画
- (void)fwAnimatedTransition:(FWAnimatedTransition *)transition;

@end

// 转场动画类
@interface FWAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning>

#pragma mark - Delegate

// 代理方式：动画代理
@property (nonatomic, weak) id<FWAnimatedTransitionDelegate> delegate;

#pragma mark - Block

// 句柄方式：动画持续时间(如果小于等于0，使用默认时间0.25)
@property (nonatomic, assign) NSTimeInterval duration;

// 句柄方式：执行转场动画
@property (nonatomic, copy) void (^transitionBlock)(FWAnimatedTransition *transition);

#pragma mark - Public

// 转场动画类型
@property (nonatomic, assign) FWAnimatedTransitionType type;

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

#pragma mark - FWViewTransitionDelegate

// 视图控制器转场动画代理类
@interface FWViewTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

// 视图控制器转场动画
@property (nonatomic, strong) FWAnimatedTransition *animatedTransition;

@end

// 视图控制器转场动画分类
@interface UIViewController (FWTransition)

// 转场动画代理，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> fwViewTransitionDelegate;

// 代理导航控制器转场动画
@property (nonatomic, strong) FWAnimatedTransition *fwNavigationAnimatedTransition;

@end

#pragma mark - FWNavigationTransitionDelegate

// 导航控制器转场动画代理类
@interface FWNavigationTransitionDelegate : NSObject <UINavigationControllerDelegate>

// 导航控制器转场动画
@property (nonatomic, strong) FWAnimatedTransition *animatedTransition;

// 是否启用视图控制器的导航栏转场动画，会优先调用vc.fwNavigationAnimatedTransition
@property (nonatomic, assign) BOOL viewControllerTransitionEnabled;

@end

// 导航控制器转场动画分类
@interface UINavigationController (FWTransition)

// 导航控制器转场动画代理，一直生效直到设置为nil
@property (nonatomic, strong) id<UINavigationControllerDelegate> fwNavigationTransitionDelegate;

@end
