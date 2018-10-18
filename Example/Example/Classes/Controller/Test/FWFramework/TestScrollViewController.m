//
//  TestScrollViewController.m
//  Example
//
//  Created by wuyong on 2018/10/18.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestScrollViewController.h"

@interface TestScrollViewController ()

@property (nonatomic, assign) NSInteger index;

@end

@implementation TestScrollViewController

- (void)renderInit
{
    // 如果tableView占不满控制器，设置如下即可
    // self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
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

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = [self.dataList objectAtIndex:indexPath.row];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    self.index = indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
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
    return self.dataList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.dataList objectAtIndex:self.index];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self.dataList objectAtIndex:self.index];
}

@end
