//
//  TestRouterViewController.m
//  Example
//
//  Created by wuyong on 2018/11/30.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestRouterViewController.h"

@implementation TestRouterResultViewController

#pragma mark - Lifecycle

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

@interface TestRouterViewController () <FWTableViewController>

@end

@implementation TestRouterViewController

- (void)renderTableLayout
{
    [self.tableView fwPinEdgesToSuperviewSafeArea];
}

- (void)renderModel
{
    NSString *url = @"http://test.com?id=我是中文";
    NSLog(@"fwUrlEncode: %@", [url fwUrlEncode]);
    NSLog(@"fwUrlDecode: %@", [[url fwUrlEncode] fwUrlDecode]);
    NSLog(@"fwUrlEncodeComponent: %@", [url fwUrlEncodeComponent]);
    NSLog(@"fwUrlDecodeComponent: %@", [[url fwUrlEncodeComponent] fwUrlDecodeComponent]);
}

- (void)renderData
{
    NSString *str = @"http://test.com?id=我是中文";
    NSURL *url = [NSURL URLWithString:str];
    NSLog(@"str: %@ =>\nurl: %@", str, url);
    url = [NSURL fwURLWithString:str];
    NSLog(@"str: %@ =>\nurl: %@", str, url);
    
    NSString *urlStr = [FWRouter generateURL:AppRouter.ROUTE_TEST parameters:nil];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:AppRouter.ROUTE_TEST parameters:@[@1]];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:AppRouter.ROUTE_TEST parameters:@{@"id": @2}];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:AppRouter.ROUTE_TEST parameters:@3];
    NSLog(@"url: %@", urlStr);
    
    [self.tableData addObjectsFromArray:@[
                                         @[@"打开Url", @"onOpen"],
                                         @[@"打开Url，通配符*", @"onOpenWild"],
                                         @[@"打开Url，协议", @"onOpenController"],
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
                                         @[@"跳转telprompt", @"onOpenTel"],
                                         @[@"跳转设置", @"onOpenSettings"],
                                         @[@"跳转home", @"onOpenHome"],
                                         @[@"跳转test", @"onOpenHome2"],
                                         @[@"跳转settings", @"onOpenHome3"],
                                         @[@"跳转home/undefined", @"onOpenHome4"],
                                         @[@"不支持tabbar/home", @"onOpenHome5"],
                                         @[@"关闭close", @"onOpenClose"],
                                         @[@"内部web", @"onOpenHttp"],
                                         @[@"通用链接douyin", @"onOpenUniversalLinks"],
                                         @[@"外部safari", @"onOpenUrl"],
                                         @[@"内部safari", @"onOpenSafari"],
                                         @[@"iOS14bug", @"onOpen14"],
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

- (void)onOpen
{
    [FWRouter openURL:@"app://test/1"];
}

- (void)onOpenWild
{
    [FWRouter openURL:@"wildcard://not_found?id=1"];
}

- (void)onOpenController
{
    [FWRouter openURL:[FWRouter generateURL:AppRouter.ROUTE_CONTROLLER parameters:@1]];
}

- (void)onOpenCallback
{
    [FWRouter openURL:[NSString stringWithFormat:@"%@?id=2", AppRouter.ROUTE_WILDCARD] completion:^(id result) {
        NSLog(@"result: %@", result);
    }];
}

- (void)onOpenObject
{
    TestRouterResultViewController *viewController = [FWRouter objectForURL:AppRouter.ROUTE_OBJECT];
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
    [FWRouter openURL:AppRouter.ROUTE_OBJECT];
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

- (void)onOpenTel
{
    [FWRouter openURL:@"telprompt:10000"];
}

- (void)onOpenSettings
{
    [FWRouter openURL:UIApplicationOpenSettingsURLString];
}

- (void)onOpenHome
{
    [FWRouter openURL:AppRouter.ROUTE_HOME];
}

- (void)onOpenHome2
{
    [FWRouter openURL:@"app://home/test"];
}

- (void)onOpenHome3
{
    [FWRouter openURL:@"app://home/settings"];
}

- (void)onOpenHome4
{
    [FWRouter openURL:@"app://home/undefined"];
}

- (void)onOpenHome5
{
    [FWRouter openURL:@"app://tabbar/home"];
}

- (void)onOpenClose
{
    [FWRouter openURL:AppRouter.ROUTE_CLOSE];
}

- (void)onOpenHttp
{
    [FWRouter openURL:@"http://kvm.wuyong.site/test.php"];
}

- (void)onOpenUniversalLinks
{
    [FWRouter openURL:@"https://v.douyin.com/JYmHJ9k/"];
}

- (void)onOpenUrl
{
    [UIApplication fwOpenSafari:@"http://kvm.wuyong.site/test.php"];
}

- (void)onOpenSafari
{
    [UIApplication fwOpenSafariController:@"http://kvm.wuyong.site/test.php" completionHandler:^{
        FWLogDebug(@"SafariController completionHandler");
    }];
}

- (void)onOpen14
{
    BaseViewController *viewController = [BaseViewController new];
    viewController.navigationItem.title = @"iOS14 bug";
    FWWeakifySelf();
    [viewController fwSetBackBarBlock:^BOOL{
        FWStrongifySelf();
        static NSInteger count = 0;
        NSInteger index = count++ % 3;
        if (index == 0) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else if (index == 1) {
            [self.navigationController popToViewController:self.navigationController.viewControllers.firstObject animated:YES];
        } else {
            [self.navigationController setViewControllers:@[self.navigationController.viewControllers.firstObject] animated:YES];
        }
        return NO;
    }];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
