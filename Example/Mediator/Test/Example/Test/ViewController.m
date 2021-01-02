//
//  ViewController.m
//  Test
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

#import "ViewController.h"
#import <FWFramework/FWFramework.h>
#import <Mediator/Mediator-Swift.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"ViewController";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Test" forState:UIControlStateNormal];
    [button fwAddTouchBlock:^(id  _Nonnull sender) {
        UIViewController *viewController = [FWModule(TestModuleService) testViewController];
        [FWRouter pushViewController:viewController animated:YES];
    }];
    [self.view addSubview:button];
    button.fwLayoutChain.center();
}

@end
