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
    
    UILabel *label = [UILabel fwAutoLayoutView];
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"%@", self.parameters];
    [self.view addSubview:label];
    [label fwAlignCenterToSuperview];
    [label fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 40];
    
    if (self.completion) {
        FWWeakifySelf();
        [self fwSetRightBarItem:@"完成" block:^(id sender) {
            FWStrongifySelf();
            if (self.completion) {
                self.completion(@"我是回调数据");
            }
            [self fwCloseViewControllerAnimated:YES];
        }];
    }
}

@end

@interface TestRouterViewController ()

@end

@implementation TestRouterViewController

- (void)renderData
{
    NSString *str = @"http://test.com?id=我是中文";
    NSURL *url = [NSURL URLWithString:str];
    NSLog(@"str: %@ =>\nurl: %@", str, url);
    url = [NSURL fwURLWithString:str];
    NSLog(@"str: %@ =>\nurl: %@", str, url);
    
    NSString *urlStr = [FWRouter generateURL:@"app://test/:id" parameters:nil];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:@"app://test/:id" parameters:@[@1]];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:@"app://test/:id" parameters:@{@"id": @2}];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:@"app://test/:id" parameters:@3];
    NSLog(@"url: %@", urlStr);
    
    [self.dataList addObjectsFromArray:@[
                                         @[@"打开Url", @"onOpen"],
                                         @[@"打开Url，通配符*", @"onOpenWild"],
                                         @[@"打开Url，支持回调", @"onOpenCallback"],
                                         @[@"解析Url，获取Object", @"onOpenObject"],
                                         @[@"过滤Url", @"onOpenFilter"],
                                         @[@"不支持的Url", @"onOpenFailed"],
                                         @[@"RewriteUrl", @"onRewrite1"],
                                         @[@"RewriteUrl URLEncode", @"onRewrite2"],
                                         @[@"RewriteUrl URLDecode", @"onRewrite3"],
                                         @[@"RewriteFilter", @"onRewriteFilter"],
                                         @[@"不匹配的openUrl", @"onOpenUnmatch"],
                                         @[@"不匹配的objectUrl", @"onOpenUnmatch2"],
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
    [FWRouter openURL:@"app://test/1"];
}

- (void)onOpenWild
{
    [FWRouter openURL:@"wildcard://not_found?id=1"];
}

- (void)onOpenCallback
{
    [FWRouter openURL:@"wildcard://test1?id=2" completion:^(id result) {
        NSLog(@"result: %@", result);
    }];
}

- (void)onOpenObject
{
    TestRouterResultViewController *viewController = [FWRouter objectForURL:@"object://test2"];
    viewController.completion = ^(id result) {
        NSLog(@"result: %@", result);
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onOpenFailed
{
    [FWRouter openURL:@"app://test"];
}

- (void)onRewrite1
{
    [FWRouter openURL:@"https://www.baidu.com/test/66666"];
}

- (void)onRewrite2
{
    [FWRouter openURL:@"https://www.baidu.com/wildcard/原子弹"];
}

- (void)onRewrite3
{
    [FWRouter openURL:@"https://www.baidu.com/wildcard2/%E5%8E%9F%E5%AD%90%E5%BC%B9"];
}

- (void)onOpenUnmatch
{
    [FWRouter openURL:@"object://test2"];
}

- (void)onOpenUnmatch2
{
    [FWRouter objectForURL:@"app://test/1"];
}

- (void)onOpenFilter
{
    [FWRouter openURL:@"app://filter/1"];
}

- (void)onRewriteFilter
{
    [FWRouter openURL:@"https://www.baidu.com/filter/1"];
}

@end
