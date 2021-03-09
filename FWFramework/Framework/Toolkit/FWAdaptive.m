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
#import "FWToolkit.h"

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

+ (BOOL)fwIsNotchedScreen
{
    return [self fwSafeAreaInsets].bottom > 0;
}

+ (CGFloat)fwPixelOne
{
    return 1 / UIScreen.mainScreen.scale;
}

+ (BOOL)fwHasSafeAreaInsets
{
    return [self fwSafeAreaInsets].bottom > 0;
}

+ (UIEdgeInsets)fwSafeAreaInsets
{
    if (@available(iOS 11.0, *)) {
        return UIWindow.fwMainWindow.safeAreaInsets;
    } else {
        return UIEdgeInsetsZero;
    }
}

+ (CGFloat)fwStatusBarHeight
{
    if (!UIApplication.sharedApplication.statusBarHidden) {
        return UIApplication.sharedApplication.statusBarFrame.size.height;
    }
    
    if ([UIDevice fwIsIpad]) {
        return [self fwIsNotchedScreen] ? 24 : 20;
    }
    
    if (![self fwIsNotchedScreen]) { return 20; }
    if ([UIDevice fwIsLandscape]) { return 0; }
    if ([[UIDevice fwDeviceModel] isEqualToString:@"iPhone12,1"]) { return 48; }
    if (CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice fwDeviceSize])) { return 47; }
    if ([self fwIsScreenInch:FWScreenInch67]) { return 47; }
    return 44;
}

+ (CGFloat)fwNavigationBarHeight
{
    if ([UIDevice fwIsIpad]) {
        return [UIDevice fwIosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice fwIsLandscape]) {
        height = [self fwIsRegularScreen] ? 44 : 32;
    }
    return height;
}

+ (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
}

+ (CGFloat)fwTabBarHeight
{
    if ([UIDevice fwIsIpad]) {
        if ([self fwIsNotchedScreen]) { return 65; }
        return [UIDevice fwIosVersion] >= 12.0 ? 50 : 49;
    }
    
    CGFloat height = 49;
    if ([UIDevice fwIsLandscape]) {
        height = [self fwIsRegularScreen] ? 49 : 32;
    }
    return height + [self fwSafeAreaInsets].bottom;
}

+ (CGFloat)fwToolBarHeight
{
    if ([UIDevice fwIsIpad]) {
        if ([UIScreen fwIsNotchedScreen]) { return 70; }
        return [UIDevice fwIosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice fwIsLandscape]) {
        height = [self fwIsRegularScreen] ? 44 : 32;
    }
    return height + [self fwSafeAreaInsets].bottom;
}

+ (BOOL)fwIsRegularScreen
{
    // https://github.com/Tencent/QMUI_iOS
    if ([UIDevice fwIsIpad]) { return YES; }
    
    BOOL isZoomedMode = NO;
    if ([UIDevice fwIsIphone]) {
        CGFloat nativeScale = UIScreen.mainScreen.nativeScale;
        CGFloat scale = UIScreen.mainScreen.scale;
        if (CGSizeEqualToSize(UIScreen.mainScreen.nativeBounds.size, CGSizeMake(1080, 1920))) {
            scale /= 1.15;
        }
        isZoomedMode = nativeScale > scale;
    }
    if (isZoomedMode) return NO;
    
    if ([self fwIsScreenInch:FWScreenInch67] ||
        [self fwIsScreenInch:FWScreenInch65] ||
        [self fwIsScreenInch:FWScreenInch61] ||
        [self fwIsScreenInch:FWScreenInch55]) {
        return YES;
    }
    return NO;
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
    if (UIApplication.sharedApplication.statusBarHidden) {
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

- (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
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
        return self.navigationController.toolbar.frame.size.height + [UIScreen fwSafeAreaInsets].bottom;
    }
}

@end
