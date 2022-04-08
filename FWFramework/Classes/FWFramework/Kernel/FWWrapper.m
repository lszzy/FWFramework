/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

- (instancetype)init:(id)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    return [[FWObjectWrapper alloc] init:self];
}

@end

#pragma mark - FWClassWrapper

@implementation FWClassWrapper

- (instancetype)init:(Class)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end

@implementation NSObject (FWClassWrapper)

+ (FWClassWrapper *)fw {
    return [[FWClassWrapper alloc] init:self];
}

@end

#pragma mark - FWWrapperCompatible

FWDefWrapper(NSString, FWStringWrapper, FWStringClassWrapper);
FWDefWrapper(NSData, FWDataWrapper, FWDataClassWrapper);
FWDefWrapper(NSURL, FWURLWrapper, FWURLClassWrapper);
FWDefWrapper(NSBundle, FWBundleWrapper, FWBundleClassWrapper);
FWDefWrapper(NSTimer, FWTimerWrapper, FWTimerClassWrapper);
FWDefWrapper(CADisplayLink, FWDisplayLinkWrapper, FWDisplayLinkClassWrapper);

FWDefWrapper(UIApplication, FWApplicationWrapper, FWApplicationClassWrapper);
FWDefWrapper(UIDevice, FWDeviceWrapper, FWDeviceClassWrapper);
FWDefWrapper(UIScreen, FWScreenWrapper, FWScreenClassWrapper);
FWDefWrapper(UIView, FWViewWrapper, FWViewClassWrapper);
FWDefWrapper(UIControl, FWControlWrapper, FWControlClassWrapper);
FWDefWrapper(UIGestureRecognizer, FWGestureRecognizerWrapper, FWGestureRecognizerClassWrapper);
FWDefWrapper(UIBarButtonItem, FWBarButtonItemWrapper, FWBarButtonItemClassWrapper);
FWDefWrapper(UINavigationBar, FWNavigationBarWrapper, FWNavigationBarClassWrapper);
FWDefWrapper(UITabBar, FWTabBarWrapper, FWTabBarClassWrapper);
FWDefWrapper(UIToolbar, FWToolbarWrapper, FWToolbarClassWrapper);
FWDefWrapper(UIWindow, FWWindowWrapper, FWWindowClassWrapper);
FWDefWrapper(UIViewController, FWViewControllerWrapper, FWViewControllerClassWrapper);
FWDefWrapper(UINavigationController, FWNavigationControllerWrapper, FWNavigationControllerClassWrapper);
