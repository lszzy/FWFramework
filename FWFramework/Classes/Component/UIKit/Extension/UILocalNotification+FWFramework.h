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
