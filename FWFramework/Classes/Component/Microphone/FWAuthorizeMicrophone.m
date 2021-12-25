//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorizeMicrophone.h"
#import <AVFoundation/AVFoundation.h>
#if FWFrameworkSPM
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

@interface FWAuthorizeMicrophone : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeMicrophone

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeMicrophone withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeMicrophone alloc] init];
        }];
    });
}

- (FWAuthorizeStatus)authorizeStatus
{
    AVAudioSessionRecordPermission status = [[AVAudioSession sharedInstance] recordPermission];
    switch (status) {
        case AVAudioSessionRecordPermissionDenied:
            return FWAuthorizeStatusDenied;
        case AVAudioSessionRecordPermissionGranted:
            return FWAuthorizeStatusAuthorized;
        case AVAudioSessionRecordPermissionUndetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession requestRecordPermission:^(BOOL granted) {
        FWAuthorizeStatus status = granted ? FWAuthorizeStatusAuthorized : FWAuthorizeStatusDenied;
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

@end
