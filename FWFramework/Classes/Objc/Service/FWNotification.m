/**
 @header     FWNotification.m
 @indexgroup FWFramework
      FWNotification
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "FWNotification.h"

@interface FWNotificationManager () <UNUserNotificationCenterDelegate>

@end

@implementation FWNotificationManager

+ (FWNotificationManager *)sharedInstance
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
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
}

- (void)handleRemoteNotification:(id)notification
{
    if (!self.remoteNotificationHandler) return;
    
    NSDictionary *userInfo = nil;
    if ([notification isKindOfClass:[NSDictionary class]]) {
        userInfo = notification;
    } else {
        if ([notification isKindOfClass:[UNNotificationResponse class]]) {
            userInfo = ((UNNotificationResponse *)notification).notification.request.content.userInfo;
        } else if ([notification isKindOfClass:[UNNotification class]]) {
            userInfo = ((UNNotification *)notification).request.content.userInfo;
        }
    }
    
    self.remoteNotificationHandler(userInfo, notification);
}

- (void)handleLocalNotification:(id)notification
{
    if (!self.localNotificationHandler) return;
    
    NSDictionary *userInfo = nil;
    if ([notification isKindOfClass:[NSDictionary class]]) {
        userInfo = notification;
    } else {
        if ([notification isKindOfClass:[UNNotificationResponse class]]) {
            userInfo = ((UNNotificationResponse *)notification).notification.request.content.userInfo;
        } else if ([notification isKindOfClass:[UNNotification class]]) {
            userInfo = ((UNNotification *)notification).request.content.userInfo;
        }
    }
    
    self.localNotificationHandler(userInfo, notification);
}

#pragma mark - UNUserNotificationCenterDelegate

// 前台收到推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
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
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
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

- (void)registerLocalNotification:(NSString *)identifier title:(NSString *)title subtitle:(NSString *)subtitle body:(NSString *)body userInfo:(NSDictionary *)userInfo badge:(NSInteger)badge soundName:(NSString *)soundName timeInterval:(NSInteger)timeInterval repeats:(BOOL)repeats block:(void (NS_NOESCAPE ^)(UNMutableNotificationContent *))block
{
    UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
    if (title) notification.title = title;
    if (subtitle) notification.subtitle = subtitle;
    if (body) notification.body = body;
    if (userInfo) notification.userInfo = userInfo;
    notification.badge = badge > 0 ? [NSNumber numberWithInteger:badge] : nil;
    if (soundName) notification.sound = [@"default" isEqualToString:soundName] ? [UNNotificationSound defaultSound] : [UNNotificationSound soundNamed:soundName];
    if (block) block(notification);
    
    UNNotificationTrigger *trigger = timeInterval > 0 ? [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:timeInterval repeats:repeats] : nil;
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:notification trigger:trigger];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}

- (void)removeLocalNotification:(NSArray<NSString *> *)identifiers
{
    [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:identifiers];
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:identifiers];
}

- (void)removeAllLocalNotifications
{
    [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
}

@end
