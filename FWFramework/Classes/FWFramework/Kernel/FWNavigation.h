/**
 @header     FWNavigation.h
 @indexgroup FWFramework
      FWNavigation
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWWindowWrapper+FWNavigation

@interface FWWindowWrapper (FWNavigation)

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *topViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *topNavigationController;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *topPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
- (BOOL)closeViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - FWWindowClassWrapper+FWNavigation

@interface FWWindowClassWrapper (FWNavigation)

/// 获取当前主window
@property (nonatomic, readonly, nullable) UIWindow *mainWindow;

/// 获取当前主场景
@property (nonatomic, readonly, nullable) UIWindowScene *mainScene API_AVAILABLE(ios(13.0));

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *topViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *topNavigationController;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *topPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
- (BOOL)closeViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - FWViewControllerWrapper+FWNavigation

@interface FWViewControllerWrapper (FWNavigation)

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (BOOL)closeViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - FWViewControllerWrapper+FWWorkflow

@interface FWViewControllerWrapper (FWWorkflow)

/** 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *workflowName;

@end

#pragma mark - FWNavigationControllerWrapper+FWWorkflow

@interface FWNavigationControllerWrapper (FWWorkflow)

/**
 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
@property (nonatomic, copy, readonly, nullable) NSString *topWorkflowName;

/**
 push控制器，并清理最外层工作流（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated;

/**
 push控制器，并清理非根控制器（只保留根控制器）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated;

/**
 push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)pushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

/**
 pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)popTopWorkflowAnimated:(BOOL)animated;

/**
 pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
