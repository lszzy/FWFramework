//
//  AppStandard.h
//  Example
//
//  Created by wuyong on 16/11/9.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - Macro

// 列表高度
static CGFloat const kAppTableCellHeightLarge       = 100.f;
static CGFloat const kAppTableCellHeightNormal      = 60.f;
static CGFloat const kAppCollectionCellHeightNormal = 105.f;

// 边框圆角
static CGFloat const kAppBorderHeightLarge  = 1.f;
static CGFloat const kAppBorderHeightNormal = 0.5f;
static CGFloat const kAppCornerRadiusLarge  = 10.f;
static CGFloat const kAppCornerRadiusNormal = 5.f;

// 外边距
static CGFloat const kAppMarginHuge   = 50.f;
static CGFloat const kAppMarginLarge  = 40.f;
static CGFloat const kAppMarginNormal = 30.f;
static CGFloat const kAppMarginSmall  = 20.f;
static CGFloat const kAppMarginTiny   = 10.f;

// 内边距
static CGFloat const kAppPaddingHuge   = 20.f;
static CGFloat const kAppPaddingLarge  = 15.f;
static CGFloat const kAppPaddingNormal = 10.f;
static CGFloat const kAppPaddingSmall  = 5.f;
static CGFloat const kAppPaddingTiny   = 1.f;

// 图标
static CGSize const kAppIconSizeLarge  = (CGSize){36.f, 36.f};
static CGSize const kAppIconSizeNormal = (CGSize){24.f, 24.f};
static CGSize const kAppIconSizeSmall  = (CGSize){18.f, 18.f};
static CGSize const kAppIconSizeTiny   = (CGSize){12.f, 12.f};

// 图片
static CGSize const kAppImageSizeHuge   = (CGSize){72.f, 72.f};
static CGSize const kAppImageSizeLarge  = (CGSize){60.f, 60.f};
static CGSize const kAppImageSizeNormal = (CGSize){48.f, 48.f};
static CGSize const kAppImageSizeSmall  = (CGSize){36.f, 36.f};
static CGSize const kAppImageSizeTiny   = (CGSize){24.f, 24.f};

// 透明度
static CGFloat const kAppOpacityHigh   = 0.75;
static CGFloat const kAppOpacityNormal = 0.5;
static CGFloat const kAppOpacityLow    = 0.25;

// 适配
#define kAppScaleFactorWidth ([UIScreen mainScreen].bounds.size.width / 375.f)
#define kAppScaleFactorHeight ([UIScreen mainScreen].bounds.size.height / 812.f)

#pragma mark - UIColor+AppStandard

@interface UIColor (AppStandard)

// 主题色，用于重要功能的按钮背景
+ (UIColor *)appColorMain;
// 辅助色，用于内容文本及分页符等
+ (UIColor *)appColorSub;
// 填充色，用于按钮禁用背景填充等
+ (UIColor *)appColorFill;
// 背景色，用于页面底色
+ (UIColor *)appColorBg;
// 表格色，用于表格底色
+ (UIColor *)appColorTable;
// 边框色，用于边框及分割线
+ (UIColor *)appColorBorder;
// 遮罩色，用于浅色背景的透明弹窗
+ (UIColor *)appColorCover;
// 透明色，用于背景
+ (UIColor *)appColorClear;

// 暗灰
+ (UIColor *)appColorDarkgray;
// 深灰
+ (UIColor *)appColorDeepgray;
// 亮灰
+ (UIColor *)appColorLightgray;

// 白色，深色背景上的文本或线条颜色
+ (UIColor *)appColorWhite;
// 95%，深色背景上的最重要内容，一级文本
+ (UIColor *)appColorWhiteOpacityHuge;
// 70%，二级文本
+ (UIColor *)appColorWhiteOpacityLarge;
// 50%，三级文本
+ (UIColor *)appColorWhiteOpacityNormal;
// 30%，最不重要内容
+ (UIColor *)appColorWhiteOpacitySmall;
// 15%，分割线，不可用状态
+ (UIColor *)appColorWhiteOpacityTiny;

// 黑色，浅色背景上的文本或线条颜色
+ (UIColor *)appColorBlack;
// 95%，浅色背景的最重要内容，一级文本
+ (UIColor *)appColorBlackOpacityHuge;
// 70%, 二级文本
+ (UIColor *)appColorBlackOpacityLarge;
// 50%，三级文本
+ (UIColor *)appColorBlackOpacityNormal;
// 30%，最不重要内容
+ (UIColor *)appColorBlackOpacitySmall;
// 15%，分割线，不可用状态
+ (UIColor *)appColorBlackOpacityTiny;

// 自定义颜色，透明度为1.0
+ (UIColor *)appColorHex:(long)hex;
// 自定义颜色，自定义透明度
+ (UIColor *)appColorHex:(long)hex alpha:(CGFloat)alpha;

@end

#pragma mark - UIFont+AppStandard

@interface UIFont (AppStandard)

// Regular普通，超大号，导航栏标题，18
+ (UIFont *)appFontHuge;
// Regular普通，大号字体，表格标题等，17
+ (UIFont *)appFontLarge;
// Regular普通，普通字体，文字，15
+ (UIFont *)appFontNormal;
// Regular普通，小号字体，13
+ (UIFont *)appFontSmall;
// Regular普通，超小号字体，10
+ (UIFont *)appFontTiny;

// Bold粗体，超大号粗体，导航栏标题，18
+ (UIFont *)appFontBoldHuge;
// Bold粗体，大号粗体，表格标题等，17
+ (UIFont *)appFontBoldLarge;
// Bold粗体，普通粗体，文字，15
+ (UIFont *)appFontBoldNormal;
// Bold粗体，小号粗体，13
+ (UIFont *)appFontBoldSmall;
// Bold粗体，超小号粗体，10
+ (UIFont *)appFontBoldTiny;

// Light细体，超大号粗体，导航栏标题，18
+ (UIFont *)appFontLightHuge;
// Light细体，大号粗体，表格标题等，17
+ (UIFont *)appFontLightLarge;
// Light细体，普通粗体，文字，15
+ (UIFont *)appFontLightNormal;
// Light细体，小号粗体，13
+ (UIFont *)appFontLightSmall;
// Light细体，超小号粗体，10
+ (UIFont *)appFontLightTiny;

// Medium中黑，超大号粗体，导航栏标题，18
+ (UIFont *)appFontMediumHuge;
// Medium中黑，大号粗体，表格标题等，17
+ (UIFont *)appFontMediumLarge;
// Medium中黑，普通粗体，文字，15
+ (UIFont *)appFontMediumNormal;
// Medium中黑，小号粗体，13
+ (UIFont *)appFontMediumSmall;
// Medium中黑，超小号粗体，10
+ (UIFont *)appFontMediumTiny;

// SemiBold中粗，超大号粗体，导航栏标题，18
+ (UIFont *)appFontSemiBoldHuge;
// SemiBold中粗，大号粗体，表格标题等，17
+ (UIFont *)appFontSemiBoldLarge;
// SemiBold中粗，普通粗体，文字，15
+ (UIFont *)appFontSemiBoldNormal;
// SemiBold中粗，小号粗体，13
+ (UIFont *)appFontSemiBoldSmall;
// SemiBold中粗，超小号粗体，10
+ (UIFont *)appFontSemiBoldTiny;

// 普通，自定义字号
+ (UIFont *)appFontSize:(CGFloat)size;
// 粗体，自定义字号
+ (UIFont *)appFontBoldSize:(CGFloat)size;
// 细体，自定义字号
+ (UIFont *)appFontLightSize:(CGFloat)size;
// 中黑，自定义字号
+ (UIFont *)appFontMediumSize:(CGFloat)size;
// 中粗，自定义字号
+ (UIFont *)appFontSemiBoldSize:(CGFloat)size;

@end

#pragma mark - AppStandard

// 标准按钮
typedef NS_ENUM(NSInteger, AppButtonStyle) {
    // 默认大按钮样式
    kAppButtonStyleDefault = 0,
};

// 标准输入框
typedef NS_ENUM(NSInteger, AppTextFieldStyle) {
    // 默认黑色样式
    kAppTextFieldStyleDefault = 0,
};

// 标准文本框
typedef NS_ENUM(NSInteger, AppTextViewStyle) {
    // 默认黑色样式
    kAppTextViewStyleDefault = 0,
};

@interface AppStandard : NSObject

// 按钮规范
+ (UIButton *)buttonWithStyle:(AppButtonStyle)style;

// 输入框规范
+ (UITextField *)textFieldWithStyle:(AppTextFieldStyle)style;

// 多行输入框规范
+ (UITextView *)textViewWithStyle:(AppTextViewStyle)style;

@end
