/*!
 @header     FWAppDelegate.h
 @indexgroup FWFramework
 @brief      FWAppDelegate
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief AppDelegate基类
 */
@interface FWAppDelegate : UIResponder <UIApplicationDelegate>

// 应用主window
@property (nonatomic, strong) UIWindow *window;

#pragma mark - Protect

// 初始化应用，子类重写
- (void)setupApplication:(UIApplication *)application options:(NSDictionary *)options;

// 初始化服务，子类重写
- (void)setupService;

// 初始化界面，子类重写
- (void)setupController;

// 初始化设备token，失败时为error
- (void)setupDeviceToken:(nullable NSData *)deviceToken error:(nullable NSError *)error;

// 统一处理打开URL
- (BOOL)handleOpenURL:(NSURL *)url options:(nullable NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END
