//
//  FWAppConfig.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAppConfig.h"

@implementation FWAppConfigDefaultTemplate

- (void)applyConfiguration {
    // 启用全局导航栏返回拦截
    // [UINavigationController.fw enablePopProxy];
    // 启用全局导航栏转场优化
    // [UINavigationController.fw enableBarTransition];
    
    // 设置默认导航栏样式
    // FWNavigationBarAppearance *defaultAppearance = [FWNavigationBarAppearance new];
    // defaultAppearance.foregroundColor = [UIColor fw_colorWithHex:0x111111];
    // 1. 指定导航栏背景色
    // defaultAppearance.backgroundColor = UIColor.whiteColor;
    // 2. 设置导航栏样式全透明
    // defaultAppearance.backgroundTransparent = YES;
    // defaultAppearance.shadowColor = nil;
    // [FWNavigationBarAppearance setAppearance:defaultAppearance forStyle:FWNavigationBarStyleDefault];
    
    // 兼容iOS15 UITableView样式
    // if (@available(iOS 15.0, *)) {
    //    UITableView.appearance.sectionHeaderTopPadding = 0;
    // }
    
    // 配置弹窗插件及默认文案
    // [__FWPluginManager registerPlugin:@protocol(FWAlertPlugin) withObject:[FWAlertControllerPlugin class]];
    // FWAlertPluginImpl.sharedInstance.defaultCloseButton = nil;
    // FWAlertPluginImpl.sharedInstance.defaultCancelButton = nil;
    // FWAlertPluginImpl.sharedInstance.defaultConfirmButton = nil;
    
    // 配置空界面插件默认文案
    // FWEmptyPluginImpl.sharedInstance.defaultText = nil;
    // FWEmptyPluginImpl.sharedInstance.defaultDetail = nil;
    // FWEmptyPluginImpl.sharedInstance.defaultImage = nil;
    // FWEmptyPluginImpl.sharedInstance.defaultAction = nil;
    
    // 配置图片选择、浏览和下拉刷新插件
    // [__FWPluginManager registerPlugin:@protocol(FWImagePickerPlugin) withObject:[FWImagePickerControllerImpl class]];
    // [__FWPluginManager registerPlugin:@protocol(FWImagePreviewPlugin) withObject:[FWImagePreviewPluginImpl class]];
    // [__FWPluginManager registerPlugin:@protocol(FWRefreshPlugin) withObject:[FWRefreshPluginImpl class]];
    
    // 配置吐司插件
    // __FWToastPluginImpl.sharedInstance.delayTime = 2.0;
    // __FWToastPluginImpl.sharedInstance.defaultLoadingText = nil;
    // __FWToastPluginImpl.sharedInstance.defaultProgressText = nil;
    // __FWToastPluginImpl.sharedInstance.defaultMessageText = nil;
    
    // 配置进度视图和指示器视图插件
    // __FWViewPluginImpl.sharedInstance.customIndicatorView = nil;
    // __FWViewPluginImpl.sharedInstance.customProgressView = nil;
}

@end
