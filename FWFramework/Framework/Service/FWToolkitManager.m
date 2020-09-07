/*!
 @header     FWToolkitManager.m
 @indexgroup FWFramework
 @brief      FWToolkitManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import "FWToolkitManager.h"

#pragma mark - UIScreen+FWToolkit

@implementation UIScreen (FWToolkit)

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

+ (CGFloat)fwPixelOne
{
    static CGFloat pixelOne = -1.0;
    if (pixelOne < 0) {
        pixelOne = 1 / [[UIScreen mainScreen] scale];
    }
    return pixelOne;
}

+ (BOOL)fwIsScreenSize:(CGSize)size
{
    return CGSizeEqualToSize(size, [UIScreen mainScreen].bounds.size);
}

+ (BOOL)fwIsScreenResolution:(CGSize)resolution
{
    return CGSizeEqualToSize(resolution, [self fwScreenResolution]);
}

+ (BOOL)fwIsScreenInch:(FWScreenInch)inch
{
    switch (inch) {
        case FWScreenInch35:
            return [self fwIsScreenSize:CGSizeMake(320, 480)];
        case FWScreenInch40:
            return [self fwIsScreenSize:CGSizeMake(320, 568)];
        case FWScreenInch47:
            return [self fwIsScreenSize:CGSizeMake(375, 667)];
        case FWScreenInch55:
            return [self fwIsScreenSize:CGSizeMake(414, 736)];
        case FWScreenInch58:
            return [self fwIsScreenSize:CGSizeMake(375, 812)];
        case FWScreenInch61:
            return [self fwIsScreenResolution:CGSizeMake(828, 1792)];
        case FWScreenInch65:
            return [self fwIsScreenResolution:CGSizeMake(1242, 2688)];
        default:
            return NO;
    }
}

+ (BOOL)fwIsScreenX
{
    return [self fwIsScreenSize:CGSizeMake(375, 812)] || [self fwIsScreenSize:CGSizeMake(414, 896)];
}

+ (BOOL)fwHasSafeAreaInsets
{
    return [self fwSafeAreaInsets].bottom > 0;
}

+ (UIEdgeInsets)fwSafeAreaInsets
{
    static UIEdgeInsets safeAreaInsets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            UIApplication *application = [UIApplication sharedApplication];
            if ([application.delegate respondsToSelector:@selector(window)]) {
                safeAreaInsets = [application.delegate window].safeAreaInsets;
            } else {
                safeAreaInsets = [application keyWindow].safeAreaInsets;
            }
        } else {
            safeAreaInsets = UIEdgeInsetsZero;
        }
    });
    return safeAreaInsets;
}

+ (CGFloat)fwStatusBarHeight
{
    return [self fwIsScreenX] ? 44.0 : 20.0;
}

+ (CGFloat)fwNavigationBarHeight
{
    return 44.0;
}

+ (CGFloat)fwTabBarHeight
{
    return [self fwIsScreenX] ? 83.0 : 49.0;
}

+ (CGFloat)fwToolBarHeight
{
    return [self fwIsScreenX] ? 78.0 : 44.0;
}

+ (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
}

+ (CGFloat)fwBottomBarHeight
{
    return [self fwTabBarHeight];
}

@end

@implementation UIViewController (FWToolkit)

- (CGFloat)fwStatusBarHeight
{
    if ([self prefersStatusBarHidden]) {
        return 0.0;
    } else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
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

- (CGFloat)fwToolBarHeight
{
    if (self.navigationController.toolbarHidden) {
        return 0.0;
    } else {
        return self.navigationController.toolbar.frame.size.height;
    }
}

- (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
}

- (CGFloat)fwBottomBarHeight
{
    return [self fwTabBarHeight];
}

@end
