//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorizeAppleMusic.h"
#import <MediaPlayer/MediaPlayer.h>

// iOS9.3+需要授权，9.3以前不需要授权
@interface FWAuthorizeAppleMusic : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeAppleMusic

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeAppleMusic withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeAppleMusic alloc] init];
        }];
    });
}

- (FWAuthorizeStatus)authorizeStatus
{
    MPMediaLibraryAuthorizationStatus status = [MPMediaLibrary authorizationStatus];
    switch (status) {
        case MPMediaLibraryAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case MPMediaLibraryAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case MPMediaLibraryAuthorizationStatusAuthorized:
            return FWAuthorizeStatusAuthorized;
        case MPMediaLibraryAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
    [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.authorizeStatus);
            });
        }
    }];
}

@end
