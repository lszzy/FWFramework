//
//  FWToastPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWToastPlugin

/// 消息吐司样式枚举，可扩展
typedef NSInteger FWToastStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ToastStyle);
/// 默认消息样式
static const FWToastStyle FWToastStyleDefault = 0;
/// 成功消息样式
static const FWToastStyle FWToastStyleSuccess = 1;
/// 失败消息样式
static const FWToastStyle FWToastStyleFailure = 2;

/// 吐司插件协议，应用可自定义吐司插件实现
NS_SWIFT_NAME(ToastPlugin)
@protocol FWToastPlugin <NSObject>

@optional

/// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
- (void)showLoadingWithAttributedText:(nullable NSAttributedString *)attributedText cancelBlock:(nullable void (^)(void))cancelBlock inView:(UIView *)view;

/// 隐藏加载吐司
- (void)hideLoading:(UIView *)view;

/// 是否正在显示加载吐司
- (BOOL)isShowingLoading:(UIView *)view;

/// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
- (void)showProgressWithAttributedText:(nullable NSAttributedString *)attributedText progress:(CGFloat)progress cancelBlock:(nullable void (^)(void))cancelBlock inView:(UIView *)view;

/// 隐藏进度条吐司
- (void)hideProgress:(UIView *)view;

/// 是否正在显示进度条吐司
- (BOOL)isShowingProgress:(UIView *)view;

/// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调
- (void)showMessageWithAttributedText:(nullable NSAttributedString *)attributedText style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(nullable void (^)(void))completion inView:(UIView *)view;

/// 隐藏消息吐司
- (void)hideMessage:(UIView *)view;

/// 是否正在显示消息吐司
- (BOOL)isShowingMessage:(UIView *)view;

@end

/// UIView使用吐司插件，全局可使用UIWindow.fw.mainWindow
@interface UIView (FWToastPlugin)

/// 自定义吐司插件，未设置时自动从插件池加载
@property (nonatomic, strong, nullable) id<FWToastPlugin> fw_toastPlugin NS_REFINED_FOR_SWIFT;

/// 设置吐司外间距，默认zero
@property (nonatomic, assign) UIEdgeInsets fw_toastInsets NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，默认文本
- (void)fw_showLoading NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，支持String和AttributedString
- (void)fw_showLoadingWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
- (void)fw_showLoadingWithText:(nullable id)text cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏加载吐司
- (void)fw_hideLoading NS_REFINED_FOR_SWIFT;

/// 是否正在显示加载吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingLoading NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，需手工隐藏，支持String和AttributedString
- (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
- (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏进度条吐司
- (void)fw_hideProgress NS_REFINED_FOR_SWIFT;

/// 是否正在显示进度条吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingProgress NS_REFINED_FOR_SWIFT;

/// 显示默认样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 隐藏消息吐司
- (void)fw_hideMessage NS_REFINED_FOR_SWIFT;

/// 是否正在显示消息吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingMessage NS_REFINED_FOR_SWIFT;

@end

/// UIViewController使用吐司插件，内部使用UIViewController.view
@interface UIViewController (FWToastPlugin)

/// 设置吐司是否显示在window上，默认NO，显示到view上
@property (nonatomic, assign) BOOL fw_toastInWindow NS_REFINED_FOR_SWIFT;

/// 设置吐司是否显示在祖先视图上，默认NO，显示到view上
@property (nonatomic, assign) BOOL fw_toastInAncestor NS_REFINED_FOR_SWIFT;

/// 设置吐司外间距，默认zero
@property (nonatomic, assign) UIEdgeInsets fw_toastInsets NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，默认文本
- (void)fw_showLoading NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，支持String和AttributedString
- (void)fw_showLoadingWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，默认需手工隐藏，指定cancelBlock点击时会自动隐藏并调用之，支持String和AttributedString
- (void)fw_showLoadingWithText:(nullable id)text cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏加载吐司
- (void)fw_hideLoading NS_REFINED_FOR_SWIFT;

/// 是否正在显示加载吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingLoading NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，需手工隐藏，支持String和AttributedString
- (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
- (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏进度条吐司
- (void)fw_hideProgress NS_REFINED_FOR_SWIFT;

/// 是否正在显示进度条吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingProgress NS_REFINED_FOR_SWIFT;

/// 显示默认样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
- (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 隐藏消息吐司
- (void)fw_hideMessage NS_REFINED_FOR_SWIFT;

/// 是否正在显示消息吐司
@property (nonatomic, assign, readonly) BOOL fw_isShowingMessage NS_REFINED_FOR_SWIFT;

@end

/// UIWindow全局使用吐司插件，内部使用UIWindow.fw.mainWindow
@interface UIWindow (FWToastPlugin)

/// 设置吐司外间距，默认zero
@property (class, nonatomic, assign) UIEdgeInsets fw_toastInsets NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，默认文本
+ (void)fw_showLoading NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，需手工隐藏，支持String和AttributedString
+ (void)fw_showLoadingWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
+ (void)fw_showLoadingWithText:(nullable id)text cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏加载吐司
+ (void)fw_hideLoading NS_REFINED_FOR_SWIFT;

/// 是否正在显示加载吐司
@property (class, nonatomic, assign, readonly) BOOL fw_isShowingLoading NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，需手工隐藏，支持String和AttributedString
+ (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress NS_REFINED_FOR_SWIFT;

/// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
+ (void)fw_showProgressWithText:(nullable id)text progress:(CGFloat)progress cancelBlock:(nullable void (^)(void))cancelBlock NS_REFINED_FOR_SWIFT;

/// 隐藏进度条吐司
+ (void)fw_hideProgress NS_REFINED_FOR_SWIFT;

/// 是否正在显示进度条吐司
@property (class, nonatomic, assign, readonly) BOOL fw_isShowingProgress NS_REFINED_FOR_SWIFT;

/// 显示默认样式消息吐司，自动隐藏，支持String和AttributedString
+ (void)fw_showMessageWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，支持String和AttributedString
+ (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
+ (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
+ (void)fw_showMessageWithText:(nullable id)text style:(FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(nullable void (^)(void))completion NS_REFINED_FOR_SWIFT;

/// 隐藏消息吐司
+ (void)fw_hideMessage NS_REFINED_FOR_SWIFT;

/// 是否正在显示消息吐司
@property (class, nonatomic, assign, readonly) BOOL fw_isShowingMessage NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
