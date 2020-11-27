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

#pragma mark - UIView+FWToastPlugin

/*!
 @brief UIView+FWToastPlugin
 */
@interface UIView (FWToastPlugin)

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

@end

#pragma mark - UIView+FWIndicator

/*!
 @brief UIView+FWIndicator
 */
@interface UIView (FWIndicator)

/**
 *  显示加载指示器，不可点击（简单版）
 *
 *  @param style           样式，小于0时自动适配
 *  @param attributedTitle 属性文本，默认白色、16号字体
 *  @return 加载指示器视图
 */
- (UIView *)fwShowIndicatorLoadingWithStyle:(UIActivityIndicatorViewStyle)style
                            attributedTitle:(nullable NSAttributedString *)attributedTitle;

/**
 *  显示加载指示器，不可点击（详细版）
 *
 *  @param style               样式，小于0时自动适配
 *  @param attributedTitle     属性文本，默认白色、16号字体
 *  @param indicatorColor      指示器颜色，影响指示器和文本颜色
 *  @param backgroundColor     吐司背景色，默认黑色、透明度0.8
 *  @param dimBackgroundColor  全局背景色，默认透明，如#000000,0.4
 *  @param horizontalAlignment 是否水平对齐，默认垂直对齐
 *  @param contentInsets       文本内间距，默认{10, 10, 10, 10}
 *  @param cornerRadius        圆角半径，默认5.0
 *  @return 加载指示器视图
 */
- (UIView *)fwShowIndicatorLoadingWithStyle:(UIActivityIndicatorViewStyle)style
                            attributedTitle:(nullable NSAttributedString *)attributedTitle
                             indicatorColor:(nullable UIColor *)indicatorColor
                            backgroundColor:(nullable UIColor *)backgroundColor
                         dimBackgroundColor:(nullable UIColor *)dimBackgroundColor
                        horizontalAlignment:(BOOL)horizontalAlignment
                              contentInsets:(UIEdgeInsets)contentInsets
                               cornerRadius:(CGFloat)cornerRadius;

/**
 *  隐藏加载指示器，与show必须成对出现
 *
 *  @return 如果加载指示器不存在，返回NO
 */
- (BOOL)fwHideIndicatorLoading;

/**
 *  显示消息指示器，默认不可点击（简单版）
 *
 *  @param attributedText 属性文本，默认白色、16号字体
 *  @return 消息指示器视图，如需点击其它视图可设置userInteractionEnabled为NO
 */
- (UIView *)fwShowIndicatorMessageWithAttributedText:(nullable NSAttributedString *)attributedText;

/**
 *  显示消息指示器，默认不可点击（详细版）
 *
 *  @param attributedText      属性文本，默认白色、16号字体
 *  @param indicatorColor      指示器颜色，影响指示器和文本颜色
 *  @param backgroundColor     吐司背景色，默认黑色、透明度0.8
 *  @param dimBackgroundColor  全局背景色，默认透明，如#000000,0.4
 *  @param paddingWidth        吐司左右最小内间距，默认10
 *  @param contentInsets       文本内间距，默认{10, 10, 10, 10}
 *  @param cornerRadius        圆角半径，默认5.0
 *  @return 消息指示器视图，如需点击其它视图可设置userInteractionEnabled为NO
 */
- (UIView *)fwShowIndicatorMessageWithAttributedText:(nullable NSAttributedString *)attributedText
                                      indicatorColor:(nullable UIColor *)indicatorColor
                                     backgroundColor:(nullable UIColor *)backgroundColor
                                  dimBackgroundColor:(nullable UIColor *)dimBackgroundColor
                                        paddingWidth:(CGFloat)paddingWidth
                                       contentInsets:(UIEdgeInsets)contentInsets
                                        cornerRadius:(CGFloat)cornerRadius;

/**
 *  手工隐藏消息指示器
 *
 *  @return 如果消息指示器不存在，返回NO
 */
- (BOOL)fwHideIndicatorMessage;

/**
 *  延迟n秒后自动隐藏消息指示器
 *
 *  @param delay 延迟时间
 *  @param completion 完成回调
 *  @return 如果消息指示器不存在，返回NO
 */
- (BOOL)fwHideIndicatorMessageAfterDelay:(NSTimeInterval)delay
                              completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
