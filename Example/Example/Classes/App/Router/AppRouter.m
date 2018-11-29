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
    [FWRouter registerURL:@"app://test" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"app://test";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [[UIWindow fwMainWindow] fwPushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"/test" withHandler:^(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"/test";
        FWBlockParam completion = parameters[FWRouterCompletionKey];
        if (completion) {
            viewController.completion = completion;
        }
        [[UIWindow fwMainWindow] fwPushViewController:viewController animated:YES];
    }];
    
    [FWRouter registerURL:@"object://test" withObjectHandler:^id(NSDictionary *parameters) {
        TestRouterResultViewController *viewController = [TestRouterResultViewController new];
        viewController.title = @"object://test";
        return viewController;
    }];
    
    [FWRouter registerURL:@"/" withHandler:^(NSDictionary *parameters) {
        NSLog(@"not supported");
    }];
}

@end
