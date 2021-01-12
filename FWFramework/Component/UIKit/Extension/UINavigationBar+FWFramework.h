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

/// 设置主题背景色并隐藏底部线条，自动跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIColor *fwThemeBackgroundColor;

/// 设置全局按钮文字样式(不含图片)，单个设置时详见UIBarButtonItem
+ (void)fwSetButtonTitleAttributes:(nullable NSDictionary *)attributes;

/// 设置标题和按钮颜色
- (void)fwSetTextColor:(nullable UIColor *)color UI_APPEARANCE_SELECTOR;

/// 设置背景颜色并隐藏底部线条。为避免barTintColor的一些兼容问题，此方法使用颜色生成的图片来设置backgroundImage
- (void)fwSetBackgroundColor:(nullable UIColor *)color UI_APPEARANCE_SELECTOR;

/// 设置透明背景并隐藏底部线条
- (void)fwSetBackgroundClear UI_APPEARANCE_SELECTOR;

/// 添加背景视图，可设置背景色等
- (UIView *)fwOverlayView;

/// 重置导航栏背景颜色和图片，移除自定义视图
- (void)fwResetBackground;

/// 背景view，可能显示磨砂、背景图，顶部有一部分溢出到UINavigationBar外。在iOS10及以后是私有的_UIBarBackground类，在iOS9及以前是私有的_UINavigationBarBackground类
@property (nullable, nonatomic, weak, readonly) UIView *fwBackgroundView;

/// 用于显示底部分隔线shadowImage，注意这个view是溢出到backgroundView外的。若shadowImage为[UIImage new]，则这个view的高度为0
@property (nullable, nonatomic, weak, readonly) UIImageView *fwShadowImageView;

@end

#pragma mark - UITabBar+FWFramework

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 @discussion 如果push时需要隐藏TabBar，需要设置vc.hidesBottomBarWhenPushed，再push即可。
    如果present时需要隐藏TabBar，需要设置tabbar.definesPresentationContext为YES，再用tabbar来present即可。
    可以设置所有控制器默认hidesBottomBarWhenPushed为YES，然后初始化TabBarController时，设置所有子控制器hidesBottomBarWhenPushed为NO即可
 */
@interface UITabBar (FWFramework)

/// 设置主题背景色并隐藏顶部线条，自动跟随系统改变，清空时需置为nil
@property (nullable, nonatomic, strong) UIColor *fwThemeBackgroundColor;

/// 设置文字颜色(含图标)
- (void)fwSetTextColor:(nullable UIColor *)color;

/// 设置背景颜色并隐藏顶部线条。为了不影响barStyle，此方法使用颜色生成的图片来设置backgroundImage
- (void)fwSetBackgroundColor:(nullable UIColor *)color;

/// UITabBar 的背景 view，可能显示磨砂、背景图，顶部有一部分溢出到 UITabBar 外。在 iOS 10 及以后是私有的 _UIBarBackground 类，在 iOS 9 及以前是私有的 _UITabBarBackgroundView 类
@property (nullable, nonatomic, weak, readonly) UIView *fwBackgroundView;

/// 用于显示顶部分隔线 shadowImage，注意这个 view 是溢出到 backgroundView 外的。若 shadowImage 为 [UIImage new]，则这个 view 的高度为 0
@property (nullable, nonatomic, weak, readonly) UIImageView *fwShadowImageView;

@end

#pragma mark - UIBarItem+FWFramework

/*!
@brief UIBarItem分类
*/
@interface UIBarItem (FWFramework)

/// 获取UIBarItem(UIBarButtonItem、UITabBarItem)内部的view，通常对于navigationItem和tabBarItem而言，需要在设置为item后并且在bar可见时(例如 viewDidAppear:及之后)获取fwView才有值
@property (nullable, nonatomic, weak, readonly) UIView *fwView;

/// 当item内的view生成后就会调用一次这个block，仅对UIBarButtonItem、UITabBarItem有效
@property (nullable, nonatomic, copy) void (^fwViewLoadedBlock)(__kindof UIBarItem *item, UIView *view);

@end

#pragma mark - UITabBarItem+FWFramework

/*!
 @brief UITabBarItem分类
 */
@interface UITabBarItem (FWFramework)

/// 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
@property (nullable, nonatomic, weak, readonly) UIImageView *fwImageView;

@end

NS_ASSUME_NONNULL_END
