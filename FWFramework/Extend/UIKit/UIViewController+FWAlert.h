//
//  UIViewController+FWAlert.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

// 弹出框优先级。优先级越高越先显示，同优先级顺序显示
typedef NS_ENUM(NSInteger, FWAlertPriority) {
    // 最低优先级
    FWAlertPriorityLow = -1,
    // 普通优先级，默认
    FWAlertPriorityNormal,
    // 高优先级
    FWAlertPriorityHigh,
    // 独占优先级，只显示该弹出框，用于强制更新等
    FWAlertPrioritySuper,
};

// 视图控制器系统弹出框分类，支持优先级
@interface UIViewController (FWAlert)

#pragma mark - Alert

/**
 *  显示警告框(简单版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题
 *  @param cancelBlock 取消按钮事件
 */
- (void)fwShowAlertWithTitle:(NSString *)title
                     message:(NSString *)message
                      cancel:(NSString *)cancel
                 cancelBlock:(void (^)())cancelBlock;

/**
 *  显示警告框(详细版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表，iOS8支持UIAlertActionStyle样式，示例:@"确定:2"
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 *  @param priority    警告框优先级
 */
- (void)fwShowAlertWithTitle:(NSString *)title
                     message:(NSString *)message
                      cancel:(NSString *)cancel
                     actions:(NSArray<NSString *> *)actions
                 actionBlock:(void (^)(NSInteger index))actionBlock
                 cancelBlock:(void (^)())cancelBlock
                    priority:(FWAlertPriority)priority;

/**
 *  显示确认框(简单版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param confirmBlock 确认按钮事件
 */
- (void)fwShowConfirmWithTitle:(NSString *)title
                       message:(NSString *)message
                        cancel:(NSString *)cancel
                       confirm:(NSString *)confirm
                  confirmBlock:(void (^)())confirmBlock;

/**
 *  显示确认框(详细版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param confirmBlock 确认按钮事件
 *  @param cancelBlock  取消按钮事件
 *  @param priority     警告框优先级
 */
- (void)fwShowConfirmWithTitle:(NSString *)title
                       message:(NSString *)message
                        cancel:(NSString *)cancel
                       confirm:(NSString *)confirm
                  confirmBlock:(void (^)())confirmBlock
                   cancelBlock:(void (^)())cancelBlock
                      priority:(FWAlertPriority)priority;

/**
 *  显示输入框(简单版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param confirmBlock 确认按钮事件
 */
- (void)fwShowPromptWithTitle:(NSString *)title
                      message:(NSString *)message
                       cancel:(NSString *)cancel
                      confirm:(NSString *)confirm
                 confirmBlock:(void (^)(NSString *text))confirmBlock;

/**
 *  显示输入框(详细版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param promptBlock  输入框初始化事件
 *  @param confirmBlock 确认按钮事件
 *  @param cancelBlock  取消按钮事件
 *  @param priority     警告框优先级
 */
- (void)fwShowPromptWithTitle:(NSString *)title
                      message:(NSString *)message
                       cancel:(NSString *)cancel
                      confirm:(NSString *)confirm
                  promptBlock:(void (^)(UITextField *textField))promptBlock
                 confirmBlock:(void (^)(NSString *text))confirmBlock
                  cancelBlock:(void (^)())cancelBlock
                     priority:(FWAlertPriority)priority;

#pragma mark - Sheet

/**
 *  显示操作表(简单版)
 *
 *  @param title       操作表标题
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表，iOS8支持UIAlertActionStyle样式，示例:@"确定:2"
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 */
- (void)fwShowSheetWithTitle:(NSString *)title
                      cancel:(NSString *)cancel
                     actions:(NSArray<NSString *> *)actions
                 actionBlock:(void (^)(NSInteger index))actionBlock;

/**
 *  显示操作表(详细版)
 *
 *  @param title       操作表标题
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表，iOS8支持UIAlertActionStyle样式，示例:@"确定:2"
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 *  @param priority    操作表优先级
 */
- (void)fwShowSheetWithTitle:(NSString *)title
                      cancel:(NSString *)cancel
                     actions:(NSArray<NSString *> *)actions
                 actionBlock:(void (^)(NSInteger index))actionBlock
                 cancelBlock:(void (^)())cancelBlock
                    priority:(FWAlertPriority)priority;

@end
