/*!
 @header     UINavigationController+FWBar.h
 @indexgroup FWFramework
 @brief      UINavigationController+FWBar
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import <UIKit/UIKit.h>

/*!
 @brief UINavigationController+FWBar
 */
@interface UINavigationController (FWBar)

// 默认白色，与解决透明navigationBar的问题有关
- (UIColor *)fwContainerViewBackgroundColor;

@end

/*!
 @brief UIViewController+FWBarTransition
 */
@interface UIViewController (FWBarTransition)

@property (nonatomic, weak) UIScrollView *fwTransitionScrollView;

@end
