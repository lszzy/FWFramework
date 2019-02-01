//
//  TestUrlViewController.m
//  Example
//
//  Created by wuyong on 2019/2/1.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestUrlViewController.h"

@interface TestUrlViewController ()

@end

@implementation TestUrlViewController

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
                                         @[@"Google Maps(query)", @"onGoogleMaps1"],
                                         @[@"Google Maps(query + callback)", @"onGoogleMaps2"],
                                         @[@"Google Maps(direction)", @"onGoogleMaps3"],
                                         @[@"Google Maps(direction + callback)", @"onGoogleMaps4"],
                                         ]];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.dataList objectAtIndex:indexPath.row];
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
    NSURL *url = [NSURL fwGoogleMapsURLWithQuery:@"275 King Street" options:@{
                                                                              @"center": @"-37.813992,144.970616",
                                                                              }];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

- (void)onGoogleMaps2
{
    NSURL *url = [NSURL fwGoogleMapsURLWithQuery:@"275 King Street" options:@{
                                                                              @"center": @"-37.813992,144.970616",
                                                                              @"x-source": @"Example",
                                                                              @"x-success": @"site.wuyong.example://",
                                                                              }];
    if ([UIApplication fwCanOpenURL:url]) {
        [UIApplication fwOpenURL:url];
    }
}

@end
