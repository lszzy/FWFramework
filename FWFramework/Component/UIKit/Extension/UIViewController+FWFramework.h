//
//  UIViewController+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+FWTransition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 UIViewController+FWFramework
 
 一、modalPresentationStyle需要在present之前(init之后)设置才会生效，UINavigationController也可设置。
 二、iOS13由于modalPresentationStyle默认值为Automatic(PageSheet)，不会触发父控制器的viewWillDisappear|viewWillAppear等生命周期方法。
 三、modalPresentationCapturesStatusBarAppearance：弹出非UIModalPresentationFullScreen控制器时，该控制器是否控制状态栏样式。默认NO，不控制。
 四、如果ScrollView占不满导航栏，iOS7-10需设置viewController.automaticallyAdjustsScrollViewInsets为NO，iOS11则需要设置contentInsetAdjustmentBehavior为UIScrollViewContentInsetAdjustmentNever
 */
@interface UIViewController (FWFramework)

/*!
 @brief 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
 */
- (BOOL)fwIsViewVisible;

/*!
 @brief 是否已经加载完数据，默认NO，加载完成后可标记为YES
 @discussion 一般第一次加载数据时需要显示loading等，可判断和标记此开关
 */
@property (nonatomic, assign) BOOL fwIsLoaded;

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
