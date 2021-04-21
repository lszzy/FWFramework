//
//  TestEmptyScrollViewController.m
//  Example
//
//  Created by wuyong on 2020/9/3.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestEmptyScrollViewController.h"

@interface TestEmptyScrollViewController () <FWTableViewController, FWEmptyViewDelegate>

@end

@implementation TestEmptyScrollViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderView
{
    self.tableView.backgroundColor = Theme.tableColor;
    self.tableView.fwEmptyViewDelegate = self;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    cell.textLabel.textColor = Theme.textColor;
    cell.textLabel.text = FWSafeString([self.tableData fwObjectAtIndex:indexPath.row]);
    return cell;
}

#pragma mark - FWEmptyViewDelegate

- (void)fwShowEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView
{
    FWWeakifySelf();
    [contentView fwShowEmptyViewWithText:@"暂无数据" detail:nil image:nil action:@"重新加载" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        [self.tableData addObjectsFromArray:@[@1, @2, @3, @4, @5, @6, @7, @8]];
        [self.tableView reloadData];
    }];
}

@end
