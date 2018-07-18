/*!
 @header     FWAppDelegate.h
 @indexgroup FWFramework
 @brief      应用抽象代理
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <UIKit/UIKit.h>

/*!
 @brief 应用代理抽象基类
 */
@interface FWAppDelegate : UIResponder <UIApplicationDelegate>

/*! @brief 应用主窗口 */
@property (nonatomic, strong) UIWindow *window;

@end
