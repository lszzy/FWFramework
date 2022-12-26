//
//  AlertPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAlertPlugin

/// 弹框样式枚举，可扩展
typedef NSInteger FWAlertStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AlertStyle);
/// 默认弹框样式
static const FWAlertStyle FWAlertStyleDefault = 0;
/// 成功弹框样式
static const FWAlertStyle FWAlertStyleSuccess = 1;
/// 失败弹框样式
static const FWAlertStyle FWAlertStyleFailure = 2;

// 弹窗插件协议，应用可自定义弹窗实现
NS_SWIFT_NAME(AlertPlugin)
@protocol FWAlertPlugin <NSObject>

@optional

/// 显示弹出框插件方法，默认使用系统UIAlertController
- (void)viewController:(UIViewController *)viewController
      showAlertWithTitle:(nullable id)title
                 message:(nullable id)message
                   style:(FWAlertStyle)style
                  cancel:(nullable id)cancel
                 actions:(nullable NSArray *)actions
             promptCount:(NSInteger)promptCount
             promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
             actionBlock:(nullable void (^)(NSArray<NSString *> *values, NSInteger index))actionBlock
             cancelBlock:(nullable void (^)(void))cancelBlock
             customBlock:(nullable void (^)(id alertController))customBlock;

/// 显示操作表插件方法，默认使用系统UIAlertController
- (void)viewController:(UIViewController *)viewController
      showSheetWithTitle:(nullable id)title
                 message:(nullable id)message
                  cancel:(nullable id)cancel
                 actions:(nullable NSArray *)actions
            currentIndex:(NSInteger)currentIndex
             actionBlock:(nullable void (^)(NSInteger index))actionBlock
             cancelBlock:(nullable void (^)(void))cancelBlock
             customBlock:(nullable void (^)(id alertController))customBlock;

/// 手工隐藏弹出框插件方法，默认查找UIAlertController|FWAlertController
- (void)viewController:(UIViewController *)viewController
             hideAlert:(BOOL)animated
            completion:(nullable void (^)(void))completion;

/// 判断是否正在显示弹出框插件方法，默认查找UIAlertController|FWAlertController
- (BOOL)isShowingAlert:(UIViewController *)viewController;

@end

#pragma mark - UIViewController+FWAlertPlugin

/// UIViewController使用弹窗插件，全局可使用UIWindow.fw.topPresentedController
@interface UIViewController (FWAlertPlugin)

/// 自定义弹窗插件，未设置时自动从插件池加载
@property (nonatomic, strong, null_resettable) id<FWAlertPlugin> fw_alertPlugin NS_REFINED_FOR_SWIFT;

/**
 *  显示警告框(精简版)，默认关闭按钮
 *
 *  @param title       警告框标题
 *  @param message   警告框消息
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message NS_REFINED_FOR_SWIFT;

/**
 *  显示警告框(简单版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题，默认关闭
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示警告框(详细版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param style        警告框样式
 *  @param cancel      取消按钮标题，默认单按钮关闭，多按钮取消
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                       style:(FWAlertStyle)style
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示确认框(简单版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件
 */
- (void)fw_showConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示确认框(详细版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock
                   cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(简单版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件，参数为输入值
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(详细版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param promptBlock  输入框初始化事件，参数为输入框
 *  @param confirmBlock 确认按钮事件，参数为输入值
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptBlock:(nullable void (^)(UITextField *textField))promptBlock
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(复杂版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param promptCount  输入框数量
 *  @param promptBlock  输入框初始化事件，参数为输入框和索引index
 *  @param confirmBlock 确认按钮事件，参数为输入值数组
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 confirmBlock:(nullable void (^)(NSArray<NSString *> *values))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示弹出框(完整版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param style        警告框样式
 *  @param cancel      取消按钮标题，默认Alert单按钮关闭，Alert多按钮取消
 *  @param actions     动作按钮标题列表
 *  @param promptCount 输入框数量
 *  @param promptBlock 输入框初始化事件，参数为输入框和索引index
 *  @param actionBlock 动作按钮点击事件，参数为输入值数组和索引index
 *  @param cancelBlock 取消按钮事件
 *  @param customBlock 自定义弹出框事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                       style:(FWAlertStyle)style
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 actionBlock:(nullable void (^)(NSArray<NSString *> *values, NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id alertController))customBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(无动作)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(简单版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(详细版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param actions     动作按钮标题列表
 *  @param currentIndex 当前选中动作索引
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(完整版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
 *  @param actions     动作按钮标题列表
 *  @param currentIndex 当前选中动作索引
 *  @param actionBlock 动作按钮点击事件，参数为输入值数组和索引index
 *  @param cancelBlock 取消按钮事件
 *  @param customBlock 自定义弹出框事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id alertController))customBlock NS_REFINED_FOR_SWIFT;

/**
 * 手工隐藏弹出框，完成后回调
 *
 * @param animated 是否执行动画
 * @param completion 完成回调
 */
- (void)fw_hideAlert:(BOOL)animated
          completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 判断是否正在显示弹出框
@property (nonatomic, assign, readonly) BOOL fw_isShowingAlert NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIView+FWAlertPlugin

/// UIView使用弹窗插件，内部使用UIView.fw.viewController
@interface UIView (FWAlertPlugin)

/**
 *  显示警告框(精简版)，默认关闭按钮
 *
 *  @param title       警告框标题
 *  @param message   警告框消息
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message NS_REFINED_FOR_SWIFT;

/**
 *  显示警告框(简单版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param cancel      取消按钮标题，默认关闭
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示警告框(详细版)
 *
 *  @param title       警告框标题
 *  @param message     警告框消息
 *  @param style        警告框样式
 *  @param cancel      取消按钮标题，默认单按钮关闭，多按钮取消
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                       style:(FWAlertStyle)style
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示确认框(简单版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件
 */
- (void)fw_showConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示确认框(详细版)
 *
 *  @param title        确认框标题
 *  @param message      确认框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showConfirmWithTitle:(nullable id)title
                       message:(nullable id)message
                        cancel:(nullable id)cancel
                       confirm:(nullable id)confirm
                  confirmBlock:(nullable void (^)(void))confirmBlock
                   cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(简单版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param confirmBlock 确认按钮事件，参数为输入值
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(详细版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param promptBlock  输入框初始化事件，参数为输入框
 *  @param confirmBlock 确认按钮事件，参数为输入值
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptBlock:(nullable void (^)(UITextField *textField))promptBlock
                 confirmBlock:(nullable void (^)(NSString *value))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示输入框(复杂版)
 *
 *  @param title        输入框标题
 *  @param message      输入框消息
 *  @param cancel       取消按钮文字，默认取消
 *  @param confirm      确认按钮文字，默认确定
 *  @param promptCount  输入框数量
 *  @param promptBlock  输入框初始化事件，参数为输入框和索引index
 *  @param confirmBlock 确认按钮事件，参数为输入值数组
 *  @param cancelBlock  取消按钮事件
 */
- (void)fw_showPromptWithTitle:(nullable id)title
                      message:(nullable id)message
                       cancel:(nullable id)cancel
                      confirm:(nullable id)confirm
                  promptCount:(NSInteger)promptCount
                  promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 confirmBlock:(nullable void (^)(NSArray<NSString *> *values))confirmBlock
                  cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示弹出框(完整版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param style        警告框样式
 *  @param cancel      取消按钮标题，默认Alert单按钮关闭，Alert多按钮取消
 *  @param actions     动作按钮标题列表
 *  @param promptCount 输入框数量
 *  @param promptBlock 输入框初始化事件，参数为输入框和索引index
 *  @param actionBlock 动作按钮点击事件，参数为输入值数组和索引index
 *  @param cancelBlock 取消按钮事件
 *  @param customBlock 自定义弹出框事件
 */
- (void)fw_showAlertWithTitle:(nullable id)title
                     message:(nullable id)message
                       style:(FWAlertStyle)style
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 promptCount:(NSInteger)promptCount
                 promptBlock:(nullable void (^)(UITextField *textField, NSInteger index))promptBlock
                 actionBlock:(nullable void (^)(NSArray<NSString *> *values, NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id alertController))customBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(无动作)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(简单版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param actions     动作按钮标题列表
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(详细版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认取消
 *  @param actions     动作按钮标题列表
 *  @param currentIndex 当前选中动作索引
 *  @param actionBlock 动作按钮点击事件，参数为索引index
 *  @param cancelBlock 取消按钮事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/**
 *  显示操作表(完整版)
 *
 *  @param title       操作表标题
 *  @param message     操作表消息
 *  @param cancel      取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
 *  @param actions     动作按钮标题列表
 *  @param currentIndex 当前选中动作索引
 *  @param actionBlock 动作按钮点击事件，参数为输入值数组和索引index
 *  @param cancelBlock 取消按钮事件
 *  @param customBlock 自定义弹出框事件
 */
- (void)fw_showSheetWithTitle:(nullable id)title
                     message:(nullable id)message
                      cancel:(nullable id)cancel
                     actions:(nullable NSArray *)actions
                currentIndex:(NSInteger)currentIndex
                 actionBlock:(nullable void (^)(NSInteger index))actionBlock
                 cancelBlock:(nullable void (^)(void))cancelBlock
                 customBlock:(nullable void (^)(id alertController))customBlock NS_REFINED_FOR_SWIFT;

/**
 * 手工隐藏弹出框，完成后回调
 *
 * @param animated 是否执行动画
 * @param completion 完成回调
 */
- (void)fw_hideAlert:(BOOL)animated
          completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 判断是否正在显示弹出框
@property (nonatomic, assign, readonly) BOOL fw_isShowingAlert NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
