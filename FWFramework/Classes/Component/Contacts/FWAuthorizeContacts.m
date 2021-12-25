//
//  FWAuthorize.m
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorizeContacts.h"
#import <Contacts/Contacts.h>
#if FWFrameworkContacts
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

// iOS9+使用Contacts
@interface FWAuthorizeContacts : NSObject <FWAuthorizeProtocol>

@end

@implementation FWAuthorizeContacts

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWAuthorizeManager registerAuthorize:FWAuthorizeTypeContacts withBlock:^id<FWAuthorizeProtocol>{
            return [[FWAuthorizeContacts alloc] init];
        }];
    });
}

- (FWAuthorizeStatus)authorizeStatus
{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusRestricted:
            return FWAuthorizeStatusRestricted;
        case CNAuthorizationStatusDenied:
            return FWAuthorizeStatusDenied;
        case CNAuthorizationStatusAuthorized:
            return FWAuthorizeStatusAuthorized;
        case CNAuthorizationStatusNotDetermined:
        default:
            return FWAuthorizeStatusNotDetermined;
    }
}

- (void)authorize:(void (^)(FWAuthorizeStatus status))completion
{
    [[CNContactStore new] requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        FWAuthorizeStatus status = granted ? FWAuthorizeStatusAuthorized : FWAuthorizeStatusDenied;
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

@end
