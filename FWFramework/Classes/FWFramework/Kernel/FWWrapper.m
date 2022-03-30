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
    id wrapper = objc_getAssociatedObject(base, @selector(fw));
    if (!wrapper) {
        wrapper = [[self alloc] init:base];
        objc_setAssociatedObject(base, @selector(fw), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return wrapper;
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

#pragma mark - FWStringWrapper

@implementation FWStringWrapper

@end

@implementation FWStringClassWrapper

@end

@implementation NSString (FWStringWrapper)

- (FWStringWrapper *)fw {
    return [FWStringWrapper wrapper:self];
}

+ (FWStringClassWrapper *)fw {
    return [FWStringClassWrapper wrapper:self];
}

@end

#pragma mark - FWDataWrapper

@implementation FWDataWrapper

@end

@implementation FWDataClassWrapper

@end

@implementation NSData (FWDataWrapper)

- (FWDataWrapper *)fw {
    return [FWDataWrapper wrapper:self];
}

+ (FWDataClassWrapper *)fw {
    return [FWDataClassWrapper wrapper:self];
}

@end

#pragma mark - FWURLWrapper

@implementation FWURLWrapper

@end

@implementation FWURLClassWrapper

@end

@implementation NSURL (FWURLWrapper)

- (FWURLWrapper *)fw {
    return [FWURLWrapper wrapper:self];
}

+ (FWURLClassWrapper *)fw {
    return [FWURLClassWrapper wrapper:self];
}

@end

#pragma mark - FWViewWrapper

@implementation FWViewWrapper

@end

@implementation UIView (FWViewWrapper)

- (FWViewWrapper *)fw {
    return [FWViewWrapper wrapper:self];
}

@end

#pragma mark - FWWindowWrapper

@implementation FWWindowWrapper

@end

@implementation FWWindowClassWrapper

@end

@implementation UIWindow (FWWindowWrapper)

- (FWWindowWrapper *)fw {
    return [FWWindowWrapper wrapper:self];
}

+ (FWWindowClassWrapper *)fw {
    return [FWWindowClassWrapper wrapper:self];
}

@end

#pragma mark - FWViewControllerWrapper

@implementation FWViewControllerWrapper

@end

@implementation UIViewController (FWViewControllerWrapper)

- (FWViewControllerWrapper *)fw {
    return [FWViewControllerWrapper wrapper:self];
}

@end

#pragma mark - FWNavigationControllerWrapper

@implementation FWNavigationControllerWrapper

@end

@implementation UINavigationController (FWNavigationControllerWrapper)

- (FWNavigationControllerWrapper *)fw {
    return [FWNavigationControllerWrapper wrapper:self];
}

@end
