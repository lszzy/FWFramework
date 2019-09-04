//
//  TestNotificationViewController.m
//  Example
//
//  Created by wuyong on 2019/9/3.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestNotificationViewController.h"

@interface TestNotificationViewController ()

@end

@implementation TestNotificationViewController

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                          @[@"本地通知(立即)", @"onNotification1"],
                                          @[@"本地通知(5秒后)", @"onNotification2"],
                                          @[@"本地通知(立即，每隔1分钟提醒一次)", @"onNotification3"],
                                          @[@"本地通知(5秒后，每隔1分钟提醒一次)", @"onNotification4"],
                                          @[@"取消本地通知", @"onNotification5"],
                                          ]];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
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
    
}

- (void)onNotification2
{
    
}

@end
