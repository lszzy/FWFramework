//
//  TestPluginController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestPluginController.h"
#import "AppSwift.h"
@import FWFramework;
@import Lottie;

@interface TestPluginController () <FWTableViewController>

@end

@implementation TestPluginController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableView
{
    [self.tableData addObject:@[@0, @1]];
    [self.tableData addObject:@[@0, @1, @2, @3, @4, @5, @6]];
    [self.tableData addObject:@[@0]];
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
    NSInteger rowData = [sectionData[indexPath.row] fw_safeInteger];
    if (indexPath.section == 0) {
        UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell1"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        FWProgressView *view = [cell viewWithTag:100];
        if (!view) {
            view = [[FWProgressView alloc] init];
            view.tag = 100;
            view.color = AppTheme.textColor;
            [cell.contentView addSubview:view];
            view.fw_layoutChain.center();
        }
        view.annular = rowData == 0 ? YES : NO;
        [TestController mockProgress:^(double progress, BOOL finished) {
            view.progress = progress;
        }];
        return cell;
    }
    
    if (indexPath.section == 2) {
        UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell3"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        FWLottieView *view = [cell viewWithTag:100];
        if (!view) {
            view = [[FWLottieView alloc] init];
            [view setAnimationWithName:@"Lottie" bundle:nil];
            view.tag = 100;
            view.color = AppTheme.textColor;
            [cell.contentView addSubview:view];
            view.fw_layoutChain.center();
        }
        [view startAnimating];
        return cell;
    }
    
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView style:UITableViewCellStyleDefault reuseIdentifier:@"cell2"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    FWIndicatorView *view = [cell viewWithTag:100];
    if (!view) {
        view = [[FWIndicatorView alloc] init];
        view.tag = 100;
        view.color = AppTheme.textColor;
        [cell.contentView addSubview:view];
        view.fw_layoutChain.center();
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
    [self fw_showAlertWithTitle:@"请选择" message:nil style:FWAlertStyleDefault cancel:nil actions:@[@"预览", @"设置全局样式"] actionBlock:^(NSInteger index) {
        FWStrongifySelf();
        if (index == 0) {
            [self onPreview:indexPath];
        } else {
            [self onSettings:indexPath];
        }
    } cancelBlock:nil];
}

#pragma mark - Action

- (void)onPreview:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        FWProgressView *view = [cell viewWithTag:100];
        [TestController mockProgress:^(double progress, BOOL finished) {
            view.progress = progress;
        }];
        return;
    }
    
    if (indexPath.section == 2) {
        FWToastPluginImpl *toastPlugin = [[FWToastPluginImpl alloc] init];
        toastPlugin.customBlock = ^(FWToastView * _Nonnull toastView) {
            FWLottieView *view = [[FWLottieView alloc] init];
            [view setAnimationWithName:@"Lottie" bundle:nil];
            toastView.indicatorView = view;
        };
        self.tableView.hidden = YES;
        [toastPlugin showLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Loading..."] cancelBlock:nil inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toastPlugin showLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Authenticating..."] cancelBlock:nil inView:self.view];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toastPlugin hideLoading:self.view];
            self.tableView.hidden = NO;
        });
        return;
    }
    
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    FWIndicatorViewAnimationType type = [sectionData[indexPath.row] fw_safeInteger];
    FWToastPluginImpl *toastPlugin = [[FWToastPluginImpl alloc] init];
    toastPlugin.customBlock = ^(FWToastView * _Nonnull toastView) {
        toastView.indicatorView = [[FWIndicatorView alloc] initWithType:type];
    };
    self.tableView.hidden = YES;
    [toastPlugin showLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Loading..."] cancelBlock:nil inView:self.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toastPlugin showLoadingWithAttributedText:[[NSAttributedString alloc] initWithString:@"Authenticating..."] cancelBlock:nil inView:self.view];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toastPlugin hideLoading:self.view];
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
        FWRefreshPluginImpl.sharedInstance.pullRefreshBlock = nil;
        FWRefreshPluginImpl.sharedInstance.infiniteScrollBlock = nil;
        return;
    }
    
    if (indexPath.section == 2) {
        FWViewPluginImpl.sharedInstance.customIndicatorView = ^UIView<FWIndicatorViewPlugin> * _Nonnull(FWIndicatorViewStyle style) {
            FWLottieView *lottieView = [[FWLottieView alloc] init];
            [lottieView setAnimationWithName:@"Lottie" bundle:nil];
            return lottieView;
        };
        // FWLottieView也支持进度显示
        FWViewPluginImpl.sharedInstance.customProgressView = ^UIView<FWProgressViewPlugin> * _Nonnull(FWProgressViewStyle style) {
            FWLottieView *lottieView = [[FWLottieView alloc] init];
            [lottieView setAnimationWithName:@"Lottie" bundle:nil];
            lottieView.hidesWhenStopped = NO;
            return lottieView;
        };
        // FWLottieView支持下拉进度显示
        FWRefreshPluginImpl.sharedInstance.pullRefreshBlock = ^(FWPullRefreshView * _Nonnull pullRefreshView) {
            FWLottieView *lottieView = [[FWLottieView alloc] initWithFrame:CGRectMake(0, 0, 54, 54)];
            lottieView.contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
            [lottieView setAnimationWithName:@"Lottie" bundle:nil];
            lottieView.hidesWhenStopped = NO;
            [pullRefreshView setAnimationView:lottieView];
        };
        FWRefreshPluginImpl.sharedInstance.infiniteScrollBlock = ^(FWInfiniteScrollView * _Nonnull infiniteScrollView) {
            FWLottieView *lottieView = [[FWLottieView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
            [lottieView setAnimationWithName:@"Lottie" bundle:nil];
            lottieView.hidesWhenStopped = NO;
            [infiniteScrollView setAnimationView:lottieView];
        };
        return;
    }
    
    NSArray *sectionData = [self.tableData objectAtIndex:indexPath.section];
    FWIndicatorViewAnimationType type = [sectionData[indexPath.row] fw_safeInteger];
    FWViewPluginImpl.sharedInstance.customIndicatorView = ^UIView<FWIndicatorViewPlugin> * _Nonnull(FWIndicatorViewStyle style) {
        return [[FWIndicatorView alloc] initWithType:type];
    };
    // FWIndicatorView也支持进度显示
    FWViewPluginImpl.sharedInstance.customProgressView = ^UIView<FWProgressViewPlugin> * _Nonnull(FWProgressViewStyle style) {
        FWIndicatorView *indicatorView = [[FWIndicatorView alloc] initWithType:type];
        indicatorView.hidesWhenStopped = NO;
        return indicatorView;
    };
    FWRefreshPluginImpl.sharedInstance.pullRefreshBlock = nil;
    FWRefreshPluginImpl.sharedInstance.infiniteScrollBlock = nil;
}

@end
