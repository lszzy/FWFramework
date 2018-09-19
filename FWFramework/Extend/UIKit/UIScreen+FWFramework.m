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

+ (BOOL)fwIsScreenSize:(CGSize)size
{
    return CGSizeEqualToSize(size, [UIScreen mainScreen].bounds.size);
}

+ (BOOL)fwIsScreenResolution:(CGSize)resolution
{
    return CGSizeEqualToSize(resolution, [self fwScreenResolution]);
}

+ (BOOL)fwIsScreen35
{
    return [self fwIsScreenSize:CGSizeMake(320, 480)];
}

+ (BOOL)fwIsScreen40
{
    return [self fwIsScreenSize:CGSizeMake(320, 568)];
}

+ (BOOL)fwIsScreen47
{
    return [self fwIsScreenSize:CGSizeMake(375, 667)];
}

+ (BOOL)fwIsScreen55
{
    return [self fwIsScreenSize:CGSizeMake(414, 736)];
}

+ (BOOL)fwIsScreen58
{
    return [self fwIsScreenSize:CGSizeMake(375, 812)];
}

+ (BOOL)fwIsScreen61
{
    return [self fwIsScreenResolution:CGSizeMake(828, 1792)];
}

+ (BOOL)fwIsScreen65
{
    return [self fwIsScreenResolution:CGSizeMake(1242, 2688)];
}

+ (BOOL)fwIsScreenX
{
    return [self fwIsScreenSize:CGSizeMake(375, 812)] || [self fwIsScreenSize:CGSizeMake(414, 896)];
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
