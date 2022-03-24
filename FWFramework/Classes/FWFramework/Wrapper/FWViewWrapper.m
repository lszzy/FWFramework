//
//  FWViewWrapper.m
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWViewWrapper.h"

@implementation FWViewWrapper

@end

@implementation UIView (FWViewWrapper)

- (FWViewWrapper *)fw {
    return [FWViewWrapper wrapperWithBase:self];
}

@end
