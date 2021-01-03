//
//  SettingsViewController.m
//  Example
//
//  Created by wuyong on 2020/4/26.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "SettingsViewController.h"
#import <FWDebug/FWDebug.h>
#import <Mediator/Mediator-Swift.h>

@interface SettingsViewController ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIImageView *screenView;
@property (nonatomic, strong) UILabel *screenLabel;

@end

@implementation SettingsViewController

- (void)renderView
{
    UIButton *moduleButton = [UIButton fwButtonWithFont:[UIFont appFontBoldNormal] titleColor:[UIColor appColorBlackOpacityHuge] title:FWLocalizedString(@"mediatorButton")];
    [moduleButton fwAddTouchTarget:self action:@selector(onMediator)];
    [self.view addSubview:moduleButton];
    moduleButton.fwLayoutChain.centerX().centerYWithOffset(-80);
    
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
    
    UIButton *button4 = [UIButton fwButtonWithFont:[UIFont appFontBoldNormal] titleColor:[UIColor appColorBlackOpacityHuge] title:@"开始截屏"];
    [button4 fwAddTouchTarget:self action:@selector(onScreenButton:)];
    [self.view addSubview:button4];
    button4.fwLayoutChain.centerX().topToBottomOfViewWithOffset(button3, 50);
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwObserveNotification:FWLocalizedLanguageChangedNotification block:^(NSNotification * _Nonnull notification) {
        FWStrongifySelf();
        [self.view fwRemoveAllSubviews];
        [self renderView];
    }];
}

- (void)onMediator
{
    FWWeakifySelf();
    [FWModule(UserModuleService) login:^{
        FWStrongifySelf();
        
        [self.view fwShowMessageWithText:@"登录成功"];
    }];
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
    [self fwShowSheetWithTitle:@"选择语言" message:nil cancel:@"取消" actions:@[@"跟随系统", @"中文", @"English", @"不刷新根控制器"] actionBlock:^(NSInteger index) {
        if (index < 3) {
            NSString *language = nil;
            if (index == 1) {
                language = @"zh-Hans";
            } else if (index == 2) {
                language = @"en";
            }
            NSBundle.fwLocalizedLanguage = language;
            [AppRouter refreshController];
        } else {
            // 只需要处理当前导航栈页面和其它Tab根页面控制器
            NSString *language = NSBundle.fwLocalizedLanguage;
            NSString *newLanguage = nil;
            if (language == nil) {
                newLanguage = @"zh-Hans";
            } else if ([language isEqualToString:@"zh-Hans"]) {
                newLanguage = @"en";
            } else {
                newLanguage = nil;
            }
            NSBundle.fwLocalizedLanguage = newLanguage;
        }
    }];
}

- (void)onScreenButton:(UIButton *)sender
{
    if ([@"开始截屏" isEqualToString:[sender titleForState:UIControlStateNormal]]) {
        [sender setTitle:@"停止截屏" forState:UIControlStateNormal];
        
        self.screenView = [UIImageView new];
        self.screenView.backgroundColor = [UIColor whiteColor];
        [self.screenView fwSetBorderColor:[UIColor appColorBorder] width:0.5 cornerRadius:5];
        [[UIWindow fwMainWindow] addSubview:self.screenView];
        self.screenView.fwLayoutChain.rightWithInset(10).bottomWithInset(FWBottomBarHeight + 10).size(CGSizeMake(100, 100.0 / FWScreenWidth * FWScreenHeight));
        
        UILabel *screenLabel = [UILabel fwLabelWithFont:[UIFont appFontTiny] textColor:[UIColor redColor] text:@"0"];
        self.screenLabel = screenLabel;
        [self.screenView addSubview:screenLabel];
        screenLabel.fwLayoutChain.rightWithInset(5).bottomWithInset(5);
        
        if ([FWDebugManager sharedInstance].isHidden) {
            [[FWDebugManager sharedInstance] show];
        }
        
        static NSTimeInterval screenTime = 0;
        static NSInteger screenCount = 0;
        
        FWWeakifySelf();
        self.displayLink = [CADisplayLink fwCommonDisplayLinkWithBlock:^(CADisplayLink * _Nonnull displayLink) {
            FWStrongifySelf();
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [self onScreenShot];
                if (image != nil) {
                    NSInteger timeCount = 0;
                    if (NSDate.date.timeIntervalSince1970 - screenTime >= 1.0) {
                        timeCount = screenCount;
                        screenTime = NSDate.date.timeIntervalSince1970;
                        screenCount = 0;
                    }
                    
                    screenCount++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.screenView.image = image;
                        if (timeCount > 0) {
                            self.screenLabel.text = [NSString stringWithFormat:@"%@", @(timeCount)];
                        }
                    });
                }
            });
        }];
    } else {
        [sender setTitle:@"开始截屏" forState:UIControlStateNormal];
        
        [self.displayLink invalidate];
        self.displayLink = nil;
        
        [self.screenView removeFromSuperview];
        self.screenView = nil;
    }
}

- (UIImage *)onScreenShot
{
    // 1秒钟截屏次数
    static NSTimeInterval lastTime = 0;
    NSTimeInterval screenCountPerSecond = 8;
    if (lastTime > 0 && (NSDate.date.timeIntervalSince1970 - lastTime) < (1.0 / screenCountPerSecond)) { return nil; }
    lastTime = NSDate.date.timeIntervalSince1970;
    
    static UIImage *lastImage = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取window和bounds需要主线程调用
        UIWindow *window = UIWindow.fwMainWindow;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(FWScreenWidth, FWScreenHeight), NO, 0);
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
        lastImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return lastImage;
}

@end
