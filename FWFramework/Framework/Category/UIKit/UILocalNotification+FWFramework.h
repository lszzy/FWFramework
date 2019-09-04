/*!
 @header     UILocalNotification+FWFramework.h
 @indexgroup FWFramework
 @brief      UILocalNotification+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/4
 */

#import <UIKit/UIKit.h>
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UILocalNotification+FWFramework
 */
@interface UILocalNotification (FWFramework)

// 创建本地通知，badge为0时不显示，soundName为default时为默认声音，timeInterval为距离当前时间戳，repeatInterval为0时不重复
+ (instancetype)fwLocalNotificationWithTitle:(nullable NSString *)title body:(nullable NSString *)body userInfo:(nullable NSDictionary *)userInfo category:(nullable NSString *)category badge:(NSInteger)badge soundName:(nullable NSString *)soundName fireDate:(nullable NSDate *)fireDate repeatInterval:(NSCalendarUnit)repeatInterval;

// 注册本地通知，scheduled为NO时立即触发，iOS8+
+ (void)fwRegisterLocalNotification:(UILocalNotification *)notification scheduled:(BOOL)scheduled;

// 删除已安排的本地通知，iOS8+
+ (void)fwRemoveLocalNotification:(UILocalNotification *)notification;

// 删除所有已安排的本地通知，iOS8+
+ (void)fwRemoveAllLocalNotifications;

@end

/*!
 @brief UNUserNotificationCenter+FWFramework
 */
@interface UNUserNotificationCenter (FWFramework)

// 创建本地通知，badge为0时不显示(nil时不修改)，soundName为default时为默认声音
+ (UNMutableNotificationContent *)fwLocalNotificationWithTitle:(nullable NSString *)title subtitle:(nullable NSString *)subtitle body:(nullable NSString *)body userInfo:(nullable NSDictionary *)userInfo category:(nullable NSString *)category badge:(nullable NSNumber *)badge soundName:(nullable NSString *)soundName;

// 注册本地通知，trigger为nil时立即触发，iOS10+
+ (void)fwRegisterLocalNotification:(NSString *)identifier content:(UNNotificationContent *)content trigger:(nullable UNNotificationTrigger *)trigger;

// 删除未发出的本地通知，iOS10+
+ (void)fwRemovePendingNotification:(NSArray<NSString *> *)identifiers;

// 删除所有未发出的本地通知，iOS10+
+ (void)fwRemoveAllPendingNotifications;

// 删除已发出的本地通知，iOS10+
+ (void)fwRemoveDeliveredNotification:(NSArray<NSString *> *)identifiers;

// 删除所有已发出的本地通知，iOS10+
+ (void)fwRemoveAllDeliveredNotifications;

@end

NS_ASSUME_NONNULL_END
