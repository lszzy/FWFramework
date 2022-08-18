//
//  FWAutoloader.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "FWAutoloader.h"
#import <objc/runtime.h>

@protocol FWAutoloadProtocol <NSObject>
@optional

+ (void)autoload;

@end

@interface FWAutoloader () <FWAutoloadProtocol>

@end

@implementation FWAutoloader

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([FWAutoloader respondsToSelector:@selector(autoload)]) {
            [FWAutoloader autoload];
        }
    });
}

@end
