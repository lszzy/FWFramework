//
//  AlertPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAlertPlugin

/// 弹框样式枚举，可扩展
typedef NSInteger __FWAlertStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(AlertStyle);
/// 默认弹框样式
static const __FWAlertStyle __FWAlertStyleDefault = 0;
/// 成功弹框样式
static const __FWAlertStyle __FWAlertStyleSuccess = 1;
/// 失败弹框样式
static const __FWAlertStyle __FWAlertStyleFailure = 2;

// 弹窗插件协议，应用可自定义弹窗实现
NS_SWIFT_NAME(AlertPlugin)
@protocol __FWAlertPlugin <NSObject>

@optional

/// 显示弹出框插件方法，默认使用系统UIAlertController
- (void)viewController:(UIViewController *)viewController
      showAlertWithTitle:(nullable id)title
                 message:(nullable id)message
                   style:(__FWAlertStyle)style
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

/// 手工隐藏弹出框插件方法，默认查找UIAlertController|__FWAlertController
- (void)viewController:(UIViewController *)viewController
             hideAlert:(BOOL)animated
            completion:(nullable void (^)(void))completion;

/// 判断是否正在显示弹出框插件方法，默认查找UIAlertController|__FWAlertController
- (BOOL)isShowingAlert:(UIViewController *)viewController;

@end

#pragma mark - __FWAlertAppearance

/**
 系统弹出框样式配置类，由于系统兼容性，建议优先使用__FWAlertController
 @note 如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
*/
NS_SWIFT_NAME(AlertAppearance)
@interface __FWAlertAppearance : NSObject

// 单例模式，统一设置样式
@property (class, nonatomic, readonly) __FWAlertAppearance *appearance;

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
