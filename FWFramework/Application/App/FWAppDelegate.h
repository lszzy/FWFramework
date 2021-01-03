/*!
 @header     FWAppDelegate.h
 @indexgroup FWFramework
 @brief      FWAppDelegate
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import <UIKit/UIKit.h>
#import "FWSceneDelegate.h"
#import "FWAlertController.h"
#import "FWEmptyPlugin.h"
#import "FWRefreshPlugin.h"
#import "FWToastPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief AppDelegate基类
 */
@interface FWAppDelegate : UIResponder <UIApplicationDelegate>

/// 应用主window
@property (nullable, nonatomic, strong) UIWindow *window;

#pragma mark - Protected

/// 初始化应用配置，子类重写
- (void)setupApplication:(UIApplication *)application options:(NSDictionary *)options;

/// 初始化根控制器，子类重写
- (void)setupController;

@end

NS_ASSUME_NONNULL_END
