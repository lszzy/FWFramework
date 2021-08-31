/*!
 @header     FWViewPlugin.m
 @indexgroup FWFramework
 @brief      FWViewPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWViewPlugin.h"
#import "FWViewPluginImpl.h"
#import "FWPlugin.h"

#pragma mark - FWViewPlugin

@implementation FWViewPluginManager

+ (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style
{
    id<FWViewPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWViewPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(createProgressView:)]) {
        plugin = FWViewPluginImpl.sharedInstance;
    }
    return [plugin createProgressView:style];
}

+ (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style
{
    id<FWViewPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWViewPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(createIndicatorView:)]) {
        plugin = FWViewPluginImpl.sharedInstance;
    }
    return [plugin createIndicatorView:style];
}

@end
