/*!
 @header     TestIndicatorViewController.m
 @indexgroup Example
 @brief      TestIndicatorViewController
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "TestIndicatorViewController.h"

@interface TestIndicatorViewController () <FWTableViewController>

@end

@implementation TestIndicatorViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    self.tableView.backgroundColor = Theme.tableColor;
    [self.tableData addObjectsFromArray:@[
                                         @[@"无文本", @"onIndicator"],
                                         @[@"有文本", @"onIndicator2"],
                                         @[@"文本太长", @"onIndicator3"],
                                         @[@"加载动画", @"onLoading"],
                                         @[@"进度动画", @"onProgress"],
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
    UITableViewCell *cell = [UITableViewCell fwCellWithTableView:tableView];
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
    [self fwShowLoadingWithText:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideLoading];
    });
}

- (void)onIndicator2
{
    [self fwShowLoading];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideLoading];
    });
}

- (void)onIndicator3
{
    [self fwShowLoadingWithText:@"我是很长很长很长很长很长很长很长很长很长很长的加载文案"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideLoading];
    });
}

- (void)onLoading
{
    [self fwShowLoadingWithText:@"加载中\n请耐心等待"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fwHideLoading];
    });
}

- (void)onProgress
{
    [self fwShowProgressWithText:[NSString stringWithFormat:@"上传中(%.0f%%)", 0.0f] progress:0];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwHideProgress];
        });
    });
}

- (void)mockProgress
{
    double progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fwShowProgressWithText:finish ? @"上传完成" : [NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100] progress:progress];
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onLoadingWindow
{
    self.view.window.fwToastInsets = UIEdgeInsetsMake(FWTopBarHeight, 0, 0, 0);
    [self.view.window fwShowLoadingWithText:@"加载中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.window.fwToastInsets = UIEdgeInsetsZero;
        [self.view.window fwHideLoading];
    });
}

- (void)onProgressWindow
{
    [self.view.window fwShowLoadingWithText:@"上传中"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgressWindow];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window fwHideLoading];
        });
    });
}

- (void)mockProgressWindow
{
    double progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window fwShowLoadingWithText:finish ? @"上传完成" : [NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100]];
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onToast
{
    self.view.tag = 100;
    static int count = 0;
    [self fwShowMessageWithText:[NSString stringWithFormat:@"吐司消息%@", @(++count)]];
}

- (void)onToast2
{
    NSString *text = @"我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息";
    FWWeakifySelf();
    [self fwShowMessageWithText:text style:FWToastStyleDefault completion:^{
        FWStrongifySelf();
        [self onToast];
    }];
}

@end
