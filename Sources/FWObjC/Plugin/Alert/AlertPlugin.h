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

NS_ASSUME_NONNULL_END
