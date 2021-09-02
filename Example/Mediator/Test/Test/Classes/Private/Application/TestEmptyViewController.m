//
//  TestEmptyViewController.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestEmptyViewController.h"

@interface TestEmptyViewController () <FWTableViewController>

@end

@implementation TestEmptyViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderModel
{
    FWWeakifySelf();
    [self fwSetRightBarItem:FWIcon.refreshImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self fwHideEmptyView];
        [self.tableView reloadData];
    }];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fwView.fwHasEmptyView ? 0 : 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
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
        [self fwShowEmptyViewWithText:@"联系人为空"];
    } else if (row == 1) {
        [self fwShowEmptyViewWithText:@"联系人为空" detail:@"请到设置-隐私查看你的联系人权限设置"];
    } else if (row == 2) {
        [self fwShowEmptyViewWithText:@"暂无数据" detail:nil image:[UIImage fwImageWithAppIcon]];
    } else if (row == 3) {
        FWWeakifySelf();
        [self fwShowEmptyViewWithText:@"请求失败" detail:@"请检查网络连接" image:nil action:@"重试" block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self fwHideEmptyView];
            [self.tableView reloadData];
        }];
    } else if (row == 4) {
        [self fwShowEmptyViewLoading];
    } else if (row == 5) {
        FWWeakifySelf();
        [self fwShowEmptyViewWithText:@"请求失败" detail:@"请检查网络连接" image:[UIImage fwImageWithAppIcon] loading:YES action:@"重试" block:^(id  _Nonnull sender) {
            FWStrongifySelf();
            [self fwHideEmptyView];
            [self.tableView reloadData];
        }];
    }
    [self.tableView reloadData];
}

@end
