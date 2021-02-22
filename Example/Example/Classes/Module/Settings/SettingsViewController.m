//
//  SettingsViewController.m
//  Example
//
//  Created by wuyong on 2020/4/26.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "SettingsViewController.h"
#import "TabBarController.h"
#if DEBUG
@import FWDebug;
#endif

@interface SettingsViewController () <FWTableViewController>

@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation SettingsViewController

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            FWThemeManager.sharedInstance.overrideWindow = YES;
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self renderData];
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderTableView
{
    self.tableView.backgroundColor = [Theme tableColor];
    
    UIView *footerView = [UIView new];
    footerView.frame = CGRectMake(0, 0, FWScreenWidth, 90);
    self.tableView.tableFooterView = footerView;
    
    UIButton *loginButton = [Theme largeButton];
    self.loginButton = loginButton;
    [loginButton fwAddTouchTarget:self action:@selector(onMediator)];
    [footerView addSubview:loginButton];
    loginButton.fwLayoutChain.center();
}

- (void)renderData
{
    [self fwSetBarTitle:FWLocalizedString(@"settingTitle")];
    
    #if DEBUG
    [self fwSetRightBarItem:FWLocalizedString(@"debugButton") block:^(id  _Nonnull sender) {
        if ([FWDebugManager sharedInstance].isHidden) {
            [[FWDebugManager sharedInstance] show];
        } else {
            [[FWDebugManager sharedInstance] hide];
        }
    }];
    #endif
    
    if (Mediator.userModule.isLogin) {
        [self.loginButton setTitle:FWLocalizedString(@"mediatorLogout") forState:UIControlStateNormal];
    } else {
        [self.loginButton setTitle:FWLocalizedString(@"mediatorLogin") forState:UIControlStateNormal];
    }
    
    [self.tableData removeAllObjects];
    [self.tableData addObject:@[FWLocalizedString(@"languageTitle"), @"onLanguage"]];
    [self.tableData addObject:@[FWLocalizedString(@"themeTitle"), @"onTheme"]];
    [self.tableData addObject:@[FWLocalizedString(@"rootTitle"), @"onRoot"]];
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView style:UITableViewCellStyleValue1];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    
    if ([@"onLanguage" isEqualToString:[rowData objectAtIndex:1]]) {
        NSString *language = FWLocalizedString(@"systemTitle");
        if (NSBundle.fwLocalizedLanguage.length > 0) {
            language = [NSBundle.fwLocalizedLanguage hasPrefix:@"zh"] ? @"中文" : @"English";
        }
        cell.detailTextLabel.text = language;
    } else if ([@"onTheme" isEqualToString:[rowData objectAtIndex:1]]) {
        FWThemeMode mode = FWThemeManager.sharedInstance.mode;
        NSString *theme = (mode == FWThemeModeSystem) ? FWLocalizedString(@"systemTitle") : (mode == FWThemeModeDark ? FWLocalizedString(@"themeDark") : FWLocalizedString(@"themeLight"));
        cell.detailTextLabel.text = theme;
    } else if ([@"onRoot" isEqualToString:[rowData objectAtIndex:1]]) {
        NSString *root;
        if (AppConfig.isRootNavigation) {
            root = AppConfig.isRootCustom ? @"Navigation+FWTabBar" : @"Navigation+UITabBar";
        } else {
            root = AppConfig.isRootCustom ? @"FWTabBar+Navigation" : @"UITabBar+Navigation";
        }
        cell.detailTextLabel.text = root;
    } else {
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    [self fwPerformSelector:NSSelectorFromString([rowData objectAtIndex:1])];
}

#pragma mark - Action

- (void)onMediator
{
    if ([Mediator.userModule isLogin]) {
        [self onLogout];
    } else {
        [self onLogin];
    }
}

- (void)onLogin
{
    FWWeakifySelf();
    [Mediator.userModule login:^{
        FWStrongifySelf();
        [self renderData];
    }];
}

- (void)onLogout
{
    FWWeakifySelf();
    [self fwShowConfirmWithTitle:FWLocalizedString(@"logoutConfirm") message:nil cancel:FWLocalizedString(@"取消") confirm:FWLocalizedString(@"确定") confirmBlock:^{
        FWStrongifySelf();
        [Mediator.userModule logout:^{
            FWStrongifySelf();
            [self renderData];
        }];
    }];
}

- (void)onLanguage
{
    FWWeakifySelf();
    [self fwShowSheetWithTitle:FWLocalizedString(@"languageTitle") message:nil cancel:FWLocalizedString(@"取消") actions:@[FWLocalizedString(@"systemTitle"), @"中文", @"English", FWLocalizedString(@"changeTitle")] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index < 3) {
            NSString *language = (index == 1) ? @"zh-Hans" : (index == 2 ? @"en" : nil);
            NSBundle.fwLocalizedLanguage = language;
            [UITabBarController refreshController];
        } else {
            NSString *localized = NSBundle.fwLocalizedLanguage;
            NSString *language = (!localized) ? @"zh-Hans" : ([localized hasPrefix:@"zh"] ? @"en" : nil);
            NSBundle.fwLocalizedLanguage = language;
            [self renderData];
        }
    }];
}

- (void)onTheme
{
    [self fwShowSheetWithTitle:FWLocalizedString(@"themeTitle") message:nil cancel:FWLocalizedString(@"取消") actions:@[FWLocalizedString(@"systemTitle"), FWLocalizedString(@"themeLight"), FWLocalizedString(@"themeDark"), FWLocalizedString(@"changeTitle")] actionBlock:^(NSInteger index) {
        FWThemeMode mode = index;
        if (index > 2) {
            FWThemeMode currentMode = FWThemeManager.sharedInstance.mode;
            mode = (currentMode == FWThemeModeSystem) ? FWThemeModeLight : (currentMode == FWThemeModeLight ? FWThemeModeDark : FWThemeModeSystem);
        }
        FWThemeManager.sharedInstance.mode = mode;
        [UITabBarController refreshController];
    }];
}

- (void)onRoot
{
    [self fwShowSheetWithTitle:FWLocalizedString(@"rootTitle") message:nil cancel:FWLocalizedString(@"取消") actions:@[@"UITabBar+Navigation", @"FWTabBar+Navigation", @"Navigation+UITabBar", @"Navigation+FWTabBar"] actionBlock:^(NSInteger index) {
        switch (index) {
            case 1:
                AppConfig.isRootNavigation = NO;
                AppConfig.isRootCustom = YES;
                break;
            case 2:
                AppConfig.isRootNavigation = YES;
                AppConfig.isRootCustom = NO;
                break;
            case 3:
                AppConfig.isRootNavigation = YES;
                AppConfig.isRootCustom = YES;
                break;
            default:
                AppConfig.isRootNavigation = NO;
                AppConfig.isRootCustom = NO;
                break;
        }
        [UITabBarController refreshController];
    }];
}

@end
