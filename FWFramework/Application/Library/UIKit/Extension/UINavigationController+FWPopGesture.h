/*!
 @header     UINavigationController+FWPopGesture.h
 @indexgroup FWFramework
 @brief      UINavigationController+FWPopGesture
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/13
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 导航栏全屏返回手势分类，兼容fwPopBackBarItem返回拦截方法
 
 @see https://github.com/forkingdog/FDFullscreenPopGesture
 */
@interface UINavigationController (FWFullscreenPopGesture)

// 是否启用导航栏全屏返回手势，默认NO。启用时系统返回手势失效，禁用时还原系统手势。如果只禁用系统手势，设置interactivePopGestureRecognizer.enabled即可
@property (nonatomic, assign) BOOL fwFullscreenPopGestureEnabled;

// 导航栏全屏返回手势对象
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *fwFullscreenPopGestureRecognizer;

// 判断手势是否是全局返回手势对象
+ (BOOL)fwIsFullscreenPopGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;

@end

/*!
 @brief 视图控制器全屏返回手势分类
 */
@interface UIViewController (FWFullscreenPopGesture)

// 视图控制器是否禁用全屏返回手势，默认NO
@property (nonatomic, assign) BOOL fwFullscreenPopGestureDisabled;

// 视图控制器全屏手势距离左侧最大距离，默认0，无限制
@property (nonatomic, assign) CGFloat fwFullscreenPopGestureDistance;

@end

NS_ASSUME_NONNULL_END
