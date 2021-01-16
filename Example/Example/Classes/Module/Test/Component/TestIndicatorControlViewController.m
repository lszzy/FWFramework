//
//  FWTestIndicatorControlViewController.m
//  Example
//
//  Created by wuyong on 2018/10/19.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestIndicatorControlViewController.h"

@interface TestIndicatorControlViewController () <FWTableViewController>

@end

@implementation TestIndicatorControlViewController

- (void)renderData
{
    self.tableView.backgroundColor = Theme.tableColor;
    [self.tableData addObjectsFromArray:@[
                                         @[@"文本指示器(简单版)", @"onText"],
                                         @[@"文本指示器(详细版)", @"onText2"],
                                         @[@"图片指示器(简单版)", @"onImage"],
                                         @[@"图片指示器(详细版)", @"onImage2"],
                                         @[@"动画指示器(简单版)", @"onActivity"],
                                         @[@"动画指示器(详细版)", @"onActivity2"],
                                         @[@"进度指示器(简单版)", @"onProgress"],
                                         @[@"进度指示器(详细版)", @"onProgress2"],
                                         @[@"动画指示器(透明)", @"onActivityClear"],
                                         @[@"进度指示器(window)", @"onProgressWindow"],
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

- (void)onText
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeText];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载"];
    [self.view.fwIndicatorControl show:YES];
    [self.view.fwIndicatorControl hide:YES afterDelay:2.0];
}

- (void)onText2
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeText];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"手机号码格式不正确，我是好长好长好长好长好长好长真的很长很长的文本\n我是另一行的文本"];
    self.view.fwIndicatorControl.indicatorColor = [UIColor redColor];
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onActivity
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeActivity];
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onActivity2
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeActivity];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载，我是好长好长好长好长好长好长真的很长很长的文本\n我是另一行的文本"];
    self.view.fwIndicatorControl.indicatorColor = [UIColor redColor];
    self.view.fwIndicatorControl.indicatorStyle = UIActivityIndicatorViewStyleWhite;
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onImage
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeImage];
    self.view.fwIndicatorControl.indicatorImage = [UIImage imageNamed:@"public_icon"];
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onImage2
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeImage];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载，我是好长好长好长好长好长好长真的很长很长的文本\n我是另一行的文本"];
    self.view.fwIndicatorControl.indicatorImage = [UIImage imageNamed:@"public_icon"];
    self.view.fwIndicatorControl.indicatorSize = CGSizeMake(20, 20);
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onProgress
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeProgress];
    [self.view.fwIndicatorControl show:YES];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.fwIndicatorControl hide:YES];
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
            self.view.fwIndicatorControl.progress = progress;
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onProgress2
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeProgress];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"开始上传" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
    self.view.fwIndicatorControl.indicatorSize = CGSizeMake(20, 20);
    [self.view.fwIndicatorControl show:YES];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgress2];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.fwIndicatorControl hide:YES];
        });
    });
}

- (void)mockProgress2
{
    double progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.02f;
        BOOL finish = progress >= 1.0f;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:finish ? @"上传完成" : @"上传中，我是好长好长好长好长好长好长真的很长很长的文本\n我是另一行的文本" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
            self.view.fwIndicatorControl.progress = progress;
        });
        usleep(finish ? 2000000 : 50000);
    }
}

- (void)onActivityClear
{
    self.view.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeActivity];
    self.view.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载"];
    self.view.fwIndicatorControl.indicatorColor = [UIColor redColor];
    [self.view.fwIndicatorControl show:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view.fwIndicatorControl hide:YES];
    });
}

- (void)onProgressWindow
{
    self.view.window.fwIndicatorControl = [[FWIndicatorControl alloc] initWithType:FWIndicatorControlTypeProgress];
    self.view.window.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"开始上传"];
    self.view.window.fwIndicatorControl.indicatorSize = CGSizeMake(20, 20);
    [self.view.window.fwIndicatorControl show:YES];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self mockProgressWindow];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window.fwIndicatorControl hide:YES];
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
            self.view.window.fwIndicatorControl.attributedTitle = [[NSAttributedString alloc] initWithString:finish ? @"上传完成" : @"上传中"];
            self.view.window.fwIndicatorControl.progress = progress;
        });
        usleep(finish ? 2000000 : 50000);
    }
}

@end
