//
//  ToastPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWToastPlugin

/// 消息吐司样式枚举，可扩展
typedef NSInteger __FWToastStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ToastStyle);
/// 默认消息样式
static const __FWToastStyle __FWToastStyleDefault = 0;
/// 成功消息样式
static const __FWToastStyle __FWToastStyleSuccess = 1;
/// 失败消息样式
static const __FWToastStyle __FWToastStyleFailure = 2;

/// 吐司插件协议，应用可自定义吐司插件实现
NS_SWIFT_NAME(ToastPlugin)
@protocol __FWToastPlugin <NSObject>

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
- (void)showMessageWithAttributedText:(nullable NSAttributedString *)attributedText style:(__FWToastStyle)style autoHide:(BOOL)autoHide interactive:(BOOL)interactive completion:(nullable void (^)(void))completion inView:(UIView *)view;

/// 隐藏消息吐司
- (void)hideMessage:(UIView *)view;

/// 是否正在显示消息吐司
- (BOOL)isShowingMessage:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
