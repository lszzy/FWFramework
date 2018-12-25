/*!
 @header     NSAttributedString+FWFramework.h
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import <UIKit/UIKit.h>

/*!
 @brief NSAttributedString+FWFramework
 */
@interface NSAttributedString (FWFramework)

// 快速创建NSAttributedString
+ (instancetype)fwAttributedString:(NSString *)string;

// 快速创建NSAttributedString，自定义字体
+ (instancetype)fwAttributedString:(NSString *)string
                          withFont:(UIFont *)font;

// 快速创建NSAttributedString，自定义字体和颜色
+ (instancetype)fwAttributedString:(NSString *)string
                          withFont:(UIFont *)font
                         textColor:(UIColor *)textColor;

@end

/*!
 @brief NSMutableParagraphStyle+FWFramework
 */
@interface NSMutableParagraphStyle (FWFramework)

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight;

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight
                                 lineBreakMode:(NSLineBreakMode)lineBreakMode;

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineHeight:(CGFloat)lineHeight
                                 lineBreakMode:(NSLineBreakMode)lineBreakMode
                                 textAlignment:(NSTextAlignment)textAlignment;

@end
