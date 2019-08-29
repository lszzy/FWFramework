//
//  TestAlertViewController.m
//  Example
//
//  Created by wuyong on 2019/4/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestAlertViewController.h"

@interface TestAlertViewController ()

@end

@implementation TestAlertViewController

- (void)renderData
{
    [self.tableData addObjectsFromArray:@[
                                         @[@"警告框(简单)", @"onAlert1"],
                                         @[@"警告框(详细)", @"onAlert2"],
                                         @[@"确认框(简单)", @"onConfirm1"],
                                         @[@"确认框(详细)", @"onConfirm2"],
                                         @[@"输入框(简单)", @"onPrompt1"],
                                         @[@"输入框(详细)", @"onPrompt2"],
                                         @[@"操作表(简单)", @"onSheet1"],
                                         @[@"操作表(详细)", @"onSheet2"],
                                         ]];
}

#pragma mark - TableView

- (void)renderCellData:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
}

- (void)onCellSelect:(NSIndexPath *)indexPath
{
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    SEL selector = NSSelectorFromString([rowData objectAtIndex:1]);
    if ([self respondsToSelector:selector]) {
        FWIgnoredBegin();
        [self performSelector:selector];
        FWIgnoredEnd();
    }
}

#pragma mark - Action

- (void)onAlert1
{
    [self fwShowAlertWithTitle:@"警告框标题"
                       message:@"警告框消息"
                        cancel:@"确定"
                   cancelBlock:nil];
}

- (void)onAlert2
{
    [self fwShowAlertWithTitle:@"警告框标题"
                       message:@"警告框消息"
                        cancel:@"取消"
                       actions:@[@"按钮1:2", @"按钮2"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的按钮index: %@", @(index));
                   }
                   cancelBlock:^{
                       NSLog(@"点击了取消按钮");
                   }
                      priority:FWAlertPriorityNormal];
}

- (void)onConfirm1
{
    [self fwShowConfirmWithTitle:@"确认框标题"
                         message:@"确认框消息"
                          cancel:@"取消"
                         confirm:@"确定"
                    confirmBlock:^{
                        NSLog(@"点击了确定按钮");
                    }];
}

- (void)onConfirm2
{
    [self fwShowConfirmWithTitle:@"确认框标题"
                         message:@"确认框消息"
                          cancel:@"取消"
                         confirm:@"确定"
                    confirmBlock:^{
                        NSLog(@"点击了确定按钮");
                    }
                     cancelBlock:^{
                         NSLog(@"点击了取消按钮");
                     }
                        priority:FWAlertPriorityNormal];
}

- (void)onPrompt1
{
    [self fwShowPromptWithTitle:@"输入框标题"
                        message:@"输入框消息"
                         cancel:@"取消"
                        confirm:@"确定"
                   confirmBlock:^(NSString *text){
                       NSLog(@"输入内容：%@", text);
                   }];
}

- (void)onPrompt2
{
    [self fwShowPromptWithTitle:@"输入框标题"
                        message:@"输入框消息"
                         cancel:@"取消"
                        confirm:@"确定"
                    promptBlock:^(UITextField *textField){
                        textField.placeholder = @"请输入密码";
                        textField.secureTextEntry = YES;
                    }
                   confirmBlock:^(NSString *text){
                       NSLog(@"输入内容：%@", text);
                   }
                    cancelBlock:^{
                        NSLog(@"点击了取消按钮");
                    }
                       priority:FWAlertPriorityNormal];
}

- (void)onSheet1
{
    [self fwShowSheetWithTitle:@"操作表标题"
                        cancel:@"取消"
                       actions:@[@"操作1:2", @"操作2"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的操作index: %@", @(index));
                   }];
}

- (void)onSheet2
{
    [self fwShowSheetWithTitle:@"操作表标题"
                        cancel:@"取消"
                       actions:@[@"操作1:2", @"操作2"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的操作index: %@", @(index));
                   }
                   cancelBlock:^{
                       NSLog(@"点击了取消操作");
                   }
                      priority:FWAlertPriorityNormal];
}

@end
