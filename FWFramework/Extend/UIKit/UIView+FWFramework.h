/*!
 @header     UIView+FWFramework.h
 @indexgroup FWFramework
 @brief      UIView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>
#import "UIView+FWAutoLayout.h"

/*!
 @brief UIView+FWFramework
 */
@interface UIView (FWFramework)

#pragma mark - ViewController

// 获取响应的视图控制器
- (UIViewController *)fwViewController;

// 获取最顶端的控制器
- (UIViewController *)fwTopMostController;

@end
