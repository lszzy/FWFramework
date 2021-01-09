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

@implementation SettingsViewController

- (void)renderModel
{
    FWWeakifySelf();
    [self fwObserveNotification:FWLanguageChangedNotification block:^(NSNotification * _Nonnull notification) {
        FWStrongifySelf();
        [self renderData];
    }];
}

- (void)renderData
{
    [self fwSetBarTitle:FWLocalizedString(@"settingTitle")];
    [self fwSetRightBarItem:FWLocalizedString(@"debugButton") block:^(id  _Nonnull sender) {
        if ([FWDebugManager sharedInstance].isHidden) {
            [[FWDebugManager sharedInstance] show];
        } else {
            [[FWDebugManager sharedInstance] hide];
        }
    }];
    
    [self.tableData removeAllObjects];
    if (FWModule(UserModuleService).isLogin) {
        [self.tableData addObject:@[FWLocalizedString(@"mediatorLogout"), @"onLogout"]];
        [self.tableData addObject:@[FWLocalizedString(@"loginInvalid"), @"onInvalid"]];
    } else {
        [self.tableData addObject:@[FWLocalizedString(@"mediatorLogin"), @"onLogin"]];
    }
    [self.tableData addObject:@[[NSString stringWithFormat:FWLocalizedString(@"languageTitle"), NSBundle.fwLocalizedLanguage, NSBundle.fwSystemLanguage, NSLocalizedString(@"确定", nil)], @"onLanguage"]];
    [self.tableView reloadData];
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    [self fwPerformSelector:NSSelectorFromString([rowData objectAtIndex:1])];
}

- (void)onLogin
{
    FWWeakifySelf();
    [FWModule(UserModuleService) login:^{
        FWStrongifySelf();
        [self.view fwShowMessageWithText:FWLocalizedString(@"loginSuccess")];
        [self renderData];
    }];
}

- (void)onLogout
{
    FWWeakifySelf();
    [FWModule(UserModuleService) logout:^{
        FWStrongifySelf();
        [self.view fwShowMessageWithText:FWLocalizedString(@"logoutSuccess")];
        [self renderData];
    }];
}

- (void)onInvalid
{
    FWWeakifySelf();
    [UIWindow.fwMainWindow fwPresentViewController:[ObjcController new] animated:YES completion:^{
        FWStrongifySelf();
        [UIWindow.fwMainWindow.fwTopPresentedController fwShowAlertWithTitle:FWLocalizedString(@"loginInvalid") message:nil cancel:FWLocalizedString(@"确定") cancelBlock:^{
            FWStrongifySelf();
            [UIWindow.fwMainWindow fwDismissViewControllers:^{
                FWStrongifySelf();
                [FWModule(UserModuleService) logout:^{
                    FWStrongifySelf();
                    [self renderData];
                    [self onLogin];
                }];
            }];
        }];
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

@end
