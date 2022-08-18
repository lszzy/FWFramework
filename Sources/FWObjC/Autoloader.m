//
//  Autoloader.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "Autoloader.h"
#import <objc/runtime.h>

@protocol __AutoloadProtocol <NSObject>
@optional

+ (void)autoload;

@end

@interface __Autoloader () <__AutoloadProtocol>

@end

@implementation __Autoloader

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([__Autoloader respondsToSelector:@selector(autoload)]) {
            [__Autoloader autoload];
        }
    });
}

@end
