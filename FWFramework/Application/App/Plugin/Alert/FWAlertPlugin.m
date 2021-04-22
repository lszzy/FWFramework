//
//  FWAlertPlugin.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAlertPlugin.h"
#import "FWAlertPluginImpl.h"
#import "FWPlugin.h"
#import "FWToolkit.h"

#pragma mark - FWAlertPluginController

@implementation UIViewController (FWAlertPluginController)

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                 cancelBlock:(void (^)(void))cancelBlock
{
    [self fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                       actions:nil
                   actionBlock:nil
                   cancelBlock:cancelBlock
                      priority:FWAlertPriorityNormal];
}

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleAlert
                         title:title
                       message:message
                        cancel:cancel
                       actions:actions
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
{
    [self fwShowConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock
                     cancelBlock:nil
                        priority:FWAlertPriorityNormal];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
                   cancelBlock:(void (^)(void))cancelBlock
                      priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                       actions:[NSArray arrayWithObjects:confirm, nil]
                   actionBlock:^(NSInteger index) {
                       if (confirmBlock) confirmBlock();
                   }
                   cancelBlock:cancelBlock
                      priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *))confirmBlock
{
    [self fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptBlock:nil
                   confirmBlock:confirmBlock
                    cancelBlock:nil
                       priority:FWAlertPriorityNormal];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptBlock:(void (^)(UITextField *))promptBlock
                 confirmBlock:(void (^)(NSString *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    [self fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptCount:1
                    promptBlock:^(UITextField *textField, NSInteger index) {
                        if (promptBlock) promptBlock(textField);
                    }
                   confirmBlock:^(NSArray<NSString *> *values) {
                        if (confirmBlock) confirmBlock(values.firstObject);
                    }
                    cancelBlock:cancelBlock
                       priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 confirmBlock:(void (^)(NSArray<NSString *> *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleAlert
                         title:title
                       message:message
                        cancel:cancel
                       actions:(confirm ? @[confirm] : nil)
                   promptCount:promptCount
                   promptBlock:promptBlock
                   actionBlock:^(NSArray<NSString *> *values, NSInteger index) {
                       if (confirmBlock) confirmBlock(values);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
{
    [self fwShowSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock
                   cancelBlock:nil
                      priority:FWAlertPriorityNormal];
}

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    [self fwShowAlertWithStyle:UIAlertControllerStyleActionSheet
                         title:title
                       message:message
                        cancel:cancel
                       actions:actions
                   promptCount:0
                   promptBlock:nil
                   actionBlock:^(NSArray<NSString *> * _Nonnull values, NSInteger index) {
                       if (actionBlock) actionBlock(index);
                   }
                   cancelBlock:cancelBlock
                   customBlock:nil
                      priority:priority];
}

- (void)fwShowAlertWithStyle:(UIAlertControllerStyle)style
                       title:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
                    priority:(FWAlertPriority)priority
{
    // 优先调用插件
    id<FWAlertPlugin> alertPlugin = [FWPluginManager loadPlugin:@protocol(FWAlertPlugin)];
    if (alertPlugin && [alertPlugin respondsToSelector:@selector(fwViewController:showAlert:title:message:cancel:actions:promptCount:promptBlock:actionBlock:cancelBlock:customBlock:priority:)]) {
        [alertPlugin fwViewController:self showAlert:style title:title message:message cancel:cancel actions:actions promptCount:promptCount promptBlock:promptBlock actionBlock:actionBlock cancelBlock:cancelBlock customBlock:customBlock priority:priority];
        return;
    }
    
    // 初始化Alert
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:style];
    
    // 添加输入框
    for (NSInteger promptIndex = 0; promptIndex < promptCount; promptIndex++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) promptBlock(textField, promptIndex);
        }];
    }
    
    // 添加动作按钮
    for (NSInteger actionIndex = 0; actionIndex < actions.count; actionIndex++) {
        UIAlertAction *alertAction = [UIAlertAction fwActionWithObject:actions[actionIndex] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (actionBlock) {
                NSMutableArray *values = [NSMutableArray new];
                for (NSInteger fieldIndex = 0; fieldIndex < promptCount; fieldIndex++) {
                    UITextField *textField = alertController.textFields[fieldIndex];
                    [values addObject:textField.text ?: @""];
                }
                actionBlock(values.copy, actionIndex);
            }
        }];
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fwActionWithObject:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (cancelBlock) cancelBlock();
        }];
        [alertController addAction:cancelAction];
    }
    
    // 添加首选按钮
    if (FWAlertAppearance.appearance.preferredActionBlock && alertController.actions.count > 0) {
        UIAlertAction *preferredAction = FWAlertAppearance.appearance.preferredActionBlock(alertController);
        if (preferredAction) {
            if (@available(iOS 9.0, *)) {
                alertController.preferredAction = preferredAction;
            }
        }
    }
    
    // 自定义Alert
    if (customBlock) {
        customBlock(alertController);
    }
    
    // 显示Alert
    alertController.fwAlertPriorityEnabled = YES;
    alertController.fwAlertPriority = priority;
    [alertController fwAlertPriorityPresentIn:self];
}

@end

@implementation UIView (FWAlertPluginController)

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                 cancelBlock:(void (^)(void))cancelBlock
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                   cancelBlock:cancelBlock];
}

- (void)fwShowAlertWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowAlertWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock
                      priority:priority];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock];
}

- (void)fwShowConfirmWithTitle:(id)title
                       message:(id)message
                        cancel:(id)cancel
                       confirm:(id)confirm
                  confirmBlock:(void (^)(void))confirmBlock
                   cancelBlock:(void (^)(void))cancelBlock
                      priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowConfirmWithTitle:title
                         message:message
                          cancel:cancel
                         confirm:confirm
                    confirmBlock:confirmBlock
                     cancelBlock:cancelBlock
                        priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *))confirmBlock
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                   confirmBlock:confirmBlock];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptBlock:(void (^)(UITextField *))promptBlock
                 confirmBlock:(void (^)(NSString *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptBlock:promptBlock
                   confirmBlock:confirmBlock
                    cancelBlock:cancelBlock
                       priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 confirmBlock:(void (^)(NSArray<NSString *> *))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptCount:promptCount
                    promptBlock:promptBlock
                   confirmBlock:confirmBlock
                    cancelBlock:cancelBlock
                       priority:priority];
}

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock];
}

- (void)fwShowSheetWithTitle:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 actionBlock:(void (^)(NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowSheetWithTitle:title
                       message:message
                        cancel:cancel
                       actions:actions
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock
                      priority:priority];
}

- (void)fwShowAlertWithStyle:(UIAlertControllerStyle)style
                       title:(id)title
                     message:(id)message
                      cancel:(id)cancel
                     actions:(NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(void (^)(UITextField *, NSInteger))promptBlock
                 actionBlock:(void (^)(NSArray<NSString *> *, NSInteger))actionBlock
                 cancelBlock:(void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id))customBlock
                    priority:(FWAlertPriority)priority
{
    UIViewController *ctrl = self.fwViewController;
    [ctrl fwShowAlertWithStyle:style
                         title:title
                       message:message
                        cancel:cancel
                       actions:actions
                   promptCount:promptCount
                   promptBlock:promptBlock
                   actionBlock:actionBlock
                   cancelBlock:cancelBlock
                   customBlock:customBlock
                      priority:priority];
}

@end
