//
//  TestToolbarController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestToolbarController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestToolbarController () <FWTableViewController, FWToolbarTitleViewDelegate, FWPopupMenuDelegate>

@property(nonatomic, strong) FWToolbarView *navigationView;
@property(nonatomic, strong) FWToolbarTitleView *titleView;
@property(nonatomic, assign) UIControlContentHorizontalAlignment horizontalAlignment;
@property(nonatomic, strong) FWToolbarView *toolbarView;

@end

@implementation TestToolbarController

- (void)didInitialize
{
    self.fw_navigationBarHidden = YES;
}

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStylePlain;
}

- (void)setupTableLayout
{
    self.navigationView = [[FWToolbarView alloc] initWithType:FWToolbarViewTypeNavBar];
    self.navigationView.menuView.tintColor = AppTheme.textColor;
    self.navigationView.backgroundColor = AppTheme.barColor;
    self.titleView = self.navigationView.menuView.titleView;
    self.titleView.showsLoadingView = YES;
    self.titleView.title = @"我是很长很长要多长有多长长得不得了的按钮";
    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
    self.navigationView.bottomHeight = FWNavigationBarHeight;
    self.navigationView.bottomHidden = YES;
    self.navigationView.bottomView.backgroundColor = UIColor.greenColor;
    FWWeakifySelf();
    self.navigationView.menuView.leftButton = [FWToolbarButton buttonWithObject:FWIcon.backImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (!self.shouldPopController) return;
        [self fw_closeViewControllerAnimated:YES];
    }];
    self.navigationView.menuView.rightButton = [FWToolbarButton buttonWithObject:FWIconImage(@"zmdi-var-refresh", 24) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (!self.shouldPopController) return;
        [self fw_closeViewControllerAnimated:YES];
    }];
    self.navigationView.menuView.rightMoreButton = [FWToolbarButton buttonWithObject:FWIconImage(@"zmdi-var-share", 24) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if (!self.shouldPopController) return;
        [self fw_closeViewControllerAnimated:YES];
    }];
    [self.view addSubview:self.navigationView];
    self.navigationView.fw_layoutChain.left().right().top();
    
    self.toolbarView = [[FWToolbarView alloc] init];
    self.toolbarView.tintColor = AppTheme.textColor;
    self.toolbarView.backgroundColor = AppTheme.barColor;
    self.toolbarView.topHeight = 44;
    self.toolbarView.topHidden = YES;
    self.toolbarView.topView.backgroundColor = UIColor.greenColor;
    self.toolbarView.menuView.leftButton = [FWToolbarButton buttonWithObject:@"取消" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.toolbarView setToolbarHidden:YES animated:YES];
        [self fw_showMessageWithText:@"点击了取消"];
    }];
    self.toolbarView.menuView.rightButton = [FWToolbarButton buttonWithObject:@"确定" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.toolbarView setToolbarHidden:YES animated:YES];
        [self fw_showMessageWithText:@"点击了确定"];
    }];
    [self.view addSubview:self.toolbarView];
    self.toolbarView.fw_layoutChain.left().right().bottom();
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 300)];
    self.tableView.fw_layoutChain.left().right().topToViewBottom(self.navigationView).bottomToViewTop(self.toolbarView);
}

- (void)setupSubviews
{
    [self.tableData addObjectsFromArray:@[
        @"显示左边的loading",
        @"显示右边的accessoryView",
        @"显示副标题",
        @"切换为上下两行显示",
        @"水平方向的对齐方式",
        @"模拟标题的loading状态切换",
        @"标题点击效果",
        
        @"导航栏顶部切换",
        @"导航栏菜单切换",
        @"导航栏底部切换",
        @"导航栏切换",
        
        @"工具栏顶部切换",
        @"工具栏菜单切换",
        @"工具栏底部切换",
        @"工具栏切换",
    ]];
}

- (BOOL)shouldPopController
{
    FWWeakifySelf();
    [self fw_showConfirmWithTitle:nil message:@"是否关闭" cancel:nil confirm:nil confirmBlock:^{
        FWStrongifySelf();
        [self fw_closeViewControllerAnimated:YES];
    }];
    return NO;
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.titleView.userInteractionEnabled = NO;
    self.titleView.delegate = nil;
    
    switch (indexPath.row) {
        case 0:
            self.titleView.loadingViewHidden = !self.titleView.loadingViewHidden;
            break;
        case 1: {
            self.titleView.accessoryImage = self.titleView.accessoryImage ? nil : FWIconImage(@"zmdi-var-caret-down", 24);
            break;
        }
        case 2:
            self.titleView.subtitle = self.titleView.subtitle ? nil : @"(副标题)";
            break;
        case 3:
            self.titleView.style = self.titleView.style == FWToolbarTitleViewStyleHorizontal ? FWToolbarTitleViewStyleVertical : FWToolbarTitleViewStyleHorizontal;
            self.titleView.subtitle = self.titleView.style == FWToolbarTitleViewStyleVertical ? @"(副标题)" : self.titleView.subtitle;
            break;
        case 4:
        {
            FWWeakifySelf();
            [self fw_showSheetWithTitle:@"水平对齐方式" message:nil cancel:@"取消" actions:@[@"左对齐", @"居中对齐", @"右对齐"] actionBlock:^(NSInteger index) {
                FWStrongifySelf();
                if (index == 0) {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                } else if (index == 1) {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                } else {
                    self.titleView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                    self.horizontalAlignment = self.titleView.contentHorizontalAlignment;
                    [self.tableView reloadData];
                }
            }];
        }
            break;
        case 5:
        {
            self.titleView.loadingViewHidden = NO;
            self.titleView.showsLoadingPlaceholder = NO;
            self.titleView.title = @"加载中...";
            self.titleView.subtitle = nil;
            self.titleView.style = FWToolbarTitleViewStyleHorizontal;
            self.titleView.accessoryImage = nil;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.titleView.showsLoadingPlaceholder = YES;
                self.titleView.loadingViewHidden = YES;
                self.titleView.title = @"主标题";
            });
        }
            break;
        case 6:
        {
            self.titleView.userInteractionEnabled = YES;
            self.titleView.title = @"点我展开分类";
            self.titleView.accessoryImage = FWIconImage(@"zmdi-var-caret-down", 24);
            self.titleView.delegate = self;
        }
            break;
        case 7:
        {
            [self.navigationView setTopHidden:!self.navigationView.topHidden animated:YES];
        }
            break;
        case 8:
        {
            [self.navigationView setMenuHidden:!self.navigationView.menuHidden animated:YES];
            break;
        }
        case 9:
        {
            [self.navigationView setBottomHidden:!self.navigationView.bottomHidden animated:YES];
            break;
        }
        case 10:
        {
            [self.navigationView setToolbarHidden:!self.navigationView.toolbarHidden animated:YES];
            break;
        }
        case 11:
        {
            [self.toolbarView setTopHidden:!self.toolbarView.topHidden animated:YES];
        }
            break;
        case 12:
        {
            [self.toolbarView setMenuHidden:!self.toolbarView.menuHidden animated:YES];
            break;
        }
        case 13:
        {
            [self.toolbarView setBottomHidden:!self.toolbarView.bottomHidden animated:YES];
            break;
        }
        case 14:
        {
            [self.toolbarView setToolbarHidden:!self.toolbarView.toolbarHidden animated:YES];
            break;
        }
            break;
    }
    
    [tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView style:UITableViewCellStyleValue1];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = self.titleView.loadingViewHidden ? @"显示左边的loading" : @"隐藏左边的loading";
            break;
        case 1:
            cell.textLabel.text = self.titleView.accessoryImage == nil ? @"显示右边的accessoryView" : @"去掉右边的accessoryView";
            break;
        case 2:
            cell.textLabel.text = self.titleView.subtitle ? @"去掉副标题" : @"显示副标题";
            break;
        case 3:
            cell.textLabel.text = self.titleView.style == FWToolbarTitleViewStyleHorizontal ? @"切换为上下两行显示" : @"切换为水平一行显示";
            break;
        case 4:
            cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = (self.horizontalAlignment == UIControlContentHorizontalAlignmentLeft ? @"左对齐" : (self.horizontalAlignment == UIControlContentHorizontalAlignmentRight ? @"右对齐" : @"居中对齐"));
            break;
        default:
            cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
            break;
    }
    return cell;
}

#pragma mark - FWToolbarTitleViewDelegate

- (void)didChangedActive:(BOOL)active forTitleView:(FWToolbarTitleView *)titleView {
    if (!active) return;
    
    [FWPopupMenu showRelyOnView:titleView titles:@[@"菜单1", @"菜单2"] icons:nil menuWidth:120 otherSettings:^(FWPopupMenu *popupMenu) {
        popupMenu.delegate = self;
    }];
}

#pragma mark - FWPopupMenuDelegate

- (void)popupMenuDidDismiss:(FWPopupMenu *)popupMenu {
    self.titleView.active = NO;
}

@end
