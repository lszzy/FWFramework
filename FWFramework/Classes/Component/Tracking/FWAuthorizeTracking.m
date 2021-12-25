//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorizeTracking.h"
#import <AdSupport/ASIdentifierManager.h>
#if __IPHONE_14_0
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif
#if FWFrameworkSPM
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

// iOS14+使用AppTrackingTransparency，其它使用AdSupport
@interface FWAuthorizeTracking : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeTracking

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeTracking withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeTracking alloc] init];
        }];
    });
}

- (FWAuthorizeStatus)authorizeStatus
{
#if __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        ATTrackingManagerAuthorizationStatus status = ATTrackingManager.trackingAuthorizationStatus;
        switch (status) {
            case ATTrackingManagerAuthorizationStatusRestricted:
                return FWAuthorizeStatusRestricted;
            case ATTrackingManagerAuthorizationStatusDenied:
                return FWAuthorizeStatusDenied;
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return FWAuthorizeStatusAuthorized;
            case ATTrackingManagerAuthorizationStatusNotDetermined:
            default:
                return FWAuthorizeStatusNotDetermined;
        }
    }
#endif
    
    return [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled ? FWAuthorizeStatusAuthorized : FWAuthorizeStatusDenied;
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
#if __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(self.authorizeStatus);
                });
            }
        }];
        return;
    }
#endif
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(self.authorizeStatus);
        });
    }
}

@end
