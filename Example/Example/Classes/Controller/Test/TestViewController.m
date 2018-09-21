/*!
 @header     TestViewController.m
 @indexgroup Example
 @brief      TestViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/21
 */

#import "TestViewController.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
                                       @[@"FWFramework", @[
                                             @[@"UIView(FWBadge)", @"TestBadgeViewController"],
                                             @[@"UITableView(FWTemplateLayout)", @"TestTableLayoutViewController"],
                                             ]],
                                       @[@"FWApplication", @[
                                             @[@"UIView+FWIndicator", @"TestIndicatorViewController"],
                                             ]],
                                       ]];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"测试";
}

#pragma mark - TableView

- (UITableView *)renderTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    return tableView;
}

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.dataList objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.dataList objectAtIndex:indexPath.section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    NSArray *rowData = [sectionList objectAtIndex:indexPath.row];
    
    NSString *vcStr = [rowData objectAtIndex:1];
    Class vcClass = NSClassFromString(vcStr);
    UIViewController *vc = [[vcClass alloc] init];
    vc.title = [rowData objectAtIndex:0];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [self.dataList objectAtIndex:section];
    NSArray *sectionList = [sectionData objectAtIndex:1];
    return sectionList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sectionData = [self.dataList objectAtIndex:section];
    NSString *sectionName = [sectionData objectAtIndex:0];
    return sectionName;
}

@end
