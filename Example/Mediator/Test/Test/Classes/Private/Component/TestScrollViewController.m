//
//  TestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/10/18.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestScrollViewController.h"

@interface TestScrollViewController () <FWTableViewController>

@property (nonatomic, assign) NSInteger index;

@end

@implementation TestScrollViewController

- (void)renderInit
{
    // 如果tableView占不满控制器，设置如下即可
    // self.automaticallyAdjustsScrollViewInsets = NO;
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderView
{
    self.view.backgroundColor = [Theme tableColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @"默认Header悬停(Plain)",
                                         @"Header不悬停(Plain)",
                                         @"默认Footer悬停(Plain)",
                                         @"Footer不悬停(Plain)",
                                         @"Header+Footer不悬停(Plain)",
                                         ]];
    [self.tableView reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.index == 0) {
        [self.tableView fwFollowWithHeader:0 footer:0];
    } else if (self.index == 1) {
        [self.tableView fwFollowWithHeader:50 footer:0];
    } else if (self.index == 2) {
        [self.tableView fwFollowWithHeader:0 footer:0];
    } else if (self.index == 3) {
        [self.tableView fwFollowWithHeader:0 footer:50];
    } else if (self.index == 4) {
        [self.tableView fwFollowWithHeader:50 footer:50];
    }
}

#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
    cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    
    if (indexPath.section % 2 == 0) {
        cell.fwBackgroundView.contentView.backgroundColor = [Theme cellColor];
        cell.fwBackgroundView.contentView.layer.cornerRadius = 10;
        [cell.fwBackgroundView.contentView fwSetShadowColor:[UIColor grayColor] offset:CGSizeMake(0, 0) radius:10];
        cell.fwBackgroundView.contentInset = UIEdgeInsetsMake(15, 15, 15, 15);
    } else {
        cell.fwBackgroundView.contentView.backgroundColor = [Theme cellColor];
        cell.fwBackgroundView.contentView.layer.cornerRadius = 10;
        [cell.fwBackgroundView.contentView fwSetShadowColor:[UIColor grayColor] offset:CGSizeMake(0, 0) radius:10];
        [cell.fwBackgroundView setSectionContentInset:UIEdgeInsetsMake(15, 15, 15, 15) tableView:self.tableView atIndexPath:indexPath];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.index = indexPath.row;
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.tableData objectAtIndex:self.index];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self.tableData objectAtIndex:self.index];
}

@end
