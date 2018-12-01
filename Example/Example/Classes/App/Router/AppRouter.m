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
    [self registerRouters];
}

+ (void)registerRouters
{
    [FWRouter registerURL:@"app://test/:id" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = [NSString stringWithFormat:@"app://test/%@", parameters[@"id"]];
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [[UIWindow fwMainWindow] fwPushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"wildcard://*" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"wildcard://*";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [[UIWindow fwMainWindow] fwPushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"wildcard://test1" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"wildcard://test1";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [[UIWindow fwMainWindow] fwPushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"object://test2" withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"object://test2";
        return viewController;
    }];
    
    [FWRouter registerErrorHandler:^(NSDictionary *parameters) {
        NSLog(@"not supported: %@", parameters);
    }];
}

@end
