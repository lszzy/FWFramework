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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FWWeakifySelf();
    self.fwBackBarBlock = ^BOOL{
        FWStrongifySelf();
        [self fwShowConfirmWithTitle:nil message:@"是否关闭" cancel:@"否" confirm:@"是" confirmBlock:^{
            FWStrongifySelf();
            [self fwCloseViewControllerAnimated:YES];
        }];
        return NO;
    };
}

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    self.tableView.backgroundColor = Theme.tableColor;
    [self.tableData addObjectsFromArray:@[
                                         @[@"上下无文本", @"onIndicator"],
                                         @[@"上下文本", @"onIndicator2"],
                                         @[@"左右无文本", @"onIndicator3"],
                                         @[@"左右文本", @"onIndicator4"],
                                         @[@"加载动画", @"onLoading"],
                                         @[@"进度动画", @"onProgress"],
                                         @[@"加载动画(window)", @"onLoadingWindow"],
                                         @[@"进度动画(window)", @"onProgressWindow"],
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
    [self.view fwShowLoadingWithText:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideLoading];
    });
}

- (void)onIndicator2
{
    [self.view fwShowLoadingWithText:@"正在加载..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideLoading];
    });
}

- (void)onIndicator3
{
    [self.view fwShowIndicatorLoadingWithStyle:UIActivityIndicatorViewStyleGray attributedTitle:nil indicatorColor:[UIColor fwThemeLight:[UIColor grayColor] dark:[UIColor whiteColor]] backgroundColor:[UIColor clearColor] dimBackgroundColor:[UIColor fwThemeLight:[UIColor whiteColor] dark:[UIColor blackColor]] horizontalAlignment:NO contentInsets:UIEdgeInsetsMake(10, 10, 10, 10) cornerRadius:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideIndicatorLoading];
    });
}

- (void)onIndicator4
{
    [self.view fwShowLoadingWithText:@"正在加载..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideLoading];
    });
}

- (void)onLoading
{
    [self.view fwShowLoadingWithText:@"加载中\n请耐心等待"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view fwHideLoading];
    });
}

- (void)onProgress
{
    [self.view fwShowLoadingWithText:@"上传中"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view fwHideLoading];
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
            [self.view fwShowLoadingWithText:finish ? @"上传完成" : [NSString stringWithFormat:@"上传中(%.0f%%)", progress * 100]];
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onLoadingWindow
{
    [self.view.window fwShowLoadingWithText:@"加载中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
    [self.view fwShowMessageWithText:[NSString stringWithFormat:@"吐司消息%@", @(++count)]];
}

- (void)onToast2
{
    NSString *text = @"我是很长很长很长很长很长很长很长很长很长很长很长的吐司消息";
    FWWeakifySelf();
    [self.view fwShowMessageWithText:text style:FWToastStyleDefault completion:^{
        FWStrongifySelf();
        [self onToast];
    }];
}

@end
