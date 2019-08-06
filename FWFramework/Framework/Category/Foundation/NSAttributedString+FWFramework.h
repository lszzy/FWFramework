/*!
 @header     NSAttributedString+FWFramework.h
 @indexgroup FWFramework
 @brief      NSAttributedString+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/25
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSAttributedString+FWFramework
 */
@interface NSAttributedString (FWFramework)

// 快速创建NSAttributedString
+ (instancetype)fwAttributedString:(NSString *)string;

// 快速创建NSAttributedString，自定义字体
+ (instancetype)fwAttributedString:(NSString *)string withFont:(nullable UIFont *)font;

// 快速创建NSAttributedString，自定义字体和颜色
+ (instancetype)fwAttributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor;

// 快速创建NSAttributedString，自定义字体、颜色和段落样式
+ (instancetype)fwAttributedString:(NSString *)string withFont:(nullable UIFont *)font textColor:(nullable UIColor *)textColor paragraphStyle:(nullable NSParagraphStyle *)paragraphStyle;

#pragma mark - Size

// 计算所占尺寸
- (CGSize)fwSize;

// 计算在指定绘制区域内所占尺寸
- (CGSize)fwSizeWithDrawSize:(CGSize)drawSize;

@end

/*!
 @brief NSMutableParagraphStyle+FWFramework
 */
@interface NSMutableParagraphStyle (FWFramework)

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing;

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing textAlignment:(NSTextAlignment)textAlignment;

// 快速创建一个NSMutableParagraphStyle
+ (instancetype)fwParagraphStyleWithLineSpacing:(CGFloat)lineSpacing textAlignment:(NSTextAlignment)textAlignment lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

NS_ASSUME_NONNULL_END
