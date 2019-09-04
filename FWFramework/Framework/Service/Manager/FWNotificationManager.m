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

- (void)registerLocalNotification:(NSString *)identifier title:(nullable NSString *)title subtitle:(nullable NSString *)subtitle body:(nullable NSString *)body userInfo:(nullable NSDictionary *)userInfo badge:(nullable NSNumber *)badge soundName:(nullable NSString *)soundName timeInterval:(NSInteger)timeInterval repeats:(BOOL)repeats
{
    if (@available(iOS 10.0, *)) {
        
    } else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.category = identifier;
        if (@available(iOS 8.2, *)) {
            notification.alertTitle = title ?: subtitle;
        }
        notification.alertBody = body;
        notification.userInfo = userInfo;
        if (badge) {
            notification.applicationIconBadgeNumber = [badge integerValue];
        }
        if (soundName) {
            notification.soundName = [@"default" isEqualToString:soundName] ? UILocalNotificationDefaultSoundName : soundName;
        }
        if (timeInterval > 0) {
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
            
            /*
            if (repeats) {
                switch (timeInterval) {
                    case <#constant#>:
                        <#statements#>
                        break;
                        
                    default:
                        break;
                }
                
                NSCalendarUnitYear              = 年单位。值很大。（2016）年
                NSCalendarUnitMonth             = 月单位。范围为1-12
                NSCalendarUnitDay               = 天单位。范围为1-31
                NSCalendarUnitHour              = 小时单位。范围为0-24
                NSCalendarUnitMinute            = 分钟单位。范围为0-60
                NSCalendarUnitWeekday           = 星期单位。范围为1-7 （一个星期有七天）
                NSCalendarUnitQuarter           = 刻钟单位。范围为1-4 （1刻钟等于15分钟）
            }*/
            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        } else {
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    }
}

- (void)removeLocalNotification:(NSString *)identifier
{
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[identifier]];
    } else {
        NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *notification in notifications) {
            if ([identifier isEqualToString:notification.category]) {
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
                break;
            }
        }
    }
}

- (void)removeAllLocalNotifications
{
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeAllPendingNotificationRequests];
    } else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

@end
