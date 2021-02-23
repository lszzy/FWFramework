//
//  UINavigationBar+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UINavigationBar+FWFramework

// 导航栏视图分类，全局设置用[UINavigationBar appearance]
@interface UINavigationBar (FWFramework)

/// 设置文字和按钮颜色
@property (nonatomic, strong, nullable) UIColor *fwTextColor UI_APPEARANCE_SELECTOR;

/// 设置背景颜色(nil时透明)并隐藏底部线条
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor UI_APPEARANCE_SELECTOR;

/// 设置主题背景色(nil时透明)并隐藏底部线条，自动跟随系统改变
@property (nonatomic, strong, nullable) UIColor *fwThemeBackgroundColor;

/// 设置透明背景并隐藏底部线条
- (void)fwSetBackgroundTransparent UI_APPEARANCE_SELECTOR;

@end

#pragma mark - UITabBar+FWFramework

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 @discussion 如果push时需要隐藏TabBar，需要设置vc.hidesBottomBarWhenPushed，再push即可。
    如果present时需要隐藏TabBar，需要设置tabbar.definesPresentationContext为YES，再用tabbar来present即可。
    可以设置所有控制器默认hidesBottomBarWhenPushed为YES，然后初始化TabBarController时，设置所有子控制器hidesBottomBarWhenPushed为NO即可
 */
@interface UITabBar (FWFramework)

/// 设置文字和按钮颜色
@property (nonatomic, strong, nullable) UIColor *fwTextColor;

/// 设置背景颜色并隐藏顶部线条
@property (nonatomic, strong, nullable) UIColor *fwBackgroundColor;

/// 设置主题背景色并隐藏顶部线条，自动跟随系统改变
@property (nonatomic, strong, nullable) UIColor *fwThemeBackgroundColor;

@end

NS_ASSUME_NONNULL_END
