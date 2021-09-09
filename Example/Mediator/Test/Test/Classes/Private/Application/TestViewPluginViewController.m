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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        FWProgressView *view = [cell viewWithTag:100];
        if (!view) {
            view = [[FWProgressView alloc] init];
            view.tag = 100;
            view.color = Theme.textColor;
            [cell.contentView addSubview:view];
            view.fwLayoutChain.center();
        }
        view.annular = rowData == 0 ? YES : NO;
        [self mockProgress:^(double progress, BOOL finished) {
            view.progress = progress;
        }];
        return cell;
    }
    
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell2"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    FWWeakifySelf();
    [self fwShowAlertWithTitle:@"请选择" message:nil cancel:nil actions:@[@"预览", @"设置全局样式"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            [self onPreview:indexPath];
        } else {
            [self onSettings:indexPath];
        }
    } cancelBlock:nil priority:FWAlertPriorityNormal];
}

#pragma mark - Action

- (void)onPreview:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        FWProgressView *view = [cell viewWithTag:100];
        [self mockProgress:^(double progress, BOOL finished) {
            view.progress = progress;
        }];
        return;
    }
    
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    FWIndicatorViewAnimationType type = [sectionData[indexPath.row] fwAsInteger];
    FWToastPluginImpl *toastPlugin = [[FWToastPluginImpl alloc] init];
    toastPlugin.customBlock = ^(FWToastView * _Nonnull toastView) {
        toastView.indicatorView = [[FWIndicatorView alloc] initWithType:type];
    };
    self.tableView.hidden = YES;
    [toastPlugin fwShowLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Loading..."] inView:self.fwView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toastPlugin fwShowLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Authenticating..."] inView:self.fwView];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toastPlugin fwHideLoading:self.fwView];
        self.tableView.hidden = NO;
    });
}

- (void)onSettings:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        BOOL annular = indexPath.row == 0;
        FWViewPluginImpl.sharedInstance.customProgressView = ^UIView<FWProgressViewPlugin> * _Nonnull(FWProgressViewStyle style) {
            FWProgressView *progressView = [[FWProgressView alloc] init];
            progressView.annular = annular;
            return progressView;
        };
        return;
    }
    
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    FWIndicatorViewAnimationType type = [sectionData[indexPath.row] fwAsInteger];
    FWViewPluginImpl.sharedInstance.customIndicatorView = ^UIView<FWIndicatorViewPlugin> * _Nonnull(FWIndicatorViewStyle style) {
        return [[FWIndicatorView alloc] initWithType:type];
    };
    // FWIndicatorView也支持进度显示
    FWViewPluginImpl.sharedInstance.customProgressView = ^UIView<FWProgressViewPlugin> * _Nonnull(FWProgressViewStyle style) {
        FWIndicatorView *indicatorView = [[FWIndicatorView alloc] initWithType:type];
        indicatorView.hidesWhenStopped = NO;
        return indicatorView;
    };
}

@end
