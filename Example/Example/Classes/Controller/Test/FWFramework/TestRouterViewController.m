//
//  TestRouterViewController.m
//  Example
//
//  Created by wuyong on 2018/11/30.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestRouterViewController.h"

@implementation TestRouterResultViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.completion) {
        FWWeakifySelf();
        [self fwSetRightBarItem:@"完成" block:^(id sender) {
            FWStrongifySelf();
            if (self.completion) {
                self.completion(@"我是回调数据");
            }
            [self fwOnClose];
        }];
    }
}

@end

@interface TestRouterViewController ()

@end

@implementation TestRouterViewController

- (void)renderData
{
    [self.dataList addObjectsFromArray:@[
                                         @[@"打开Url", @"onOpen"],
                                         @[@"打开Url，通配符~", @"onOpenWild"],
                                         @[@"打开Url，支持回调", @"onOpenCallback"],
                                         @[@"解析Url，获取Object", @"onOpenObject"],
                                         @[@"不支持的Url", @"onOpenFailed"],
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

- (void)onOpen
{
    [FWRouter openURL:@"app://test"];
}

- (void)onOpenWild
{
    [FWRouter openURL:@"other://test"];
}

- (void)onOpenCallback
{
    [FWRouter openURL:@"app://test" completion:^(id result) {
        NSLog(@"result: %@", result);
    }];
}

- (void)onOpenObject
{
    TestRouterResultViewController *viewController = [FWRouter objectForURL:@"object://test"];
    viewController.completion = ^(id result) {
        NSLog(@"result: %@", result);
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onOpenFailed
{
    [FWRouter openURL:@"other://not_found"];
}

@end
