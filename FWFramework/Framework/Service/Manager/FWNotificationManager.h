/*!
 @header     FWNotificationManager.h
 @indexgroup FWFramework
 @brief      FWNotificationManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import <UIKit/UIKit.h>
@import UserNotifications;
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

#pragma mark - Badge

// 清空图标通知计数
- (void)clearNotificationBadges;

#pragma mark - Handler

// 设置远程推送处理句柄，参数为userInfo和原始通知对象
@property (nonatomic, copy) void (^remoteNotificationHandler)(NSDictionary *userInfo, id notification);

// 设置本地推送处理句柄，参数为userInfo和原始通知对象
@property (nonatomic, copy) void (^localNotificationHandler)(NSDictionary *userInfo, id notification);

// 注册通知处理器，iOS10+生效，iOS10以下详见UIApplicationDelegate
- (void)registerNotificationHandler;

// 处理远程推送通知，支持NSDictionary|UNNotification|UNNotificationResponse等
- (void)handleRemoteNotification:(id)notification;

// 处理本地通知，支持NSDictionary|UILocalNotification|UNNotification|UNNotificationResponse等
- (void)handleLocalNotification:(id)notification;

#pragma mark - Local

// 注册本地通知，badge为0时不改变，soundName为default时为默认声音，timeInterval为触发时间间隔(0为立即触发)，重复触发时最少间隔1分钟(60)。(iOS10以下只支持重复NSCalendarUnit标准单位时间，如60|900|3600|86400|86400*7|86400*30|86400*365，否则不生效)
- (void)registerLocalNotification:(NSString *)identifier title:(nullable NSString *)title subtitle:(nullable NSString *)subtitle body:(nullable NSString *)body userInfo:(nullable NSDictionary *)userInfo badge:(NSInteger)badge soundName:(nullable NSString *)soundName timeInterval:(NSInteger)timeInterval repeats:(BOOL)repeats;

// 批量删除本地通知(未发出和已发出)
- (void)removeLocalNotification:(NSArray<NSString *> *)identifiers;

// 删除所有本地通知(未发出和已发出)
- (void)removeAllLocalNotifications;

@end

NS_ASSUME_NONNULL_END
