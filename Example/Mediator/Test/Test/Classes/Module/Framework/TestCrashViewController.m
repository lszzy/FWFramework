//
//  TestCrashViewController.m
//  Example
//
//  Created by wuyong on 2020/2/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "TestCrashViewController.h"

@interface TestCrashViewController () <FWTableViewController>

@end

@implementation TestCrashViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[[@"NSNull" stringByAppendingString:FWIsDebug ? @"(Debug)" : @"(Release)"], @"onNull"],
                                         @[@"NSNumber", @"onNumber"],
                                         @[@"NSString", @"onString"],
                                         @[@"NSArray", @"onArray"],
                                         @[@"NSDictionary", @"onDictionary"],
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

- (void)onNull
{
    id object = [NSNull null];
    [object onNull];
}

- (void)onNumber
{
    id value = nil;
    [@(1) fwIsEqualToNumber:value];
    [@(1) fwCompare:value];
}

- (void)onString
{
    NSString *str = @"test";
    [str fwSubstringFromIndex:10];
    [str fwSubstringToIndex:10];
    [str fwSubstringWithRange:NSMakeRange(2, 10)];
}

- (void)onArray
{
    NSArray *arr = @[@1, @2, @3];
    [arr fwObjectAtIndex:10];
    [arr fwSubarrayWithRange:NSMakeRange(2, 10)];
    
    NSMutableArray *arrm = arr.mutableCopy;
    [arrm fwAddObject:nil];
    [arrm fwRemoveObjectAtIndex:10];
    [arrm fwReplaceObjectAtIndex:10 withObject:@3];
}

- (void)onDictionary
{
    NSDictionary *dict = @{@"a": @1};
    [dict fwObjectForKey:nil];
    
    NSMutableDictionary *dictm = dict.mutableCopy;
    [dictm fwRemoveObjectForKey:nil];
    [dictm fwSetObject:nil forKey:nil];
}

@end
