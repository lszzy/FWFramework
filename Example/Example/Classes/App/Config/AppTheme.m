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

+ (UIColor *)tableColor
{
    return [UIColor fwThemeLight:[UIColor fwColorWithHex:0xF5F6F8] dark:[UIColor blackColor]];
}

+ (UIColor *)textColor
{
    return [UIColor fwThemeLight:[UIColor blackColor] dark:[UIColor whiteColor]];
}

+ (UIButton *)themeButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button fwSetCornerRadius:5];
    button.titleLabel.font = [UIFont fwFontOfSize:17];
    [button fwSetDimension:NSLayoutAttributeWidth toSize:FWScreenWidth - 15 * 2];
    [button fwSetDimension:NSLayoutAttributeHeight toSize:45];
    return button;
}

@end
