//
//  UIViewController+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+FWAlert.h"
#import "UIViewController+FWBar.h"
#import "UIViewController+FWBack.h"
#import "UIViewController+FWTransition.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIViewController+FWFramework
 @discussion 注意modalPresentationStyle需要在present之前(init之后)设置才会生效，UINavigationController也可设置。
 iOS13由于modalPresentationStyle默认值为Automatic(PageSheet)，不会触发父控制器的viewWillDisappear|viewWillAppear等生命周期方法
 */
@interface UIViewController (FWFramework)

/*!
 @brief 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
 */
- (BOOL)fwIsViewVisible;

/*!
 @brief 当前viewController是否是被以present的方式显示的，是则返回YES，否则返回NO
 @discussion 如果self是self.navigationController的第一个viewController，则如果self.navigationController是被present起来的，那么self.fwIsPresented为YES，可以方便地给navigationController的第一个界面的左上角添加关闭按钮
 */
- (BOOL)fwIsPresented;

/*!
 @brief 是否是第一次加载数据，默认YES，加载完成后可标记为NO
 @discussion 一般第一次加载数据时需要显示loading等，可判断和设置此开关
 */
@property (nonatomic, assign) BOOL fwIsFirstLoad;

#pragma mark - Present

/*!
 @brief 全局适配iOS13默认present样式(系统Automatic)，仅当未自定义modalPresentationStyle时生效
 */
+ (void)fwDefaultModalPresentationStyle:(UIModalPresentationStyle)style;

/*!
 @brief 设置iOS13默认present手势下拉dismiss时的回调block，仅iOS13生效
 @discussion 手工dismiss不会触发，iOS12及以下也不会触发(会触发生命周期方法)。会自动设置presentationController.delegate
 */
@property (nullable, nonatomic, copy) void (^fwPresentationDidDismiss)(void);

/*!
 @brief 设置手工dismiss完成回调block，优先级presented大于self，viewController大于navigationController
 @discussion 仅当控制器自身被dismiss时才会触发，如果有presented控制器，会触发presented控制器的对应block。iOS13默认present手势下拉dismiss时不会触发
 */
@property (nullable, nonatomic, copy) void (^fwDismissBlock)(void);

#pragma mark - Action

// 打开页面。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

// 关闭页面。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (void)fwCloseViewControllerAnimated:(BOOL)animated;

#pragma mark - Child

// 获取当前显示的子控制器，解决不能触发viewWillAppear等的bug
- (nullable UIViewController *)fwChildViewController;

// 设置当前显示的子控制器，解决不能触发viewWillAppear等的bug
- (void)fwSetChildViewController:(UIViewController *)viewController;

// 移除子控制器，解决不能触发viewWillAppear等的bug
- (void)fwRemoveChildViewController:(UIViewController *)viewController;

// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
- (void)fwAddChildViewController:(UIViewController *)viewController;

// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
- (void)fwAddChildViewController:(UIViewController *)viewController inView:(UIView *)view;

#pragma mark - Previous

// 获取和自身处于同一个UINavigationController里的上一个UIViewController
@property(nullable, nonatomic, weak, readonly) UIViewController *fwPreviousViewController;

@end

NS_ASSUME_NONNULL_END
