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
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

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
    static BOOL isIphone;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIphone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    });
    return isIphone;
}

+ (BOOL)fwIsIpad
{
    static BOOL isIpad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIpad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    });
    return isIpad;
}

+ (float)fwIosVersion
{
    static float version;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [UIDevice currentDevice].systemVersion.floatValue;
    });
    return version;
}

+ (BOOL)fwIsIos:(NSInteger)version
{
    return [self fwIosVersion] >= version && [self fwIosVersion] < (version + 1);
}

+ (BOOL)fwIsIosLater:(NSInteger)version
{
    return [self fwIosVersion] >= version;
}

+ (NSString *)fwDeviceModel
{
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

+ (NSString *)fwDeviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fwDeviceIDFA
{
#if FWCOMPONENT_TRACKING_ENABLED
    return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
#else
    return nil;
#endif
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
        case FWScreenInch54:
            return [self fwIsScreenSize:CGSizeMake(360, 780)];
        case FWScreenInch55:
            return [self fwIsScreenSize:CGSizeMake(414, 736)];
        case FWScreenInch58:
            return [self fwIsScreenSize:CGSizeMake(375, 812)];
        case FWScreenInch61:
            return [self fwIsScreenResolution:CGSizeMake(828, 1792)]
                || [self fwIsScreenSize:CGSizeMake(390, 844)];
        case FWScreenInch65:
            return [self fwIsScreenResolution:CGSizeMake(1242, 2688)];
        case FWScreenInch67:
            return [self fwIsScreenSize:CGSizeMake(428, 926)];
        default:
            return NO;
    }
}

+ (BOOL)fwIsScreenX
{
    return [self fwSafeAreaInsets].bottom > 0;
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
