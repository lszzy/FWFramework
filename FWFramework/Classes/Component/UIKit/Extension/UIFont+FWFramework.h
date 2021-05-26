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

/// 是否是粗体
@property (nonatomic, assign, readonly) BOOL fwIsBold;

/// 是否是斜体
@property (nonatomic, assign, readonly) BOOL fwIsItalic;

/// 当前字体的粗体字体
@property (nonatomic, strong, readonly) UIFont *fwBoldFont;

/// 当前字体的非粗体字体
@property (nonatomic, strong, readonly) UIFont *fwNonBoldFont;

/// 当前字体的斜体字体
@property (nonatomic, strong, readonly) UIFont *fwItalicFont;

/// 当前字体的非斜体字体
@property (nonatomic, strong, readonly) UIFont *fwNonItalicFont;

#pragma mark - Height

// 字体空白高度(上下之和)
@property (nonatomic, assign, readonly) CGFloat fwSpaceHeight;

// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
- (CGFloat)fwLineSpacingWithMultiplier:(CGFloat)multiplier;

// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
- (CGFloat)fwLineHeightWithMultiplier:(CGFloat)multiplier;

/// 计算当前字体与指定字体居中对齐的偏移值
- (CGFloat)fwBaselineOffset:(UIFont *)font;

@end

NS_ASSUME_NONNULL_END
