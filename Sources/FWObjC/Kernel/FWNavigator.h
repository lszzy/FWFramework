//
//  FWNavigator.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigator

/// 控制器导航选项定义
///
/// @const FWNavigatorOptionEmbedInNavigation 嵌入导航控制器并使用present转场方式
///
/// @const FWNavigatorOptionTransitionAutomatic 自动判断转场方式，默认
/// @const FWNavigatorOptionTransitionPush 指定push转场方式，仅open生效
/// @const FWNavigatorOptionTransitionPresent 指定present转场方式，仅open生效
/// @const FWNavigatorOptionTransitionPop 指定pop转场方式，仅close生效
/// @const FWNavigatorOptionTransitionDismiss 指定dismiss转场方式，仅close生效
///
/// @const FWNavigatorOptionPopNone 不pop控制器，默认
/// @const FWNavigatorOptionPopToRoot 同时pop到根控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop 同时pop顶部控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop2 同时pop顶部2个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop3 同时pop顶部3个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop4 同时pop顶部4个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop5 同时pop顶部5个控制器，仅push|pop生效
/// @const FWNavigatorOptionPopTop6 同时pop顶部6个控制器，仅push|pop生效
///
/// @const FWNavigatorOptionStyleAutomatic 自动使用系统present样式，默认
/// @const FWNavigatorOptionStyleFullScreen 指定present样式为ullScreen，仅present生效
/// @const FWNavigatorOptionStylePageSheet 指定present样式为pageSheet，仅present生效
typedef NS_OPTIONS(NSUInteger, FWNavigatorOptions) {
    FWNavigatorOptionEmbedInNavigation   = 1 << 0,
    
    FWNavigatorOptionTransitionAutomatic = 0 << 16, // default
    FWNavigatorOptionTransitionPush      = 1 << 16,
    FWNavigatorOptionTransitionPresent   = 2 << 16,
    FWNavigatorOptionTransitionPop       = 3 << 16,
    FWNavigatorOptionTransitionDismiss   = 4 << 16,
    
    FWNavigatorOptionPopNone             = 0 << 20, // default
    FWNavigatorOptionPopTop              = 1 << 20,
    FWNavigatorOptionPopTop2             = 2 << 20,
    FWNavigatorOptionPopTop3             = 3 << 20,
    FWNavigatorOptionPopTop4             = 4 << 20,
    FWNavigatorOptionPopTop5             = 5 << 20,
    FWNavigatorOptionPopTop6             = 6 << 20,
    FWNavigatorOptionPopToRoot           = 7 << 20,
    
    FWNavigatorOptionStyleAutomatic      = 0 << 24, // default
    FWNavigatorOptionStyleFullScreen     = 1 << 24,
    FWNavigatorOptionStylePageSheet      = 2 << 24,
} NS_SWIFT_NAME(NavigatorOptions);

/// 导航管理器
NS_SWIFT_NAME(Navigator)
@interface FWNavigator : NSObject

/// 获取最顶部的视图控制器
@property (class, nonatomic, readonly, nullable) UIViewController *topViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (class, nonatomic, readonly, nullable) UINavigationController *topNavigationController;

/// 获取最顶部的显示控制器
@property (class, nonatomic, readonly, nullable) UIViewController *topPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
+ (BOOL)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
+ (BOOL)pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present，完成时回调
+ (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功，完成时回调
+ (BOOL)closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion;

@end

#pragma mark - UIWindow+FWNavigator

@interface UIWindow (FWNavigator)

/// 获取当前主window
@property (class, nonatomic, readonly, nullable) UIWindow *fw_mainWindow NS_REFINED_FOR_SWIFT;

/// 获取当前主场景
@property (class, nonatomic, readonly, nullable) UIWindowScene *fw_mainScene API_AVAILABLE(ios(13.0)) NS_REFINED_FOR_SWIFT;

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *fw_topViewController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *fw_topNavigationController NS_REFINED_FOR_SWIFT;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *fw_topPresentedController NS_REFINED_FOR_SWIFT;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fw_pushViewController:(UIViewController *)viewController animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的导航栏控制器打开控制器，同时pop指定数量控制器
- (BOOL)fw_pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fw_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present，完成时回调
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功，完成时回调
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWNavigator

@interface UIViewController (FWNavigator)

#pragma mark - Navigator

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated NS_SWIFT_UNAVAILABLE("");

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present，完成时回调
- (void)fw_openViewController:(UIViewController *)viewController animated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated NS_SWIFT_UNAVAILABLE("");

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop，完成时回调
- (BOOL)fw_closeViewControllerAnimated:(BOOL)animated options:(FWNavigatorOptions)options completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

#pragma mark - Workflow

/** 自定义工作流名称，支持二级("."分隔)；默认返回小写类名(去掉ViewController、Controller) */
@property (nonatomic, copy) NSString *fw_workflowName NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UINavigationController+FWNavigator

@interface UINavigationController (FWNavigator)

#pragma mark - Navigator

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

/// push新界面，同时pop指定数量界面，至少保留一个根控制器，完成时回调
- (void)fw_pushViewController:(UIViewController *)viewController pop:(NSUInteger)count animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// pop指定数量界面，0不会pop，至少保留一个根控制器，完成时回调
- (nullable NSArray<__kindof UIViewController *> *)fw_popViewControllers:(NSUInteger)count animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

#pragma mark - Workflow

/**
 当前最外层工作流名称，即topViewController的工作流名称
 
 @return 工作流名称
 */
@property (nonatomic, copy, readonly, nullable) NSString *fw_topWorkflowName NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理最外层工作流（不属于工作流则不清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popTopWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理到指定工作流（不属于工作流则清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、9
 
 @param viewController push的控制器
 @param workflow 指定工作流
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popToWorkflow:(NSString *)workflow animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 push控制器，并清理非根控制器（只保留根控制器），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、9
 
 @param viewController push的控制器
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popToRootWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 push控制器，并从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、9
 
 @param viewController push的控制器
 @param workflows 指定工作流
 @param animated 是否执行动画
 */
- (void)fw_pushViewController:(UIViewController *)viewController popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 pop方式清理最外层工作流，至少保留一个根控制器（不属于工作流则不清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4、（5、6）
 
 @param animated 是否执行动画
 */
- (void)fw_popTopWorkflowAnimated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 pop方式清理到指定工作流，至少保留一个根控制器（不属于工作流则清理），完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）
 
 @param workflow 指定工作流
 @param animated 是否执行动画
 */
- (void)fw_popToWorkflow:(NSString *)workflow animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/**
 pop方式从外到内清理指定工作流，直到遇到不属于指定工作流的控制器停止，至少保留一个根控制器，完成时回调
 @note 示例：1、（2、3）、4、（5、6）、（7、8），操作后为1、（2、3）、4
 
 @param workflows 指定工作流
 @param animated  是否执行动画
 */
- (void)fw_popWorkflows:(nullable NSArray<NSString *> *)workflows animated:(BOOL)animated completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
