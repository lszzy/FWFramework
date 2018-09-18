//
//  UIViewController+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+FWAlert.h"
#import "UIViewController+FWBar.h"
#import "UIViewController+FWTransition.h"

@interface UIViewController (FWFramework)

/**
 *  视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
 */
- (BOOL)fwIsViewVisible;

#pragma mark - Child

// 获取当前显示的子控制器，解决不能触发viewWillAppear等的bug
- (UIViewController *)fwChildViewController;

// 设置当前显示的子控制器，解决不能触发viewWillAppear等的bug
- (void)fwSetChildViewController:(UIViewController *)viewController;

// 移除子控制器，解决不能触发viewWillAppear等的bug
- (void)fwRemoveChildViewController:(UIViewController *)viewController;

// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
- (void)fwAddChildViewController:(UIViewController *)viewController;

// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
- (void)fwAddChildViewController:(UIViewController *)viewController inView:(UIView *)view;

@end
