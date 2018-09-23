//
//  UIWindow+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2017/6/19.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (FWFramework)

// 获取当前的视图控制器(fwTopMostController堆栈的topViewController)
- (UIViewController *)fwViewController;

// 获取最顶端的控制器
- (UIViewController *)fwTopMostController;

@end
