/*!
 @header     UIFont+FWFramework.h
 @indexgroup FWFramework
 @brief      UIFont+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIFont+FWFramework
 */
@interface UIFont (FWFramework)

#pragma mark - Font

// 是否是粗体
- (BOOL)fwIsBold;

// 是否是斜体
- (BOOL)fwIsItalic;

// 当前字体的粗体字体
- (UIFont *)fwBoldFont;

// 当前字体的非粗体字体
- (UIFont *)fwNonBoldFont;

// 当前字体的斜体字体
- (UIFont *)fwItalicFont;

// 当前字体的非斜体字体
- (UIFont *)fwNonItalicFont;

#pragma mark - Height

// 字体占用行高(含空白)
- (CGFloat)fwLineHeight;

// 字体实际高度(不含空白)
- (CGFloat)fwPointHeight;

// 字体空白高度(上下之和)
- (CGFloat)fwSpaceHeight;

// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
- (CGFloat)fwLineSpacingWithMultiplier:(CGFloat)multiplier;

// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
- (CGFloat)fwLineHeightWithMultiplier:(CGFloat)multiplier;

@end

NS_ASSUME_NONNULL_END
