//
//  AppStandard.m
//  Example
//
//  Created by wuyong on 16/11/9.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "AppStandard.h"

#pragma mark - UIColor+AppStandard

#define AppColorHex( hex, opacity ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:opacity]

#define AppColorImpl( name, hex, opacity ) \
+ (UIColor *)name \
{ \
    static UIColor *name##_color; \
    static dispatch_once_t name##_onceToken; \
    dispatch_once(&name##_onceToken, ^{ \
        name##_color = AppColorHex(hex, opacity); \
    }); \
    return name##_color; \
}

@implementation UIColor (AppStandard)

AppColorImpl(appColorMain, 0x806beb, 1.0);
AppColorImpl(appColorSub, 0x14ccca, 1.0);
AppColorImpl(appColorFill, 0xc8c8c8, 1.0);
AppColorImpl(appColorBg, 0xf0f0f0, 1.0);
AppColorImpl(appColorBorder, 0xc8c8c8, 1.0);
AppColorImpl(appColorCover, 0x000000, 0.9);

AppColorImpl(appColorDarkgray, 0x1c1c1c, 1.0);
AppColorImpl(appColorDeepgray, 0x727272, 1.0);
AppColorImpl(appColorLightgray, 0xa8a8a8, 1.0);

AppColorImpl(appColorWhite, 0xffffff, 1.0);
AppColorImpl(appColorWhiteOpacityHuge, 0xffffff, 0.95);
AppColorImpl(appColorWhiteOpacityLarge, 0xffffff, 0.70);
AppColorImpl(appColorWhiteOpacityNormal, 0xffffff, 0.50);
AppColorImpl(appColorWhiteOpacitySmall, 0xffffff, 0.30);
AppColorImpl(appColorWhiteOpacityTiny, 0xffffff, 0.15);

AppColorImpl(appColorBlack, 0x000000, 1.0);
AppColorImpl(appColorBlackOpacityHuge, 0x000000, 0.95);
AppColorImpl(appColorBlackOpacityLarge, 0x000000, 0.70);
AppColorImpl(appColorBlackOpacityNormal, 0x000000, 0.50);
AppColorImpl(appColorBlackOpacitySmall, 0x000000, 0.30);
AppColorImpl(appColorBlackOpacityTiny, 0x000000, 0.15);

+ (UIColor *)appColorClear
{
    return [UIColor clearColor];
}

+ (UIColor *)appColorHex:(long)hex
{
    return [UIColor appColorHex:hex alpha:1.0];
}

+ (UIColor *)appColorHex:(long)hex alpha:(CGFloat)alpha
{
    return AppColorHex(hex, alpha);
}

@end

#pragma mark - UIFont+AppStandard

#define AppFontImpl( name, size, bold ) \
+ (UIFont *)name \
{ \
    if (bold) { \
        return [UIFont boldSystemFontOfSize:size]; \
    } else { \
        return [UIFont systemFontOfSize:size]; \
    } \
}

@implementation UIFont (AppStandard)

AppFontImpl(appFontHuge, 24, NO);
AppFontImpl(appFontLarge, 18, NO);
AppFontImpl(appFontNormal, 16, NO);
AppFontImpl(appFontSmall, 14, NO);
AppFontImpl(appFontTiny, 12, NO);

+ (UIFont *)appFontSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size];
}

AppFontImpl(appFontBoldHuge, 24, YES);
AppFontImpl(appFontBoldLarge, 18, YES);
AppFontImpl(appFontBoldNormal, 16, YES);
AppFontImpl(appFontBoldSmall, 14, YES);
AppFontImpl(appFontBoldTiny, 12, YES);

+ (UIFont *)appFontBoldSize:(CGFloat)size
{
    return [UIFont boldSystemFontOfSize:size];
}

@end

#pragma mark - AppStandard

#import <FWFramework/FWFramework.h>

@implementation AppStandard

+ (UIButton *)buttonWithStyle:(AppButtonStyle)style
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button fwSetAutoLayout:YES];
    [button fwSetCornerRadius:kAppCornerRadiusNormal];
    button.titleLabel.font = [UIFont appFontLarge];
    [button setTitleColor:[UIColor appColorWhite] forState:UIControlStateNormal];
    // 设置阴影
    [button.titleLabel fwSetShadowColor:[UIColor appColorBlack] offset:CGSizeMake(0, -1) radius:0.01];
    // 全局背景色
    button.backgroundColor = [UIColor appColorMain];
    // 禁用背景色图片
    [button fwSetBackgroundColor:[UIColor appColorFill] forState:UIControlStateDisabled];
    [button fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - kAppPaddingLarge * 2];
    [button fwSetDimension:NSLayoutAttributeHeight toSize:45];
    return button;
}

+ (UITextField *)textFieldWithStyle:(AppTextFieldStyle)style
{
    UITextField *textField = [UITextField fwAutoLayoutView];
    textField.font = [UIFont appFontNormal];
    textField.textColor = [UIColor appColorBlackOpacityHuge];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [textField fwSetBorderView:UIRectEdgeBottom color:[UIColor appColorBorder] width:kAppBorderHeightNormal];
    [textField fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - kAppPaddingLarge * 2];
    [textField fwSetDimension:NSLayoutAttributeHeight toSize:50];
    return textField;
}

+ (UITextView *)textViewWithStyle:(AppTextViewStyle)style
{
    UITextView *textView = [UITextView fwAutoLayoutView];
    textView.font = [UIFont appFontNormal];
    textView.textColor = [UIColor appColorBlackOpacityHuge];
    [textView fwSetBorderColor:[UIColor appColorBorder] width:kAppBorderHeightNormal cornerRadius:kAppCornerRadiusNormal];
    [textView fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - kAppPaddingLarge * 2];
    [textView fwSetDimension:NSLayoutAttributeHeight toSize:100];
    return textView;
}

@end
