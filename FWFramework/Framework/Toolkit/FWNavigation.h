/*!
 @header     FWNavigation.h
 @indexgroup FWFramework
 @brief      FWNavigation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UINavigationController+FWWorkflow

/*!
 @brief 视图控制器工作流分类
 */
@interface UIViewController (FWWorkflow)

/*! @brief 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *fwWorkflowName;

@end

/*!
 @brief 导航控制器工作流分类
 */
@interface UINavigationController (FWWorkflow)

/*!
 @brief 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
- (nullable NSString *)fwTopWorkflowName;

/*!
 @brief push控制器，并清理最外层工作流（不属于工作流则不清理）
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated;

/*!
 @brief push控制器，并清理非根控制器（只保留根控制器）
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated;

/*!
 @brief push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)fwPushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

/*!
 @brief pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)fwPopTopWorkflowAnimated:(BOOL)animated;

/*!
 @brief pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)fwPopWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated;

@end

#pragma mark - UIWindow+FWNavigation

/*!
 @brief 窗口导航分类
 */
@interface UIWindow (FWNavigation)

// 获取当前主window
+ (nullable UIWindow *)fwMainWindow;

// 获取最顶部的视图控制器
- (nullable UIViewController *)fwTopViewController;

// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
- (nullable UINavigationController *)fwTopNavigationController;

// 获取最顶部的显示控制器
- (nullable UIViewController *)fwTopPresentedController;

// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable void (^)(void))completion;

@end

#pragma mark - FWRouter+FWNavigation

/*!
 @brief URL路由导航
 */
@interface FWRouter (FWNavigation)

/*!
 @brief 使用最顶部的导航栏控制器打开控制器
 */
+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/*!
 @brief 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
 */
+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
