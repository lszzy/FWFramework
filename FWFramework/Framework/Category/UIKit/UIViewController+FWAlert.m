//
//  UIViewController+FWAlert.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWAlert.h"
#import "UIAlertController+FWFramework.h"
#import "NSObject+FWRuntime.h"
#import <objc/runtime.h>

#pragma mark - UIAlertController+FWPriority

// UIAlertController支持优先级
@interface UIAlertController (FWPriority)

// 启用弹出框优先级，未启用不生效
@property (nonatomic, assign) BOOL fwPriorityEnabled;
// 设置弹出优先级，默认Normal
@property (nonatomic, assign) FWAlertPriority fwPriority;
// 设置父弹出框，弱引用
@property (nonatomic, weak) UIViewController *fwParentController;
// 隐藏状态。0正常隐藏并移除队列；1立即隐藏并保留队列；2立即隐藏执行状态(解决弹出框还未显示完成时调用dismiss触发警告问题)。默认0
@property (nonatomic, assign) NSInteger fwDismissState;
// 在指定控制器中显示弹出框
- (void)fwPresentInViewController:(UIViewController *)viewController;

@end

@implementation UIAlertController (FWPriority)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self fwSwizzleInstanceMethod:@selector(viewDidAppear:) with:@selector(fwInnerAlertViewDidAppear:)];
        [self fwSwizzleInstanceMethod:@selector(viewDidDisappear:) with:@selector(fwInnerAlertViewDidDisappear:)];
    });
}

- (void)fwInnerAlertViewDidAppear:(BOOL)animated
{
    [self fwInnerAlertViewDidAppear:animated];
    if (!self.fwPriorityEnabled) return;
    
    // 替换弹出框时显示完成立即隐藏
    if (self.fwDismissState == 1) {
        self.fwDismissState = 2;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)fwInnerAlertViewDidDisappear:(BOOL)animated
{
    [self fwInnerAlertViewDidDisappear:animated];
    if (!self.fwPriorityEnabled) return;
    
    // 立即隐藏不移除队列，正常隐藏移除队列
    NSMutableArray *alertControllers = [self fwInnerAlertControllers:NO];
    if (self.fwDismissState > 0) {
        self.fwDismissState = 0;
    } else {
        [alertControllers removeObject:self];
    }
    
    // 按优先级显示下一个弹出框
    if (alertControllers.count > 0) {
        [self.fwParentController presentViewController:[alertControllers firstObject] animated:YES completion:nil];
    }
}

- (void)fwPresentInViewController:(UIViewController *)viewController
{
    if (!self.fwPriorityEnabled) return;
    
    // 加入队列并按优先级排序
    self.fwParentController = viewController;
    NSMutableArray *alertControllers = [self fwInnerAlertControllers:YES];
    if (![alertControllers containsObject:self]) {
        [alertControllers addObject:self];
    }
    [alertControllers sortUsingComparator:^NSComparisonResult(UIAlertController *obj1, UIAlertController *obj2) {
        return [@(obj2.fwPriority) compare:@(obj1.fwPriority)];
    }];
    // 独占优先级只显示一个
    UIAlertController *firstController = [alertControllers firstObject];
    if (firstController.fwPriority == FWAlertPrioritySuper) {
        [alertControllers removeAllObjects];
        [alertControllers addObject:firstController];
    }
    
    if (viewController.presentedViewController && [viewController.presentedViewController isKindOfClass:[UIAlertController class]]) {
        UIAlertController *currentController = (UIAlertController *)viewController.presentedViewController;
        if (currentController != firstController) {
            // 替换弹出框时显示完成立即隐藏。如果已经显示，直接隐藏；如果未显示完，等待显示完成立即隐藏。解决弹出框还未显示完成时调用dismiss触发警告问题
            currentController.fwDismissState = 1;
            if (currentController.isViewLoaded && currentController.view.window && currentController.fwDismissState == 1) {
                currentController.fwDismissState = 2;
                [currentController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [viewController presentViewController:firstController animated:YES completion:nil];
    }
}

- (NSMutableArray *)fwInnerAlertControllers:(BOOL)autoCreate
{
    // parentController强引用弹出框数组，内部使用弱引用
    NSMutableArray *array = objc_getAssociatedObject(self.fwParentController, _cmd);
    if (!array && autoCreate) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self.fwParentController, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

#pragma mark - Accessor

- (BOOL)fwPriorityEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwPriorityEnabled)) boolValue];
}

- (void)setFwPriorityEnabled:(BOOL)fwPriorityEnabled
{
    objc_setAssociatedObject(self, @selector(fwPriorityEnabled), @(fwPriorityEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAlertPriority)fwPriority
{
    return [objc_getAssociatedObject(self, @selector(fwPriority)) integerValue];
}

- (void)setFwPriority:(FWAlertPriority)fwPriority
{
    objc_setAssociatedObject(self, @selector(fwPriority), @(fwPriority), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)fwParentController
{
    return objc_getAssociatedObject(self, @selector(fwParentController));
}

- (void)setFwParentController:(UIViewController *)fwParentController
{
    objc_setAssociatedObject(self, @selector(fwParentController), fwParentController, OBJC_ASSOCIATION_ASSIGN);
}

- (NSInteger)fwDismissState
{
    return [objc_getAssociatedObject(self, @selector(fwDismissState)) integerValue];
}

- (void)setFwDismissState:(NSInteger)fwDismissState
{
    objc_setAssociatedObject(self, @selector(fwDismissState), @(fwDismissState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - UIViewController+FWAlert

@implementation UIViewController (FWAlert)

#pragma mark - Alert

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
    // 初始化Alert
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *preferredAction = nil;
    
    // 添加动作按钮
    NSInteger actionsCount = actions ? actions.count : 0;
    if (actionsCount > 0) {
        for (NSInteger index = 0; index < actionsCount; index++) {
            UIAlertAction *alertAction = [UIAlertAction fwActionWithObject:[actions objectAtIndex:index] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (actionBlock) {
                    actionBlock(index);
                }
            }];
            if (alertAction.fwIsPreferred) {
                preferredAction = alertAction;
            }
            [alertController addAction:alertAction];
        }
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fwActionWithObject:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (cancelBlock) {
                cancelBlock();
            }
        }];
        if (cancelAction.fwIsPreferred) {
            preferredAction = cancelAction;
        }
        [alertController addAction:cancelAction];
    }
    
    // 显示Alert
    alertController.fwPriorityEnabled = YES;
    alertController.fwPriority = priority;
    if (@available(iOS 9.0, *)) {
        if (preferredAction != nil) {
            alertController.preferredAction = preferredAction;
        }
    }
    [alertController fwPresentInViewController:self];
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
                       if (confirmBlock) {
                           confirmBlock();
                       }
                   }
                   cancelBlock:cancelBlock
                      priority:priority];
}

- (void)fwShowPromptWithTitle:(id)title
                      message:(id)message
                       cancel:(id)cancel
                      confirm:(id)confirm
                 confirmBlock:(void (^)(NSString *text))confirmBlock
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
                  promptBlock:(void (^)(UITextField *textField))promptBlock
                 confirmBlock:(void (^)(NSString *text))confirmBlock
                  cancelBlock:(void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority
{
    [self fwShowPromptWithTitle:title
                        message:message
                         cancel:cancel
                        confirm:confirm
                    promptCount:1
                    promptBlock:^(UITextField *textField, NSInteger index) {
                        if (promptBlock) {
                            promptBlock(textField);
                        }
                    }
                   confirmBlock:^(NSArray<NSString *> *texts) {
                        if (confirmBlock) {
                            confirmBlock(texts.firstObject);
                        }
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
    // 初始化Alert
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *preferredAction = nil;
    
    // 添加输入框并初始化输入框
    for (NSInteger index = 0; index < promptCount; index++) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (promptBlock) {
                promptBlock(textField, index);
            }
        }];
    }
    
    // 添加确定按钮
    if (confirm != nil) {
        UIAlertAction *alertAction = [UIAlertAction fwActionWithObject:confirm style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (confirmBlock) {
                // 回调输入框的值
                NSMutableArray *texts = [NSMutableArray new];
                for (NSInteger index = 0; index < promptCount; index++) {
                    UITextField *textField = alertController.textFields[index];
                    [texts addObject:textField.text ?: @""];
                }
                confirmBlock(texts);
            }
        }];
        if (alertAction.fwIsPreferred) {
            preferredAction = alertAction;
        }
        [alertController addAction:alertAction];
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fwActionWithObject:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (cancelBlock) {
                cancelBlock();
            }
        }];
        if (cancelAction.fwIsPreferred) {
            preferredAction = cancelAction;
        }
        [alertController addAction:cancelAction];
    }
    
    // 显示Alert
    alertController.fwPriorityEnabled = YES;
    alertController.fwPriority = priority;
    if (@available(iOS 9.0, *)) {
        if (preferredAction != nil) {
            alertController.preferredAction = preferredAction;
        }
    }
    [alertController fwPresentInViewController:self];
}

#pragma mark - Sheet

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
    // 初始化ActionSheet
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *preferredAction = nil;
    
    // 添加动作按钮
    NSInteger actionsCount = actions ? actions.count : 0;
    if (actionsCount > 0) {
        for (NSInteger index = 0; index < actionsCount; index++) {
            UIAlertAction *alertAction = [UIAlertAction fwActionWithObject:[actions objectAtIndex:index] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                if (actionBlock) {
                    actionBlock(index);
                }
            }];
            if (alertAction.fwIsPreferred) {
                preferredAction = alertAction;
            }
            [alertController addAction:alertAction];
        }
    }
    
    // 添加取消按钮
    if (cancel != nil) {
        UIAlertAction *cancelAction = [UIAlertAction fwActionWithObject:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (cancelBlock) {
                cancelBlock();
            }
        }];
        if (cancelAction.fwIsPreferred) {
            preferredAction = cancelAction;
        }
        [alertController addAction:cancelAction];
    }
    
    // 显示ActionSheet
    alertController.fwPriorityEnabled = YES;
    alertController.fwPriority = priority;
    if (@available(iOS 9.0, *)) {
        if (preferredAction != nil) {
            alertController.preferredAction = preferredAction;
        }
    }
    [alertController fwPresentInViewController:self];
}

@end
