/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"
#import "FWAppearance.h"
#import <objc/runtime.h>

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

- (instancetype)init:(id)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

- (Class)wrapperClass {
    return [FWClassWrapper class];
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

- (Class)wrapperClass {
    return [FWObjectWrapper class];
}

@end

#pragma mark - NSObject+FWWrapperExtended

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    // 1. 兼容_UIAppearance对象，未指定包装器类时自动查找
    // 2. 如果appearance.fw自定义样式未生效，需fw内部调用原视图类扩展方法才行(详见FWKeyboard)
    if ([self isKindOfClass:NSClassFromString(@"_UIAppearance")]) {
        Class appearanceClass = [FWAppearance classForAppearance:self];
        Class wrapperClass = [[appearanceClass fw] wrapperClass];
        return [[wrapperClass alloc] init:self];
    }
    
    return [[FWObjectWrapper alloc] init:self];
}

@end

@implementation NSObject (FWClassWrapper)

+ (FWClassWrapper *)fw {
    return [[FWClassWrapper alloc] init:self];
}

@end

#pragma mark - FWWrapperExtended

FWDefWrapperFramework_(FWDefWrapper, fw);

#pragma mark - FWWrapper

@implementation FWWrapper

@end
