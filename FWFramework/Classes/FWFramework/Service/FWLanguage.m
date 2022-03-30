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

#pragma mark - FWBundleWrapper+FWLanguage

@implementation FWBundleWrapper (FWLanguage)

- (NSBundle *)localizedBundle
{
    if ([self.base isKindOfClass:[FWInnerBundle class]]) return self.base;
    @synchronized (self.base) {
        if (![self.base isKindOfClass:[FWInnerBundle class]]) {
            object_setClass(self.base, [FWInnerBundle class]);
            
            NSString *language = [NSBundle.fw localizedLanguage];
            if (language) {
                [self languageChanged:[NSNotification notificationWithName:FWLanguageChangedNotification object:language]];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChanged:) name:FWLanguageChangedNotification object:nil];
        }
    }
    return self.base;
}

- (void)languageChanged:(NSNotification *)notification
{
    NSString *language = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
    NSBundle *bundle = [self localizedBundleWithLanguage:language];
    objc_setAssociatedObject(self.base, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSBundle *)localizedBundleWithLanguage:(NSString *)language
{
    return language ? [NSBundle bundleWithPath:[self.base pathForResource:language ofType:@"lproj"]] : nil;
}

@end

#pragma mark - FWBundleClassWrapper+FWLanguage

@implementation FWBundleClassWrapper (FWLanguage)

#pragma mark - Main

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *language = [NSBundle.fw localizedLanguage];
        if (language) {
            [NSBundle.fw localizedChanged:language];
        }
    });
}

- (NSString *)currentLanguage
{
    return [self localizedLanguage] ?: [self systemLanguage];
}

- (NSString *)systemLanguage
{
    // preferredLanguages包含语言和区域信息，可能返回App不支持的语言，示例：zh-Hans-CN
    // return [NSLocale preferredLanguages].firstObject;
    // preferredLocalizations只包含语言信息，只返回App支持的语言，示例：zh-Hans
    return [[NSBundle mainBundle] preferredLocalizations].firstObject;
}

- (NSString *)localizedLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalizedLanguage"];
}

- (void)setLocalizedLanguage:(NSString *)language
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
    [self localizedChanged:language];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FWLanguageChangedNotification object:language];
}

- (void)localizedChanged:(NSString *)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object_setClass(NSBundle.mainBundle, [FWInnerBundle class]);
    });
    
    NSBundle *bundle = language ? [NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:language ofType:@"lproj"]] : nil;
    objc_setAssociatedObject(NSBundle.mainBundle, @selector(localizedStringForKey:value:table:), bundle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)localizedString:(NSString *)key
{
    return [self localizedString:key table:nil];
}

- (NSString *)localizedString:(NSString *)key table:(NSString *)table
{
    return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
}

#pragma mark - Bundle

- (NSBundle *)bundleWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

- (NSBundle *)bundleWithClass:(Class)clazz name:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:clazz];
    if (name.length > 0) {
        NSString *path = [bundle pathForResource:name ofType:([name hasSuffix:@".bundle"] ? nil : @"bundle")];
        bundle = path ? [NSBundle bundleWithPath:path] : nil;
    }
    return bundle;
}

- (NSString *)localizedString:(NSString *)key bundle:(NSBundle *)bundle
{
    return [self localizedString:key table:nil bundle:bundle];
}

- (NSString *)localizedString:(NSString *)key table:(NSString *)table bundle:(NSBundle *)bundle
{
    if (bundle) {
        return [[bundle.fw localizedBundle] localizedStringForKey:key value:nil table:table];
    } else {
        return [[NSBundle mainBundle] localizedStringForKey:key value:nil table:table];
    }
}

@end

#pragma mark - FWStringWrapper+FWLanguage

@implementation FWStringWrapper (FWLanguage)

- (NSString *)localized
{
    return [NSBundle.fw localizedString:self.base];
}

@end
