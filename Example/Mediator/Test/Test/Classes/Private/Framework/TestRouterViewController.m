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
FWDefStaticString(ROUTE_OBJECT_UNMATCH, @"object://test");
FWDefStaticString(ROUTE_LOADER, @"app://loader");
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
    [FWRouter.sharedLoader addBlock:^id _Nullable(NSString * _Nonnull input) {
        if ([input isEqualToString:TestRouter.ROUTE_LOADER]) {
            return [TestRouterResultViewController class];
        }
        return nil;
    }];
    
    FWRouter.preFilter = ^BOOL(FWRouterContext * _Nonnull context) {
        NSURL *url = [NSURL fwURLWithString:context.URL];
        if ([UIApplication fwIsSystemURL:url]) {
            [UIApplication fwOpenURL:url];
            return NO;
        }
        if ([url.absoluteString hasPrefix:@"app://filter/"]) {
            TestRouterResultViewController *viewController = [TestRouterResultViewController new];
            viewController.context = context;
            [FWRouter pushViewController:viewController animated:YES];
            return NO;
        }
        return YES;
    };
    FWRouter.postFilter = ^(FWRouterContext * _Nonnull context, id  _Nonnull object) {
        if (context.isOpening) {
            if ([object isKindOfClass:[UIViewController class]]) {
                [FWRouter openViewController:object animated:YES];
            } else {
                FWRouter.errorHandler(context);
            }
        }
        return object;
    };
    FWRouter.errorHandler = ^(FWRouterContext * _Nonnull context) {
        [UIWindow.fwMainWindow.fwTopPresentedController fwShowAlertWithTitle:[NSString stringWithFormat:@"url not supported\nurl: %@\nparameters: %@", context.URL, context.parameters] message:nil cancel:nil cancelBlock:nil];
    };
}

+ (void)registerRouters
{
    [FWRouter registerURL:@[@"http://*", @"https://*"] withHandler:^id(FWRouterContext *context) {
        // 尝试打开通用链接，失败了再内部浏览器打开
        [UIApplication fwOpenUniversalLinks:context.URL completionHandler:^(BOOL success) {
            if (success) return;
            
            TestWebViewController *viewController = [TestWebViewController new];
            viewController.fwNavigationItem.title = context.URL;
            viewController.requestUrl = context.URL;
            [FWRouter pushViewController:viewController animated:YES];
        }];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_TEST withHandler:^id(FWRouterContext *context) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.context = context;
        [FWRouter pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:@"wildcard://*" withHandler:^id(FWRouterContext *context) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.context = context;
        [FWRouter pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_WILDCARD withHandler:^id(FWRouterContext *context) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.context = context;
        [FWRouter pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_CONTROLLER withHandler:^id(FWRouterContext * _Nonnull context) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.context = context;
        [FWRouter pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_OBJECT withHandler:^id(FWRouterContext *context) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.context = context;
        return viewController;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_OBJECT_UNMATCH withHandler:^id(FWRouterContext *context) {
        if (context.isOpening) {
            return @"OBJECT UNMATCH";
        } else {
            FWRouter.errorHandler(context);
            return nil;
        }
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_JAVASCRIPT withHandler:^id(FWRouterContext *context) {
        UIViewController *topController = [[UIWindow fwMainWindow] fwTopViewController];
        if (![topController isKindOfClass:[TestWebViewController class]] || !topController.isViewLoaded) return nil;
        
        NSString *param = [context.parameters[@"param"] fwAsNSString];
        NSString *result = [NSString stringWithFormat:@"js:%@ => app:%@", param, @"2"];
        
        NSString *callback = [context.parameters[@"callback"] fwAsNSString];
        NSString *javascript = [NSString stringWithFormat:@"%@('%@');", callback, result];
        
        TestWebViewController *viewController = (TestWebViewController *)topController;
        [viewController.webView evaluateJavaScript:javascript completionHandler:^(id value, NSError *error) {
            [[[UIWindow fwMainWindow] fwTopViewController] fwShowAlertWithTitle:@"App" message:[NSString stringWithFormat:@"app:%@ => js:%@", @"2", value] cancel:nil cancelBlock:nil];
        }];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME withHandler:^id(FWRouterContext * _Nonnull context) {
        [UIWindow.fwMainWindow fwSelectTabBarIndex:0];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME_TEST withHandler:^id(FWRouterContext * _Nonnull context) {
        TestModuleController *testController = [UIWindow.fwMainWindow fwSelectTabBarController:[TestModuleController class]];
        [testController setSelectedIndex:1];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME_SETTINGS withHandler:^id(FWRouterContext * _Nonnull context) {
        [UIWindow.fwMainWindow fwSelectTabBarIndex:2];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_CLOSE withHandler:^id(FWRouterContext * _Nonnull context) {
        UIViewController *topController = [UIWindow.fwMainWindow fwTopViewController];
        [topController fwCloseViewControllerAnimated:YES];
        return nil;
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

+ (id)fwRouterURL
{
    return TestRouter.ROUTE_LOADER;
}

+ (id)fwRouterHandler:(FWRouterContext *)context
{
    TestRouterResultViewController *viewController = [TestRouterResultViewController new];
    viewController.context = context;
    return viewController;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fwBarTitle = self.context.URL;
    
    UILabel *label = [UILabel fwAutoLayoutView];
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"URL: %@\n\nparameters: %@", self.context.URL, self.context.parameters];
    [self.fwView addSubview:label];
    [label fwAlignCenterToSuperview];
    [label fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 40];
    
    if (self.context.completion) {
        FWWeakifySelf();
        [self fwSetRightBarItem:@"完成" block:^(id sender) {
            FWStrongifySelf();
            [FWRouter completeURL:self.context result:@"我是回调数据"];
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
    [self.tableView fwPinEdgesToSuperview];
}

- (void)renderModel
{
    self.fwNavigationItem.title = @"FWRouter";
    NSString *url = @"http://test.com?id=我是中文";
    FWLogDebug(@"fwUrlEncode: %@", [url fwUrlEncode]);
    FWLogDebug(@"fwUrlDecode: %@", [[url fwUrlEncode] fwUrlDecode]);
    FWLogDebug(@"fwUrlEncodeComponent: %@", [url fwUrlEncodeComponent]);
    FWLogDebug(@"fwUrlDecodeComponent: %@", [[url fwUrlEncodeComponent] fwUrlDecodeComponent]);
    
    url = @"app://test/1?value=2&name=name2&title=我是字符串100%&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2";
    FWLogDebug(@"string.fwQueryDecode: %@", [url fwQueryDecode]);
    FWLogDebug(@"string.fwQueryEncode: %@", [NSString fwQueryEncode:[url fwQueryDecode]]);
    NSURL *nsurl = [NSURL fwURLWithString:url];
    FWLogDebug(@"query.fwQueryDecode: %@", [nsurl.query fwQueryDecode]);
    FWLogDebug(@"url.fwQueryDictionary: %@", nsurl.fwQueryDictionary);
}

- (void)renderData
{
    NSString *str = @"http://test.com?id=我是中文";
    NSURL *url = [NSURL URLWithString:str];
    FWLogDebug(@"str: %@ =>\nurl: %@", str, url);
    url = [NSURL fwURLWithString:str];
    FWLogDebug(@"str: %@ =>\nurl: %@", str, url);
    
    NSString *urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:nil];
    FWLogDebug(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@[@1]];
    FWLogDebug(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@{@"id": @2}];
    FWLogDebug(@"url: %@", urlStr);
    urlStr = [FWRouter generateURL:TestRouter.ROUTE_TEST parameters:@3];
    FWLogDebug(@"url: %@", urlStr);
    
    [self.tableData addObjectsFromArray:@[
                                         @[@"打开Web", @"onOpenHttp"],
                                         @[@"测试Cookie", @"onOpenCookie"],
                                         @[@"Url编码", @"onOpenEncode"],
                                         @[@"Url未编码", @"onOpenImage"],
                                         @[@"不规范Url", @"onOpenSlash"],
                                         @[@"打开Url", @"onOpen"],
                                         @[@"中文Url", @"onOpenChinese"],
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
                                         @[@"打开objectUrl", @"onOpenUnmatch3"],
                                         @[@"自动注册的Url", @"onOpenLoader"],
                                         @[@"跳转telprompt", @"onOpenTel"],
                                         @[@"跳转设置", @"onOpenSettings"],
                                         @[@"跳转home", @"onOpenHome"],
                                         @[@"跳转test", @"onOpenHome2"],
                                         @[@"跳转settings", @"onOpenHome3"],
                                         @[@"跳转home/undefined", @"onOpenHome4"],
                                         @[@"不支持tabbar/home", @"onOpenHome5"],
                                         @[@"关闭close", @"onOpenClose"],
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
    [FWRouter openURL:@"app://test/1#anchor"];
}

- (void)onOpenChinese
{
    [FWRouter openURL:@"app://test/%E4%B8%AD%E6%96%87?value=1#anchor"];
}

- (void)onOpenEncode
{
    [FWRouter openURL:@"app://test/1?value=2&name=name2&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2"];
}

- (void)onOpenImage
{
    [FWRouter openURL:@"app://test/1?url=https://kvm.wuyong.site/test.php"];
}

- (void)onOpenSlash
{
    [FWRouter openURL:@"app:test/1#anchor"];
}

- (void)onOpenWild
{
    [FWRouter openURL:@"wildcard://not_found?id=1#anchor"];
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
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onOpenFailed
{
    [FWRouter openURL:@"app://test?FWRouterBlock=1"];
}

- (void)onRewrite1
{
    [FWRouter openURL:@"https://www.baidu.com/test/66666"];
}

- (void)onRewrite2
{
    [FWRouter openURL:@"https://www.baidu.com/wildcard/原子弹?title=我是字符串100%"];
}

- (void)onRewrite3
{
    [FWRouter openURL:@"https://www.baidu.com/wildcard2/%E5%8E%9F%E5%AD%90%E5%BC%B9"];
}

- (void)onOpenUnmatch
{
    [FWRouter openURL:TestRouter.ROUTE_OBJECT_UNMATCH];
}

- (void)onOpenUnmatch2
{
    [FWRouter objectForURL:TestRouter.ROUTE_OBJECT_UNMATCH];
}

- (void)onOpenUnmatch3
{
    [FWRouter openURL:TestRouter.ROUTE_OBJECT];
}

- (void)onOpenLoader
{
    [FWRouter openURL:TestRouter.ROUTE_LOADER];
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
    [FWRouter openURL:@"http://kvm.wuyong.site/test.php#anchor"];
}

- (void)onOpenCookie
{
    [FWRouter openURL:@"http://kvm.wuyong.site/cookie.php?param=value#anchor"];
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
    viewController.fwNavigationItem.title = @"iOS14 bug";
    FWWeakifySelf();
    viewController.fwBackBarBlock = ^BOOL{
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
    };
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
