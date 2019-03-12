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

#pragma mark - FWInnerBundle

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

#pragma mark - NSBundle+FWFramework

@implementation NSBundle (FWFramework)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([self fwLocalizedLanguage]) {
            [self fwLoadLocalizedLanguage];
        }
    });
}

+ (void)fwLoadLocalizedLanguage
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass([NSBundle mainBundle], [FWInnerBundle class]);
    });
    
    NSString *language = [self fwLocalizedLanguage];
    id value = language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil;
    objc_setAssociatedObject([NSBundle mainBundle], &FWInnerBundleKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)fwSystemLanguage
{
    return [NSLocale preferredLanguages].firstObject;
}

+ (NSString *)fwLocalizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

+ (void)fwSetLocalizedLanguage:(NSString *)language
{
    if (language) {
        [[NSUserDefaults standardUserDefaults] setObject:language forKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWLocalizedLanguage"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self fwLoadLocalizedLanguage];
}

@end
