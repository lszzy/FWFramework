//
//  NSObject+FWObjc.m
//  FWFramework
//
//  Created by wuyong on 2018/7/16.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "NSObject+FWObjc.h"
#import <FWFramework/FWFramework-Swift.h>

@implementation NSObject (FWObjc)

- (void)fwObjc
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)fwObjcCallSwift
{
    [self fwSwift];
}

@end
