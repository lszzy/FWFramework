/*!
 @header     FWToastPluginImpl.h
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIView+FWIndicator

/*!
 @brief UIView+FWIndicator
 */
@interface UIView (FWIndicator)

/**
 *  显示加载指示器，不可点击（简单版）
 *
 *  @param style           样式
 *  @param attributedTitle 属性文本，默认白色、16号字体
 *  @return 加载指示器视图
 */
- (UIView *)fwShowIndicatorLoadingWithStyle:(UIActivityIndicatorViewStyle)style
                            attributedTitle:(nullable NSAttributedString *)attributedTitle;

/**
 *  显示加载指示器，不可点击（详细版）
 *
 *  @param style               样式
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
 *  延迟n秒后自动隐藏加载指示器，如果期间调用了show则取消隐藏，可避免连续show|hide时闪烁问题
 *
 *  @param delay 延迟时间，如0.1秒
 *  @return 如果加载指示器不存在，返回NO
 */
- (BOOL)fwHideIndicatorLoadingAfterDelay:(NSTimeInterval)delay;

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
