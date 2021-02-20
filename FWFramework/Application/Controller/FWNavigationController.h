/*!
 @header     FWNavigationController.h
 @indexgroup FWFramework
 @brief      FWNavigationController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2021/2/21
 */

#import <UIKit/UIKit.h>

@class FWRootNavigationController;

@protocol FWNavigationItemCustomizable <NSObject>

@optional

/*!
 *  @brief Override this method to provide a custom back bar item, default is a normal @c UIBarButtonItem with title @b "Back"
 *
 *  @param target the action target
 *  @param action the pop back action
 *
 *  @return a custom UIBarButtonItem
 */
- (UIBarButtonItem *)rt_customBackItemWithTarget:(id)target action:(SEL)action;

@end

IB_DESIGNABLE
@interface UIViewController (FWRootNavigationController) <FWNavigationItemCustomizable>

/*!
 *  @brief set this property to @b YES to disable interactive pop
 */
@property (nonatomic, assign) IBInspectable BOOL rt_disableInteractivePop;

/*!
 *  @brief @c self\.navigationControlle will get a wrapping @c UINavigationController, use this property to get the real navigation controller
 */
@property (nonatomic, readonly, strong) FWRootNavigationController *rt_navigationController;

/*!
 *  @brief Override this method to provide a custom subclass of @c UINavigationBar, defaults return nil
 *
 *  @return new UINavigationBar class
 */
- (Class)rt_navigationBarClass;

@end

@interface FWContainerController : UIViewController
@property (nonatomic, readonly, strong) __kindof UIViewController *contentViewController;
@end


/**
 *  @class FWContainerNavigationController
 *  @brief This Controller will forward all @a Navigation actions to its containing navigation controller, i.e. @b FWRootNavigationController.
 *  If you are using UITabBarController in your project, it's recommand to wrap it in @b FWRootNavigationController as follows:
 *  @code
tabController.viewControllers = @[[[FWContainerNavigationController alloc] initWithRootViewController:vc1],
                                  [[FWContainerNavigationController alloc] initWithRootViewController:vc2],
                                  [[FWContainerNavigationController alloc] initWithRootViewController:vc3],
                                  [[FWContainerNavigationController alloc] initWithRootViewController:vc4]];
self.window.rootViewController = [[FWRootNavigationController alloc] initWithRootViewControllerNoWrapping:tabController];
 *  @endcode
 */
@interface FWContainerNavigationController : UINavigationController
@end



/*!
 *  @class FWRootNavigationController
 *  @superclass UINavigationController
 *  @coclass FWContainerController
 *  @coclass FWContainerNavigationController
 *
 *  @see https://github.com/rickytan/RTRootNavigationController
 */
IB_DESIGNABLE
@interface FWRootNavigationController : UINavigationController

/*!
 *  @brief use system original back bar item or custom back bar item returned by
 *  @c -(UIBarButtonItem*)customBackItemWithTarget:action: , default is NO
 *  @warning Set this to @b YES will @b INCREASE memory usage!
 */
@property (nonatomic, assign) IBInspectable BOOL useSystemBackBarButtonItem;

/// Weather each individual navigation bar uses the visual style of root navigation bar. Default is @b NO
@property (nonatomic, assign) IBInspectable BOOL transferNavigationBarAttributes;

/*!
 *  @brief use this property instead of @c visibleViewController to get the current visiable content view controller
 */
@property (nonatomic, readonly, strong) UIViewController *rt_visibleViewController;

/*!
 *  @brief use this property instead of @c topViewController to get the content view controller on the stack top
 */
@property (nonatomic, readonly, strong) UIViewController *rt_topViewController;

/*!
 *  @brief use this property to get all the content view controllers;
 */
@property (nonatomic, readonly, strong) NSArray <__kindof UIViewController *> *rt_viewControllers;

/**
 *  Init with a root view controller without wrapping into a navigation controller
 *
 *  @param rootViewController The root view controller
 *
 *  @return new instance
 */
- (instancetype)initWithRootViewControllerNoWrapping:(UIViewController *)rootViewController;

/*!
 *  @brief Remove a content view controller from the stack
 *
 *  @param controller the content view controller
 */
- (void)removeViewController:(UIViewController *)controller NS_REQUIRES_SUPER;
- (void)removeViewController:(UIViewController *)controller animated:(BOOL)flag NS_REQUIRES_SUPER;

/*!
 *  @brief Push a view controller and do sth. when animation is done
 *
 *  @param viewController new view controller
 *  @param animated       use animation or not
 *  @param block          animation complete callback block
 */
- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                  complete:(void(^)(BOOL finished))block;

/*!
 *  @brief Pop current view controller on top with a complete handler
 *
 *  @param animated       use animation or not
 *  @param block          complete handler
 *
 *  @return The current UIViewControllers(content controller) poped from the stack
 */
- (UIViewController *)popViewControllerAnimated:(BOOL)animated complete:(void(^)(BOOL finished))block;

/*!
 *  @brief Pop to a specific view controller with a complete handler
 *
 *  @param viewController The view controller to pop  to
 *  @param animated       use animation or not
 *  @param block          complete handler
 *
 *  @return A array of UIViewControllers(content controller) poped from the stack
 */
- (NSArray <__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController
                                                      animated:(BOOL)animated
                                                      complete:(void(^)(BOOL finished))block;

/*!
 *  @brief Pop to root view controller with a complete handler
 *
 *  @param animated use animation or not
 *  @param block    complete handler
 *
 *  @return A array of UIViewControllers(content controller) poped from the stack
 */
- (NSArray <__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
                                                                  complete:(void(^)(BOOL finished))block;
@end
