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

// 转场动画类，默认系统动画。实现任一转场方式即可：delegate|block|inherit
@interface FWAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

#pragma mark - Factory

// 创建转场：代理方式
+ (instancetype)transitionWithDelegate:(id<FWAnimatedTransitionDelegate>)delegate;

// 创建转场：句柄方式
+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *transition))block;

// 创建转场：继承方式
+ (instancetype)transition;

#pragma mark - Public

// 设置动画代理
@property (nonatomic, weak) id<FWAnimatedTransitionDelegate> delegate;

// 设置动画句柄
@property (nonatomic, copy) void (^block)(FWAnimatedTransition *transition);

// 是否启用转场。默认YES，设为NO可禁用
@property (nonatomic, assign) BOOL enabled;

// 动画持续时间。默认使用系统时间(大约0.25秒)
@property (nonatomic, assign) NSTimeInterval duration;

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

#pragma mark - FWSystemAnimationTransition

// 系统转场动画类，可通过transition方法获取单例
@interface FWSystemAnimationTransition : FWAnimatedTransition

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

#pragma mark - UIViewController+FWTransition

// 视图控制器转场动画分类，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
@interface UIViewController (FWTransition)

// 视图控制器present|dismiss转场动画，注意会修改transitioningDelegate
@property (nonatomic, strong) FWAnimatedTransition *fwModalTransition;

// 视图控制器push|pop转场动画，代理导航控制器转场动画，fwNavigationTransition设置后生效
@property (nonatomic, strong) FWAnimatedTransition *fwViewTransition;

@end

#pragma mark - UINavigationController+FWTransition

// 导航控制器转场动画分类
@interface UINavigationController (FWTransition)

// 导航控制器push|pop转场动画，注意会修改delegate，一直生效直到设置为nil
@property (nonatomic, strong) FWAnimatedTransition *fwNavigationTransition;

@end
