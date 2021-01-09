//
//  TestWindowViewController.m
//  Example
//
//  Created by wuyong on 2018/10/11.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestWindowViewController.h"
#import "ObjcController.h"

@interface TestWindowViewController ()

@end

@implementation TestWindowViewController

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"push", @"onPush"],
                                         @[@"present", @"onPresent"],
                                         @[@"present nav && push", @"onPush2"],
                                         @[@"present nav && present", @"onPresent2"],
                                         @[@"present vc && push", @"onPush3"],
                                         @[@"present vc && present", @"onPresent3"],
                                         @[@"url review", @"onReview"],
                                         @[@"app review", @"onReview2"],
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

- (void)onPush
{
    [[UIWindow fwMainWindow] fwPushViewController:[ObjcController new] animated:YES];
}

- (void)onPresent
{
    [[UIWindow fwMainWindow] fwPresentViewController:[ObjcController new] animated:YES completion:nil];
}

- (void)onPush2
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[ObjcController new]];
    [self presentViewController:nav animated:YES completion:^{
        [[UIWindow fwMainWindow] fwPushViewController:[ObjcController new] animated:YES];
    }];
}

- (void)onPresent2
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[ObjcController new]];
    [self presentViewController:nav animated:YES completion:^{
        [[UIWindow fwMainWindow] fwPresentViewController:[ObjcController new] animated:YES completion:nil];
    }];
}

- (void)onPush3
{
    [self presentViewController:[ObjcController new] animated:YES completion:^{
        [[UIWindow fwMainWindow] fwPushViewController:[ObjcController new] animated:YES];
    }];
}

- (void)onPresent3
{
    [self presentViewController:[ObjcController new] animated:YES completion:^{
        [[UIWindow fwMainWindow] fwPresentViewController:[ObjcController new] animated:YES completion:nil];
    }];
}

- (void)onReview
{
    [UIApplication fwOpenAppReview:@"923302754"];
}

- (void)onReview2
{
    [UIApplication fwRequestAppReview];
}

@end
