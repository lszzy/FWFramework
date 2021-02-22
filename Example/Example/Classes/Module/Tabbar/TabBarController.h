//
//  TabBarController.h
//  Example
//
//  Created by wuyong on 2020/9/12.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarController (AppTabBar) <UITabBarControllerDelegate>

+ (UIViewController *)setupController;

+ (void)refreshController;

@end

NS_ASSUME_NONNULL_END
