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

#pragma mark - FWViewPluginManager

@implementation FWViewPluginManager

+ (FWViewPluginManager *)sharedInstance
{
    static FWViewPluginManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWViewPluginManager alloc] init];
    });
    return instance;
}

- (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style
{
    if (self.progressViewCreator) {
        return self.progressViewCreator(style);
    }
    
    FWProgressView *progressView = [[FWProgressView alloc] init];
    return progressView;
}

- (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style
{
    if (self.indicatorViewCreator) {
        return self.indicatorViewCreator(style);
    }
    
    UIActivityIndicatorViewStyle indicatorStyle;
    if (@available(iOS 13.0, *)) {
        indicatorStyle = UIActivityIndicatorViewStyleMedium;
    } else {
        indicatorStyle = (style == FWIndicatorViewStyleGray) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    indicatorView.color = (style == FWIndicatorViewStyleGray) ? UIColor.grayColor : UIColor.whiteColor;
    indicatorView.hidesWhenStopped = YES;
    return indicatorView;
}

@end
