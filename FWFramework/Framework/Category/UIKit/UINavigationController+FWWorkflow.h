/*!
 @header     UINavigationController+FWWorkflow.h
 @indexgroup FWFramework
 @brief      导航栏控制器工作流分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import <UIKit/UIKit.h>

/*!
 @brief 视图控制器工作流分类
 */
@interface UIViewController (FWWorkflow)

/*! @brief 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *fwWorkflowName;

// 打开页面。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOpenViewController:(UIViewController *)viewController;

// 打开页面。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

// 关闭页面。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (void)fwCloseViewController;

// 关闭页面。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (void)fwCloseViewControllerAnimated:(BOOL)animated;

@end

/*!
 @brief 导航控制器工作流分类
 */
@interface UINavigationController (FWWorkflow)

/*!
 @brief 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
- (NSString *)fwTopWorkflowName;

/*!
 @brief push控制器，并清理最外层工作流（不属于工作流则不清理）
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 @return pop的控制器数组
 */
- (NSArray<UIViewController *> *)fwPushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated;

/*!
 @brief push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 @return pop的控制器数组
 */
- (NSArray<UIViewController *> *)fwPushViewController:(UIViewController *)viewController popWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated;

/*!
 @brief pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 @return pop的控制器数组
 */
- (NSArray<UIViewController *> *)fwPopTopWorkflowAnimated:(BOOL)animated;

/*!
 @brief pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
 @discussion 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 @return pop的控制器数组
 */
- (NSArray<UIViewController *> *)fwPopWorkflows:(NSArray<NSString *> *)workflows animated:(BOOL)animated;

@end
