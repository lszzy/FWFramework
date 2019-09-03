/*!
 @header     FWNotificationManager.m
 @indexgroup FWFramework
 @brief      FWNotificationManager
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "FWNotificationManager.h"

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

@end
