/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"
#import <objc/runtime.h>

#pragma mark - FWWrapper

@implementation FWWrapper

+ (instancetype)wrapperWithBase:(id)base {
    id wrapper = objc_getAssociatedObject(base, @selector(fw));
    if (!wrapper) {
        wrapper = [[self alloc] initWithBase:base];
        objc_setAssociatedObject(self, @selector(fw), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return wrapper;
}

- (instancetype)initWithBase:(id)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end

#pragma mark - FWClassWrapper

@implementation FWClassWrapper

+ (instancetype)wrapperWithBase:(Class)base {
    id wrapper = objc_getAssociatedObject(base, @selector(fw));
    if (!wrapper) {
        wrapper = [[self alloc] initWithBase:base];
        objc_setAssociatedObject(self, @selector(fw), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return wrapper;
}

- (instancetype)initWithBase:(Class)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end
