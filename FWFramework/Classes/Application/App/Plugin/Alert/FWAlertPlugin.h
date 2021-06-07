//
//  FWAlertPlugin.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAlertPlugin

// 弹出框优先级枚举。优先级越高越先显示，同优先级顺序显示
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

// 弹窗插件协议，应用可自定义弹窗实现
@protocol FWAlertPlugin <NSObject>

@required

// 显示弹出框插件方法，默认使用系统UIAlertController
- (void)fwViewController:(UIViewController *)viewController
               showAlert:(UIAlertControllerStyle)style
                   title:(nullable id)title
                 message:(nullable id)message
                  cancel:(nullable id)cancel
                 actions:(nullable NSArray *)actions
             promptCount:(NSInteger)promptCount
             promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
             actionBlock:(nullable void (^)(NSArray<NSString *> *values, NSInteger index))actionBlock
             cancelBlock:(nullable void (^)(void))cancelBlock
             customBlock:(nullable void (^)(id alertController))customBlock
                priority:(FWAlertPriority)priority;

@end

#pragma mark - FWAlertPluginController

/// 弹窗插件控制器协议，使用弹窗插件
@protocol FWAlertPluginController <NSObject>
@required

/**
 *  显示警告框(简单版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题
 *  @param cancelBlock 取消按钮事件
 */
- (void)fwShowAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock;

/**
 *  显示警告框(详细版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 *  @param priority    警告框优先级
 */
- (void)fwShowAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
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
- (void)fwShowConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock;

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
- (void)fwShowConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock
                   cancelBlock:(nullable void (^)(void))cancelBlock
                      priority:(FWAlertPriority)priority;

/**
 *  显示输入框(简单版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param confirmBlock 确认按钮事件，参数为输入值
 */
- (void)fwShowPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock;

/**
 *  显示输入框(详细版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param promptBlock  输入框初始化事件，参数为输入框
 *  @param confirmBlock 确认按钮事件，参数为输入值
 *  @param cancelBlock  取消按钮事件
 *  @param priority     警告框优先级
 */
- (void)fwShowPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptBlock:(nullable void (^)(UITextField *textField))promptBlock
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority;

/**
 *  显示输入框(复杂版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字
 *  @param confirm      确认按钮文字
 *  @param promptCount  输入框数量
 *  @param promptBlock  输入框初始化事件，参数为输入框和索引index
 *  @param confirmBlock 确认按钮事件，参数为输入值数组
 *  @param cancelBlock  取消按钮事件
 *  @param priority     警告框优先级
 */
- (void)fwShowPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 confirmBlock:(nullable void (^)(NSArray<NSString *> *values))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority;

/**
 *  显示操作表(简单版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 */
- (void)fwShowSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock;

/**
 *  显示操作表(详细版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 *  @param priority    操作表优先级
 */
- (void)fwShowSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                    priority:(FWAlertPriority)priority;

/**
 *  显示弹出框(完整版)
 *
 *  @param style       弹出框样式
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题
 *  @param actions     动作按钮标题列表
 *  @param promptCount 输入框数量
 *  @param promptBlock 输入框初始化事件，参数为输入框和索引index
 *  @param actionBlock 动作按钮点击事件，参数为输入值数组和索引index
 *  @param cancelBlock 取消按钮事件
 *  @param customBlock 自定义弹出框事件
 *  @param priority    操作表优先级
 */
- (void)fwShowAlertWithStyle:(UIAlertControllerStyle)style
                       title:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 actionBlock:(nullable void (^)(NSArray<NSString *> *values, NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id alertController))customBlock
                    priority:(FWAlertPriority)priority;

@end

/// UIViewController使用弹窗插件，全局可使用UIWindow.fwMainWindow.fwTopPresentedController
@interface UIViewController (FWAlertPluginController) <FWAlertPluginController>

@end

/// UIView使用弹窗插件，内部使用UIView.fwViewController
@interface UIView (FWAlertPluginController) <FWAlertPluginController>

@end

NS_ASSUME_NONNULL_END
