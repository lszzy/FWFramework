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

@end
