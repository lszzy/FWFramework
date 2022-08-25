//
//  TestNotificationController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestNotificationController.h"
@import UserNotifications;
@import FWFramework;

@interface TestNotificationController () <FWTableViewController>

@end

@implementation TestNotificationController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableView
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

- (void)onNotification1
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test" title:@"立即通知" subtitle:nil body:@"body" userInfo:@{@"id": @"test"} badge:0 soundName:nil timeInterval:0 repeats:NO block:^(UNMutableNotificationContent *content) {
        // iOS15时效性通知，需entitlements开启配置生效
        #if __IPHONE_15_0
        if (@available(iOS 15.0, *)) {
            content.interruptionLevel = UNNotificationInterruptionLevelTimeSensitive;
        }
        #endif
    }];
}

- (void)onNotification2
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test2" title:@"5秒后通知" subtitle:@"subtitle" body:@"body" userInfo:@{@"id": @"test2"} badge:1 soundName:@"default" timeInterval:5 repeats:NO block:^(UNMutableNotificationContent * _Nonnull content) {
        // iOS15时效性通知，需entitlements开启配置生效
        #if __IPHONE_15_0
        if (@available(iOS 15.0, *)) {
            content.interruptionLevel = UNNotificationInterruptionLevelTimeSensitive;
        }
        #endif
    }];
}

- (void)onNotification3
{
    [[FWNotificationManager sharedInstance] registerLocalNotification:@"test3" title:@"重复1分钟通知" subtitle:@"subtitle" body:@"body" userInfo:@{@"id": @"test3"} badge:1 soundName:@"default" timeInterval:60 repeats:YES block:nil];
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
