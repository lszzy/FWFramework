/*!
 @header     FWImagePreviewPluginImpl.m
 @indexgroup FWFramework
 @brief      FWImagePreviewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePreviewPluginImpl.h"

#pragma mark - FWImagePreviewPluginImpl

@implementation FWImagePreviewPluginImpl

+ (FWImagePreviewPluginImpl *)sharedInstance
{
    static FWImagePreviewPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImagePreviewPluginImpl alloc] init];
    });
    return instance;
}

@end
