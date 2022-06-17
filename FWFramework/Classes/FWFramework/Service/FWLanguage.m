/**
 @header     FWLanguage.m
 @indexgroup FWFramework
      FWLanguage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/4/21
 */

#import "FWLanguage.h"
#import <objc/runtime.h>

NSNotificationName const FWLanguageChangedNotification = @"FWLanguageChangedNotification";

#pragma mark - FWInnerBundle

@interface FWInnerBundle : NSBundle

@end

@implementation FWInnerBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle *bundle = objc_getAssociatedObject(self, @selector(localizedStringForKey:value:table:));
    if (bundle) {
        return [bundle localizedStringForKey:key value:value table:tableName];
    } else {
        return [super localizedStringForKey:key value:value table:tableName];
    }
}

@end

#pragma mark - NSBundle+FWLanguage

@implementation NSBundle (FWLanguage)

#pragma mark - Main

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *language = [NSBundle fw_localizedLanguage];
        if (language) {
            [NSBundle fw_localizedChanged:language];
        }
    });
}

+ (NSString *)fw_currentLanguage
{
    return [self fw_localizedLanguage] ?: [self fw_systemLanguage];
}

+ (NSString *)fw_systemLanguage
{
    // preferredLanguages包含语言和区域信息，可能返回App不支持的语言，示例：zh-Hans-CN
    // return [NSLocale preferredLanguages].firstObject;
    // preferredLocalizations只包含语言信息，只返回App支持的语言，示例：zh-Hans
    return [[NSBundle mainBundle] preferredLocalizations].firstObject;
}

+ (NSString *)fw_localizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

+ (void)setFw_localizedLanguage:(NSString *)language
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
    [self fw_localizedChanged:language];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLanguageChangedNotification object:language];
}

+ (void)fw_localizedChanged:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass(NSBundle.mainBundle, [FWInnerBundle class]);
    });
    
    NSBundle *bundle = language ? [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:language ofType:@"lproj"]] : nil;
    objc_setAssociatedObject(NSBundle.mainBundle, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)fw_localizedString:(NSString *)key
{
    return [self fw_localizedString:key table:nil];
}

+ (NSString *)fw_localizedString:(NSString *)key table:(NSString *)table
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
}

#pragma mark - Bundle

+ (NSBundle *)fw_bundleWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

+ (NSBundle *)fw_bundleWithClass:(Class)clazz name:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:clazz];
    if (name.length > 0) {
        NSString *path = [bundle pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
        bundle = path ? [NSBundle bundleWithPath:path] : nil;
    }
    return bundle;
}

+ (NSString *)fw_localizedString:(NSString *)key bundle:(NSBundle *)bundle
{
    return [self fw_localizedString:key table:nil bundle:bundle];
}

+ (NSString *)fw_localizedString:(NSString *)key table:(NSString *)table bundle:(NSBundle *)bundle
{
    if (bundle) {
        return [[bundle fw_localizedBundle] localizedStringForKey:key value:nil table:table];
    } else {
        return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
    }
}

#pragma mark - Localized

- (NSBundle *)fw_localizedBundle
{
    if ([self isKindOfClass:[FWInnerBundle class]]) return self;
    @synchronized (self) {
        if (![self isKindOfClass:[FWInnerBundle class]]) {
            object_setClass(self, [FWInnerBundle class]);
            
            NSString *language = [NSBundle fw_localizedLanguage];
            if (language) {
                [self fw_languageChanged:[NSNotification notificationWithName:FWLanguageChangedNotification object:language]];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fw_languageChanged:) name:FWLanguageChangedNotification object:nil];
        }
    }
    return self;
}

- (void)fw_languageChanged:(NSNotification *)notification
{
    NSString *language = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
    NSBundle *bundle = [self fw_localizedBundleWithLanguage:language];
    objc_setAssociatedObject(self, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSBundle *)fw_localizedBundleWithLanguage:(NSString *)language
{
    return language ? [NSBundle bundleWithPath:[self pathForResource:language ofType:@"lproj"]] : nil;
}

@end

#pragma mark - NSString+FWLanguage

@implementation NSString (FWLanguage)

- (NSString *)fw_localized
{
    return [NSBundle fw_localizedString:self];
}

@end
