//
//  UIScreen+FWFramework.h
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - Screen

// 屏幕尺寸
#define FWScreenSize \
    [UIScreen mainScreen].bounds.size

// 屏幕宽度
#define FWScreenWidth \
    [UIScreen mainScreen].bounds.size.width

// 屏幕高度
#define FWScreenHeight \
    [UIScreen mainScreen].bounds.size.height

// 屏幕像素比例
#define FWScreenScale \
    [UIScreen mainScreen].scale

// 屏幕分辨率
#define FWScreenResolution \
    CGSizeMake( [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale, [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale )

// 判断屏幕英寸
#define FWIsScreenInch_( x, y ) \
    (CGSizeEqualToSize(CGSizeMake(x, y), [UIScreen mainScreen].bounds.size) ? YES : NO)

// 是否是3.5英寸屏幕
#define FWIsScreen35 \
    FWIsScreenInch_( 320, 480 )

// 是否是4.0英寸屏幕
#define FWIsScreen40 \
    FWIsScreenInch_( 320, 568 )

// 是否是4.7英寸屏幕
#define FWIsScreen47 \
    FWIsScreenInch_( 375, 667 )

// 是否是5.5英寸屏幕
#define FWIsScreen55 \
    FWIsScreenInch_( 414, 736 )

// 是否是5.8英寸屏幕
#define FWIsScreen58 \
    FWIsScreenInch_( 375, 812 )

// 是否是6.1英寸屏幕
#define FWIsScreen61 \
    FWIsScreenInch_( 375, 812 )

// 是否是6.5英寸屏幕
#define FWIsScreen65 \
    FWIsScreenInch_( 375, 812 )

// 是否是iPhoneX系列全面屏幕
#define FWIsScreenX \
    (FWIsScreenInch_( 375, 812 ) || FWIsScreenInch_( 414, 896 ))

// 状态栏高度
#define FWStatusBarHeight (FWIsScreenX ? 44.0 : 20.0)

// 导航栏高度
#define FWNavigationBarHeight (FWIsScreenX ? 88.0 : 44.0)

// 标签栏高度
#define FWTabBarHeight (FWIsScreenX ? 83.0 : 49.0)

@interface UIScreen (FWFramework)

// 屏幕尺寸
+ (CGSize)fwScreenSize;

// 屏幕宽度
+ (CGFloat)fwScreenWidth;

// 屏幕高度
+ (CGFloat)fwScreenHeight;

// 屏幕像素比例
+ (CGFloat)fwScreenScale;

// 屏幕分辨率
+ (CGSize)fwScreenResolution;

// 是否是3.5英寸屏幕
+ (BOOL)fwIsScreen35;

// 是否是4.0英寸屏幕
+ (BOOL)fwIsScreen40;

// 是否是4.7英寸屏幕
+ (BOOL)fwIsScreen47;

// 是否是5.5英寸屏幕
+ (BOOL)fwIsScreen55;

// 是否是5.8英寸iPhoneX屏幕
+ (BOOL)fwIsScreenX;

// 状态栏高度，与是否隐藏无关
+ (CGFloat)fwStatusBarHeight;

// 导航栏高度，与是否隐藏无关
+ (CGFloat)fwNavigationBarHeight;

// 标签栏高度，与是否隐藏无关
+ (CGFloat)fwTabBarHeight;

@end

@interface UIViewController (FWScreen)

// 当前状态栏高度，隐藏为0
- (CGFloat)fwStatusBarHeight;

// 当前导航栏高度，隐藏为0
- (CGFloat)fwNavigationBarHeight;

// 当前标签栏高度，隐藏为0
- (CGFloat)fwTabBarHeight;

@end
