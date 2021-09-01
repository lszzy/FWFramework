//
//  TestViewPluginViewController.m
//  Example
//
//  Created by wuyong on 2019/4/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestViewPluginViewController.h"

@interface TestViewPluginViewController () <FWTableViewController>

@end

@implementation TestViewPluginViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    [self.tableData addObject:@[@0, @1]];
    [self.tableData addObject:@[@0, @1, @2, @3, @4, @5, @6]];
    [self.tableView reloadData];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = [self.tableData objectAtIndex:section];
    return sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    NSInteger rowData = [sectionData[indexPath.row] fwAsInteger];
    if (indexPath.section == 0) {
        UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell1"];
        FWProgressView *view = [cell viewWithTag:100];
        if (!view) {
            view = [[FWProgressView alloc] init];
            view.tag = 100;
            view.color = Theme.textColor;
            [cell.contentView addSubview:view];
            view.fwLayoutChain.center();
        }
        view.annular = rowData == 0 ? YES : NO;
        [self mockProgress:view];
        return cell;
    }
    
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell2"];
    FWIndicatorView *view = [cell viewWithTag:100];
    if (!view) {
        view = [[FWIndicatorView alloc] init];
        view.tag = 100;
        view.color = Theme.textColor;
        [cell.contentView addSubview:view];
        view.fwLayoutChain.center();
    }
    view.type = (FWIndicatorViewAnimationType)rowData;
    [view startAnimating];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        FWProgressView *view = [cell viewWithTag:100];
        [self mockProgress:view];
    } else {
        FWIndicatorView *view = [cell viewWithTag:100];
        if ([view isAnimating]) {
            [view stopAnimating];
        } else {
            [view startAnimating];
        }
    }
}

#pragma mark - Action

- (void)mockProgress:(FWProgressView *)progressView
{
    progressView.progress = 0;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self runProgress:progressView];
        dispatch_async(dispatch_get_main_queue(), ^{
            progressView.progress = 1;
        });
    });
}

- (void)runProgress:(FWProgressView *)progressView
{
    double progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            progressView.progress = progress;
        });
        usleep(finish ? 2000000 : 50000);
    }
}

@end
