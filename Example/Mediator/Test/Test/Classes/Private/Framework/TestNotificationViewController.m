//
//  TestNotificationViewController.m
//  Example
//
//  Created by wuyong on 2019/9/3.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestNotificationViewController.h"

@interface TestNotificationViewController () <FWTableViewController>

@end

@implementation TestNotificationViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                          @[@"本地通知(不重复，立即)", @"onNotification1"],
                                          @[@"本地通知(不重复，5秒后)", @"onNotification2"],
                                          @[@"本地通知(重复，每1分钟)", @"onNotification3"],
                                          @[@"取消本地通知(批量)", @"onNotification4"],
                                          @[@"取消本地通知(所有)", @"onNotification5"],
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

- (void)onNotification1
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test" title:@"立即通知" subtitle:nil body:@"body" userInfo:@{@"id": @"test"} badge:0 soundName:nil timeInterval:0 repeats:NO];
}

- (void)onNotification2
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test2" title:@"5秒后通知" subtitle:@"subtitle" body:@"body" userInfo:@{@"id": @"test2"} badge:1 soundName:@"default" timeInterval:5 repeats:NO];
}

- (void)onNotification3
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test3" title:@"重复1分钟通知" subtitle:@"subtitle" body:@"body" userInfo:@{@"id": @"test3"} badge:1 soundName:@"default" timeInterval:60 repeats:YES];
}

- (void)onNotification4
{
    [[FWNotificationManager sharedInstance] removeLocalNotification:@[@"test", @"test2", @"test3"]];
}

- (void)onNotification5
{
    [[FWNotificationManager sharedInstance] removeAllLocalNotifications];
}

@end
