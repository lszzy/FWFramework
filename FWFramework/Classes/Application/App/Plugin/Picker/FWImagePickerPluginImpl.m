/*!
 @header     FWImagePickerPluginImpl.m
 @indexgroup FWFramework
 @brief      FWImagePickerPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWImagePickerPluginImpl.h"

#pragma mark - FWImagePickerPluginImpl

@implementation FWImagePickerPluginImpl

+ (FWImagePickerPluginImpl *)sharedInstance
{
    static FWImagePickerPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImagePickerPluginImpl alloc] init];
    });
    return instance;
}

@end
