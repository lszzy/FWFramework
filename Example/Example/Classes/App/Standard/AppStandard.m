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
AppColorImpl(appColorTable, 0xf5f6f8, 1.0);
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

typedef NS_ENUM(NSInteger, AppFontStyle) {
    AppFontStyleRegular = 0,
    AppFontStyleLight,
    AppFontStyleMedium,
    AppFontStyleBold,
    AppFontStyleSemiBold,
};

#define AppFontImpl( name, size, style ) \
    + (UIFont *)name \
    { \
        return [UIFont appFontStyle:style andSize:size]; \
    }

@implementation UIFont (AppStandard)

AppFontImpl(appFontHuge, 18, AppFontStyleRegular);
AppFontImpl(appFontLarge, 17, AppFontStyleRegular);
AppFontImpl(appFontNormal, 15, AppFontStyleRegular);
AppFontImpl(appFontSmall, 13, AppFontStyleRegular);
AppFontImpl(appFontTiny, 10, AppFontStyleRegular);

AppFontImpl(appFontBoldHuge, 18, AppFontStyleBold);
AppFontImpl(appFontBoldLarge, 17, AppFontStyleBold);
AppFontImpl(appFontBoldNormal, 15, AppFontStyleBold);
AppFontImpl(appFontBoldSmall, 13, AppFontStyleBold);
AppFontImpl(appFontBoldTiny, 10, AppFontStyleBold);

AppFontImpl(appFontLightHuge, 18, AppFontStyleLight);
AppFontImpl(appFontLightLarge, 17, AppFontStyleLight);
AppFontImpl(appFontLightNormal, 15, AppFontStyleLight);
AppFontImpl(appFontLightSmall, 13, AppFontStyleLight);
AppFontImpl(appFontLightTiny, 10, AppFontStyleLight);

AppFontImpl(appFontMediumHuge, 18, AppFontStyleMedium);
AppFontImpl(appFontMediumLarge, 17, AppFontStyleMedium);
AppFontImpl(appFontMediumNormal, 15, AppFontStyleMedium);
AppFontImpl(appFontMediumSmall, 13, AppFontStyleMedium);
AppFontImpl(appFontMediumTiny, 10, AppFontStyleMedium);

AppFontImpl(appFontSemiBoldHuge, 18, AppFontStyleSemiBold);
AppFontImpl(appFontSemiBoldLarge, 17, AppFontStyleSemiBold);
AppFontImpl(appFontSemiBoldNormal, 15, AppFontStyleSemiBold);
AppFontImpl(appFontSemiBoldSmall, 13, AppFontStyleSemiBold);
AppFontImpl(appFontSemiBoldTiny, 10, AppFontStyleSemiBold);

+ (UIFont *)appFontSize:(CGFloat)size { return [UIFont appFontStyle:AppFontStyleRegular andSize:size]; }
+ (UIFont *)appFontBoldSize:(CGFloat)size { return [UIFont appFontStyle:AppFontStyleBold andSize:size]; }
+ (UIFont *)appFontLightSize:(CGFloat)size { return [UIFont appFontStyle:AppFontStyleLight andSize:size]; }
+ (UIFont *)appFontMediumSize:(CGFloat)size { return [UIFont appFontStyle:AppFontStyleMedium andSize:size]; }
+ (UIFont *)appFontSemiBoldSize:(CGFloat)size { return [UIFont appFontStyle:AppFontStyleSemiBold andSize:size]; }

+ (UIFont *)appFontStyle:(AppFontStyle)style andSize:(CGFloat)size {
    switch (style) {
        case AppFontStyleLight:
            return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
        case AppFontStyleMedium:
            return [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
        case AppFontStyleBold:
            return [UIFont systemFontOfSize:size weight:UIFontWeightBold];
        case AppFontStyleSemiBold:
            return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
        default:
            return [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
    }
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
    [button.titleLabel fwSetShadowColor:[UIColor appColorBlack] offset:CGSizeMake(0, -1) radius:0.01];
    button.backgroundColor = [UIColor appColorMain];
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
