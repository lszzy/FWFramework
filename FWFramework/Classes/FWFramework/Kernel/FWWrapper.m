/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"
#import <objc/runtime.h>

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

+ (instancetype)wrapper:(id)base {
    id wrapper = objc_getAssociatedObject(base, @selector(fw));
    if (!wrapper) {
        wrapper = [[self alloc] init:base];
        objc_setAssociatedObject(base, @selector(fw), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return wrapper;
}

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
    return [FWObjectWrapper wrapper:self];
}

@end

#pragma mark - FWClassWrapper

@implementation FWClassWrapper

+ (instancetype)wrapper:(Class)base {
    return [[self alloc] init:base];
}

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
    return [FWClassWrapper wrapper:self];
}

@end

#pragma mark - FWObjectWrapper

@implementation FWStringWrapper

@end

@implementation NSString (FWStringWrapper)

- (FWStringWrapper *)fw {
    return [FWStringWrapper wrapper:self];
}

@end

@implementation FWDataWrapper

@end

@implementation NSData (FWDataWrapper)

- (FWDataWrapper *)fw {
    return [FWDataWrapper wrapper:self];
}

@end

@implementation FWURLWrapper

@end

@implementation NSURL (FWURLWrapper)

- (FWURLWrapper *)fw {
    return [FWURLWrapper wrapper:self];
}

@end

@implementation FWBundleWrapper

@end

@implementation NSBundle (FWBundleWrapper)

- (FWBundleWrapper *)fw {
    return [FWBundleWrapper wrapper:self];
}

@end

@implementation FWViewWrapper

@dynamic base;

@end

@implementation UIView (FWViewWrapper)

- (FWViewWrapper *)fw {
    return [FWViewWrapper wrapper:self];
}

@end

@implementation FWWindowWrapper

@end

@implementation UIWindow (FWWindowWrapper)

- (FWWindowWrapper *)fw {
    return [FWWindowWrapper wrapper:self];
}

@end

@implementation FWViewControllerWrapper

@dynamic base;

@end

@implementation UIViewController (FWViewControllerWrapper)

- (FWViewControllerWrapper *)fw {
    return [FWViewControllerWrapper wrapper:self];
}

@end

@implementation FWNavigationControllerWrapper

@end

@implementation UINavigationController (FWNavigationControllerWrapper)

- (FWNavigationControllerWrapper *)fw {
    return [FWNavigationControllerWrapper wrapper:self];
}

@end

#pragma mark - FWClassWrapper

@implementation FWStringClassWrapper

@end

@implementation NSString (FWStringClassWrapper)

+ (FWStringClassWrapper *)fw {
    return [FWStringClassWrapper wrapper:self];
}

@end

@implementation FWDataClassWrapper

@end

@implementation NSData (FWDataClassWrapper)

+ (FWDataClassWrapper *)fw {
    return [FWDataClassWrapper wrapper:self];
}

@end

@implementation FWURLClassWrapper

@end

@implementation NSURL (FWURLClassWrapper)

+ (FWURLClassWrapper *)fw {
    return [FWURLClassWrapper wrapper:self];
}

@end

@implementation FWBundleClassWrapper

@end

@implementation NSBundle (FWBundleClassWrapper)

+ (FWBundleClassWrapper *)fw {
    return [FWBundleClassWrapper wrapper:self];
}

@end

@implementation FWApplicationClassWrapper

@end

@implementation UIApplication (FWApplicationClassWrapper)

+ (FWApplicationClassWrapper *)fw {
    return [FWApplicationClassWrapper wrapper:self];
}

@end

@implementation FWDeviceClassWrapper

@end

@implementation UIDevice (FWDeviceClassWrapper)

+ (FWDeviceClassWrapper *)fw {
    return [FWDeviceClassWrapper wrapper:self];
}

@end

@implementation FWScreenClassWrapper

@end

@implementation UIScreen (FWScreenClassWrapper)

+ (FWScreenClassWrapper *)fw {
    return [FWScreenClassWrapper wrapper:self];
}

@end

@implementation FWViewClassWrapper

@end

@implementation UIView (FWViewClassWrapper)

+ (FWViewClassWrapper *)fw {
    return [FWViewClassWrapper wrapper:self];
}

@end

@implementation FWWindowClassWrapper

@end

@implementation UIWindow (FWWindowClassWrapper)

+ (FWWindowClassWrapper *)fw {
    return [FWWindowClassWrapper wrapper:self];
}

@end
