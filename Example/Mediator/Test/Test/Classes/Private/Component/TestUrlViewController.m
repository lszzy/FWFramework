//
//  TestUrlViewController.m
//  Example
//
//  Created by wuyong on 2019/2/1.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestUrlViewController.h"

@interface TestUrlViewController () <FWTableViewController>

@property (nonatomic, strong) NSString *gps;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *from;
@property (nonatomic, strong) NSString *to;
@property (nonatomic, strong) NSString *target;

@end

@implementation TestUrlViewController

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)renderData
{
    self.gps = @"29.5302033389,106.4601725638";
    self.address = @"港城凤鸣香山";
    self.from = @"29.6014365904,106.5026870776";
    self.to = @"29.5302033389,106.4601725638";
    self.target = @"港城凤鸣香山";
    
    [self.tableData addObjectsFromArray:@[
                                         @[@"Google Maps(gps)", @"onGoogleMaps1"],
                                         @[@"Google Maps(address)", @"onGoogleMaps2"],
                                         @[@"Google Maps(direction)", @"onGoogleMaps3"],
                                         @[@"Google Maps(current)", @"onGoogleMaps4"],
                                         @[@"Apple Maps(gps)", @"onAppleMaps1"],
                                         @[@"Apple Maps(address)", @"onAppleMaps2"],
                                         @[@"Apple Maps(direction)", @"onAppleMaps3"],
                                         @[@"Apple Maps(current)", @"onAppleMaps4"],
                                         @[@"Baidu Maps(gps)", @"onBaiduMaps1"],
                                         @[@"Baidu Maps(address)", @"onBaiduMaps2"],
                                         @[@"Baidu Maps(direction)", @"onBaiduMaps3"],
                                         @[@"Baidu Maps(current)", @"onBaiduMaps4"],
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

- (void)onGoogleMaps1
{
    NSURL *url = [NSURL fwGoogleMapsURLWithAddr:self.gps options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onGoogleMaps2
{
    NSURL *url = [NSURL fwGoogleMapsURLWithAddr:self.address options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onGoogleMaps3
{
    NSURL *url = [NSURL fwGoogleMapsURLWithSaddr:self.from daddr:self.to mode:nil options:@{@"dirflg": @"t,h"}];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onGoogleMaps4
{
    NSURL *url = [NSURL fwGoogleMapsURLWithSaddr:nil daddr:self.target mode:@"driving" options:@{@"dirflg": @"th"}];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onAppleMaps1
{
    NSURL *url = [NSURL fwAppleMapsURLWithAddr:self.gps options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onAppleMaps2
{
    NSURL *url = [NSURL fwAppleMapsURLWithAddr:self.address options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onAppleMaps3
{
    NSURL *url = [NSURL fwAppleMapsURLWithSaddr:self.from daddr:self.to options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onAppleMaps4
{
    NSURL *url = [NSURL fwAppleMapsURLWithSaddr:nil daddr:self.target options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onBaiduMaps1
{
    NSURL *url = [NSURL fwBaiduMapsURLWithAddr:self.gps options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onBaiduMaps2
{
    NSURL *url = [NSURL fwBaiduMapsURLWithAddr:self.address options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onBaiduMaps3
{
    NSURL *url = [NSURL fwBaiduMapsURLWithSaddr:self.from daddr:self.to mode:nil options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onBaiduMaps4
{
    NSURL *url = [NSURL fwBaiduMapsURLWithSaddr:nil daddr:self.target mode:@"walking" options:nil];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

@end
