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
#import "FWAlertPlugin.h"
#import "FWAlertController.h"
#import "FWEmptyPlugin.h"
#import "FWJsBridge.h"
#import "FWRefreshPlugin.h"
#import "FWToastPlugin.h"
#import "FWModel.h"
#import "FWViewModel.h"
#import "FWViewController.h"
#import "FWCollectionViewController.h"
#import "FWScrollViewController.h"
#import "FWTableViewController.h"
#import "FWWebViewController.h"
#import "FWView.h"

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

/// 初始化优先级高的服务，子类重写
- (void)setupService;

/// 初始化全局样式，子类重写
- (void)setupAppearance;

/// 初始化根控制器，子类重写
- (void)setupController;

/// 初始化优先级低的组件，子类重写
- (void)setupComponent;

/// 初始化设备token，失败时为error
- (void)setupDeviceToken:(nullable NSData *)tokenData error:(nullable NSError *)error;

/// 统一处理打开URL，默认包含通用链接
- (BOOL)handleOpenURL:(NSURL *)url options:(nullable NSDictionary *)options;

/// 统一处理通用链接，默认转发handleOpenURL
- (BOOL)handleUserActivity:(NSUserActivity *)userActivity;

@end

NS_ASSUME_NONNULL_END
