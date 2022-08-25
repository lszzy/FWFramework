//
//  TestRouterController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestRouterController.h"
#import "WebController.h"
@import FWFramework;

@interface TestRouterResultController : UIViewController <FWViewController>

@property (nonatomic, strong) FWRouterContext *context;

@end

@implementation TestRouterResultController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fw_title = self.context.URL;
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"URL: %@\n\nparameters: %@", self.context.URL, self.context.parameters];
    [self.view addSubview:label];
    [label fw_alignCenterToSuperview];
    [label fw_setDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 40];
    
    if (self.context.completion) {
        FWWeakifySelf();
        [self fw_setRightBarItem:@"完成" block:^(id sender) {
            FWStrongifySelf();
            [FWRouter completeURL:self.context result:@"我是回调数据"];
            [self fw_closeViewControllerAnimated:YES];
        }];
    }
}

@end

@interface TestRouter : NSObject

FWStaticString(ROUTE_TEST);
FWStaticString(ROUTE_HOME);
FWStaticString(ROUTE_WILDCARD);
FWStaticString(ROUTE_OBJECT);
FWStaticString(ROUTE_OBJECT_UNMATCH);
FWStaticString(ROUTE_LOADER);
FWStaticString(ROUTE_ITEM);
FWStaticString(ROUTE_JAVASCRIPT);
FWStaticString(ROUTE_CLOSE);

@end

@implementation TestRouter

FWDefStaticString(ROUTE_TEST, @"app://tests/:id");
FWDefStaticString(ROUTE_HOME, @"app://tab/home");
FWDefStaticString(ROUTE_WILDCARD, @"wildcard://test1");
FWDefStaticString(ROUTE_OBJECT, @"object://test2");
FWDefStaticString(ROUTE_OBJECT_UNMATCH, @"object://test");
FWDefStaticString(ROUTE_LOADER, @"app://loader");
FWDefStaticString(ROUTE_ITEM, @"app://shops/:id/items/:itemId");
FWDefStaticString(ROUTE_JAVASCRIPT, @"app://javascript");
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
            return [TestRouterResultController class];
        }
        return nil;
    }];
    
    [FWRouter setRouteFilter:^BOOL(FWRouterContext * _Nonnull context) {
        NSURL *url = [NSURL fw_urlWithString:context.URL];
        if ([UIApplication fw_isSystemURL:url]) {
            [UIApplication fw_openURL:url];
            return NO;
        }
        if ([url.absoluteString hasPrefix:@"app://filter/"]) {
            TestRouterResultController *viewController = [TestRouterResultController new];
            viewController.context = context;
            [FWNavigator pushViewController:viewController animated:YES];
            return NO;
        }
        return YES;
    }];
    [FWRouter setRouteHandler:^id _Nullable(FWRouterContext * _Nonnull context, id  _Nonnull object) {
        if (context.isOpening) {
            if ([object isKindOfClass:[UIViewController class]]) {
                [FWNavigator openViewController:object animated:YES options:0 completion:nil];
            } else {
                [FWNavigator.topPresentedController fw_showAlertWithTitle:[NSString stringWithFormat:@"url not supported\nurl: %@\nparameters: %@", context.URL, context.parameters] message:nil cancel:nil cancelBlock:nil];
            }
        }
        return object;
    }];
    [FWRouter setErrorHandler:^(FWRouterContext * _Nonnull context) {
        [FWNavigator.topPresentedController fw_showAlertWithTitle:[NSString stringWithFormat:@"url not supported\nurl: %@\nparameters: %@", context.URL, context.parameters] message:nil cancel:nil cancelBlock:nil];
    }];
}

+ (void)registerRouters
{
    [FWRouter registerURL:TestRouter.ROUTE_TEST withHandler:^id(FWRouterContext *context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        [FWNavigator pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:@"wildcard://*" withHandler:^id(FWRouterContext *context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        [FWNavigator pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_WILDCARD withHandler:^id(FWRouterContext *context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        [FWNavigator pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_ITEM withHandler:^id(FWRouterContext * _Nonnull context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        [FWNavigator pushViewController:viewController animated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_OBJECT withHandler:^id(FWRouterContext *context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        return viewController;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_OBJECT_UNMATCH withHandler:^id(FWRouterContext *context) {
        if (context.isOpening) {
            return @"OBJECT UNMATCH";
        } else {
            [FWNavigator.topPresentedController fw_showAlertWithTitle:[NSString stringWithFormat:@"url not supported\nurl: %@\nparameters: %@", context.URL, context.parameters] message:nil cancel:nil cancelBlock:nil];
            return nil;
        }
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_JAVASCRIPT withHandler:^id(FWRouterContext *context) {
        UIViewController *topController = [FWNavigator topViewController];
        if (![topController isKindOfClass:[WebController class]] || !topController.isViewLoaded) return nil;
        
        NSString *param = [context.parameters[@"param"] fw_safeString];
        NSString *result = [NSString stringWithFormat:@"js:%@ => app:%@", param, @"2"];
        
        NSString *callback = [context.parameters[@"callback"] fw_safeString];
        NSString *javascript = [NSString stringWithFormat:@"%@('%@');", callback, result];
        
        WebController *viewController = (WebController *)topController;
        [viewController.webView evaluateJavaScript:javascript completionHandler:^(id value, NSError *error) {
            [[FWNavigator topViewController] fw_showAlertWithTitle:@"App" message:[NSString stringWithFormat:@"app:%@ => js:%@", @"2", value] cancel:nil cancelBlock:nil];
        }];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_HOME withHandler:^id(FWRouterContext * _Nonnull context) {
        [UIWindow.fw_mainWindow fw_selectTabBarIndex:0];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_CLOSE withHandler:^id(FWRouterContext * _Nonnull context) {
        UIViewController *topController = [FWNavigator topViewController];
        [topController fw_closeViewControllerAnimated:YES];
        return nil;
    }];
    
    [FWRouter registerURL:TestRouter.ROUTE_LOADER withHandler:^id _Nullable(FWRouterContext * _Nonnull context) {
        TestRouterResultController *viewController = [TestRouterResultController new];
        viewController.context = context;
        return viewController;
    }];
}

+ (void)registerRewrites
{
    [FWRouter setRewriteFilter:^NSString *(NSString *url) {
        url = [url stringByReplacingOccurrencesOfString:@"https://www.baidu.com/filter/" withString:@"app://filter/"];
        return url;
    }];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/tests/(\\d+)" targetRule:@"app://tests/$1"];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/wildcard/(.*)" targetRule:@"wildcard://$$1"];
    [FWRouter addRewriteRule:@"(?:https://)?www.baidu.com/wildcard2/(.*)" targetRule:@"wildcard://$#1"];
}

@end

@interface TestRouterController () <FWTableViewController>

@end

@implementation TestRouterController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupTableLayout
{
    [self.tableView fw_pinEdgesToSuperview];
}

- (void)setupNavbar
{
    self.navigationItem.title = @"FWRouter";
    NSString *url = @"http://test.com?id=我是中文";
    FWLogDebug(@"fwUrlEncode: %@", [url fw_urlEncode]);
    FWLogDebug(@"fwUrlDecode: %@", [[url fw_urlEncode] fw_urlDecode]);
    FWLogDebug(@"fwUrlEncodeComponent: %@", [url fw_urlEncodeComponent]);
    FWLogDebug(@"fwUrlDecodeComponent: %@", [[url fw_urlEncodeComponent] fw_urlDecodeComponent]);
    
    url = @"app://tests/1?value=2&name=name2&title=我是字符串100%&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2";
    FWLogDebug(@"string.fwQueryDecode: %@", [url fw_queryDecode]);
    FWLogDebug(@"string.fwQueryEncode: %@", [NSString fw_queryEncode:[url fw_queryDecode]]);
    NSURL *nsurl = [NSURL fw_urlWithString:url];
    FWLogDebug(@"query.fwQueryDecode: %@", [nsurl.query fw_queryDecode]);
    FWLogDebug(@"url.fwQueryDictionary: %@", nsurl.fw_queryDictionary);
}

- (void)setupSubviews
{
    NSString *str = @"http://test.com?id=我是中文";
    NSURL *url = [NSURL URLWithString:str];
    FWLogDebug(@"str: %@ =>\nurl: %@", str, url);
    url = [NSURL fw_urlWithString:str];
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
        @[@"打开完整Web", @"onOpenHttp2"],
        @[@"打开异常Web", @"onOpenHttp3"],
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
        @[@"跳转首页", @"onOpenHome"],
        @[@"跳转home/undefined", @"onOpenHome2"],
        @[@"不支持tabbar/home", @"onOpenHome3"],
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
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
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
    [FWRouter openURL:@"app://tests/1#anchor"];
}

- (void)onOpenChinese
{
    [FWRouter openURL:@"app://tests/%E4%B8%AD%E6%96%87?value=1#anchor"];
}

- (void)onOpenEncode
{
    [FWRouter openURL:@"app://tests/1?value=2&name=name2&url=https%3A%2F%2Fkvm.wuyong.site%2Ftest.php%3Fvalue%3D1%26name%3Dname1%23%2Fhome1#/home2"];
}

- (void)onOpenImage
{
    [FWRouter openURL:@"app://tests/1?url=https://kvm.wuyong.site/test.php"];
}

- (void)onOpenSlash
{
    [FWRouter openURL:@"app:tests/1#anchor"];
}

- (void)onOpenWild
{
    [FWRouter openURL:@"wildcard://not_found?id=1#anchor"];
}

- (void)onOpenController
{
    [FWRouter openURL:[FWRouter generateURL:TestRouter.ROUTE_ITEM parameters:@[@1, @2]]];
}

- (void)onOpenCallback
{
    [FWRouter openURL:[NSString stringWithFormat:@"%@?id=2", TestRouter.ROUTE_WILDCARD] completion:^(id result) {
        [UIWindow fw_showMessageWithText:result];
    }];
}

- (void)onOpenObject
{
    TestRouterResultController *viewController = [FWRouter objectForURL:TestRouter.ROUTE_OBJECT];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onOpenFailed
{
    [FWRouter openURL:@"app://tests?FWRouterBlock=1"];
}

- (void)onRewrite1
{
    [FWRouter openURL:@"https://www.baidu.com/tests/66666"];
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
    [FWRouter openURL:@"app://tab/home/undefined"];
}

- (void)onOpenHome3
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

- (void)onOpenHttp2
{
    [FWRouter openURL:@"http://www.baidu.com/test/directory%202/index.html?param=value#anchor"];
}

- (void)onOpenHttp3
{
    [FWRouter openURL:@"http://username:password@localhost:8000/test:8001/directory%202/index.html?param=value#anchor"];
}

- (void)onOpenCookie
{
    [FWRouter openURL:@"http://kvm.wuyong.site/cookie.php?param=value#anchor"];
}

- (void)onOpenUniversalLinks
{
    NSString *url = @"https://v.douyin.com/";
    [UIApplication fw_openUniversalLinks:url completionHandler:^(BOOL success) {
        if (!success) {
            [FWRouter openURL:url];
        }
    }];
}

- (void)onOpenUrl
{
    [UIApplication fw_openURL:@"http://kvm.wuyong.site/test.php"];
}

- (void)onOpenSafari
{
    [UIApplication fw_openSafariController:@"http://kvm.wuyong.site/test.php" completionHandler:^{
        FWLogDebug(@"SafariController completionHandler");
    }];
}

- (void)onOpen14
{
    TestRouterResultController *viewController = [TestRouterResultController new];
    viewController.navigationItem.title = @"iOS14 bug";
    viewController.context = [[FWRouterContext alloc] initWithURL:@"http://kvm.wuyong.site/test.php?key=value" userInfo:nil completion:nil];
    FWWeakifySelf();
    viewController.fw_shouldPopController = ^BOOL{
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
