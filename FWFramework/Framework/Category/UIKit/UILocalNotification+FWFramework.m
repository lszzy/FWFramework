/*!
 @header     UILocalNotification+FWFramework.m
 @indexgroup FWFramework
 @brief      UILocalNotification+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/4
 */

#import "UILocalNotification+FWFramework.h"

@implementation UILocalNotification (FWFramework)

+ (instancetype)fwLocalNotificationWithTitle:(NSString *)title body:(NSString *)body userInfo:(NSDictionary *)userInfo category:(NSString *)category badge:(NSInteger)badge soundName:(nullable NSString *)soundName fireDate:(nullable NSDate *)fireDate repeatInterval:(NSCalendarUnit)repeatInterval
{
    UILocalNotification *notification = [[self alloc] init];
    if (@available(iOS 8.2, *)) {
        notification.alertTitle = title;
    }
    notification.alertBody = body;
    notification.userInfo = userInfo;
    if (category) {
        notification.category = category;
    }
    notification.applicationIconBadgeNumber = badge;
    if (soundName) {
        notification.soundName = [@"default" isEqualToString:soundName] ? UILocalNotificationDefaultSoundName : soundName;
    }
    if (fireDate) {
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.fireDate = fireDate;
    }
    notification.repeatInterval = repeatInterval;
    return notification;
}

+ (void)fwRegisterLocalNotification:(UILocalNotification *)notification scheduled:(BOOL)scheduled
{
    if (scheduled) {
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    } else {
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

+ (void)fwRemoveLocalNotification:(UILocalNotification *)notification
{
    [[UIApplication sharedApplication] cancelLocalNotification:notification];
}

+ (void)fwRemoveAllLocalNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end

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
