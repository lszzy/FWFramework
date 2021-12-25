//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorizeCalendar.h"
#import <EventKit/EventKit.h>
#if FWFrameworkSPM
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

@interface FWAuthorizeEventKit : NSObject <FWAuthorizeProtocol>

@property (nonatomic, readonly) EKEntityType type;

- (instancetype)initWithType:(EKEntityType)type;

@end

@implementation FWAuthorizeEventKit

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeCalendars withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeEventKit alloc] initWithType:EKEntityTypeEvent];
        }];
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeReminders withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeEventKit alloc] initWithType:EKEntityTypeReminder];
        }];
    });
}

- (instancetype)initWithType:(EKEntityType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (FWAuthorizeStatus)authorizeStatus
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:self.type];
    switch (status) {
        case EKAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case EKAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case EKAuthorizationStatusAuthorized:
            return FWAuthorizeStatusAuthorized;
        case EKAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus))completion
{
    EKEventStore *store = [[EKEventStore alloc] init];
    [store requestAccessToEntityType:self.type completion:^(BOOL granted, NSError * _Nullable error) {
        FWAuthorizeStatus status = granted ? FWAuthorizeStatusAuthorized : FWAuthorizeStatusDenied;
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

@end
