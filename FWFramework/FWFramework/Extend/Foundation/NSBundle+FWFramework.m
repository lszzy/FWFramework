/*!
 @header     NSBundle+FWFramework.m
 @indexgroup FWFramework
 @brief      NSBundle分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import "NSBundle+FWFramework.h"
#import <objc/runtime.h>

static const char FWInnerBundleKey = 0;

@interface FWInnerBundle : NSBundle

@end

@implementation FWInnerBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle *bundle = objc_getAssociatedObject(self, &FWInnerBundleKey);
    if (bundle) {
        return [bundle localizedStringForKey:key value:value table:tableName];
    } else {
        return [super localizedStringForKey:key value:value table:tableName];
    }
}

@end

@implementation NSBundle (FWFramework)

+ (void)load
{
    NSString *localizedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
    if (localizedLanguage) {
        [self fwApplyLocalizedLanguage:localizedLanguage];
    }
}

+ (void)fwApplyLocalizedLanguage:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [FWInnerBundle class]);
    });
    
    id value = language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil;
    objc_setAssociatedObject([NSBundle mainBundle], &FWInnerBundleKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)fwLocalizedLanguage
{
    NSString *localizedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
    if (localizedLanguage) {
        return localizedLanguage;
    } else {
        return [NSLocale preferredLanguages].firstObject;
    }
}

+ (void)fwSetLocalizedLanguage:(NSString *)language
{
    if (!language) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self fwApplyLocalizedLanguage:nil];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"FWLocalizedLanguage"];
    [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self fwApplyLocalizedLanguage:language];
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
