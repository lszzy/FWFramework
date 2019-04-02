//
//  TestWorkflowViewController.m
//  Example
//
//  Created by wuyong on 16/11/13.
//  Copyright © 2016年 ocphp.com. All rights reserved.
//

#import "TestWorkflowViewController.h"

@interface TestWorkflowViewController ()

@end

@implementation TestWorkflowViewController

- (NSString *)fwWorkflowName
{
    return [NSString stringWithFormat:@"workflow.%ld", self.step];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.step < 1) {
        self.step = 1;
    }
    
    self.title = [NSString stringWithFormat:@"工作流-%ld", self.step];
    
    if (self.step < 3) {
        [self fwSetRightBarItem:@"下一步" target:self action:@selector(onNext)];
    } else {
        UIBarButtonItem *item1 = [UIBarButtonItem fwBarItemWithObject:@"退出" target:self action:@selector(onExit)];
        UIBarButtonItem *item2 = [UIBarButtonItem fwBarItemWithObject:@"重来" target:self action:@selector(onOpen)];
        self.navigationItem.rightBarButtonItems = @[item1, item2];
    }
}

#pragma mark - Action

- (void)onNext
{
    TestWorkflowViewController *workflow = [[TestWorkflowViewController alloc] init];
    workflow.step = self.step + 1;
    [self.navigationController pushViewController:workflow animated:YES];
}

- (void)onExit
{
    [self.navigationController fwPopWorkflows:@[@"workflow"] animated:YES];
}

- (void)onOpen
{
    [self.navigationController fwPushViewController:[[TestWorkflowViewController alloc] init] popWorkflows:@[@"workflow"] animated:YES];
}

@end
