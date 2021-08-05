/*!
 @header     UILocalNotification+FWFramework.m
 @indexgroup FWFramework
 @brief      UILocalNotification+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/4
 */

#import "UILocalNotification+FWFramework.h"

@implementation UNUserNotificationCenter (FWFramework)

+ (UNMutableNotificationContent *)fwLocalNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body userInfo:(NSDictionary *)userInfo category:(NSString *)category badge:(NSNumber *)badge soundName:(NSString *)soundName
{
    UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
    if (title) notification.title = title;
    if (subtitle) notification.subtitle = subtitle;
    if (body) notification.body = body;
    if (userInfo) notification.userInfo = userInfo;
    if (category) notification.categoryIdentifier = category;
    notification.badge = badge;
    if (soundName) {
        notification.sound = [@"default" isEqualToString:soundName] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed:soundName];
    }
    return notification;
}

+ (void)fwRegisterLocalNotification:(NSString *)identifier content:(UNNotificationContent *)content trigger:(UNNotificationTrigger *)trigger
{
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}

+ (void)fwRemovePendingNotification:(NSArray<NSString *> *)identifiers
{
    [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:identifiers];
}

+ (void)fwRemoveAllPendingNotifications
{
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
}

+ (void)fwRemoveDeliveredNotification:(NSArray<NSString *> *)identifiers
{
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:identifiers];
}

+ (void)fwRemoveAllDeliveredNotifications
{
    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
}

@end
