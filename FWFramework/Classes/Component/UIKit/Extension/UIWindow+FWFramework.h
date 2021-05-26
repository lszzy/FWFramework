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

// 关闭所有弹出控制器，完成时回调。如果没有present控制器，直接回调
- (void)fwDismissViewControllers:(nullable void (^)(void))completion;

// 选中并获取指定类TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fwSelectTabBarController:(Class)viewController;

// 选中并获取指定索引TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
- (nullable __kindof UIViewController *)fwSelectTabBarIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
