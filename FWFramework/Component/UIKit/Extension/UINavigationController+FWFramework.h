/*!
 @header     UINavigationController+FWFramework.h
 @indexgroup FWFramework
 @brief      UINavigationController+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>
#import "UINavigationController+FWBar.h"
#import "UINavigationController+FWWorkflow.h"

/*!
 @brief 修复iOS14.0如果pop到一个hidesBottomBarWhenPushed=NO的vc，tabBar无法正确显示出来的bug
 @discussion present带导航栏webview，如果存在input[type=file]，会dismiss两次，无法选择照片。解决方法：1.使用push 2.重写dismiss方法仅当presentedViewController存在时才调用dismiss
 
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface UINavigationController (FWFramework)

@end
