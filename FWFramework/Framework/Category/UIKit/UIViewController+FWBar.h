//
//  UIViewController+FWBar.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 视图控制器Bar分类
 *
 * 备注：需要设置UIViewControllerBasedStatusBarAppearance为YES，视图控制器修改状态栏样式才会生效
 */
@interface UIViewController (FWBar)

#pragma mark - Bar

// 状态栏是否隐藏，默认NO
@property (nonatomic, assign) BOOL fwStatusBarHidden;

// 导航栏样式，默认UIStatusBarStyleDefault
@property (nonatomic, assign) UIStatusBarStyle fwStatusBarStyle;

// 导航栏是否隐藏，默认为NO
@property (nonatomic, assign) BOOL fwNavigationBarHidden;

// 标签栏是否隐藏，默认为NO。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
@property (nonatomic, assign) BOOL fwTabBarHidden;

// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，All为全部延伸(全部Bar覆盖视图)
- (void)fwSetBarExtendEdge:(UIRectEdge)edge;

#pragma mark - Item

// 快捷设置导航栏标题文字或视图
- (void)fwSetBarTitle:(id)title;

// 快捷设置导航栏左侧按钮
- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action;

// 快捷设置导航栏左侧按钮，block事件
- (void)fwSetLeftBarItem:(id)object block:(void (^)(id sender))block;

// 快捷设置导航栏右侧按钮
- (void)fwSetRightBarItem:(id)object target:(id)target action:(SEL)action;

// 快捷设置导航栏右侧按钮，block事件
- (void)fwSetRightBarItem:(id)object block:(void (^)(id sender))block;

#pragma mark - Back

// 设置导航栏返回按钮文字(显示系统返回箭头)，下个页面生效
- (void)fwSetBackBarTitle:(NSString *)title;

// 设置导航栏返回按钮图片(只显示此图片，不显示返回箭头)，下个页面生效
- (void)fwSetBackBarImage:(UIImage *)image;

// 设置导航栏返回按钮透明(只显示返回箭头)，下个页面生效
- (void)fwSetBackBarClear;

// 导航栏返回按钮点击事件(pop不会触发)，当前页面生效。返回YES关闭页面，NO不关闭，子类可重写。默认调用已设置的block事件
- (BOOL)fwPopBackBarItem;

// 设置导航栏返回按钮点击block事件，默认fwPopBackBarItem自动调用。逻辑同上
- (void)fwSetBackBarBlock:(BOOL (^)(void))block;

#pragma mark - Action

// 打开页面。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOnOpen:(UIViewController *)viewController;

// 关闭页面。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (void)fwOnClose;

@end

#pragma mark - UINavigationBar+FWBar

// 导航栏视图分类，全局设置用[UINavigationBar appearance]
@interface UINavigationBar (FWBar)

// 设置全局按钮文字样式(不含图片)，单个设置时详见UIBarButtonItem
+ (void)fwSetButtonTitleAttributes:(NSDictionary *)attributes;

// 设置标题和按钮颜色
- (void)fwSetTextColor:(UIColor *)color;

// 设置标题样式属性
- (void)fwSetTitleAttributes:(NSDictionary *)attributes;

// 设置背景颜色
- (void)fwSetBackgroundColor:(UIColor *)color;

// 设置背景图片
- (void)fwSetBackgroundImage:(UIImage *)image;

// 设置透明背景并隐藏底部线条
- (void)fwSetBackgroundClear;

// 设置是否隐藏底部线条
- (void)fwSetLineHidden:(BOOL)hidden;

// 设置返回箭头图片，值为nil则还原默认
- (void)fwSetIndicatorImage:(UIImage *)image;

// 设置返回箭头图片，值为nil则还原默认，支持图片偏移
- (void)fwSetIndicatorImage:(UIImage *)image insets:(UIEdgeInsets)insets;

@end

#pragma mark - UITabBar+FWBar

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 @discussion 如果push时需要隐藏TabBar，需要设置vc.hidesBottomBarWhenPushed，再push即可。
    如果present时需要隐藏TabBar，需要设置tabbar.definesPresentationContext为YES，再用tabbar来present即可
 */
@interface UITabBar (FWBar)

// 设置文字颜色(含图标)
- (void)fwSetTextColor:(UIColor *)color;

// 设置背景颜色
- (void)fwSetBackgroundColor:(UIColor *)color;

// 设置背景图片
- (void)fwSetBackgroundImage:(UIImage *)image;

// 设置是否隐藏顶部线条
- (void)fwSetLineHidden:(BOOL)hidden;

// 设置阴影色，offset示例(0,1)，radius示例6
- (void)fwSetShadowColor:(UIColor *)color
                  offset:(CGSize)offset
                  radius:(CGFloat)radius;

@end
