/*!
 @header     NSData+FWFramework.m
 @indexgroup FWFramework
 @brief      NSData+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import "NSData+FWFramework.h"

@implementation NSData (FWFramework)

+ (NSData *)fwArchiveObject:(id)object
{
    return [NSKeyedArchiver archivedDataWithRootObject:object];
}

- (id)fwUnarchiveObject
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:self];
}

- (NSString *)fwUTF8String
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}

@end
