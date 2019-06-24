//
//  UIViewController+FWBar.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 视图控制器Bar分类
 *
 * 备注：需要设置UIViewControllerBasedStatusBarAppearance为YES，视图控制器修改状态栏样式才会生效
 * modalPresentationCapturesStatusBarAppearance：弹出非UIModalPresentationFullScreen控制器时，该控制器是否控制状态栏样式。默认NO，不控制
 */
@interface UIViewController (FWBar)

#pragma mark - Bar

// 状态栏是否隐藏，默认NO
@property (nonatomic, assign) BOOL fwStatusBarHidden;

// 导航栏样式，默认UIStatusBarStyleDefault
@property (nonatomic, assign) UIStatusBarStyle fwStatusBarStyle;

// 导航栏是否隐藏，默认为NO
@property (nonatomic, assign) BOOL fwNavigationBarHidden;

// 动态设置导航栏是否隐藏，切换动画不突兀，建议使用此方法。一般在viewWillAppear中设置，viewWillDisappear时还原，animated参数相同
- (void)fwSetNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;

// 标签栏是否隐藏，默认为NO。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
@property (nonatomic, assign) BOOL fwTabBarHidden;

// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，All为全部延伸(全部Bar覆盖视图)
- (void)fwSetBarExtendEdge:(UIRectEdge)edge;

#pragma mark - Item

// 快捷设置导航栏标题文字或视图
- (void)fwSetBarTitle:(id)title;

// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fwSetLeftBarItem:(id)object target:(id)target action:(SEL)action;

// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
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

@end

#pragma mark - UINavigationBar+FWBar

// 导航栏视图分类，全局设置用[UINavigationBar appearance]
@interface UINavigationBar (FWBar)

// 设置全局按钮文字样式(不含图片)，单个设置时详见UIBarButtonItem
+ (void)fwSetButtonTitleAttributes:(NSDictionary *)attributes;

// 设置标题和按钮颜色
- (void)fwSetTextColor:(UIColor *)color UI_APPEARANCE_SELECTOR;

// 设置背景颜色。为避免barTintColor的一些兼容问题，此方法未使用barTintColor，而是使用颜色生成的图片来设置backgroundImage
- (void)fwSetBackgroundColor:(UIColor *)color UI_APPEARANCE_SELECTOR;

// 设置背景图片
- (void)fwSetBackgroundImage:(UIImage *)image UI_APPEARANCE_SELECTOR;

// 设置透明背景并隐藏底部线条
- (void)fwSetBackgroundClear UI_APPEARANCE_SELECTOR;

// 设置是否隐藏底部线条
- (void)fwSetLineHidden:(BOOL)hidden UI_APPEARANCE_SELECTOR;

// 添加背景视图，可设置背景色等
- (UIView *)fwOverlayView;

// 重置导航栏背景颜色和图片，移除自定义视图
- (void)fwResetBackground;

// 设置返回箭头图片，值为nil则还原默认
- (void)fwSetIndicatorImage:(UIImage *)image UI_APPEARANCE_SELECTOR;

// 设置返回箭头图片，值为nil则还原默认，支持图片偏移
- (void)fwSetIndicatorImage:(UIImage *)image insets:(UIEdgeInsets)insets UI_APPEARANCE_SELECTOR;

// 背景view，可能显示磨砂、背景图，顶部有一部分溢出到UINavigationBar外。在iOS10及以后是私有的_UIBarBackground类，在iOS9及以前是私有的_UINavigationBarBackground类
- (UIView *)fwBackgroundView;

// 用于显示底部分隔线shadowImage，注意这个view是溢出到backgroundView外的。若shadowImage为[UIImage new]，则这个view的高度为0
- (UIImageView *)fwShadowImageView;

@end

#pragma mark - UITabBar+FWBar

/*!
 @brief 标签栏视图分类，全局设置用[UITabBar appearance]
 @discussion 如果push时需要隐藏TabBar，需要设置vc.hidesBottomBarWhenPushed，再push即可。
    如果present时需要隐藏TabBar，需要设置tabbar.definesPresentationContext为YES，再用tabbar来present即可。
    可以设置所有控制器默认hidesBottomBarWhenPushed为YES，然后初始化TabBarController时，设置所有子控制器hidesBottomBarWhenPushed为NO即可
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

// UITabBar 的背景 view，可能显示磨砂、背景图，顶部有一部分溢出到 UITabBar 外。在 iOS 10 及以后是私有的 _UIBarBackground 类，在 iOS 9 及以前是私有的 _UITabBarBackgroundView 类
- (UIView *)fwBackgroundView;

// 用于显示顶部分隔线 shadowImage，注意这个 view 是溢出到 backgroundView 外的。若 shadowImage 为 [UIImage new]，则这个 view 的高度为 0
- (UIImageView *)fwShadowImageView;

@end
