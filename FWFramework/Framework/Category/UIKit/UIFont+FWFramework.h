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
 @brief 快速创建细字体
 
 @param fontSize 字号
 @return UIFont
 */
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat fontSize);

/*!
 @brief 快速创建普通字体
 
 @param fontSize 字号
 @return UIFont
 */
FOUNDATION_EXPORT UIFont * FWFontNormal(CGFloat fontSize);

/*!
 @brief 快速创建粗体字体
 
 @param fontSize 字号
 @return UIFont
 */
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat fontSize);

/*!
 @brief 快速创建斜体字体
 
 @param fontSize 字号
 @return UIFont
 */
FOUNDATION_EXPORT UIFont * FWFontItalic(CGFloat fontSize);

#pragma mark - UIFont+FWFramework

// 字体weight枚举
typedef NS_ENUM(NSUInteger, FWFontWeight) {
    FWFontWeightLight,
    FWFontWeightNormal,
    FWFontWeightBold,
};

/*!
 @brief UIFont+FWFramework
 */
@interface UIFont (FWFramework)

#pragma mark - Static

// 返回系统字体的细体
+ (UIFont *)fwLightSystemFontOfSize:(CGFloat)fontSize;

// 返回系统字体的普通体
+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize;

// 返回系统字体的粗体
+ (UIFont *)fwBoldSystemFontOfSize:(CGFloat)fontSize;

// 返回系统字体的斜体
+ (UIFont *)fwItalicSystemFontOfSize:(CGFloat)fontSize;

#pragma mark - Weight

// 创建指定尺寸和weight的系统字体
+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize weight:(FWFontWeight)weight;

// 创建指定尺寸和weight和倾斜的系统字体
+ (UIFont *)fwSystemFontOfSize:(CGFloat)fontSize weight:(FWFontWeight)weight italic:(BOOL)italic;

#pragma mark - Font

// 是否是粗体
- (BOOL)fwIsBold;

// 是否是斜体
- (BOOL)fwIsItalic;

// 当前字体的普通字体
- (UIFont *)fwNormalFont;

// 当前字体的粗体字体
- (UIFont *)fwBoldFont;

// 当前字体的常规字体(非斜体)
- (UIFont *)fwRegularFont;

// 当前字体的斜体字体
- (UIFont *)fwItalicFont;

#pragma mark - Height

// 字体占用行高(含空白)
- (CGFloat)fwLineHeight;

// 字体实际高度(不含空白)
- (CGFloat)fwPointHeight;

// 上下单边空白高度，(fwLineHeight-fwPointHeight)/2，用于精确布局
- (CGFloat)fwSpaceHeight;

@end

NS_ASSUME_NONNULL_END
