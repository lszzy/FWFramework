/*!
 @header     UIFont+FWFramework.h
 @indexgroup FWFramework
 @brief      UIFont+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <UIKit/UIKit.h>

/*!
 @brief UIFont+FWFramework
 */
@interface UIFont (FWFramework)

// 是否是普通字体
- (BOOL)fwIsNormal;

// 是否是粗体
- (BOOL)fwIsBold;

// 是否是斜体
- (BOOL)fwIsItalic;

// 是否是粗斜体
- (BOOL)fwIsBoldItalic;

// 当前字体的普通字体
- (UIFont *)fwNormalFont;

// 当前字体的粗体字体
- (UIFont *)fwBoldFont;

// 当前字体的斜体字体
- (UIFont *)fwItalicFont;

// 当前字体的粗斜体字体
- (UIFont *)fwBoldItalicFont;

@end
