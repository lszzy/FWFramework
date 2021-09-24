/*!
 @header     FWUIKit.m
 @indexgroup FWFramework
 @brief      FWUIKit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWUIKit.h"
#import "FWSwizzle.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

#pragma mark - UIDevice+FWUIKit

@implementation UIDevice (FWUIKit)

+ (void)fwSetDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[deviceToken copy] forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fwDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
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

#pragma mark - UIView+FWUIKit

@implementation UIView (FWUIKit)

- (UIViewController *)fwViewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

@end

#pragma mark - UIButton+FWUIKit

@implementation UIButton (FWUIKit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIButton, @selector(setEnabled:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL enabled), FWSwizzleCode({
            FWSwizzleOriginal(enabled);
            
            if (selfObject.fwDisabledAlpha > 0) {
                selfObject.alpha = enabled ? 1 : selfObject.fwDisabledAlpha;
            }
        }));
        
        FWSwizzleClass(UIButton, @selector(setHighlighted:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL highlighted), FWSwizzleCode({
            FWSwizzleOriginal(highlighted);
            
            if (selfObject.enabled && selfObject.fwHighlightedAlpha > 0) {
                selfObject.alpha = highlighted ? selfObject.fwHighlightedAlpha : 1;
            }
        }));
    });
}

- (CGFloat)fwDisabledAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwDisabledAlpha)) doubleValue];
}

- (void)setFwDisabledAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwDisabledAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (alpha > 0) {
        self.alpha = self.isEnabled ? 1 : alpha;
    }
}

- (CGFloat)fwHighlightedAlpha
{
    return [objc_getAssociatedObject(self, @selector(fwHighlightedAlpha)) doubleValue];
}

- (void)setFwHighlightedAlpha:(CGFloat)alpha
{
    objc_setAssociatedObject(self, @selector(fwHighlightedAlpha), @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.enabled && alpha > 0) {
        self.alpha = self.isHighlighted ? alpha : 1;
    }
}

@end

#pragma mark - UIViewController+FWUIKit

@implementation UIViewController (FWUIKit)

- (BOOL)fwIsRoot
{
    return !self.navigationController || self.navigationController.viewControllers.firstObject == self;
}

- (BOOL)fwIsChild
{
    UIViewController *parentController = self.parentViewController;
    if (parentController && ![parentController isKindOfClass:[UINavigationController class]] &&
        ![parentController isKindOfClass:[UITabBarController class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)fwIsPresented
{
    UIViewController *viewController = self;
    if (self.navigationController) {
        if (self.navigationController.viewControllers.firstObject != self) return NO;
        viewController = self.navigationController;
    }
    return viewController.presentingViewController.presentedViewController == viewController;
}

- (BOOL)fwIsPageSheet
{
    if (@available(iOS 13.0, *)) {
        UIViewController *controller = self.navigationController ?: self;
        if (!controller.presentingViewController) return NO;
        UIModalPresentationStyle style = controller.modalPresentationStyle;
        if (style == UIModalPresentationAutomatic || style == UIModalPresentationPageSheet) return YES;
    }
    return NO;
}

- (BOOL)fwIsViewVisible
{
    return self.isViewLoaded && self.view.window;
}

- (BOOL)fwIsLoaded
{
    return [objc_getAssociatedObject(self, @selector(fwIsLoaded)) boolValue];
}

- (void)setFwIsLoaded:(BOOL)fwIsLoaded
{
    objc_setAssociatedObject(self, @selector(fwIsLoaded), @(fwIsLoaded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
