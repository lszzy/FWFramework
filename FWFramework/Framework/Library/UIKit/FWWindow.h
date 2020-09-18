/*!
 @header     FWWindow.h
 @indexgroup FWFramework
 @brief      FWWindow
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/18
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 窗口导航分类
 */
@interface UIWindow (FWWindow)

// 获取当前主window
+ (nullable UIWindow *)fwMainWindow;

// 获取当前主场景
+ (nullable UIWindowScene *)fwMainScene API_AVAILABLE(ios(13.0));

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

NS_ASSUME_NONNULL_END
