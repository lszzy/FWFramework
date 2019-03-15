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

#pragma mark - FWAnimatedTransition

// 转场动画类
@interface FWAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning>

#pragma mark - Block

// 快速创建句柄转场
+ (instancetype)transitionWithBlock:(void (^)(FWAnimatedTransition *transition))block;

// 设置动画句柄
@property (nonatomic, copy) void (^block)(FWAnimatedTransition *transition);

#pragma mark - Public

// 动画持续时间，必须大于0，默认0.35秒
@property (nonatomic, assign) NSTimeInterval duration;

// 获取动画类型，默认根据上下文判断
@property (nonatomic, assign) FWAnimatedTransitionType type;

#pragma mark - Animate

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
// 执行动画，子类重写，可选
- (void)animate;
// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

@end

#pragma mark - FWSwipeAnimationTransition

// 滑动转场动画类
@interface FWSwipeAnimationTransition : FWAnimatedTransition

// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection;

// 指定进入(push|present)方向，默认Left
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;
// 指定消失(pop|dismiss)方向，默认Right
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end

#pragma mark - FWInteractiveTransition

// 百分比交互转场
@interface FWInteractiveTransition : UIPercentDrivenInteractiveTransition

// 设置交互边缘方向，默认UIRectEdgeTop
@property (nonatomic, assign) UIRectEdge interactiveEdge;

// 设置手势开始时动作句柄，比如调用push|pop|present|dismiss方法
@property (nonatomic, copy) void(^interactiveBlock)(void);

// 动画完成多少百分比后，释放手指可以完成转场，少于该值将取消转场。取值范围：[0 ，1），默认：0.5
@property (nonatomic, assign) CGFloat percentOfInteractive;

// 动画完成多少百分比后，直接完成转场（默认：0 表示不启用）（0 ，1]
@property (nonatomic, assign) CGFloat percentOfFinished;

// 用来调节完成百分比，数值越大越快（默认：0 表示不启用）
@property (nonatomic, assign) CGFloat speedOfPercent;

// 是否正在交互中，手势开始才会标记YES，手势结束标记NO
@property (nonatomic, assign, readonly) BOOL isInteractive;

// 绑定交互控制器，自动添加pan手势。需要vc.view存在时调用才生效
- (void)interactWithViewController:(UIViewController *)viewController;

@end

#pragma mark - FWTransitionDelegate

// 视图控制器转场代理
@interface FWTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

// 创建转场代理对象，进入和消失都使用该对象，nil时为系统转场
+ (instancetype)delegateWithTransition:(FWAnimatedTransition *)transition;

// 设置转场对象，进入和消失都使用该对象，nil时为系统转场
@property (nonatomic, strong) FWAnimatedTransition *transition;

@end

#pragma mark - UIViewController+FWTransition

// 视图控制器转场分类，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
@interface UIViewController (FWTransition)

// 视图控制器present|dismiss转场代理。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> fwModalTransitionDelegate;

// 视图控制器push|pop转场代理，代理导航控制器转场，需在fwNavigationTransitionDelegate设置为FWTransitionDelegate后生效
@property (nonatomic, strong) FWTransitionDelegate *fwViewTransitionDelegate;

@end

#pragma mark - UINavigationController+FWTransition

// 导航控制器转场分类
@interface UINavigationController (FWTransition)

// 导航控制器push|pop转场代理。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
@property (nonatomic, strong) id<UINavigationControllerDelegate> fwNavigationTransitionDelegate;

@end
