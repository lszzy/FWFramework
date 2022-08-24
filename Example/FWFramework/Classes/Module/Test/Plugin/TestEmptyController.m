//
//  TestEmptyController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestEmptyController.h"
@import FWFramework;

@interface TestEmptyController () <FWTableViewController>

@end

@implementation TestEmptyController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupNavbar
{
    FWWeakifySelf();
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fw_hideEmptyView];
        [self.tableView reloadData];
    }];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.view.fw_hasEmptyView ? 0 : 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
    NSInteger row = indexPath.row;
    if (row == 0) {
        cell.textLabel.text = @"显示提示语";
    } else if (row == 1) {
        cell.textLabel.text = @"显示提示语和详情";
    } else if (row == 2) {
        cell.textLabel.text = @"显示图片和提示语";
    } else if (row == 3) {
        cell.textLabel.text = @"显示提示语及操作按钮";
    } else if (row == 4) {
        cell.textLabel.text = @"显示加载视图";
    } else if (row == 5) {
        cell.textLabel.text = @"显示所有视图";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;
    if (row == 0) {
        [self fw_showEmptyViewWithText:@"联系人为空"];
    } else if (row == 1) {
        [self fw_showEmptyViewWithText:@"联系人为空" detail:@"请到设置-隐私查看你的联系人权限设置"];
    } else if (row == 2) {
        [self fw_showEmptyViewWithText:@"暂无数据" detail:nil image:[UIImage fw_appIconImage]];
    } else if (row == 3) {
        FWWeakifySelf();
        [self fw_showEmptyViewWithText:@"请求失败" detail:@"请检查网络连接" image:nil action:@"重试" block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self fw_hideEmptyView];
            [self.tableView reloadData];
        }];
    } else if (row == 4) {
        [self fw_showEmptyViewLoading];
    } else if (row == 5) {
        FWWeakifySelf();
        [self fw_showEmptyViewWithText:@"请求失败" detail:@"请检查网络连接" image:[UIImage fw_appIconImage] loading:YES actions:@[@"取消", @"重试"] block:^(NSInteger index, id  _Nonnull sender) {
            FWStrongifySelf();
            if (index == 0) {
                [self fw_showEmptyViewWithText:@"请求失败" detail:@"请检查网络连接" image:[UIImage fw_appIconImage] loading:YES actions:nil block:nil];
            } else {
                [self fw_hideEmptyView];
                [self.tableView reloadData];
            }
        }];
    }
    [self.tableView reloadData];
}

@end
