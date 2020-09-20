/*!
 @header     FWDevice.m
 @indexgroup FWFramework
 @brief      FWDevice
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWDevice.h"
#import "FWCoder.h"
#import "FWRouter.h"
#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>

#pragma mark - UIApplication+FWToolkit

@interface FWSafariViewControllerDelegate : NSObject <SFSafariViewControllerDelegate>

@end

@implementation FWSafariViewControllerDelegate

+ (FWSafariViewControllerDelegate *)sharedInstance
{
    static FWSafariViewControllerDelegate *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSafariViewControllerDelegate alloc] init];
    });
    return instance;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    void (^completion)(void) = objc_getAssociatedObject(controller, @selector(safariViewControllerDidFinish:));
    if (completion) {
        completion();
    }
}

@end

@implementation UIApplication (FWToolkit)

+ (BOOL)fwIsDebug
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

#pragma mark - URL

+ (BOOL)fwCanOpenURL:(id)url
{
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    return [[UIApplication sharedApplication] canOpenURL:nsurl];
}

+ (void)fwOpenURL:(id)url
{
    [self fwOpenURL:url completionHandler:nil];
}

+ (void)fwOpenURL:(id)url completionHandler:(void (^)(BOOL success))completion
{
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
    } else {
        BOOL success = [[UIApplication sharedApplication] openURL:nsurl];
        if (completion) {
            completion(success);
        }
    }
}

+ (void)fwOpenUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
    } else {
        if (completion) {
            completion(NO);
        }
    }
}

+ (void)fwOpenAppStore:(NSString *)appId
{
    // SKStoreProductViewController可以内部打开，但需要加载
    [self fwOpenURL:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", appId]];
}

+ (BOOL)fwIsAppStoreURL:(id)url
{
    // itms-apps等
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    if ([nsurl.scheme hasPrefix:@"itms"]) {
        return YES;
    // https://itunes.apple.com/等
    } else if ([nsurl.host isEqualToString:@"itunes.apple.com"] ||
               [nsurl.host isEqualToString:@"apps.apple.com"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)fwIsAppSchemeURL:(id)url
{
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    if (nsurl.scheme && [@[@"tel", @"telprompt", @"sms", @"mailto"] containsObject:nsurl.scheme]) {
        return YES;
    }
    if ([self fwIsAppStoreURL:nsurl]) {
        return YES;
    }
    if (nsurl.absoluteString && [nsurl.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        return YES;
    }
    return NO;
}

+ (void)fwOpenSafariController:(id)url
{
    [self fwOpenSafariController:url completionHandler:nil];
}

+ (void)fwOpenSafariController:(id)url completionHandler:(nullable void (^)(void))completion
{
    NSURL *nsurl = [url isKindOfClass:[NSString class]] ? [NSURL fwURLWithString:url] : url;
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:nsurl];
    if (completion) {
        objc_setAssociatedObject(safariController, @selector(safariViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        safariController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    }
    [UIWindow.fwMainWindow fwPresentViewController:safariController animated:YES completion:nil];
}

@end

#pragma mark - UIDevice+FWDevice

@implementation UIDevice (FWDevice)

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

@end

#pragma mark - UIScreen+FWDevice

@implementation UIScreen (FWDevice)

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

@end

@implementation UIViewController (FWDevice)

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
