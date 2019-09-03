/*!
 @header     FWNotificationManager.m
 @indexgroup FWFramework
 @brief      FWNotificationManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "FWNotificationManager.h"
@import UserNotifications;

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

#pragma mark - Handler

- (void)registerHandler
{
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
}

- (void)handleRemoteNotification:(id)notification
{
    if (@available(iOS 10.0, *)) {
        
    }
}

- (void)handleLocalNotification:(id)notification
{
    if (@available(iOS 10.0, *)) {
        
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

@end
