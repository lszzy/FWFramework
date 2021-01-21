//
//  ViewController.m
//  Test
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

#import "ViewController.h"
@import FWFramework;
@import Mediator;

@interface ViewController () <FWViewController>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"TestModule Example";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Test" forState:UIControlStateNormal];
    [button fwAddTouchBlock:^(id  _Nonnull sender) {
        [FWRouter pushViewController:[Mediator.testModule testViewController] animated:YES];
    }];
    [self.view addSubview:button];
    button.fwLayoutChain.center();
}

@end
