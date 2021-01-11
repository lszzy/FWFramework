//
//  AppTheme.m
//  Example
//
//  Created by wuyong on 2021/1/11.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

#import "AppTheme.h"

@implementation AppTheme

+ (UIColor *)backgroundColor
{
    return [UIColor fwThemeLight:[UIColor whiteColor] dark:[UIColor blackColor]];
}

+ (UIColor *)textColor
{
    return [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
}

+ (UIColor *)barColor
{
    return [UIColor fwThemeLight:[UIColor fwColorWithHex:0xF8F8FD] dark:[UIColor fwColorWithHex:0x121312]];
}

+ (UIColor *)tableColor
{
    return [UIColor fwThemeLight:[UIColor fwColorWithHex:0xF2F2F7] dark:[UIColor fwColorWithHex:0x000000]];
}

+ (UIColor *)cellColor
{
    return [UIColor fwThemeLight:[UIColor fwColorWithHex:0xFFFFFF] dark:[UIColor fwColorWithHex:0x1C1C1E]];
}

+ (UIColor *)borderColor
{
    return [UIColor fwThemeLight:[UIColor fwColorWithHex:0xDDDDDD] dark:[UIColor fwColorWithHex:0x303032]];
}

+ (UIButton *)largeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button fwSetCornerRadius:5];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button fwSetBackgroundColor:[UIColor fwThemeLight:[UIColor fwColorWithHex:0x017AFF] dark:[UIColor fwColorWithHex:0x0A84FF]] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fwBoldFontOfSize:17];
    [button fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [button fwSetDimension:NSLayoutAttributeHeight toSize:45];
    return button;
}

@end
