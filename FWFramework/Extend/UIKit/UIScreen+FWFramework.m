//
//  UIScreen+FWFramework.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "UIScreen+FWFramework.h"

@implementation UIScreen (FWFramework)

+ (CGSize)fwScreenSize
{
    return [UIScreen mainScreen].bounds.size;
}

+ (CGFloat)fwScreenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

+ (CGFloat)fwScreenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

+ (CGFloat)fwScreenScale
{
    return [UIScreen mainScreen].scale;
}

+ (CGSize)fwScreenResolution
{
    return CGSizeMake(
                      [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale,
                      [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale
                      );
}

+ (BOOL)fwInnerIsScreenWidth:(CGFloat)width height:(CGFloat)height
{
    return CGSizeEqualToSize(CGSizeMake(width, height), [UIScreen mainScreen].bounds.size);
}

+ (BOOL)fwIsScreen35
{
    return [self fwInnerIsScreenWidth:320 height:480];
}

+ (BOOL)fwIsScreen40
{
    return [self fwInnerIsScreenWidth:320 height:568];
}

+ (BOOL)fwIsScreen47
{
    return [self fwInnerIsScreenWidth:375 height:667];
}

+ (BOOL)fwIsScreen55
{
    return [self fwInnerIsScreenWidth:414 height:736];
}

+ (BOOL)fwIsScreenX
{
    return [self fwInnerIsScreenWidth:375 height:812];
}

+ (CGFloat)fwStatusBarHeight
{
    return [self fwIsScreenX] ? 44.0 : 20.0;
}

+ (CGFloat)fwNavigationBarHeight
{
    return [self fwIsScreenX] ? 44.0 : 44.0;
}

+ (CGFloat)fwTabBarHeight
{
    return [self fwIsScreenX] ? 83.0 : 49.0;
}

@end

@implementation UIViewController (FWScreen)

+ (BOOL)fwIsControllerStatusBar
{
    static BOOL isController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 读取当前UIViewControllerBasedStatusBarAppearance设置，默认YES视图控制器生效，NO则UIApplication生效
        id object = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
        isController = (object && ![object boolValue]) ? NO : YES;
    });
    return isController;
}

- (CGFloat)fwStatusBarHeight
{
    if ([self.class fwIsControllerStatusBar]) {
        if ([self prefersStatusBarHidden]) {
            return 0.0;
        } else {
            return [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    } else {
        if ([UIApplication sharedApplication].statusBarHidden) {
            return 0.0;
        } else {
            return [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    }
}

- (CGFloat)fwNavigationBarHeight
{
    if (self.navigationController.navigationBarHidden) {
        return 0.0;
    } else {
        return self.navigationController.navigationBar.frame.size.height;
    }
}

- (CGFloat)fwTabBarHeight
{
    if (self.tabBarController.tabBar.hidden) {
        return 0.0;
    } else {
        return self.tabBarController.tabBar.frame.size.height;
    }
}

@end
