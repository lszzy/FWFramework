/**
 @header     FWRelative.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIScreen+FWRelative

/// 当前屏幕宽度缩放比例
#define FWScaleWidth [UIScreen fwScaleWidth]
/// 当前屏幕高度缩放比例
#define FWScaleHeight [UIScreen fwScaleHeight]

/**
 UIScreen+FWRelative
 */
@interface UIScreen (FWRelative)

/// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
@property (class, nonatomic, assign) CGSize fwReferenceSize;
/// 获取当前屏幕宽度缩放比例，宽度常用
@property (class, nonatomic, assign, readonly) CGFloat fwScaleWidth;
/// 获取当前屏幕高度缩放比例，高度不常用
@property (class, nonatomic, assign, readonly) CGFloat fwScaleHeight;

/// 获取相对设计图宽度等比例缩放值
+ (CGFloat)fwRelativeValue:(CGFloat)value;

@end

/// 获取相对设计图宽度等比例缩放值
CG_INLINE CGFloat FWRelativeValue(CGFloat value) {
    return [UIScreen fwRelativeValue:value];
}

#pragma mark - UIFont+FWRelative

/// 快速创建等比例缩放系统字体，字重可选，默认Regular
#define FWFontRelative( size, ... ) \
    [UIFont fwFontRelative:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建等比例缩放Thin字体
FOUNDATION_EXPORT UIFont * FWFontThinRelative(CGFloat size);
/// 快速创建等比例缩放Light字体
FOUNDATION_EXPORT UIFont * FWFontLightRelative(CGFloat size);
/// 快速创建等比例缩放Regular字体
FOUNDATION_EXPORT UIFont * FWFontRegularRelative(CGFloat size);
/// 快速创建等比例缩放Medium字体
FOUNDATION_EXPORT UIFont * FWFontMediumRelative(CGFloat size);
/// 快速创建等比例缩放Semibold字体
FOUNDATION_EXPORT UIFont * FWFontSemiboldRelative(CGFloat size);
/// 快速创建等比例缩放Bold字体
FOUNDATION_EXPORT UIFont * FWFontBoldRelative(CGFloat size);
/// 快速创建等比例缩放斜体字体
FOUNDATION_EXPORT UIFont * FWFontItalicRelative(CGFloat size);

/**
 UIFont+FWRelative
 */
@interface UIFont (FWRelative)

/// 返回等比例缩放系统Thin字体
+ (UIFont *)fwThinFontRelative:(CGFloat)size;
/// 返回等比例缩放系统Light字体
+ (UIFont *)fwLightFontRelative:(CGFloat)size;
/// 返回等比例缩放系统Regular字体
+ (UIFont *)fwFontRelative:(CGFloat)size;
/// 返回等比例缩放系统Medium字体
+ (UIFont *)fwMediumFontRelative:(CGFloat)size;
/// 返回等比例缩放系统Semibold字体
+ (UIFont *)fwSemiboldFontRelative:(CGFloat)size;
/// 返回等比例缩放系统Bold字体
+ (UIFont *)fwBoldFontRelative:(CGFloat)size;
/// 返回等比例缩放系统斜体字体
+ (UIFont *)fwItalicFontRelative:(CGFloat)size;

/// 创建指定尺寸和weight的等比例缩放系统字体
+ (UIFont *)fwFontRelative:(CGFloat)size weight:(UIFontWeight)weight;

@end

NS_ASSUME_NONNULL_END
