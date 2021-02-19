//
//  TestRouterViewController.m
//  Example
//
//  Created by wuyong on 2018/11/30.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "TestRouterViewController.h"
#import "TestWebViewController.h"
#import "TestModuleController.h"

@implementation TestRouter

FWDefStaticString(ROUTE_TEST, @"app://test/:id");
FWDefStaticString(ROUTE_WILDCARD, @"wildcard://test1");
FWDefStaticString(ROUTE_OBJECT, @"object://test2");
FWDefStaticString(ROUTE_CONTROLLER, @"app://controller/:id");
FWDefStaticString(ROUTE_JAVASCRIPT, @"app://javascript");
FWDefStaticString(ROUTE_HOME, @"app://home");
FWDefStaticString(ROUTE_HOME_TEST, @"app://home/test");
FWDefStaticString(ROUTE_HOME_SETTINGS, @"app://home/settings");
FWDefStaticString(ROUTE_CLOSE, @"app://close");

+ (void)load
{
    [self registerFilters];
    [self registerRouters];
    [self registerRewrites];
}

+ (void)registerFilters
{
    [FWRouter setFilterHandler:^BOOL(NSDictionary *parameters) {
        NSURL *url = [NSURL fwURLWithString:parameters[FWRouterURLKey]];
        if ([UIApplication fwIsSystemURL:url]) {
            [UIApplication fwOpenURL:url];
            return NO;
        }
        if ([url.absoluteString hasPrefix:@"app://filter/"]) {
            TestRouterResultViewController *viewController = [TestRouterResultViewController new];
            viewController.parameters = parameters;
            viewController.navigationItem.title = url.absoluteString;
            [FWRouter pushViewController:viewController animated:YES];
            return NO;
        }
        return YES;
    }];
    [FWRouter setErrorHandler:^(NSDictionary *parameters) {
        [[[UIWindow fwMainWindow] fwTopPresentedController] fwShowAlertWithTitle:[NSString stringWithFormat:@"url not supported\n%@", parameters] message:nil cancel:@"OK" cancelBlock:nil];
    }];
}

+ (void)registerRouters
{
    [FWRouter registerURL:@[@"http://*", @"https://*"] withHandler:^(NSDictionary *parameters) {
        // 尝试打开通用链接，失败了再内部浏览器打开
        [UIApplication fwOpenUniversalLinks:parameters[FWRouterURLKey] completionHandler:^(BOOL success) {
            if (success) return;
            
            TestWebViewController *viewController = [TestWebViewController new];
            viewController.navigationItem.title = parameters[FWRouterURLKey];
            viewController.requestUrl = parameters[FWRouterURLKey];
            viewController.showToolbar = [parameters[@"toolbar"] fwAsBool];
            [FWRouter pushViewController:viewController animated:YES];
        }];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_TEST withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = [NSString stringWithFormat:@"app://test/%@", parameters[@"id"]];
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"wildcard://*" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = @"wildcard://*";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_WILDCARD withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = TestRouter.ROUTE_WILDCARD;
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_CONTROLLER withHandler:^(NSDictionary * _Nonnull parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = [NSString stringWithFormat:@"app://controller/%@", parameters[@"id"]];
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_OBJECT withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = TestRouter.ROUTE_OBJECT;
        return viewController;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_JAVASCRIPT withHandler:^(NSDictionary *parameters) {
        UIViewController *topController = [[UIWindow fwMainWindow] fwTopViewController];
        if (![topController isKindOfClass:[TestWebViewController class]] || !topController.isViewLoaded) return;
        
        NSString *param = [parameters[@"param"] fwAsNSString];
        NSString *result = [NSString stringWithFormat:@"js:%@ => app:%@", param, @"2"];
        
        NSString *callback = [parameters[@"callback"] fwAsNSString];
        NSString *javascript = [NSString stringWithFormat:@"%@('%@');", callback, result];
        
        TestWebViewController *viewController = (TestWebViewController *)topController;
        [viewController.webView evaluateJavaScript:javascript completionHandler:^(id value, NSError *error) {
            [[[UIWindow fwMainWindow] fwTopViewController] fwShowAlertWithTitle:@"App" message:[NSString stringWithFormat:@"app:%@ => js:%@", @"2", value] cancel:@"关闭" cancelBlock:nil];
        }];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME withHandler:^(NSDictionary * _Nonnull parameters) {
        [UIWindow.fwMainWindow fwSelectTabBarIndex:0];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME_TEST withHandler:^(NSDictionary * _Nonnull parameters) {
        TestModuleController *testController = [UIWindow.fwMainWindow fwSelectTabBarController:[TestModuleController class]];
        [testController setSelectedIndex:1];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME_SETTINGS withHandler:^(NSDictionary * _Nonnull parameters) {
        [UIWindow.fwMainWindow fwSelectTabBarIndex:2];
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_CLOSE withHandler:^(NSDictionary * _Nonnull parameters) {
        UIViewController *topController = [UIWindow.fwMainWindow fwTopViewController];
        [topController fwCloseViewControllerAnimated:YES];
    }];
}

+ (void)registerRewrites
{
    [FWRouter setRewriteFilter:^NSString *(NSString *url) {
        url = [url stringByReplacingOccurrencesOfString:@"https://www.baidu.com/filter/" withString:@"app://filter/"];
        return url;
    }];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/test/(\\d+)" targetRule:@"app://test/$1"];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/wildcard/(.*)" targetRule:@"wildcard://$$1"];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/wildcard2/(.*)" targetRule:@"wildcard://$#1"];
}

@end

@implementation TestRouterResultViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (UITableViewStyle)renderTableStyle
{
    return UITableViewStyleGrouped;
}

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
    
    NSString *urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:nil];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@[@1]];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@{@"id": @2}];
    NSLog(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@3];
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
    [FWRouter openURL:[FWRouter generateURL:TestRouter.ROUTE_CONTROLLER parameters:@1]];
}

- (void)onOpenCallback
{
    [FWRouter openURL:[NSString stringWithFormat:@"%@?id=2", TestRouter.ROUTE_WILDCARD] completion:^(id result) {
        NSLog(@"result: %@", result);
    }];
}

- (void)onOpenObject
{
    TestRouterResultViewController *viewController = [FWRouter objectForURL:TestRouter.ROUTE_OBJECT];
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
    [FWRouter openURL:TestRouter.ROUTE_OBJECT];
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
    [FWRouter openURL:TestRouter.ROUTE_HOME];
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
    [FWRouter openURL:TestRouter.ROUTE_CLOSE];
}

- (void)onOpenHttp
{
    [FWRouter openURL:@"http://kvm.wuyong.site/test.php?toolbar=1"];
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
    TestViewController *viewController = [TestViewController new];
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
