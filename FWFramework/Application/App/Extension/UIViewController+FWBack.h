/*!
 @header     UIViewController+FWBack.h
 @indexgroup FWFramework
 @brief      UIViewController+FWBack
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/12
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIViewController+FWBack
 */
@interface UIViewController (FWBack)

// 当自定义left按钮之后，系统返回手势失效，可通过此方法强制加回手势。当interactivePopGestureRecognizer.enabled为NO时不生效
@property (nonatomic, assign) BOOL fwForcePopGesture;

// 导航栏返回按钮点击事件(pop不会触发)，当前页面生效。返回YES关闭页面，NO不关闭，子类可重写。默认调用已设置的block事件
- (BOOL)fwPopBackBarItem;

// 设置导航栏返回按钮点击block事件，默认fwPopBackBarItem自动调用。逻辑同上
- (void)fwSetBackBarBlock:(nullable BOOL (^)(void))block;

@end

NS_ASSUME_NONNULL_END
