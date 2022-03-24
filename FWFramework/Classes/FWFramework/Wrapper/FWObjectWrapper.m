//
//  FWObjectWrapper.m
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWObjectWrapper.h"

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

@end

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    return [FWObjectWrapper wrapperWithBase:self];
}

@end

#pragma mark - FWObjectClassWrapper

@implementation FWObjectClassWrapper

@end

@implementation NSObject (FWObjectClassWrapper)

+ (FWObjectClassWrapper *)fw {
    return [FWObjectClassWrapper wrapperWithBase:self];
}

@end
