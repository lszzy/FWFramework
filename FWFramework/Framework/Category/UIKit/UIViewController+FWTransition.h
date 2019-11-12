//
//  UIViewController+FWTransition.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
@interface FWAnimatedTransition : NSObject <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

#pragma mark - Public

// 创建系统转场单例，不支持交互转场
+ (instancetype)systemTransition;

// 创建动画句柄转场
+ (instancetype)transitionWithBlock:(nullable void (^)(FWAnimatedTransition *transition))block;

// 设置动画句柄
@property (nullable, nonatomic, copy) void (^transitionBlock)(FWAnimatedTransition *transition);

// 动画持续时间，必须大于0，默认0.35秒
@property (nonatomic, assign) NSTimeInterval transitionDuration;

// 获取动画类型，默认根据上下文判断
@property (nonatomic, assign) FWAnimatedTransitionType transitionType;

#pragma mark - Interactive

// 设置进入交互转场，可选，需要在调用push|present之前设置并绑定控制器
@property (nullable, nonatomic, strong) id<UIViewControllerInteractiveTransitioning> inInteractiveTransition;
// 设置消失交互转场，可选，需要在调用pop|dismiss之前设置并绑定控制器。当设置为FWPercentInteractiveTransition时，会自动绑定
@property (nullable, nonatomic, strong) id<UIViewControllerInteractiveTransitioning> outInteractiveTransition;

#pragma mark - Presentation

// 设置展示控制器创建句柄，自定义弹出效果。present时建议设置modalPresentationStyle为UIModalPresentationCustom
@property (nullable, nonatomic, copy) UIPresentationController *(^presentationBlock)(UIViewController *presented, UIViewController *presenting);

// 设置展示控制器，自定义弹出效果。present时建议设置modalPresentationStyle为UIModalPresentationCustom
@property (nullable, nonatomic, strong) UIPresentationController *presentationController;

#pragma mark - Animate

// 转场上下文，只读
@property (nullable, nonatomic, weak, readonly) id<UIViewControllerContextTransitioning> transitionContext;

// 标记动画开始(自动添加视图到容器)
- (void)start;
// 执行动画，子类重写，可选
- (void)animate;
// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

@end

#pragma mark - FWSwipeAnimatedTransition

// 滑动转场动画类
@interface FWSwipeAnimatedTransition : FWAnimatedTransition

// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection;

// 指定进入(push|present)方向，默认上滑Up
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;
// 指定消失(pop|dismiss)方向，默认下滑Down
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end

#pragma mark - FWPercentInteractiveTransition

@class FWPanGestureRecognizer;

// 百分比交互转场
@interface FWPercentInteractiveTransition : UIPercentDrivenInteractiveTransition

// 设置交互方向，默认下滑Down。可通过percentBlock和transitionBlock实现多个方向交互
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;

// 设置手势开始时动作句柄，比如调用push|pop|present|dismiss方法
@property (nullable, nonatomic, copy) void(^interactiveBlock)(void);

// 自定义进度计算方法，默认根据direction和translation计算进度
@property (nullable, nonatomic, copy) CGFloat(^percentBlock)(UIPanGestureRecognizer *sender);

// 自定义转场动画动作句柄，比如指定转场动画方向等。可通过isInteractive区分是否交互转场
@property (nullable, nonatomic, copy) void(^transitionBlock)(FWAnimatedTransition *transition);

// 配置完成判定百分比，当交互大于该值时判定为交互完成，默认0.5
@property (nonatomic, assign) CGFloat completionPercent;

// 是否正在交互中，手势开始才会标记为YES，手势结束标记为NO
@property (nonatomic, assign, readonly) BOOL isInteractive;

// 交互pan手势，调用interactWithViewController之后才存在
@property (nullable, nonatomic, weak, readonly) FWPanGestureRecognizer *gestureRecognizer;

// 绑定交互控制器，自动添加pan手势。需要vc.view存在时调用才生效
- (void)interactWithViewController:(UIViewController *)viewController;

@end

#pragma mark - FWPresentationController

// 自定义展示控制器。present时建议设置modalPresentationStyle为UIModalPresentationCustom
@interface FWPresentationController : UIPresentationController

// 是否显示暗色背景，默认YES
@property (nonatomic, assign) BOOL showDimming;

// 是否可以点击暗色背景关闭，默认YES
@property (nonatomic, assign) BOOL dimmingClick;

// 设置弹出视图的左上和右上圆角，默认0
@property (nonatomic, assign) CGFloat cornerRadius;

// 设置弹出视图的frame，默认CGRectZero占满，优先级高
@property (nonatomic, assign) CGRect presentedFrame;

// 设置弹出视图的顶部距离，默认0占满，优先级低
@property (nonatomic, assign) CGFloat verticalInset;

@end

#pragma mark - UIViewController+FWTransition

// 视图控制器转场分类，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
@interface UIViewController (FWTransition)

// 视图控制器present|dismiss转场。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
@property (nullable, nonatomic, strong) FWAnimatedTransition *fwModalTransition;

// 视图控制器push|pop转场，代理导航控制器转场，需在fwNavigationTransition设置后生效
@property (nullable, nonatomic, strong) FWAnimatedTransition *fwViewTransition;

@end

#pragma mark - UINavigationController+FWTransition

// 导航控制器转场分类
@interface UINavigationController (FWTransition)

// 导航控制器push|pop转场。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
@property (nullable, nonatomic, strong) FWAnimatedTransition *fwNavigationTransition;

@end

NS_ASSUME_NONNULL_END
