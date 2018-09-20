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

+ (NSString *)fwLocalizedLanguage
{
    NSString *localizedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
    if (localizedLanguage) {
        return localizedLanguage;
    }
    return [NSLocale preferredLanguages].firstObject;
}

+ (void)fwSetLocalizedLanguage:(NSString *)language
{
    if (!language || language.length == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"FWLocalizedLanguage"];
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)fwLocalizedString:(NSString *)key
{
    return [NSBundle fwLocalizedString:key table:nil];
}

+ (NSString *)fwLocalizedString:(NSString *)key table:(NSString *)table
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:table];
}

@end
