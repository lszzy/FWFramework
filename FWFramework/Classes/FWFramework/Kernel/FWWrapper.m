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

#pragma mark - FWObjectWrapperCompatible

FWDefObjectWrapper(NSString, FWStringWrapper);
FWDefObjectWrapper(NSData, FWDataWrapper);
FWDefObjectWrapper(NSURL, FWURLWrapper);
FWDefObjectWrapper(NSBundle, FWBundleWrapper);
FWDefObjectWrapper(UIView, FWViewWrapper);
FWDefObjectWrapper(UINavigationBar, FWNavigationBarWrapper);
FWDefObjectWrapper(UITabBar, FWTabBarWrapper);
FWDefObjectWrapper(UIToolbar, FWToolbarWrapper);
FWDefObjectWrapper(UIWindow, FWWindowWrapper);
FWDefObjectWrapper(UIViewController, FWViewControllerWrapper);
FWDefObjectWrapper(UINavigationController, FWNavigationControllerWrapper);

#pragma mark - FWClassWrapperCompatible

FWDefClassWrapper(NSString, FWStringClassWrapper);
FWDefClassWrapper(NSData, FWDataClassWrapper);
FWDefClassWrapper(NSURL, FWURLClassWrapper);
FWDefClassWrapper(NSBundle, FWBundleClassWrapper);
FWDefClassWrapper(UIApplication, FWApplicationClassWrapper);
FWDefClassWrapper(UIDevice, FWDeviceClassWrapper);
FWDefClassWrapper(UIScreen, FWScreenClassWrapper);
FWDefClassWrapper(UIView, FWViewClassWrapper);
FWDefClassWrapper(UIWindow, FWWindowClassWrapper);
