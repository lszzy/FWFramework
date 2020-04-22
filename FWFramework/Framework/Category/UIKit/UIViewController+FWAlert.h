//
//  UIViewController+FWAlert.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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

// 弹出框优先级协议。控制器必须声明该协议后优先级才会生效
@protocol FWAlertPriorityProtocol <NSObject>

@optional

// 设置弹出框优先级，默认普通
@property (nonatomic, assign) FWAlertPriority *fwAlertPriority;

// 根据优先级在视图控制器中显示弹出框，必须调用此方法才生效
- (void)fwAlertPresentInViewController:(UIViewController *)viewController;

@end

#pragma mark - UIViewController+FWAlert

// 视图控制器系统弹出框分类，支持优先级
@interface UIViewController (FWAlert)

#pragma mark - Alert

/**
 *  显示警告框(简单版)
 *
 *  @param title       警告框标题，支持NSAttributedString
 *  @param message     警告框消息，支持NSAttributedString
 *  @param cancel      取消按钮标题，支持UIAlertAction
 *  @param cancelBlock 取消按钮事件
 */
- (void)fwShowAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock;

/**
 *  显示警告框(详细版)
 *
 *  @param title       警告框标题，支持NSAttributedString
 *  @param message     警告框消息，支持NSAttributedString
 *  @param cancel      取消按钮标题，支持UIAlertAction
 *  @param actions     动作按钮标题列表，支持UIAlertAction
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
 *  @param title        确认框标题，支持NSAttributedString
 *  @param message      确认框消息，支持NSAttributedString
 *  @param cancel       取消按钮文字，支持UIAlertAction
 *  @param confirm      确认按钮文字，支持UIAlertAction
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
 *  @param title        确认框标题，支持NSAttributedString
 *  @param message      确认框消息，支持NSAttributedString
 *  @param cancel       取消按钮文字，支持UIAlertAction
 *  @param confirm      确认按钮文字，支持UIAlertAction
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
 *  @param title        输入框标题，支持NSAttributedString
 *  @param message      输入框消息，支持NSAttributedString
 *  @param cancel       取消按钮文字，支持UIAlertAction
 *  @param confirm      确认按钮文字，支持UIAlertAction
 *  @param confirmBlock 确认按钮事件
 */
- (void)fwShowPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                 confirmBlock:(nullable void (^)(NSString *text))confirmBlock;

/**
 *  显示输入框(详细版)
 *
 *  @param title        输入框标题，支持NSAttributedString
 *  @param message      输入框消息，支持NSAttributedString
 *  @param cancel       取消按钮文字，支持UIAlertAction
 *  @param confirm      确认按钮文字，支持UIAlertAction
 *  @param promptBlock  输入框初始化事件
 *  @param confirmBlock 确认按钮事件
 *  @param cancelBlock  取消按钮事件
 *  @param priority     警告框优先级
 */
- (void)fwShowPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptBlock:(nullable void (^)(UITextField *textField))promptBlock
                 confirmBlock:(nullable void (^)(NSString *text))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock
                     priority:(FWAlertPriority)priority;

#pragma mark - Sheet

/**
 *  显示操作表(简单版)
 *
 *  @param title       操作表标题，支持NSAttributedString
 *  @param message     操作表消息，支持NSAttributedString
 *  @param cancel      取消按钮标题，支持UIAlertAction
 *  @param actions     动作按钮标题列表，支持UIAlertAction
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
 *  @param title       操作表标题，支持NSAttributedString
 *  @param message     操作表消息，支持NSAttributedString
 *  @param cancel      取消按钮标题，支持UIAlertAction
 *  @param actions     动作按钮标题列表，支持UIAlertAction
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

@end

#pragma mark - UIAlertController+FWAlert

// 系统弹出框控制器分类，自定义样式
@interface UIAlertController (FWAlert)

// 快速创建弹出控制器，支持字符串和NSAttributedString
+ (instancetype)fwAlertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

@end

#pragma mark - UIAlertAction+FWAlert

// 系统弹出框动作分类，自定义属性
@interface UIAlertAction (FWAlert)

// 快速创建弹出动作，支持标题和样式
+ (instancetype)fwActionWithTitle:(nullable NSString *)title style:(UIAlertActionStyle)style;

// 快速创建弹出动作，支持字符串和UIAlertAction(拷贝)
+ (instancetype)fwActionWithObject:(nullable id)object style:(UIAlertActionStyle)style handler:(void (^ __nullable)(UIAlertAction *action))handler;

// 是否是首选动作
@property (nonatomic, assign) BOOL fwIsPreferred;

// 快捷设置首选动作
@property (nonatomic, copy, readonly) UIAlertAction *(^fwPreferred)(BOOL preferred) NS_REFINED_FOR_SWIFT;

// 快捷设置是否禁用
@property (nonatomic, copy, readonly) UIAlertAction *(^fwEnabled)(BOOL enabled) NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWAlertConfig

/*! @brief 弹出框全局配置单例类，默认系统样式 */
@interface FWAlertConfig : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWAlertConfig *sharedInstance;

/*! @brief 背景颜色 */
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
/*! @brief 分割线颜色 */
@property (nonatomic, strong, nullable) UIColor *separatorColor;

/*! @brief 标题颜色 */
@property (nonatomic, strong, nullable) UIColor *titleColor;
/*! @brief 标题字体 */
@property (nonatomic, strong, nullable) UIFont *titleFont;

/*! @brief 消息颜色 */
@property (nonatomic, strong, nullable) UIColor *messageColor;
/*! @brief 消息字体 */
@property (nonatomic, strong, nullable) UIFont *messageFont;

/*! @brief 默认动作颜色 */
@property (nonatomic, strong, nullable) UIColor *defaultActionColor;
/*! @brief 默认动作字体 */
@property (nonatomic, strong, nullable) UIFont *defaultActionFont;

/*! @brief 取消动作颜色 */
@property (nonatomic, strong, nullable) UIColor *cancelActionColor;
/*! @brief 取消动作字体 */
@property (nonatomic, strong, nullable) UIFont *cancelActionFont;

/*! @brief 警告动作颜色 */
@property (nonatomic, strong, nullable) UIColor *destructiveActionColor;
/*! @brief 警告动作字体 */
@property (nonatomic, strong, nullable) UIFont *destructiveActionFont;

/*! @brief 首选动作颜色 */
@property (nonatomic, strong, nullable) UIColor *preferredActionColor;
/*! @brief 首选动作字体 */
@property (nonatomic, strong, nullable) UIFont *preferredActionFont;

/*! @brief 禁用动作颜色 */
@property (nonatomic, strong, nullable) UIColor *disabledActionColor;
/*! @brief 禁用动作字体 */
@property (nonatomic, strong, nullable) UIFont *disabledActionFont;

@end

NS_ASSUME_NONNULL_END
