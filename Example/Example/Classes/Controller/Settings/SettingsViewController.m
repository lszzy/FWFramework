//
//  SettingsViewController.m
//  Example
//
//  Created by wuyong on 2020/4/26.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)renderView
{
    UIButton *button = [UIButton fwButtonWithFont:[UIFont appFontBoldNormal] titleColor:[UIColor appColorBlackOpacityHuge] title:@"present时登录失效"];
    [button fwAddTouchTarget:self action:@selector(onLogout)];
    [self.view addSubview:button];
    button.fwLayoutChain.center();
    
    UIButton *button2 = [UIButton fwButtonWithFont:[UIFont appFontBoldNormal] titleColor:[UIColor appColorBlackOpacityHuge] title:@"非present时登录失效"];
    [button2 fwAddTouchTarget:self action:@selector(onLogout2)];
    [self.view addSubview:button2];
    button2.fwLayoutChain.centerX().topToBottomOfViewWithOffset(button, 50);
    
    NSString *language = [NSString stringWithFormat:@"自定义:%@ 系统:%@ 示例：%@", NSBundle.fwLocalizedLanguage, NSBundle.fwSystemLanguage, NSLocalizedString(@"确定", nil)];
    UIButton *button3 = [UIButton fwButtonWithFont:[UIFont appFontBoldNormal] titleColor:[UIColor appColorBlackOpacityHuge] title:language];
    [button3 fwAddTouchTarget:self action:@selector(onLanguage)];
    [self.view addSubview:button3];
    button3.fwLayoutChain.centerX().topToBottomOfViewWithOffset(button2, 50);
}

- (void)onLogout
{
    [UIWindow.fwMainWindow fwPresentViewController:[ObjcController new] animated:YES completion:^{
        [UIWindow.fwMainWindow.fwTopPresentedController fwShowAlertWithTitle:@"点击登录失效" message:nil cancel:@"确定" cancelBlock:^{
            [UIWindow.fwMainWindow fwDismissViewControllers:^{
                [UIWindow.fwMainWindow.rootViewController fwShowAlertWithTitle:@"弹出登录界面" message:nil cancel:@"登录" cancelBlock:nil];
            }];
        }];
    }];
}

- (void)onLogout2
{
    [UIWindow.fwMainWindow fwDismissViewControllers:^{
        [UIWindow.fwMainWindow.rootViewController fwShowAlertWithTitle:@"弹出登录界面" message:nil cancel:@"登录" cancelBlock:nil];
    }];
}

- (void)onLanguage
{
    [self fwShowSheetWithTitle:@"选择语言" message:nil cancel:@"取消" actions:@[@"跟随系统", @"中文", @"英文"] actionBlock:^(NSInteger index) {
        NSString *language = nil;
        if (index == 1) {
            language = @"zh-Hans";
        } else if (index == 2) {
            language = @"en";
        }
        NSBundle.fwLocalizedLanguage = language;
        [AppRouter refreshController];
    }];
}

@end
