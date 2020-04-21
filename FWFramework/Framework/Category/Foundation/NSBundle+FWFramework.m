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

+ (NSString *)fwLocalizedString:(NSString *)key
{
    return [self fwLocalizedString:key table:nil];
}

+ (NSString *)fwLocalizedString:(NSString *)key table:(NSString *)table
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
}

@end
