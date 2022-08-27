//
//  TestAlertController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/25.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "TestAlertController.h"
@import FWFramework;

@interface TestAlertController () <FWTableViewController>

@end

@implementation TestAlertController

- (UITableViewStyle)setupTableStyle
{
    return UITableViewStyleGrouped;
}

- (void)setupNavbar
{
    [self fw_setRightBarItem:@"切换插件" block:^(id  _Nonnull sender) {
        id<FWAlertPlugin> alertPlugin = [FWPluginManager loadPlugin:@protocol(FWAlertPlugin)];
        if (alertPlugin) {
            [FWPluginManager unloadPlugin:@protocol(FWAlertPlugin)];
            [FWPluginManager unregisterPlugin:@protocol(FWAlertPlugin)];
        } else {
            [FWPluginManager registerPlugin:@protocol(FWAlertPlugin) withObject:[FWAlertControllerImpl class]];
        }
    }];
}

- (void)setupSubviews
{
    [self.tableData addObjectsFromArray:@[
        @[@"警告框(简单)", @"onAlert1"],
        @[@"警告框(详细)", @"onAlert2"],
        @[@"确认框(简单)", @"onConfirm1"],
        @[@"确认框(详细)", @"onConfirm2"],
        @[@"输入框(简单)", @"onPrompt1"],
        @[@"输入框(详细)", @"onPrompt2"],
        @[@"输入框(复杂)", @"onPrompt3"],
        @[@"警告框(容错)", @"onAlertE"],
        @[@"操作表(简单)", @"onSheet1"],
        @[@"操作表(详细)", @"onSheet2"],
        @[@"弹出框(完整)", @"onAlertF"],
        @[@"弹出框(头部视图)", @"onAlertH"],
        @[@"弹出框(整个视图)", @"onAlertV"],
        @[@"警告框(样式)", @"onAlertA"],
        @[@"操作表(样式)", @"onSheetA"],
        @[@"警告框(优先)", @"onAlertP"],
        @[@"操作表(优先)", @"onSheetP"],
        @[@"关闭弹出框", @"onCloseA"],
    ]];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [UITableViewCell fw_cellWithTableView:tableView];
    NSArray *rowData = [self.tableData objectAtIndex:indexPath.row];
    cell.textLabel.text = [rowData objectAtIndex:0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [self fw_showAlertWithTitle:@"警告框标题"
                       message:@"警告框消息"
                        cancel:nil
                   cancelBlock:^{
                        NSLog(@"顶部控制器：%@", FWNavigator.topPresentedController);
                    }];
}

- (void)onAlert2
{
    [self fw_showAlertWithTitle:@"警告框标题"
                       message:@"警告框消息"
                         style:FWAlertStyleDefault
                        cancel:nil
                       actions:@[@"按钮1", @"按钮2"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的按钮index: %@", @(index));
                   }
                   cancelBlock:^{
                       NSLog(@"点击了取消按钮");
                   }];
}

- (void)onConfirm1
{
    [self fw_showConfirmWithTitle:@"确认框标题"
                         message:@"确认框消息"
                          cancel:nil
                         confirm:nil
                    confirmBlock:^{
                        NSLog(@"点击了确定按钮");
                    }];
}

- (void)onConfirm2
{
    [self fw_showConfirmWithTitle:@"确认框标题"
                         message:@"确认框消息"
                          cancel:nil
                         confirm:@"我是很长的确定按钮"
                    confirmBlock:^{
                        NSLog(@"点击了确定按钮");
                    }
                     cancelBlock:^{
                         NSLog(@"点击了取消按钮");
                     }];
}

- (void)onPrompt1
{
    [self fw_showPromptWithTitle:@"输入框标题"
                        message:@"输入框消息"
                         cancel:nil
                        confirm:nil
                   confirmBlock:^(NSString *text){
                       NSLog(@"输入内容：%@", text);
                   }];
}

- (void)onPrompt2
{
    [self fw_showPromptWithTitle:@"输入框标题"
                        message:@"输入框消息"
                         cancel:nil
                        confirm:nil
                    promptBlock:^(UITextField *textField){
                        textField.placeholder = @"请输入密码";
                        textField.secureTextEntry = YES;
                    }
                   confirmBlock:^(NSString *text){
                       NSLog(@"输入内容：%@", text);
                   }
                    cancelBlock:^{
                        NSLog(@"点击了取消按钮");
                    }];
}

- (void)onPrompt3
{
    [self fw_showPromptWithTitle:@"输入框标题"
                        message:@"输入框消息"
                         cancel:nil
                        confirm:nil
                    promptCount:2
                    promptBlock:^(UITextField *textField, NSInteger index) {
                        if (index == 0) {
                            textField.placeholder = @"请输入用户名";
                            textField.secureTextEntry = NO;
                        } else {
                            textField.placeholder = @"请输入密码";
                            textField.secureTextEntry = YES;
                        }
                    }
                   confirmBlock:^(NSArray<NSString *> *values) {
                        NSLog(@"输入内容：%@", values);
                    }
                    cancelBlock:^{
                        NSLog(@"点击了取消按钮");
                    }];
}

- (void)onAlertE
{
    [self fw_showAlertWithTitle:nil
                       message:nil
                        cancel:nil
                   cancelBlock:^{
                        NSLog(@"顶部控制器：%@", FWNavigator.topPresentedController);
                    }];
}

- (void)onSheet1
{
    [self fw_showSheetWithTitle:nil
                       message:nil
                        cancel:@"取消"
                       actions:@[@"操作1"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的操作index: %@", @(index));
                   }];
}

- (void)onSheet2
{
    [self fw_showSheetWithTitle:@"操作表标题"
                       message:@"操作表消息"
                        cancel:@"取消"
                       actions:@[@"操作1", @"操作2", @"操作3"]
                   currentIndex:1
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的操作index: %@", @(index));
                   }
                   cancelBlock:^{
                       NSLog(@"点击了取消操作");
                   }];
}

- (void)onAlertF
{
    FWWeakifySelf();
    [self fw_showAlertWithTitle:@"请输入账号信息，我是很长很长很长很长很长很长的标题"
                       message:@"账户信息必填，我是很长很长很长很长很长很长的消息"
                         style:FWAlertStyleDefault
                        cancel:@"取消"
                       actions:@[@"重试", @"高亮", @"禁用", @"确定"]
                   promptCount:2
                   promptBlock:^(UITextField *textField, NSInteger index) {
                        if (index == 0) {
                            textField.placeholder = @"请输入用户名";
                            textField.secureTextEntry = NO;
                        } else {
                            textField.placeholder = @"请输入密码";
                            textField.secureTextEntry = YES;
                        }
                    }
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                        FWStrongifySelf();
                        if (index == 0) {
                            [self onAlertF];
                        } else {
                            NSLog(@"输入内容：%@", values);
                        }
                    }
                   cancelBlock:^{
                        NSLog(@"点击了取消按钮");
                    }
                   customBlock:^(UIAlertController *alertController) {
                        alertController.preferredAction = alertController.actions[1];
                        alertController.actions[2].enabled = NO;
                        if ([alertController isKindOfClass:[FWAlertController class]]) {
                            ((FWAlertController *)alertController).image = [UIImage fw_appIconImage];
                        }
                    }];
}

- (void)onAlertH
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    headerView.backgroundColor = UIColor.whiteColor;
    
    [[FWAlertControllerImpl sharedInstance] viewController:self
                                          showAlertWithStyle:UIAlertControllerStyleAlert
                                                  headerView:headerView
                                                 cancel:@"取消"
                                                actions:@[@"确定"]
                                            actionBlock:^(NSInteger index) {
                                                NSLog(@"点击了确定按钮");
                                            }
                                            cancelBlock:^{
                                                NSLog(@"点击了取消按钮");
                                            }
                                            customBlock:nil];
}

- (void)onAlertV
{
    UIView *alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    alertView.backgroundColor = UIColor.whiteColor;
    FWWeakifySelf();
    [alertView fw_addTapGestureWithBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [[FWAlertControllerImpl sharedInstance] viewController:self
                                          showAlertWithStyle:UIAlertControllerStyleAlert
                                                  headerView:alertView
                                                 cancel:nil
                                                actions:nil
                                            actionBlock:nil
                                            cancelBlock:nil
                                            customBlock:^(FWAlertController *alertController) {
                                                alertController.tapBackgroundViewDismiss = YES;
                                            }];
}

- (void)onAlertA
{
    NSMutableAttributedString *title = [NSMutableAttributedString new];
    NSTextAttachment *attachment = [NSTextAttachment new];
    attachment.image = [[UIImage fw_appIconImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    attachment.bounds = CGRectMake(0, -20, 30, 30);
    [title appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    NSDictionary *attrs = @{
        NSFontAttributeName: [UIFont fw_boldFontOfSize:17],
        NSForegroundColorAttributeName: [UIColor redColor],
    };
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n警告框标题" attributes:attrs]];
        
    NSMutableAttributedString *message = [NSMutableAttributedString new];
    attrs = @{
        NSFontAttributeName: [UIFont fw_fontOfSize:15],
        NSForegroundColorAttributeName: [UIColor greenColor],
    };
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"警告框消息" attributes:attrs]];
    
    [self fw_showAlertWithTitle:title
                       message:message
                         style:FWAlertStyleDefault
                        cancel:nil
                       actions:@[@"按钮1", @"按钮2", @"按钮3", @"按钮4"]
                   actionBlock:nil
                   cancelBlock:nil];
}

- (void)onSheetA
{
    NSMutableAttributedString *title = [NSMutableAttributedString new];
    NSTextAttachment *attachment = [NSTextAttachment new];
    attachment.image = [[UIImage fw_appIconImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    attachment.bounds = CGRectMake(0, -20, 30, 30);
    [title appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    NSDictionary *attrs = @{
        NSFontAttributeName: [UIFont fw_boldFontOfSize:17],
        NSForegroundColorAttributeName: [UIColor redColor],
    };
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n操作表标题" attributes:attrs]];
        
    NSMutableAttributedString *message = [NSMutableAttributedString new];
    attrs = @{
        NSFontAttributeName: [UIFont fw_fontOfSize:15],
        NSForegroundColorAttributeName: [UIColor greenColor],
    };
    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"操作表消息" attributes:attrs]];
    
    [self fw_showSheetWithTitle:title
                       message:message
                        cancel:@"取消"
                       actions:@[@"操作1", @"操作2", @"操作3", @"操作4", @"操作5", @"操作6", @"操作7", @"操作8", @"操作9", @"操作10"]
                   actionBlock:^(NSInteger index) {
                       NSLog(@"点击的操作index: %@", @(index));
                   }];
}

- (void)onAlertP
{
    FWWeakifySelf();
    [self fw_showAlertWithTitle:@"高优先级" message:@"警告框消息" cancel:nil cancelBlock:^{
        FWStrongifySelf();
        [self fw_showAlertWithTitle:@"普通优先级" message:@"警告框消息" cancel:nil cancelBlock:^{
            FWStrongifySelf();
            [self fw_showAlertWithTitle:@"低优先级" message:@"警告框消息" cancel:nil cancelBlock:nil];
        }];
    }];
}

- (void)onSheetP
{
    FWWeakifySelf();
    [self fw_showSheetWithTitle:@"高优先级" message:@"操作表消息" cancel:nil cancelBlock:^{
        FWStrongifySelf();
        [self fw_showSheetWithTitle:@"普通优先级" message:@"操作表消息" cancel:nil cancelBlock:^{
            FWStrongifySelf();
            [self fw_showSheetWithTitle:@"低优先级" message:@"操作表消息" cancel:nil cancelBlock:nil];
        }];
    }];
}

- (void)onCloseA
{
    [self fw_showAlertWithTitle:nil message:@"我将在两秒后自动关闭"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [FWNavigator.topPresentedController fw_showAlertWithTitle:nil message:@"我将在一秒后自动关闭"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fw_hideAlert:YES completion:nil];
    });
}

@end
