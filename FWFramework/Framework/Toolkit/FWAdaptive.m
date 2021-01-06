/*!
 @header     FWAdaptive.m
 @indexgroup FWFramework
 @brief      FWAdaptive
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWAdaptive.h"
#import "FWRouter.h"

@implementation UIApplication (FWAdaptive)

+ (BOOL)fwIsDebug
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

@end

#pragma mark - UIDevice+FWAdaptive

@implementation UIDevice (FWAdaptive)

+ (BOOL)fwIsSimulator
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)fwIsIphone
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

+ (BOOL)fwIsIpad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (BOOL)fwIsMac
{
#if __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        return NSProcessInfo.processInfo.isiOSAppOnMac ||
            NSProcessInfo.processInfo.isMacCatalystApp;
    }
#endif
    return NO;
}

+ (BOOL)fwIsLandscape
{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

+ (BOOL)fwIsDeviceLandscape
{
    return UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
}

+ (BOOL)fwSetDeviceOrientation:(UIDeviceOrientation)orientation
{
    if ([UIDevice currentDevice].orientation == orientation) {
        [UIViewController attemptRotationToDeviceOrientation];
        return NO;
    }
    
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    return YES;
}

+ (double)fwIosVersion
{
    return [UIDevice currentDevice].systemVersion.doubleValue;
}

+ (BOOL)fwIsIos:(NSInteger)version
{
    return [self fwIosVersion] >= version && [self fwIosVersion] < (version + 1);
}

+ (BOOL)fwIsIosLater:(NSInteger)version
{
    return [self fwIosVersion] >= version;
}

+ (CGSize)fwDeviceSize
{
    return CGSizeMake([self fwDeviceWidth], [self fwDeviceHeight]);
}

+ (CGFloat)fwDeviceWidth
{
    return MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

+ (CGFloat)fwDeviceHeight
{
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

+ (CGSize)fwDeviceResolution
{
    return CGSizeMake([self fwDeviceWidth] * [UIScreen mainScreen].scale, [self fwDeviceHeight] * [UIScreen mainScreen].scale);
}

@end

#pragma mark - UIScreen+FWAdaptive

static CGFloat fwStaticScaleFactorWidth = 375;
static CGFloat fwStaticScaleFactorHeight = 812;

@implementation UIScreen (FWAdaptive)

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

+ (BOOL)fwIsScreenInch:(FWScreenInch)inch
{
    switch (inch) {
        case FWScreenInch35:
            return CGSizeEqualToSize(CGSizeMake(320, 480), [UIDevice fwDeviceSize]);
        case FWScreenInch40:
            return CGSizeEqualToSize(CGSizeMake(320, 568), [UIDevice fwDeviceSize]);
        case FWScreenInch47:
            return CGSizeEqualToSize(CGSizeMake(375, 667), [UIDevice fwDeviceSize]);
        case FWScreenInch54:
            return CGSizeEqualToSize(CGSizeMake(360, 780), [UIDevice fwDeviceSize]);
        case FWScreenInch55:
            return CGSizeEqualToSize(CGSizeMake(414, 736), [UIDevice fwDeviceSize]);
        case FWScreenInch58:
            return CGSizeEqualToSize(CGSizeMake(375, 812), [UIDevice fwDeviceSize]);
        case FWScreenInch61:
            return CGSizeEqualToSize(CGSizeMake(828, 1792), [UIDevice fwDeviceResolution])
                || CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice fwDeviceSize]);
        case FWScreenInch65:
            return CGSizeEqualToSize(CGSizeMake(1242, 2688), [UIDevice fwDeviceResolution]);
        case FWScreenInch67:
            return CGSizeEqualToSize(CGSizeMake(428, 926), [UIDevice fwDeviceSize]);
        default:
            return NO;
    }
}

+ (BOOL)fwIsScreenX
{
    return [self fwSafeAreaInsets].bottom > 0;
}

+ (CGFloat)fwPixelOne
{
    static CGFloat pixelOne = -1.0;
    if (pixelOne < 0) {
        pixelOne = 1 / [[UIScreen mainScreen] scale];
    }
    return pixelOne;
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
            safeAreaInsets = UIWindow.fwMainWindow.safeAreaInsets;
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

+ (void)fwSetScaleFactorSize:(CGSize)size
{
    fwStaticScaleFactorWidth = size.width;
    fwStaticScaleFactorHeight = size.height;
}

+ (CGFloat)fwScaleFactorWidth
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.width / fwStaticScaleFactorWidth;
    } else {
        return [UIScreen mainScreen].bounds.size.width / fwStaticScaleFactorHeight;
    }
}

+ (CGFloat)fwScaleFactorHeight
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.height / fwStaticScaleFactorHeight;
    } else {
        return [UIScreen mainScreen].bounds.size.height / fwStaticScaleFactorWidth;
    }
}

@end

@implementation UIViewController (FWAdaptive)

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
