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

#pragma mark - UIView+FWViewPlugin

@implementation UIView (FWViewPlugin)

+ (UIView<FWProgressViewPlugin> *)fwProgressViewWithStyle:(FWProgressViewStyle)style
{
    id<FWViewPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWViewPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwProgressViewWithStyle:)]) {
        plugin = FWViewPluginImpl.sharedInstance;
    }
    return [plugin progressViewWithStyle:style];
}

+ (UIView<FWIndicatorViewPlugin> *)fwIndicatorViewWithStyle:(FWIndicatorViewStyle)style
{
    id<FWViewPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWViewPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwIndicatorViewWithStyle:)]) {
        plugin = FWViewPluginImpl.sharedInstance;
    }
    return [plugin indicatorViewWithStyle:style];
}

@end
