//
//  AppRouter.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "AppRouter.h"
#import "BaseWebViewController.h"
#import "TestRouterViewController.h"

@implementation AppRouter

FWDefStaticString(ROUTE_TEST, @"app://test/:id");
FWDefStaticString(ROUTE_WILDCARD, @"wildcard://test1");
FWDefStaticString(ROUTE_OBJECT, @"object://test2");
FWDefStaticString(ROUTE_CONTROLLER, @"app://controller/:id");

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
        if ([UIApplication fwIsAppStoreURL:url]) {
            [UIApplication fwOpenURL:url];
            return NO;
        }
        if ([url.absoluteString hasPrefix:@"app://filter/"]) {
            TestRouterResultViewController *viewController = [TestRouterResultViewController new];
            viewController.parameters = parameters;
            viewController.title = url.absoluteString;
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
        BaseWebViewController *viewController = [BaseWebViewController new];
        viewController.title = parameters[FWRouterURLKey];
        viewController.requestUrl = parameters[FWRouterURLKey];
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_TEST withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = [NSString stringWithFormat:@"app://test/%@", parameters[@"id"]];
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"wildcard://*" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = @"wildcard://*";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_WILDCARD withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = AppRouter.ROUTE_WILDCARD;
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:AppRouter.ROUTE_OBJECT withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = AppRouter.ROUTE_OBJECT;
        return viewController;
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
