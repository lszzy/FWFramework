//
//  UIViewController+FWAlert.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIViewController+FWAlert.h"
#import <objc/runtime.h>

#pragma mark - FWAlertController

// 弹出框控制器，支持优先级
@interface FWAlertController : UIAlertController

// 弹出优先级
@property (nonatomic, assign) FWAlertPriority priority;

// 父弹出框，弱引用
@property (nonatomic, weak) UIViewController *parentController;

// 隐藏状态。0正常隐藏并移除队列；1立即隐藏并保留队列；2立即隐藏执行状态(解决弹出框还未显示完成时调用dismiss触发警告问题)。默认0
@property (nonatomic, assign) NSInteger dismissState;

// 在指定控制器中显示弹出框
- (void)presentInViewController:(UIViewController *)viewController;

@end

@implementation FWAlertController

- (void)dealloc
{
    // 打印被释放日志，防止内存泄露
    NSLog(@"%@ did dealloc", NSStringFromClass(self.class));
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // 替换弹出框时显示完成立即隐藏
    if (self.dismissState == 1) {
        self.dismissState = 2;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // 立即隐藏不移除队列，正常隐藏移除队列
    NSMutableArray *alertControllers = [self alertControllers:NO];
    if (self.dismissState > 0) {
        self.dismissState = 0;
    } else {
        [alertControllers removeObject:self];
    }
    
    // 按优先级显示下一个弹出框
    if (alertControllers.count > 0) {
        [self.parentController presentViewController:[alertControllers firstObject] animated:YES completion:nil];
    }
}

- (void)presentInViewController:(UIViewController *)viewController
{
    self.parentController = viewController;
    
    // 加入队列并按优先级排序
    NSMutableArray *alertControllers = [self alertControllers:YES];
    if (![alertControllers containsObject:self]) {
        [alertControllers addObject:self];
    }
    [alertControllers sortUsingComparator:^NSComparisonResult(FWAlertController *obj1, FWAlertController *obj2) {
        return [@(obj2.priority) compare:@(obj1.priority)];
    }];
    // 独占优先级只显示一个
    FWAlertController *firstController = [alertControllers firstObject];
    if (firstController.priority == FWAlertPrioritySuper) {
        [alertControllers removeAllObjects];
        [alertControllers addObject:firstController];
    }
    
    if (viewController.presentedViewController && [viewController.presentedViewController isKindOfClass:[FWAlertController class]]) {
        FWAlertController *currentController = (FWAlertController *)viewController.presentedViewController;
        if (currentController != firstController) {
            // 替换弹出框时显示完成立即隐藏。如果已经显示，直接隐藏；如果未显示完，等待显示完成立即隐藏。解决弹出框还未显示完成时调用dismiss触发警告问题
            currentController.dismissState = 1;
            if (currentController.isViewLoaded && currentController.view.window && currentController.dismissState == 1) {
                currentController.dismissState = 2;
                [currentController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else {
        [viewController presentViewController:firstController animated:YES completion:nil];
    }
}

- (NSMutableArray *)alertControllers:(BOOL)create
{
    // parentController强引用弹出框数组，内部使用弱引用
    NSMutableArray *array = objc_getAssociatedObject(self.parentController, _cmd);
    if (!array && create) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self.parentController, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

@end

#pragma mark - UIViewController+FWAlert

// 视图控制器系统弹出框分类，支持优先级
@implementation UIViewController (FWAlert)

#pragma mark - Alert

- (UIAlertController *)fwShowAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                     cancel:(NSString *)cancel
                                cancelBlock:(void (^)(void))cancelBlock
{
    return [self fwShowAlertWithTitle:title
                              message:message
                               cancel:cancel
                              actions:nil
                          actionBlock:nil
                          cancelBlock:cancelBlock
                             priority:FWAlertPriorityNormal];
}

- (UIAlertController *)fwShowAlertWithTitle:(NSString *)title
                                    message:(NSString *)message
                                     cancel:(NSString *)cancel
                                    actions:(NSArray<NSString *> *)actions
                                actionBlock:(void (^)(NSInteger))actionBlock
                                cancelBlock:(void (^)(void))cancelBlock
                                   priority:(FWAlertPriority)priority
{
    // 初始化Alert
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加取消按钮
    if (cancel.length > 0) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancel
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 if (cancelBlock) {
                                                                     cancelBlock();
                                                                 }
                                                             }];
        [alertController addAction:cancelAction];
    }
    
    // 添加动作按钮，支持样式
    NSInteger actionsCount = actions ? actions.count : 0;
    if (actionsCount > 0) {
        for (NSInteger index = 0; index < actionsCount; index++) {
            // 解析标题样式，格式@"标题:style"
            NSString *actionTitle = [actions objectAtIndex:index];
            UIAlertActionStyle actionStyle = UIAlertActionStyleDefault;
            if ([actionTitle rangeOfString:@":"].location != NSNotFound) {
                NSArray *titleComps = [actionTitle componentsSeparatedByString:@":"];
                actionTitle = [titleComps firstObject];
                actionStyle = (UIAlertActionStyle)[[titleComps lastObject] integerValue];
            }
            
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle
                                                                  style:actionStyle
                                                                handler:^(UIAlertAction *action) {
                                                                    if (actionBlock) {
                                                                        actionBlock(index);
                                                                    }
                                                                }];
            [alertController addAction:alertAction];
        }
    }
    
    // 显示Alert
    alertController.priority = priority;
    [alertController presentInViewController:self];
    return alertController;
}

- (UIAlertController *)fwShowConfirmWithTitle:(NSString *)title
                                      message:(NSString *)message
                                       cancel:(NSString *)cancel
                                      confirm:(NSString *)confirm
                                 confirmBlock:(void (^)(void))confirmBlock
{
    return [self fwShowConfirmWithTitle:title
                                message:message
                                 cancel:cancel
                                confirm:confirm
                           confirmBlock:confirmBlock
                            cancelBlock:nil
                               priority:FWAlertPriorityNormal];
}

- (UIAlertController *)fwShowConfirmWithTitle:(NSString *)title
                                      message:(NSString *)message
                                       cancel:(NSString *)cancel
                                      confirm:(NSString *)confirm
                                 confirmBlock:(void (^)(void))confirmBlock
                                  cancelBlock:(void (^)(void))cancelBlock
                                     priority:(FWAlertPriority)priority
{
    return [self fwShowAlertWithTitle:title
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

- (UIAlertController *)fwShowPromptWithTitle:(NSString *)title
                                     message:(NSString *)message
                                      cancel:(NSString *)cancel
                                     confirm:(NSString *)confirm
                                confirmBlock:(void (^)(NSString *text))confirmBlock
{
    return [self fwShowPromptWithTitle:title
                               message:message
                                cancel:cancel
                               confirm:confirm
                           promptBlock:nil
                          confirmBlock:confirmBlock
                           cancelBlock:nil
                              priority:FWAlertPriorityNormal];
}

- (UIAlertController *)fwShowPromptWithTitle:(NSString *)title
                                     message:(NSString *)message
                                      cancel:(NSString *)cancel
                                     confirm:(NSString *)confirm
                                 promptBlock:(void (^)(UITextField *textField))promptBlock
                                confirmBlock:(void (^)(NSString *text))confirmBlock
                                 cancelBlock:(void (^)(void))cancelBlock
                                    priority:(FWAlertPriority)priority
{
    // 初始化Alert
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加输入框并初始化输入框
    [alertController addTextFieldWithConfigurationHandler:promptBlock];
    
    // 添加取消按钮
    if (cancel.length > 0) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancel
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 if (cancelBlock) {
                                                                     cancelBlock();
                                                                 }
                                                             }];
        [alertController addAction:cancelAction];
    }
    
    // 添加确定按钮，支持样式
    if (confirm.length > 0) {
        // 解析标题样式，格式@"标题:style"
        NSString *actionTitle = confirm;
        UIAlertActionStyle actionStyle = UIAlertActionStyleDefault;
        if ([actionTitle rangeOfString:@":"].location != NSNotFound) {
            NSArray *titleComps = [actionTitle componentsSeparatedByString:@":"];
            actionTitle = [titleComps firstObject];
            actionStyle = (UIAlertActionStyle)[[titleComps lastObject] integerValue];
        }
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle
                                                              style:actionStyle
                                                            handler:^(UIAlertAction *action) {
                                                                if (confirmBlock) {
                                                                    // 回调输入框的值
                                                                    confirmBlock([alertController.textFields objectAtIndex:0].text);
                                                                }
                                                            }];
        [alertController addAction:alertAction];
    }
    
    // 显示Alert
    alertController.priority = priority;
    [alertController presentInViewController:self];
    return alertController;
}

#pragma mark - Sheet

- (UIAlertController *)fwShowSheetWithTitle:(NSString *)title
                                     cancel:(NSString *)cancel
                                    actions:(NSArray<NSString *> *)actions
                                actionBlock:(void (^)(NSInteger))actionBlock
{
    return [self fwShowSheetWithTitle:title
                               cancel:cancel
                              actions:actions
                          actionBlock:actionBlock
                          cancelBlock:nil
                             priority:FWAlertPriorityNormal];
}

- (UIAlertController *)fwShowSheetWithTitle:(NSString *)title
                                     cancel:(NSString *)cancel
                                    actions:(NSArray<NSString *> *)actions
                                actionBlock:(void (^)(NSInteger))actionBlock
                                cancelBlock:(void (^)(void))cancelBlock
                                   priority:(FWAlertPriority)priority
{
    // 初始化ActionSheet
    FWAlertController *alertController = [FWAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 添加动作按钮，支持样式
    NSInteger actionsCount = actions ? actions.count : 0;
    if (actionsCount > 0) {
        for (NSInteger index = 0; index < actionsCount; index++) {
            // 解析样式，格式@"标题:style"
            NSString *actionTitle = [actions objectAtIndex:index];
            UIAlertActionStyle actionStyle = UIAlertActionStyleDefault;
            if ([actionTitle rangeOfString:@":"].location != NSNotFound) {
                NSArray *titleComps = [actionTitle componentsSeparatedByString:@":"];
                actionTitle = [titleComps objectAtIndex:0];
                actionStyle = (UIAlertActionStyle)[[titleComps objectAtIndex:1] integerValue];
            }
            
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle
                                                                  style:actionStyle
                                                                handler:^(UIAlertAction *action) {
                                                                    if (actionBlock) {
                                                                        actionBlock(index);
                                                                    }
                                                                }];
            [alertController addAction:alertAction];
        }
    }
    
    // 添加取消按钮
    if (cancel.length > 0) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancel
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action) {
                                                                 if (cancelBlock) {
                                                                     cancelBlock();
                                                                 }
                                                             }];
        [alertController addAction:cancelAction];
    }
    
    // 显示ActionSheet
    alertController.priority = priority;
    [alertController presentInViewController:self];
    return alertController;
}

@end
