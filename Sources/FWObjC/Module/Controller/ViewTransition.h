//
//  ViewTransition.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAnimatedTransitionType

/**
 转场动画类型
 
 @const __FWAnimatedTransitionTypeNone 转场未开始
 @const __FWAnimatedTransitionTypePush push转场
 @const __FWAnimatedTransitionTypePop pop转场
 @const __FWAnimatedTransitionTypePresent present转场
 @const __FWAnimatedTransitionTypeDismiss dismiss转场
 */
typedef NS_ENUM(NSInteger, __FWAnimatedTransitionType) {
    __FWAnimatedTransitionTypeNone = 0,
    __FWAnimatedTransitionTypePush,
    __FWAnimatedTransitionTypePop,
    __FWAnimatedTransitionTypePresent,
    __FWAnimatedTransitionTypeDismiss,
} NS_SWIFT_NAME(AnimatedTransitionType);

#pragma mark - __FWAnimatedTransition

/// 转场动画类，默认透明度变化
NS_SWIFT_NAME(AnimatedTransition)
@interface __FWAnimatedTransition : UIPercentDrivenInteractiveTransition <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

#pragma mark - Public

/// 创建系统转场单例，不支持交互手势转场
+ (instancetype)systemTransition;

/// 创建动画句柄转场
+ (instancetype)transitionWithBlock:(nullable void (^)(__FWAnimatedTransition *transition))block;

/// 设置动画句柄
@property (nullable, nonatomic, copy) void (^transitionBlock)(__FWAnimatedTransition *transition);

/// 动画持续时间，必须大于0，默认0.35秒(默认设置completionSpeed为0.35)
@property (nonatomic, assign) NSTimeInterval transitionDuration;

/// 获取动画类型，默认根据上下文判断
@property (nonatomic, assign) __FWAnimatedTransitionType transitionType;

#pragma mark - Interactive

/// 是否启用交互pan手势进行pop|dismiss，默认NO。可使用父类属性设置交互动画
@property (nonatomic, assign) BOOL interactEnabled;

/// 是否启用screenEdge交互手势，默认NO，gestureRecognizer加载前设置生效
@property (nonatomic, assign) BOOL interactScreenEdge;

/// 指定交互pan手势对象，默认__FWPanGestureRecognizer，可设置交互方向，滚动视图等
@property (nonatomic, strong) __kindof UIPanGestureRecognizer *gestureRecognizer;

/// 是否正在交互中，手势开始才会标记为YES，手势结束标记为NO
@property (nonatomic, assign, readonly) BOOL isInteractive;

/// 自定义交互句柄，可根据手势state处理不同状态的交互，返回YES执行默认交互，返回NO不执行。默认为空，执行默认交互
@property (nullable, nonatomic, copy) BOOL(^interactBlock)(__kindof UIPanGestureRecognizer *gestureRecognizer);

/// 自定义dismiss关闭动画完成回调，默认nil
@property (nullable, nonatomic, copy) void(^dismissCompletion)(void);

/// 手工绑定交互控制器，添加pan手势，需要vc.view存在时调用才生效。默认自动绑定，如果自定义interactBlock，必须手工绑定
- (void)interactWith:(UIViewController *)viewController;

#pragma mark - Presentation

/// 是否启用默认展示控制器，启用后自动设置presentationBlock返回__FWPresentationController，默认NO
@property (nonatomic, assign) BOOL presentationEnabled;

/// 设置展示控制器创建句柄，自定义弹出效果。present时建议设置modalPresentationStyle为Custom
@property (nullable, nonatomic, copy) UIPresentationController *(^presentationBlock)(UIViewController *presented, UIViewController *presenting);

#pragma mark - Animate

/// 转场上下文，只读
@property (nullable, nonatomic, weak, readonly) id<UIViewControllerContextTransitioning> transitionContext;

/// 标记动画开始(自动添加视图到容器)
- (void)start;

/// 执行动画，子类重写，可选
- (void)animate;

/// 自动标记动画完成(根据transitionContext是否被取消判断)
- (void)complete;

@end

#pragma mark - __FWSwipeAnimatedTransition

/// 滑动转场动画类，默认上下
NS_SWIFT_NAME(SwipeAnimatedTransition)
@interface __FWSwipeAnimatedTransition : __FWAnimatedTransition

/// 创建滑动转场，指定进入(push|present)和消失(pop|dismiss)方向
+ (instancetype)transitionWithInDirection:(UISwipeGestureRecognizerDirection)inDirection
                             outDirection:(UISwipeGestureRecognizerDirection)outDirection;

/// 指定进入(push|present)方向，默认上滑Up
@property (nonatomic, assign) UISwipeGestureRecognizerDirection inDirection;
/// 指定消失(pop|dismiss)方向，默认下滑Down
@property (nonatomic, assign) UISwipeGestureRecognizerDirection outDirection;

@end

#pragma mark - __FWTransformAnimatedTransition

/// 形变转场动画类，默认缩放
NS_SWIFT_NAME(TransformAnimatedTransition)
@interface __FWTransformAnimatedTransition : __FWAnimatedTransition

/// 创建形变转场，指定进入(push|present)和消失(pop|dismiss)形变
+ (instancetype)transitionWithInTransform:(CGAffineTransform)inTransform
                             outTransform:(CGAffineTransform)outTransform;

/// 指定进入(push|present)形变，默认缩放0.01
@property (nonatomic, assign) CGAffineTransform inTransform;
/// 指定消失(pop|dismiss)形变，默认缩放0.01
@property (nonatomic, assign) CGAffineTransform outTransform;

@end

#pragma mark - __FWPresentationController

/// 自定义展示控制器。默认显示暗色背景动画且弹出视图占满容器，可通过属性自定义
NS_SWIFT_NAME(PresentationController)
@interface __FWPresentationController : UIPresentationController

/// 是否显示暗色背景，默认YES
@property (nonatomic, assign) BOOL showDimming;
/// 是否可以点击暗色背景关闭，默认YES。如果弹出视图占满容器，手势不生效(因为弹出视图挡住了暗色背景)
@property (nonatomic, assign) BOOL dimmingClick;
/// 是否执行暗黑背景透明度动画，默认YES
@property (nonatomic, assign) BOOL dimmingAnimated;
/// 暗色背景颜色，默认黑色，透明度0.5
@property (nonatomic, strong, nullable) UIColor *dimmingColor;
/// 设置点击暗色背景关闭完成回调，默认nil
@property (nonatomic, copy, nullable) void (^dismissCompletion)(void);

/// 设置弹出视图的圆角位置，默认左上和右上。如果弹出视图占满容器，不生效需弹出视图自定义
@property (nonatomic, assign) UIRectCorner rectCorner;
/// 设置弹出视图的圆角半径，默认0无圆角。如果弹出视图占满容器，不生效需弹出视图自定义
@property (nonatomic, assign) CGFloat cornerRadius;

/// 自定义弹出视图的frame计算block，默认nil占满容器，优先级高
@property (nonatomic, copy, nullable) CGRect (^frameBlock)(__FWPresentationController *presentationController);
/// 设置弹出视图的frame，默认CGRectZero占满容器，优先级中
@property (nonatomic, assign) CGRect presentedFrame;
/// 设置弹出视图的居中size，默认CGSizeZero占满容器，优先级中
@property (nonatomic, assign) CGSize presentedSize;
/// 设置弹出视图的顶部距离，默认0占满容器，优先级低
@property (nonatomic, assign) CGFloat verticalInset;

@end

#pragma mark - __FWPanGestureRecognizer

/**
 __FWPanGestureRecognizer
 @note 自动处理与滚动视图pan手势在指定方向的冲突，默认设置delegate为自身。如果找到滚动视图则处理之，否则同父类
 */
NS_SWIFT_NAME(PanGestureRecognizer)
@interface __FWPanGestureRecognizer : UIPanGestureRecognizer

/// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
@property (nonatomic, assign) BOOL autoDetected;

/// 是否按下就立即转换Began状态，默认NO，需要等待移动才会触发Began
@property (nonatomic, assign) BOOL instantBegan;

/// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。自动设置默认delegate为自身
@property (nullable, nonatomic, weak) UIScrollView *scrollView;

/// 指定与滚动视图pan手势的冲突交互方向，默认向下
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;

/// 获取当前手势在指定交互方向的滑动进度
@property (nonatomic, assign) CGFloat swipePercent;

/// 指定当前手势在指定交互方向的最大识别距离，默认0，无限制
@property (nonatomic, assign) CGFloat maximumDistance;

/// 自定义Failed判断句柄。默认判定失败时直接修改状态为Failed，可设置此block修改判定条件
@property (nullable, nonatomic, copy) BOOL (^shouldFailed)(__FWPanGestureRecognizer *gestureRecognizer);

/// 自定义shouldBegin判断句柄
@property (nullable, nonatomic, copy) BOOL (^shouldBegin)(__FWPanGestureRecognizer *gestureRecognizer);

/// 自定义shouldBeRequiredToFail判断句柄
@property (nullable, nonatomic, copy) BOOL (^shouldBeRequiredToFail)(UIGestureRecognizer *otherGestureRecognizer);

/// 自定义shouldRequireFailure判断句柄
@property (nullable, nonatomic, copy) BOOL (^shouldRequireFailure)(UIGestureRecognizer *otherGestureRecognizer);

@end

NS_ASSUME_NONNULL_END
