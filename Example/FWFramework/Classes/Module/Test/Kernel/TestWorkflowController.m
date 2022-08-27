//
//  TestWorkflowController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestWorkflowController.h"
@import FWFramework;

@interface TestWorkflowController () <FWViewController>

@property (nonatomic, assign) NSInteger step;

@end

@implementation TestWorkflowController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.step < 1) {
        self.step = 1;
    }
    
    self.fw_workflowName = [NSString stringWithFormat:@"workflow.%ld", self.step];
    self.navigationItem.title = [NSString stringWithFormat:@"工作流-%ld", self.step];
    
    if (self.step < 3) {
        [self fw_setRightBarItem:@"下一步" target:self action:@selector(onNext)];
    } else {
        [self fw_addRightBarItem:@"退出" target:self action:@selector(onExit)];
        [self fw_addRightBarItem:@"重来" target:self action:@selector(onOpen)];
    }
}

#pragma mark - Action

- (void)onNext
{
    TestWorkflowController *workflow = [[TestWorkflowController alloc] init];
    workflow.step = self.step + 1;
    [self.navigationController pushViewController:workflow animated:YES];
}

- (void)onExit
{
    [self.navigationController fw_popWorkflows:@[@"workflow"] animated:YES completion:nil];
}

- (void)onOpen
{
    [self.navigationController fw_pushViewController:[[TestWorkflowController alloc] init] popWorkflows:@[@"workflow"] animated:YES completion:nil];
}

@end
