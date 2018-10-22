//
//  UIWindow+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (FWFramework)

// 检查是否含有安全区域，可用来判断iPhoneX
+ (BOOL)fwHasSafeAreaInsets;

// 获取当前主window
+ (UIWindow *)fwMainWindow;

// 获取最顶部的视图控制器
- (UIViewController *)fwTopViewController;

// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
- (UINavigationController *)fwTopNavigationController;

// 获取最顶部的显示控制器
- (UIViewController *)fwTopPresentedController;

// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(void (^)(void))completion;

@end
