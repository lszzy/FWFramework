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

// 设置动画代理，方式一
@property (nonatomic, weak) id<FWAnimatedTransitionDelegate> delegate;

// 设置动画句柄，方式二
@property (nonatomic, copy) void (^block)(FWAnimatedTransition *transition);

// 动画持续时间。默认使用系统时间(大约0.25秒)
@property (nonatomic, assign) NSTimeInterval duration;

#pragma mark - Interactive

// 设置动画转场交互，如果需要支持交互式转场，设置此属性即可。如果类型为FWPercentInteractiveTransition，自动设置参数
@property (nonatomic, strong) id<UIViewControllerInteractiveTransitioning> interactiveTransition;

#pragma mark - Transition

// 转场动画类型。默认自动根据上下文判断
@property (nonatomic, assign) FWAnimatedTransitionType type;

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

// 执行动画，子类重写，方式三
- (void)animate;

// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

@end

#pragma mark - FWSwipeAnimationTransition

// 滑动转场动画类
@interface FWSwipeAnimationTransition : FWAnimatedTransition

// 创建滑动转场，指定in(push|present)和out(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection;

// 指定in(push|present)方向，默认Left
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;

// 指定out(pop|dismiss)方向，默认Right
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end

#pragma mark - FWPercentInteractiveTransition

// 百分比交互转场
@interface FWPercentInteractiveTransition : UIPercentDrivenInteractiveTransition

// 初始化交互转场，指定控制器和拖动边缘。自动添加pan手势到vc.view
- (instancetype)initWithViewController:(UIViewController *)viewController
                          draggingEdge:(UIRectEdge)edge NS_DESIGNATED_INITIALIZER;

// 初始化交互转场，指定pan手势和拖动边缘。pan手势需手工添加到view
- (instancetype)initWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
                             draggingEdge:(UIRectEdge)edge NS_DESIGNATED_INITIALIZER;

// 禁用默认初始化方法
- (instancetype)init NS_UNAVAILABLE;

// 转场动画类型，如果设置此值，会自动调用push|pop|present|dismiss
@property (nonatomic, assign) FWAnimatedTransitionType type;

// 如果type为push(必须)|pop(可选)，需指定对应的navigationController
@property (nonatomic, weak) UINavigationController *navigationController;

// 动画完成多少百分比后，释放手指可以完成转场，少于该值将取消转场。取值范围：[0 ，1），默认：0.5
@property (nonatomic, assign) CGFloat percentOfInteractive;

// 动画完成多少百分比后，直接完成转场（默认：0 表示不启用）（0 ，1]
@property (nonatomic, assign) CGFloat percentOfFinished;

// 用来调节完成完成百分比，数值越大越快（默认：0 表示不启用）
@property (nonatomic, assign) CGFloat speedOfPercent;

@end

#pragma mark - FWTransitionDelegate

// 视图控制器转场代理
@interface FWTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

// 创建转场代理对象，注意进入和消失为同一转场对象，nil时为系统转场
+ (instancetype)delegateWithTransition:(id<UIViewControllerAnimatedTransitioning>)transition;

// 创建转场代理对象，分别设置进入和消失转场对象，nil时为系统转场
+ (instancetype)delegateWithInTransition:(id<UIViewControllerAnimatedTransitioning>)inTransition
                           outTransition:(id<UIViewControllerAnimatedTransitioning>)outTransition;

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
