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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 100)];
    view.backgroundColor = Theme.cellColor;
    
    UILabel *label = [UILabel fwLabelWithFont:[UIFont fwFontOfSize:15] textColor:Theme.textColor text:@"我是Section头视图"];
    [view addSubview:label];
    label.fwLayoutChain.leftWithInset(15).centerY();
    return view;
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

- (void)fwShowEmptyView:(UIScrollView *)scrollView
{
    FWWeakifySelf();
    scrollView.fwOverlayView.backgroundColor = Theme.tableColor;
    [scrollView fwShowEmptyViewWithText:nil detail:nil image:nil action:nil block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        
        [self.tableData addObjectsFromArray:@[@1, @2, @3, @4, @5, @6, @7, @8]];
        [self.tableView reloadData];
    }];
}

@end