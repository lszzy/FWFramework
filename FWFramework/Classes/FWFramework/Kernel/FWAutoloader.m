/**
 @header     FWAutoloader.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import "FWAutoloader.h"

@protocol FWInnerAutoloadProtocol <NSObject>
@optional

+ (BOOL)autoload:(id)clazz;

@end

@interface FWAutoloader () <FWInnerAutoloadProtocol>

@end

@implementation FWAutoloader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWAutoload(FWAutoloader.class);
    });
}

@end

BOOL FWAutoload(id clazz) {
    if ([FWAutoloader respondsToSelector:@selector(autoload:)]) {
        return [FWAutoloader autoload:clazz];
    }
    return NO;
}
