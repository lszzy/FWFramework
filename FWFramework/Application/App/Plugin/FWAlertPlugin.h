//
//  FWAlertPlugin.h
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

#pragma mark - FWAlertPlugin

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

#pragma mark - UIViewController+FWAlert

/*!
 @brief 视图控制器系统弹出框分类，支持优先级
 @discussion 系统弹出框仅支持参数类型如下：
    1.title和message仅支持NSString
    2.action仅支持NSString
    如果需要支持NSAttributedString等，建议优先使用FWAlertController
 */
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

#pragma mark - Sheet

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

#pragma mark - Style

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

#pragma mark - UIViewController+FWAlertPriority

// 视图控制器弹窗优先级分类，支持优先级
@interface UIViewController (FWAlertPriority)

// 启用弹出框优先级，未启用不生效
@property (nonatomic, assign) BOOL fwAlertPriorityEnabled;

// 设置弹出优先级，默认普通
@property (nonatomic, assign) FWAlertPriority fwAlertPriority;

// 设置弹出框在指定控制器中按照优先级显示
- (void)fwAlertPriorityPresentIn:(UIViewController *)viewController;

@end

#pragma mark - UIAlertAction+FWAlert

/*!
 @brief 系统弹出框动作分类，自定义属性
 @discussion 系统弹出动作title仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertAction (FWAlert)

// 快速创建弹出动作，title仅支持NSString
+ (instancetype)fwActionWithObject:(nullable id)object style:(UIAlertActionStyle)style handler:(void (^ __nullable)(UIAlertAction *action))handler;

// 指定标题颜色
@property (nonatomic, strong, nullable) UIColor *fwTitleColor;

@end

#pragma mark - UIAlertController+FWAlert

/*!
 @brief 系统弹出框控制器分类，自定义样式
 @discussion 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用FWAlertController
*/
@interface UIAlertController (FWAlert)

// 快速创建弹出控制器，title和message仅支持NSString
+ (instancetype)fwAlertControllerWithTitle:(nullable id)title message:(nullable id)message preferredStyle:(UIAlertControllerStyle)preferredStyle;

// 设置属性标题
@property (nonatomic, copy, nullable) NSAttributedString *fwAttributedTitle;

// 设置属性消息
@property (nonatomic, copy, nullable) NSAttributedString *fwAttributedMessage;

@end

#pragma mark - FWAlertAppearance

/*!
 @brief 系统弹出框样式配置类，由于系统兼容性，建议优先使用FWAlertController
 @discussion 如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
*/
@interface FWAlertAppearance : NSObject

// 单例模式，统一设置样式
+ (instancetype)appearance;

// 自定义首选动作句柄，默认nil，跟随系统
@property (nonatomic, copy, nullable) id _Nullable (^preferredActionBlock)(id alertController);

// 是否启用Controller样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL controllerEnabled;
// 标题颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *titleColor;
// 标题字体，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIFont *titleFont;
// 消息颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *messageColor;
// 消息字体，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIFont *messageFont;

// 是否启用Action样式，设置后自动启用
@property (nonatomic, assign, readonly) BOOL actionEnabled;
// 默认动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *actionColor;
// 首选动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *preferredActionColor;
// 取消动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *cancelActionColor;
// 警告动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *destructiveActionColor;
// 禁用动作颜色，仅全局生效，默认nil
@property (nonatomic, strong, nullable) UIColor *disabledActionColor;

@end

NS_ASSUME_NONNULL_END
