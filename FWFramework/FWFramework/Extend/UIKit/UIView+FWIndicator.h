/*!
 @header     UIView+FWIndicator.h
 @indexgroup FWFramework
 @brief      UIView+FWIndicator
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIView+FWIndicator
 */
@interface UIView (FWIndicator)

#pragma mark - Indicator

/**
 *  显示加载吐司，不可点击（简单版）
 *
 *  @param style           样式
 *  @param attributedTitle 属性文本，默认白色、16号字体
 *  @return 加载吐司视图
 */
- (UIView *)fwShowIndicatorWithStyle:(UIActivityIndicatorViewStyle)style
                     attributedTitle:(NSAttributedString *)attributedTitle;

/**
 *  显示加载吐司，不可点击（详细版）
 *
 *  @param style               样式
 *  @param attributedTitle     属性文本，默认白色、16号字体
 *  @param backgroundColor     吐司背景色，默认黑色、透明度0.8
 *  @param dimBackgroundColor  全局背景色，默认透明，如#000000,0.4
 *  @param horizontalAlignment 是否水平对齐，默认垂直对齐
 *  @param contentInsets       文本内间距，默认{10, 10, 10, 10}
 *  @param cornerRadius        圆角半径，默认5.0
 *  @return 加载吐司视图
 */
- (UIView *)fwShowIndicatorWithStyle:(UIActivityIndicatorViewStyle)style
                     attributedTitle:(NSAttributedString *)attributedTitle
                     backgroundColor:(UIColor *)backgroundColor
                  dimBackgroundColor:(UIColor *)dimBackgroundColor
                 horizontalAlignment:(BOOL)horizontalAlignment
                       contentInsets:(UIEdgeInsets)contentInsets
                        cornerRadius:(CGFloat)cornerRadius;

/**
 *  隐藏加载吐司，与show必须成对出现
 */
- (void)fwHideIndicator;

#pragma mark - Toast

/**
 *  显示吐司，不可点击（简单版）
 *
 *  @param attributedText 属性文本，默认白色、16号字体
 *  @return 吐司视图
 */
- (UIView *)fwShowToastWithAttributedText:(NSAttributedString *)attributedText;

/**
 *  显示吐司，不可点击（详细版）
 *
 *  @param attributedText      属性文本，默认白色、16号字体
 *  @param backgroundColor     吐司背景色，默认黑色、透明度0.8
 *  @param dimBackgroundColor  全局背景色，默认透明，如#000000,0.4
 *  @param paddingWidth        吐司左右最小内间距，默认10
 *  @param contentInsets       文本内间距，默认{10, 10, 10, 10}
 *  @param cornerRadius        圆角半径，默认5.0
 *  @return 吐司视图
 */
- (UIView *)fwShowToastWithAttributedText:(NSAttributedString *)attributedText
                          backgroundColor:(UIColor *)backgroundColor
                       dimBackgroundColor:(UIColor *)dimBackgroundColor
                             paddingWidth:(CGFloat)paddingWidth
                            contentInsets:(UIEdgeInsets)contentInsets
                             cornerRadius:(CGFloat)cornerRadius;

/**
 *  手工隐藏吐司
 */
- (void)fwHideToast;

/**
 *  延迟n秒后自动隐藏吐司
 *
 *  @param delay 延迟时间
 *  @param completion 完成回调
 */
- (void)fwHideToastAfterDelay:(NSTimeInterval)delay
                   completion:(void (^)(void))completion;

@end
