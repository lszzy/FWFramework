//
//  FWViewControllerWrapper.m
//  FWFramework
//
//  Created by wuyong on 2022/3/24.
//

#import "FWViewControllerWrapper.h"

@implementation FWViewControllerWrapper

@end

@implementation UIViewController (FWViewControllerWrapper)

- (FWViewControllerWrapper *)fw {
    return [FWViewControllerWrapper wrapperWithBase:self];
}

@end
