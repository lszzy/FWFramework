/*!
 @header     UIViewController+FWDelegate.h
 @indexgroup FWFramework
 @brief      UIViewController+FWDelegate
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/3/11
 */

#import <UIKit/UIKit.h>

#pragma mark - FWModalTransitionDelegate

// 视图控制器转场代理
@interface FWModalTransitionDelegate : NSObject <UIViewControllerTransitioningDelegate>

// 创建转场代理对象，nil时为系统转场
+ (instancetype)delegateWithTransition:(id<UIViewControllerAnimatedTransitioning>)transition;

@end

#pragma mark - UIViewController+FWDelegate

// 视图控制器转场分类，如需半透明，请在init中设置modalPresentationStyle为UIModalPresentationCustom
@interface UIViewController (FWDelegate)

// 视图控制器present|dismiss转场代理。注意会修改transitioningDelegate，且会强引用之；如需weak引用，请直接设置transitioningDelegate
@property (nonatomic, strong) id<UIViewControllerTransitioningDelegate> fwModalTransitionDelegate;

// 视图控制器push|pop转场，代理导航控制器转场，fwNavigationDelegate设置后生效
@property (nonatomic, strong) id<UIViewControllerAnimatedTransitioning> fwNavigationTransition;

@end

#pragma mark - FWNavigationTransitionDelegate

// 导航控制器转场代理
@interface FWNavigationTransitionDelegate : NSObject <UINavigationControllerDelegate>

// 创建转场代理对象，nil时为系统转场
+ (instancetype)delegateWithTransition:(id<UIViewControllerAnimatedTransitioning>)transition;

@end

#pragma mark - UINavigationController+FWDelegate

// 导航控制器转场分类
@interface UINavigationController (FWDelegate)

// 导航控制器push|pop转场代理。注意会修改delegate，且会强引用之，一直生效直到设置为nil。如需weak引用，请直接设置delegate
@property (nonatomic, strong) id<UINavigationControllerDelegate> fwNavigationTransitionDelegate;

@end
