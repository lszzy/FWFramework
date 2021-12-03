/**
 @header     FWNavigation.h
 @indexgroup FWFramework
      FWNavigation
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIWindow+FWNavigation

/**
 窗口导航分类
 */
@interface UIWindow (FWNavigation)

/// 获取当前主window
@property (class, nonatomic, readonly, nullable) UIWindow *fwMainWindow;

/// 获取当前主场景
@property (class, nonatomic, readonly, nullable) UIWindowScene *fwMainScene API_AVAILABLE(ios(13.0));

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *fwTopViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *fwTopNavigationController;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *fwTopPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - UIViewController+FWNavigation

/**
 控制器导航分类
 */
@interface UIViewController (FWNavigation)

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - UINavigationController+FWWorkflow

/**
 视图控制器工作流分类
 */
@interface UIViewController (FWWorkflow)

/** 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *fwWorkflowName;

@end

/**
 导航控制器工作流分类
 */
@interface UINavigationController (FWWorkflow)

/**
 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
@property (nonatomic, copy, readonly, nullable) NSString *fwTopWorkflowName;

/**
 push控制器，并清理最外层工作流（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated;

/**
 push控制器，并清理非根控制器（只保留根控制器）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated;

/**
 push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

/**
 pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)fwPopTopWorkflowAnimated:(BOOL)animated;

/**
 pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)fwPopWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
