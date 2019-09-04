/*!
 @header     FWNotificationManager.m
 @indexgroup FWFramework
 @brief      FWNotificationManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "FWNotificationManager.h"

@interface FWNotificationManager () <UNUserNotificationCenterDelegate>

@end

@implementation FWNotificationManager

+ (instancetype)sharedInstance
{
    static FWNotificationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWNotificationManager alloc] init];
    });
    return instance;
}

#pragma mark - Authorize

- (void)authorizeStatus:(void (^)(FWAuthorizeStatus))completion
{
    [[FWAuthorizeManager managerWithType:FWAuthorizeTypeNotifications] authorizeStatus:completion];
}

- (void)requestAuthorize:(void (^)(FWAuthorizeStatus))completion
{
    [[FWAuthorizeManager managerWithType:FWAuthorizeTypeNotifications] authorize:completion];
}

#pragma mark - Badge

- (void)clearNotificationBadges
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - Handler

- (void)registerNotificationHandler
{
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
}

- (void)handleRemoteNotification:(id)notification
{
    if (@available(iOS 10.0, *)) {
        
    } else {
        
    }
}

- (void)handleLocalNotification:(id)notification
{
    if (@available(iOS 10.0, *)) {
        
    } else {
        
    }
}

#pragma mark - UNUserNotificationCenterDelegate

// 前台收到推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0))
{
    // 远程推送
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    // 本地推送
    } else {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    }
}

// 后台收到推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0))
{
    // 远程推送
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [self handleRemoteNotification:response];
        completionHandler();
    // 本地推送
    } else {
        [self handleLocalNotification:response];
        completionHandler();
    }
}

#pragma mark - Local

- (void)registerLocalNotification:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body userInfo:(NSDictionary *)userInfo badge:(NSInteger)badge soundName:(NSString *)soundName timeInterval:(NSInteger)timeInterval repeats:(BOOL)repeats
{
    if (@available(iOS 10.0, *)) {
        UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
        if (title) notification.title = title;
        if (subtitle) notification.subtitle = subtitle;
        if (body) notification.body = body;
        if (userInfo) notification.userInfo = userInfo;
        notification.badge = badge > 0 ? [NSNumber numberWithInteger:badge] : nil;
        if (soundName) {
            notification.sound = [@"default" isEqualToString:soundName] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed:soundName];
        }
        
        UNNotificationTrigger *trigger = timeInterval > 0 ? [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:repeats] : nil;
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:notification trigger:trigger];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    } else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.category = identifier;
        if (@available(iOS 8.2, *)) {
            notification.alertTitle = title ?: subtitle;
        }
        notification.alertBody = body;
        notification.userInfo = userInfo;
        notification.applicationIconBadgeNumber = badge;
        if (soundName) {
            notification.soundName = [@"default" isEqualToString:soundName] ? UILocalNotificationDefaultSoundName : soundName;
        }
        if (timeInterval > 0) {
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
            
            // UILocalNotification只支持NSCalendarUnit级别的重复，否则不生效
            if (repeats) {
                switch (timeInterval) {
                    case 60:
                        notification.repeatInterval = NSCalendarUnitMinute;
                        break;
                    case 900:
                        notification.repeatInterval = NSCalendarUnitQuarter;
                        break;
                    case 3600:
                        notification.repeatInterval = NSCalendarUnitHour;
                        break;
                    case 86400:
                        notification.repeatInterval = NSCalendarUnitDay;
                        break;
                    case 86400 * 7:
                        notification.repeatInterval = NSCalendarUnitWeekday;
                        break;
                    case 86400 * 30:
                        notification.repeatInterval = NSCalendarUnitMonth;
                        break;
                    case 86400 * 365:
                        notification.repeatInterval = NSCalendarUnitYear;
                        break;
                    default:
                        break;
                }
            }
            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        } else {
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

- (void)removeLocalNotification:(NSArray<NSString *> *)identifiers
{
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:identifiers];
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:identifiers];
    } else {
        NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *notification in notifications) {
            if (notification.category && [identifiers containsObject:notification.category]) {
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
            }
        }
    }
}

- (void)removeAllLocalNotifications
{
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
        [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
    } else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

@end
