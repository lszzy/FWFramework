/*!
 @header     NSBundle+FWFramework.m
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSBundle+FWFramework.h"

@implementation NSBundle (FWFramework)

+ (instancetype)fwBundleWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

@end
