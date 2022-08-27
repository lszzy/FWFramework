//
//  FWAutoloader.m
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#import "FWAutoloader.h"

#pragma mark - FWAutoloadProtocol

@protocol FWAutoloadProtocol <NSObject>
@optional

+ (BOOL)autoload:(id)clazz;

@end

#pragma mark - FWAutoloader

@interface FWAutoloader () <FWAutoloadProtocol>

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

#pragma mark - Function

BOOL FWAutoload(id clazz) {
    if ([FWAutoloader respondsToSelector:@selector(autoload:)]) {
        return [FWAutoloader autoload:clazz];
    }
    return NO;
}
