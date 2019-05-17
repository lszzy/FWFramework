//
//  AppRouter.m
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import "AppRouter.h"
#import "TestRouterViewController.h"

@implementation AppRouter

+ (void)load
{
    [self registerFilters];
    [self registerRouters];
    [self registerRewrites];
}

+ (void)registerFilters
{
    [FWRouter setFilterHandler:^BOOL(NSDictionary *parameters) {
        NSString *url = parameters[FWRouterURLKey];
        if ([url hasPrefix:@"app://filter/"]) {
            TestRouterResultViewController *viewController = [TestRouterResultViewController new];
            viewController.parameters = parameters;
            viewController.title = url;
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
    [FWRouter registerURL:@"app://test/:id" withHandler:^(NSDictionary *parameters) {
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
    
    [FWRouter registerURL:@"wildcard://test1" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = @"wildcard://test1";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [FWRouter pushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"object://test2" withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.parameters = parameters;
        viewController.title = @"object://test2";
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
