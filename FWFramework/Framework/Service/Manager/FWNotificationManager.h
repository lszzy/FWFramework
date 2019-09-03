/*!
 @header     FWNotificationManager.h
 @indexgroup FWFramework
 @brief      FWNotificationManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "FWAuthorizeManager.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 通知管理器
 */
@interface FWNotificationManager : NSObject

// 单例模式
+ (instancetype)sharedInstance;

#pragma mark - Authorize

// 异步查询通知权限状态，当前线程回调
- (void)authorizeStatus:(nullable void (^)(FWAuthorizeStatus status))completion;

// 执行通知权限授权，主线程回调
- (void)requestAuthorize:(nullable void (^)(FWAuthorizeStatus status))completion;

#pragma mark - Handler

// 注册通知处理器
- (void)registerHandler;

// 处理远程推送通知，支持NSDictionary|UNNotification|UNNotificationResponse等
- (void)handleRemoteNotification:(id)notification;

// 处理本地通知，支持NSDictionary|UILocalNotification|UNNotification|UNNotificationResponse等
- (void)handleLocalNotification:(id)notification;

@end

NS_ASSUME_NONNULL_END
