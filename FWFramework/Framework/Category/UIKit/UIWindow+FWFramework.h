//
//  UIWindow+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (FWFramework)

// 获取当前主window
+ (nullable UIWindow *)fwMainWindow;

// 获取最顶部的视图控制器
- (nullable UIViewController *)fwTopViewController;

// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
- (nullable UINavigationController *)fwTopNavigationController;

// 获取最顶部的显示控制器
- (nullable UIViewController *)fwTopPresentedController;

// 选中并获取指定类TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fwSelectTabBarController:(Class)viewController;

// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
