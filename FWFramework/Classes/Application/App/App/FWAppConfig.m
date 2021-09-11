/*!
 @header     FWAppConfig.m
 @indexgroup FWFramework
 @brief      FWAppConfig
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/14
 */

#import "FWAppConfig.h"

static FWAppConfig *fwStaticAppConfig = nil;

@implementation FWAppConfig

+ (FWAppConfig *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!fwStaticAppConfig) {
            fwStaticAppConfig = [[FWAppConfig alloc] init];
        }
    });
    return fwStaticAppConfig;
}

+ (void)setSharedInstance:(FWAppConfig *)sharedInstance {
    fwStaticAppConfig = sharedInstance;
}

@end
