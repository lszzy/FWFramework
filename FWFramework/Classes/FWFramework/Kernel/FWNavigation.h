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

/// 控制器导航选项定义
///
/// FWNavigationOptionAutomatic: 自动判断push还是present，默认
/// FWNavigationOptionPush: push方式
/// FWNavigationOptionPresent: present方式
/// FWNavigationOptionPresentNavigation: present导航栏方式
///
/// FWNavigationOptionPopTop: pop顶部控制器后再打开
/// FWNavigationOptionPopToRoot: pop到根控制器再打开
///
/// FWNavigationOptionPageSheet: present样式为pageSheet
/// FWNavigationOptionFullScreen: present样式为fullScreen
typedef NS_OPTIONS(NSUInteger, FWNavigationOptions) {
    FWNavigationOptionAutomatic         = 0,
    FWNavigationOptionPush              = 1 << 0,
    FWNavigationOptionPresent           = 1 << 1,
    FWNavigationOptionPresentNavigation = 1 << 2,
    
    FWNavigationOptionPopTop            = 1 << 3,
    FWNavigationOptionPopToRoot         = 1 << 4,
    
    FWNavigationOptionPageSheet         = 1 << 5,
    FWNavigationOptionFullScreen        = 1 << 6,
} NS_SWIFT_NAME(NavigationOptions);

#pragma mark - UIWindow+FWNavigation

@interface UIWindow (FWNavigation)

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *fw_topViewController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *fw_topNavigationController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *fw_topPresentedController NS_REFINED_FOR_SWIFT;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present，完成时回调
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功，完成时回调
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 获取当前主window
@property (class, nonatomic, readonly, nullable) UIWindow *fw_mainWindow NS_REFINED_FOR_SWIFT;

/// 获取当前主场景
@property (class, nonatomic, readonly, nullable) UIWindowScene *fw_mainScene API_AVAILABLE(ios(13.0)) NS_REFINED_FOR_SWIFT;

/// 获取最顶部的视图控制器
@property (class, nonatomic, readonly, nullable) UIViewController *fw_topViewController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (class, nonatomic, readonly, nullable) UINavigationController *fw_topNavigationController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的显示控制器
@property (class, nonatomic, readonly, nullable) UIViewController *fw_topPresentedController NS_REFINED_FOR_SWIFT;

/// 使用最顶部的导航栏控制器打开控制器
+ (BOOL)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
+ (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
+ (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present，完成时回调
+ (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
+ (BOOL)fw_closeViewControllerAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功，完成时回调
+ (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWNavigation

@interface UIViewController (FWNavigation)

#pragma mark - Navigation

/// 自定义open|close导航样式，默认automatic自动判断
@property (nonatomic, assign) FWNavigationOptions fw_navigationOptions NS_REFINED_FOR_SWIFT;

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present，完成时回调
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop，完成时回调
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

#pragma mark - Workflow

/** 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *fw_workflowName NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UINavigationController+FWNavigation

@interface UINavigationController (FWNavigation)

#pragma mark - Navigation

/// push新界面，完成时回调
- (void)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// pop当前界面，完成时回调
- (nullable UIViewController *)fw_popViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// pop到指定界面，完成时回调
- (nullable NSArray<__kindof UIViewController *> *)fw_popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// pop到根界面，完成时回调
- (nullable NSArray<__kindof UIViewController *> *)fw_popToRootViewControllerAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 设置界面数组，完成时回调
- (void)fw_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

#pragma mark - Workflow

/**
 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
@property (nonatomic, copy, readonly, nullable) NSString *fw_topWorkflowName NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理最外层工作流（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理最外层工作流（不属于工作流则不清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理非根控制器（只保留根控制器）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理非根控制器（只保留根控制器），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/**
 push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理）
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)fw_popTopWorkflowAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/**
 pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)fw_popTopWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)fw_popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/**
 pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器，完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)fw_popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
