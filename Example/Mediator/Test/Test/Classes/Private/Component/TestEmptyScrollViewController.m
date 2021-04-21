//
//  TestEmptyScrollViewController.m
//  Example
//
//  Created by wuyong on 2020/9/3.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

#import "TestEmptyScrollViewController.h"

@interface TestEmptyScrollViewController () <FWTableViewController, FWEmptyViewDataSource, FWEmptyViewDelegate>

@end

@implementation TestEmptyScrollViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderView
{
    self.tableView.backgroundColor = Theme.tableColor;
    self.tableView.fwEmptyViewDataSource = self;
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
    return cell;
}

#pragma mark - FWEmptyViewDataSource

- (void)fwShowEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView
{
    FWWeakifySelf();
    contentView.backgroundColor = Theme.backgroundColor;
    [contentView fwShowEmptyViewWithText:@"暂无数据" detail:nil image:nil action:@"重新加载" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        [self.tableData setArray:@[@1]];
        [self.tableView reloadData];
    }];
}

@end
