/*!
 @header     FWToastPlugin.h
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWToastPlugin

/// 消息吐司样式枚举，可扩展
typedef NSInteger FWToastStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 默认消息样式
static const FWToastStyle FWToastStyleDefault = 0;
/// 成功消息样式
static const FWToastStyle FWToastStyleSuccess = 1;
/// 失败消息样式
static const FWToastStyle FWToastStyleFailure = 2;

/// 吐司插件协议，应用可自定义吐司插件实现
@protocol FWToastPlugin <NSObject>

@optional

/// 显示加载吐司，需手工隐藏
- (void)fwShowLoadingWithAttributedText:(nullable NSAttributedString *)attributedText inView:(UIView *)view;

/// 隐藏加载吐司
- (void)fwHideLoading:(UIView *)view;

/// 显示进度条吐司，需手工隐藏
- (void)fwShowProgressWithAttributedText:(nullable NSAttributedString *)attributedText progress:(CGFloat)progress inView:(UIView *)view;

/// 隐藏进度条吐司
- (void)fwHideProgress:(UIView *)view;

/// 显示指定样式消息吐司，自动隐藏，关闭时回调
- (void)fwShowMessageWithAttributedText:(nullable NSAttributedString *)attributedText style:(FWToastStyle)style completion:(nullable void (^)(void))completion inView:(UIView *)view;

/// 隐藏消息吐司，仅用于提前隐藏
- (void)fwHideMessage:(UIView *)view;

@end

/// 吐司插件配置类
@interface FWToastPluginConfig : NSObject

/// 配置单例
@property (class, nonatomic, readonly) FWToastPluginConfig *sharedInstance;

/// 默认加载吐司文本句柄，支持String和AttributedString
@property (nonatomic, copy, nullable) id _Nullable (^defaultLoadingText)(void);
/// 默认进度条吐司文本句柄，支持String和AttributedString
@property (nonatomic, copy, nullable) id _Nullable (^defaultProgressText)(void);
/// 默认消息吐司文本句柄，支持String和AttributedString
@property (nonatomic, copy, nullable) id _Nullable (^defaultMessageText)(FWToastStyle style);

@end

#pragma mark - UIView+FWToastPlugin

/*!
 @brief UIView+FWToastPlugin
 */
@interface UIView (FWToastPlugin)

/// 显示加载吐司，需手工隐藏，默认文本
- (void)fwShowLoading;

/// 显示加载吐司，需手工隐藏，支持String和AttributedString
- (void)fwShowLoadingWithText:(nullable id)text;

/// 隐藏加载吐司
- (void)fwHideLoading;

/// 显示进度条吐司，需手工隐藏，支持String和AttributedString
- (void)fwShowProgressWithText:(nullable id)text progress:(CGFloat)progress;

/// 隐藏进度条吐司
- (void)fwHideProgress;

/// 显示默认样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fwShowMessageWithText:(nullable id)text;

/// 显示指定样式消息吐司，自动隐藏，支持String和AttributedString
- (void)fwShowMessageWithText:(nullable id)text style:(FWToastStyle)style;

/// 显示指定样式消息吐司，自动隐藏，关闭时回调，支持String和AttributedString
- (void)fwShowMessageWithText:(nullable id)text style:(FWToastStyle)style completion:(nullable void (^)(void))completion;

/// 隐藏消息吐司，仅用于提前隐藏
- (void)fwHideMessage;

#pragma mark - Static

/// 显示加载吐司，需手工隐藏，默认文本
+ (void)fwShowLoading;

/// 显示加载吐司，需手工隐藏，支持String和AttributedString
+ (void)fwShowLoadingWithText:(nullable id)text;

/// 隐藏加载吐司
+ (void)fwHideLoading;

/// 显示进度条吐司，需手工隐藏，支持String和AttributedString
+ (void)fwShowProgressWithText:(nullable id)text progress:(CGFloat)progress;

/// 隐藏进度条吐司
+ (void)fwHideProgress;

/// 显示默认样式消息吐司，自动隐藏，支持String和AttributedString
+ (void)fwShowMessageWithText:(nullable id)text;

/// 显示指定样式消息吐司，自动隐藏，支持String和AttributedString
+ (void)fwShowMessageWithText:(nullable id)text style:(FWToastStyle)style;

/// 显示指定样式消息吐司，自动隐藏，关闭时回调，支持String和AttributedString
+ (void)fwShowMessageWithText:(nullable id)text style:(FWToastStyle)style completion:(nullable void (^)(void))completion;

/// 隐藏消息吐司，仅用于提前隐藏
+ (void)fwHideMessage;

@end

NS_ASSUME_NONNULL_END
