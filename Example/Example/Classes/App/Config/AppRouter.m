//
//  AppRouter.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "AppRouter.h"
#import "WebViewController.h"
#import "TestViewController.h"
#import "SettingsViewController.h"
#import "TestRouterViewController.h"

@implementation AppRouter

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
            
            WebViewController *viewController = [WebViewController new];
            viewController.navigationItem.title = parameters[FWRouterURLKey];
            viewController.requestUrl = parameters[FWRouterURLKey];
            [FWRouter pushViewController:viewController animated:YES];
        }];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_TEST withHandler:^(NSDictionary *parameters) {
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
    
    [FWRouter registerURL:AppRouter.ROUTE_WILDCARD withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = AppRouter.ROUTE_WILDCARD;
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_CONTROLLER withHandler:^(NSDictionary * _Nonnull parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = [NSString stringWithFormat:@"app://controller/%@", parameters[@"id"]];
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_OBJECT withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.navigationItem.title = AppRouter.ROUTE_OBJECT;
        return viewController;
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_JAVASCRIPT withHandler:^(NSDictionary *parameters) {
        UIViewController *topController = [[UIWindow fwMainWindow] fwTopViewController];
        if (![topController isKindOfClass:[WebViewController class]] || !topController.isViewLoaded) return;
        
        NSString *param = [parameters[@"param"] fwAsNSString];
        NSString *result = [NSString stringWithFormat:@"js:%@ => app:%@", param, @"2"];
        
        NSString *callback = [parameters[@"callback"] fwAsNSString];
        NSString *javascript = [NSString stringWithFormat:@"%@('%@');", callback, result];
        
        WebViewController *viewController = (WebViewController *)topController;
        [viewController.webView evaluateJavaScript:javascript completionHandler:^(id value, NSError *error) {
            [[[UIWindow fwMainWindow] fwTopViewController] fwShowAlertWithTitle:@"App" message:[NSString stringWithFormat:@"app:%@ => js:%@", @"2", value] cancel:@"关闭" cancelBlock:nil];
        }];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_HOME withHandler:^(NSDictionary * _Nonnull parameters) {
        ObjcController *homeController = [UIWindow.fwMainWindow fwSelectTabBarController:[ObjcController class]];
        homeController.selectedIndex = 1;
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_HOME_TEST withHandler:^(NSDictionary * _Nonnull parameters) {
        [UIWindow.fwMainWindow fwSelectTabBarController:[TestViewController class]];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_HOME_SETTINGS withHandler:^(NSDictionary * _Nonnull parameters) {
        [UIWindow.fwMainWindow fwSelectTabBarController:[SettingsViewController class]];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_CLOSE withHandler:^(NSDictionary * _Nonnull parameters) {
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

+ (void)refreshController
{
    if (@available(iOS 13.0, *)) {
        FWSceneDelegate *sceneDelegete = (FWSceneDelegate *)UIWindow.fwMainScene.delegate;
        [sceneDelegete setupController];
    } else {
        FWAppDelegate *appDelegate = (FWAppDelegate *)UIApplication.sharedApplication.delegate;
        [appDelegate setupController];
    }
}

@end
