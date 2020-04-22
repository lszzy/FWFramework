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

@class FWPanGestureRecognizer;

// 转场动画类，默认透明度变化
@interface FWAnimatedTransition : UIPercentDrivenInteractiveTransition <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

#pragma mark - Public

// 创建系统转场单例，不支持交互手势转场
+ (instancetype)systemTransition;

// 创建动画句柄转场
+ (instancetype)transitionWithBlock:(nullable void (^)(FWAnimatedTransition *transition))block;

// 设置动画句柄
@property (nullable, nonatomic, copy) void (^transitionBlock)(FWAnimatedTransition *transition);

// 动画持续时间，必须大于0，默认0.35秒(默认设置completionSpeed为0.35)
@property (nonatomic, assign) NSTimeInterval transitionDuration;

// 获取动画类型，默认根据上下文判断
@property (nonatomic, assign) FWAnimatedTransitionType transitionType;

#pragma mark - Interactive

// 是否启用交互pan手势进行pop|dismiss，默认NO。可使用父类属性设置交互动画
@property (nonatomic, assign) BOOL interactEnabled;

// 交互pan手势对象，延迟加载，可设置交互方向，滚动视图等
@property (nonatomic, strong, readonly) FWPanGestureRecognizer *gestureRecognizer;

// 是否正在交互中，手势开始才会标记为YES，手势结束标记为NO
@property (nonatomic, assign, readonly) BOOL isInteractive;

// 自定义交互句柄，可根据手势state处理不同状态的交互，返回YES执行默认交互，返回NO不执行。默认为空，执行默认交互
@property (nullable, nonatomic, copy) BOOL(^interactBlock)(FWPanGestureRecognizer *gestureRecognizer);

// 手工绑定交互控制器，添加pan手势，需要vc.view存在时调用才生效。默认自动绑定，如果自定义interactBlock，必须手工绑定
- (void)interactWith:(UIViewController *)viewController;

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

// 滑动转场动画类，默认上下
@interface FWSwipeAnimatedTransition : FWAnimatedTransition

// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection;

// 指定进入(push|present)方向，默认上滑Up
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;
// 指定消失(pop|dismiss)方向，默认下滑Down
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end

#pragma mark - FWTransformAnimatedTransition

// 形变转场动画类，默认缩放
@interface FWTransformAnimatedTransition : FWAnimatedTransition

// 创建形变转场，指定进入(push|present)和消失(pop|dismiss)形变
+ (instancetype)transitionWithInTransform:(CGAffineTransform)inTransform
                             outTransform:(CGAffineTransform)outTransform;

// 指定进入(push|present)形变，默认缩放0.01
@property (nonatomic, assign) CGAffineTransform inTransform;
// 指定消失(pop|dismiss)形变，默认缩放0.01
@property (nonatomic, assign) CGAffineTransform outTransform;

@end

#pragma mark - FWPresentationController

// 自定义展示控制器。present时建议设置modalPresentationStyle为UIModalPresentationCustom
@interface FWPresentationController : UIPresentationController

// 是否显示暗色背景，默认YES
@property (nonatomic, assign) BOOL showDimming;

// 是否可以点击暗色背景关闭，默认YES。如果presentedView占满containerView，手势不生效
@property (nonatomic, assign) BOOL dimmingClick;

// 是否执行暗黑背景透明度动画，默认YES
@property (nonatomic, assign) BOOL dimmingAnimated;

// 设置弹出视图的圆角位置，默认左上和右上
@property (nonatomic, assign) UIRectCorner rectCorner;

// 设置弹出视图的圆角半径，默认0无圆角
@property (nonatomic, assign) CGFloat cornerRadius;

// 自定义弹出视图的frame计算block，默认nil，优先级高
@property (nonatomic, copy, nullable) CGRect (^frameBlock)(FWPresentationController *presentationController);

// 设置弹出视图的frame，默认CGRectZero不生效，优先级中
@property (nonatomic, assign) CGRect presentedFrame;

// 设置弹出视图的居中size，默认CGSizeZero不生效，优先级中
@property (nonatomic, assign) CGSize presentedSize;

// 设置弹出视图的顶部距离，默认0不生效，优先级低
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
