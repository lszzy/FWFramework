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
#import "FWPlugin.h"
#import "FWProxy.h"
#import <objc/runtime.h>

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

#pragma mark - Style

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
    id<FWAlertPlugin> alertPlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWAlertPlugin)];
    if (alertPlugin && [alertPlugin respondsToSelector:@selector(fwViewController:showAlert:title:message:cancel:actions:promptCount:promptBlock:actionBlock:cancelBlock:customBlock:priority:)]) {
        [alertPlugin fwViewController:self showAlert:style title:title message:message cancel:cancel actions:actions promptCount:promptCount promptBlock:promptBlock actionBlock:actionBlock cancelBlock:cancelBlock customBlock:customBlock priority:priority];
        return;
    }
    
    // 初始化Alert
    UIAlertController *alertController = [UIAlertController fwAlertControllerWithTitle:title
                                                                               message:message
                                                                        preferredStyle:style];
    
    // 添加输入框并初始化输入框
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

#pragma mark - UIViewController+FWAlertPriority

// 优先级隐藏状态：0正常隐藏并移除队列；1立即隐藏并保留队列；2立即隐藏执行状态(解决弹出框还未显示完成时调用dismiss触发警告问题)。默认0
@implementation UIViewController (FWAlertPriority)

#pragma mark - Accessor

- (BOOL)fwAlertPriorityEnabled
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriorityEnabled)) boolValue];
}

- (void)setFwAlertPriorityEnabled:(BOOL)fwAlertPriorityEnabled
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityEnabled), @(fwAlertPriorityEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FWAlertPriority)fwAlertPriority
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriority)) integerValue];
}

- (void)setFwAlertPriority:(FWAlertPriority)fwAlertPriority
{
    objc_setAssociatedObject(self, @selector(fwAlertPriority), @(fwAlertPriority), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)fwAlertPriorityParentController
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwAlertPriorityParentController));
    return value.object;
}

- (void)setFwAlertPriorityParentController:(UIViewController *)fwAlertPriorityParentController
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityParentController), [[FWWeakObject alloc] initWithObject:fwAlertPriorityParentController], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)fwAlertPriorityDismissState
{
    return [objc_getAssociatedObject(self, @selector(fwAlertPriorityDismissState)) integerValue];
}

- (void)setFwAlertPriorityDismissState:(NSInteger)fwAlertPriorityDismissState
{
    objc_setAssociatedObject(self, @selector(fwAlertPriorityDismissState), @(fwAlertPriorityDismissState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Hook

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
    if (!self.fwAlertPriorityEnabled) return;
    
    // 替换弹出框时显示完成立即隐藏
    if (self.fwAlertPriorityDismissState == 1) {
        self.fwAlertPriorityDismissState = 2;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)fwInnerAlertViewDidDisappear:(BOOL)animated
{
    [self fwInnerAlertViewDidDisappear:animated];
    if (!self.fwAlertPriorityEnabled) return;
    
    // 立即隐藏不移除队列，正常隐藏移除队列
    NSMutableArray *alertControllers = [self fwInnerAlertPriorityControllers:NO];
    if (self.fwAlertPriorityDismissState > 0) {
        self.fwAlertPriorityDismissState = 0;
    } else {
        [alertControllers removeObject:self];
    }
    
    // 按优先级显示下一个弹出框
    if (alertControllers.count > 0) {
        [self.fwAlertPriorityParentController presentViewController:[alertControllers firstObject] animated:YES completion:nil];
    }
}

- (void)fwAlertPriorityPresentIn:(UIViewController *)viewController
{
    if (!self.fwAlertPriorityEnabled) return;
    
    // 加入队列并按优先级排序
    self.fwAlertPriorityParentController = viewController;
    NSMutableArray *alertControllers = [self fwInnerAlertPriorityControllers:YES];
    if (![alertControllers containsObject:self]) {
        [alertControllers addObject:self];
    }
    [alertControllers sortUsingComparator:^NSComparisonResult(UIViewController *obj1, UIViewController *obj2) {
        return [@(obj2.fwAlertPriority) compare:@(obj1.fwAlertPriority)];
    }];
    // 独占优先级只显示一个
    UIAlertController *firstController = [alertControllers firstObject];
    if (firstController.fwAlertPriority == FWAlertPrioritySuper) {
        [alertControllers removeAllObjects];
        [alertControllers addObject:firstController];
    }
    
    UIViewController *currentController = viewController.presentedViewController;
    if (currentController && currentController.fwAlertPriorityEnabled) {
        if (currentController != firstController) {
            // 替换弹出框时显示完成立即隐藏。如果已经显示，直接隐藏；如果未显示完，等待显示完成立即隐藏。解决弹出框还未显示完成时调用dismiss触发警告问题
            currentController.fwAlertPriorityDismissState = 1;
            if (currentController.isViewLoaded && currentController.view.window && currentController.fwAlertPriorityDismissState == 1) {
                currentController.fwAlertPriorityDismissState = 2;
                [currentController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [viewController presentViewController:firstController animated:YES completion:nil];
    }
}

- (NSMutableArray *)fwInnerAlertPriorityControllers:(BOOL)autoCreate
{
    // parentController强引用弹出框数组，内部使用弱引用
    NSMutableArray *array = objc_getAssociatedObject(self.fwAlertPriorityParentController, _cmd);
    if (!array && autoCreate) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self.fwAlertPriorityParentController, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

@end
