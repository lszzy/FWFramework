//
//  TestToastController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestToastController.h"
#import "AppSwift.h"
@import FWFramework;

@interface TestToastController () <FWTableViewController>

@end

@implementation TestToastController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupSubviews
{
    [self.tableData addObjectsFromArray:@[
        @[@"无文本", @"onIndicator"],
        @[@"有文本(可取消)", @"onIndicator2"],
        @[@"文本太长", @"onIndicator3"],
        @[@"加载动画", @"onLoading"],
        @[@"进度动画(可取消)", @"onProgress"],
        @[@"加载动画(window)", @"onLoadingWindow"],
        @[@"加载进度动画(window)", @"onProgressWindow"],
        @[@"单行吐司(可点击)", @"onToast"],
        @[@"多行吐司(默认不可点击)", @"onToast2"],
    ]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

- (void)onIndicator
{
    [self fw_showLoadingWithText:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fw_hideLoading];
    });
}

- (void)onIndicator2
{
    static BOOL isCancelled = NO;
    FWWeakifySelf();
    isCancelled = NO;
    [self fw_showLoadingWithText:nil cancelBlock:^{
        isCancelled = YES;
        FWStrongifySelf();
        [self fw_showMessageWithText:@"已取消"];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (isCancelled) return;
        FWStrongifySelf();
        [self fw_hideLoading];
    });
}

- (void)onIndicator3
{
    [self fw_showLoadingWithText:@"我是很长很长很长很长很长很长很长很长很长很长的加载文案"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fw_hideLoading];
    });
}

- (void)onLoading
{
    [self fw_showLoadingWithText:@"加载中\n请耐心等待"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fw_hideLoading];
    });
}

- (void)onProgress
{
    static BOOL isCancelled = NO;
    FWWeakifySelf();
    isCancelled = NO;
    [TestController mockProgress:^(double progress, BOOL finished) {
        if (isCancelled) return;
        FWStrongifySelf();
        if (!finished) {
            [self fw_showProgressWithText:[NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100] progress:progress cancelBlock:^{
                isCancelled = YES;
                FWStrongifySelf();
                [self fw_showMessageWithText:@"已取消"];
            }];
        } else {
            [self fw_hideProgress];
        }
    }];
}

- (void)onLoadingWindow
{
    self.view.window.fw_toastInsets = UIEdgeInsetsMake(FWTopBarHeight, 0, 0, 0);
    [self.view.window fw_showLoadingWithText:@"加载中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.window.fw_toastInsets = UIEdgeInsetsZero;
        [self.view.window fw_hideLoading];
    });
}

- (void)onProgressWindow
{
    FWWeakifySelf();
    [TestController mockProgress:^(double progress, BOOL finished) {
        FWStrongifySelf();
        if (!finished) {
            [self.view.window fw_showLoadingWithText:[NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100]];
        } else {
            [self.view.window fw_hideLoading];
        }
    }];
}

- (void)onToast
{
    self.view.tag = 100;
    static int count = 0;
    [self fw_showMessageWithText:[NSString stringWithFormat:@"吐司消息%@", @(++count)]];
}

- (void)onToast2
{
    NSString *text = @"我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息";
    FWWeakifySelf();
    [self fw_showMessageWithText:text style:FWToastStyleDefault completion:^{
        FWStrongifySelf();
        [self onToast];
    }];
}

@end
