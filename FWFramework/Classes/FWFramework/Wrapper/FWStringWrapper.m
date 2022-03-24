//
//  FWStringWrapper.m
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWStringWrapper.h"

@implementation FWStringWrapper

@end

@implementation NSString (FWStringWrapper)

- (FWStringWrapper *)fw {
    return [FWStringWrapper wrapperWithBase:self];
}

@end
